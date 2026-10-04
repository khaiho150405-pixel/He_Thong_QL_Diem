BEGIN;
ALTER TABLE public.thanh_phan_diem ALTER COLUMN he_so SET DEFAULT 1.00;
CREATE TABLE public.lich_nhap_diem (
 ma_bang_diem integer NOT NULL REFERENCES public.bang_diem ON DELETE RESTRICT,
 ma_thanh_phan integer NOT NULL REFERENCES public.thanh_phan_diem ON DELETE RESTRICT,
 mo_luc timestamptz(6) NOT NULL,
 dong_luc timestamptz(6) NOT NULL CHECK(dong_luc>mo_luc),
 nguoi_dat integer NOT NULL REFERENCES public.nguoi_dung ON DELETE RESTRICT,
 version integer NOT NULL DEFAULT 1,
 PRIMARY KEY(ma_bang_diem,ma_thanh_phan)
);
CREATE INDEX lich_nhap_diem_deadline_idx ON public.lich_nhap_diem(dong_luc);
GRANT SELECT ON public.lich_nhap_diem TO app_runtime;
REVOKE EXECUTE ON FUNCTION public.chot_cot(text,integer,integer,integer), public.chot_bang_diem(text,integer,integer) FROM app_runtime;
CREATE FUNCTION public.kiem_thoi_gian_nhap(p_book integer,p_component integer) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE w public.lich_nhap_diem;
BEGIN
 SELECT * INTO w FROM public.lich_nhap_diem WHERE ma_bang_diem=p_book AND ma_thanh_phan=p_component;
 IF FOUND AND (clock_timestamp()<w.mo_luc OR clock_timestamp()>=w.dong_luc) THEN
 RAISE EXCEPTION 'GRADE_ENTRY_WINDOW_CLOSED' USING ERRCODE='23514'; END IF;
END $$;
REVOKE ALL ON FUNCTION public.kiem_thoi_gian_nhap(integer,integer) FROM PUBLIC;
CREATE FUNCTION public.dat_lich_nhap_diem(p_session text,p_book integer,p_component integer,p_open timestamptz,p_close timestamptz,p_version integer) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE actor_id integer; b public.bang_diem; current_version integer;
BEGIN
 SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
 WHERE s.ma_bam=p_session AND u.vai_tro='QUAN_TRI_VIEN' AND u.trang_thai AND s.het_han>clock_timestamp() AND s.hoat_dong_cuoi>clock_timestamp()-interval '30 minutes';
 IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
 SELECT * INTO b FROM public.bang_diem WHERE ma_bang_diem=p_book FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
 IF b.trang_thai='DA_CHOT' OR EXISTS(SELECT 1 FROM public.chot_cot_diem WHERE ma_bang_diem=p_book AND ma_thanh_phan=p_component) OR EXISTS(SELECT 1 FROM public.hoc_ky WHERE ma_hoc_ky=b.ma_hoc_ky AND da_cong_bo) THEN
 RAISE EXCEPTION 'COLUMN_LOCKED' USING ERRCODE='23514'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem WHERE ma_mon=b.ma_mon AND ma_thanh_phan=p_component) THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
 SELECT version INTO current_version FROM public.lich_nhap_diem WHERE ma_bang_diem=p_book AND ma_thanh_phan=p_component;
 IF p_version IS NULL OR p_version<>coalesce(current_version,0) THEN RAISE EXCEPTION 'DEADLINE_VERSION_CONFLICT' USING ERRCODE='23514'; END IF;
 IF EXISTS(SELECT 1 FROM public.lich_nhap_diem WHERE ma_bang_diem=p_book AND ma_thanh_phan=p_component AND dong_luc<=clock_timestamp()) THEN RAISE EXCEPTION 'COLUMN_LOCKED' USING ERRCODE='23514'; END IF;
 IF p_open IS NULL OR p_close IS NULL OR p_close<=p_open OR p_close<=clock_timestamp() THEN RAISE EXCEPTION 'INVALID_ENTRY_WINDOW' USING ERRCODE='23514'; END IF;
 INSERT INTO public.lich_nhap_diem VALUES(p_book,p_component,p_open,p_close,actor_id,1)
 ON CONFLICT(ma_bang_diem,ma_thanh_phan) DO UPDATE SET mo_luc=EXCLUDED.mo_luc,dong_luc=EXCLUDED.dong_luc,nguoi_dat=actor_id,version=public.lich_nhap_diem.version+1;
 INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'GRADE_DEADLINE_CONFIGURED',p_book::text||':'||p_component::text);
END $$;
REVOKE ALL ON FUNCTION public.dat_lich_nhap_diem(text,integer,integer,timestamptz,timestamptz,integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.dat_lich_nhap_diem(text,integer,integer,timestamptz,timestamptz,integer) TO app_runtime;
CREATE FUNCTION public.xu_ly_han_nhap_diem() RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE w record; b public.bang_diem; d public.diem_thanh_phan; n integer:=0;
BEGIN
 IF current_setting('transaction_isolation')<>'serializable' THEN RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
 IF NOT pg_try_advisory_xact_lock(714042026) THEN RETURN 0; END IF;
 FOR w IN SELECT l.* FROM public.lich_nhap_diem l WHERE l.dong_luc<=clock_timestamp()
 AND NOT EXISTS(SELECT 1 FROM public.chot_cot_diem c WHERE c.ma_bang_diem=l.ma_bang_diem AND c.ma_thanh_phan=l.ma_thanh_phan)
 ORDER BY l.ma_bang_diem,l.ma_thanh_phan LIMIT 100 LOOP
 SELECT * INTO b FROM public.bang_diem WHERE ma_bang_diem=w.ma_bang_diem FOR UPDATE;
 IF b.trang_thai='DA_CHOT' OR EXISTS(SELECT 1 FROM public.chot_cot_diem WHERE ma_bang_diem=w.ma_bang_diem AND ma_thanh_phan=w.ma_thanh_phan) THEN CONTINUE; END IF;
 -- Sync newly enrolled students before assigning an explicit zero to missing grades.
 INSERT INTO public.diem_thanh_phan(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan)
 SELECT b.ma_bang_diem,hs.ma_hoc_sinh,w.ma_thanh_phan FROM public.hoc_sinh hs WHERE hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc
 ON CONFLICT(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan) DO NOTHING;
 FOR d IN SELECT g.* FROM public.diem_thanh_phan g JOIN public.hoc_sinh hs USING(ma_hoc_sinh)
 WHERE g.ma_bang_diem=b.ma_bang_diem AND g.ma_thanh_phan=w.ma_thanh_phan AND hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc AND (g.gia_tri IS NULL OR g.trang_thai<>'DA_DUYET') FOR UPDATE OF g LOOP
 UPDATE public.diem_thanh_phan SET gia_tri=0.0,trang_thai='DA_DUYET',nguon_nhap='NHAP_TAY' WHERE ma_diem=d.ma_diem;
 INSERT INTO public.lich_su_sua_diem(ma_diem,nguoi_sua,gia_tri_cu,gia_tri_moi,ly_do)
 VALUES(d.ma_diem,w.nguoi_dat,d.gia_tri,0.0,'Hệ thống tự ghi 0 do hết hạn nhập điểm do nhà trường đặt; ô thiếu hoặc chưa được duyệt.');
 END LOOP;
 UPDATE public.phieu_nhan_dien SET trang_thai='LOI',ma_loi='GRADE_DEADLINE_EXPIRED',version=version+1 WHERE ma_bang_diem=b.ma_bang_diem AND ma_thanh_phan=w.ma_thanh_phan AND trang_thai IN ('DANG_XU_LY','CHO_DOI_CHIEU');
 INSERT INTO public.chot_cot_diem(ma_bang_diem,ma_thanh_phan,nguoi_chot) VALUES(b.ma_bang_diem,w.ma_thanh_phan,w.nguoi_dat);
 UPDATE public.bang_diem SET version=version+1,trang_thai=CASE WHEN NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem t WHERE t.ma_mon=b.ma_mon AND NOT EXISTS(SELECT 1 FROM public.chot_cot_diem c WHERE c.ma_bang_diem=b.ma_bang_diem AND c.ma_thanh_phan=t.ma_thanh_phan)) THEN 'DA_CHOT'::public."TrangThaiBangDiem" ELSE trang_thai END WHERE ma_bang_diem=b.ma_bang_diem;
 INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(NULL,'GRADE_COLUMN_AUTO_LOCKED',b.ma_bang_diem::text||':'||w.ma_thanh_phan::text);
 n:=n+1;
 END LOOP;
 RETURN n;
END $$;
REVOKE ALL ON FUNCTION public.xu_ly_han_nhap_diem() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.xu_ly_han_nhap_diem() TO app_runtime;
CREATE OR REPLACE FUNCTION public.kiem_phieu_cot() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
 PERFORM 1 FROM public.bang_diem WHERE ma_bang_diem=NEW.ma_bang_diem FOR UPDATE;
 PERFORM public.kiem_thoi_gian_nhap(NEW.ma_bang_diem,NEW.ma_thanh_phan);
 IF EXISTS(SELECT 1 FROM public.chot_cot_diem WHERE ma_bang_diem=NEW.ma_bang_diem AND ma_thanh_phan=NEW.ma_thanh_phan) THEN RAISE EXCEPTION 'COLUMN_LOCKED' USING ERRCODE='23514'; END IF;
 RETURN NEW;
END $$;
CREATE OR REPLACE FUNCTION public.cap_nhat_diem(p_phien text, p_book integer, p_version integer, p_changes jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE b public.bang_diem; d public.diem_thanh_phan; c jsonb; v numeric;
 actor_id integer; items jsonb:='[]'::jsonb; seen bigint[]:='{}'; cell_id bigint; reason text;
BEGIN
 b:=public.kiem_quyen_ghi_bang(p_phien,p_book,p_version);
 SELECT ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec WHERE ma_bam=p_phien;
 IF p_changes IS NULL OR jsonb_typeof(p_changes)<>'array' THEN
   RAISE EXCEPTION 'INVALID_CHANGES' USING ERRCODE='23514'; END IF;
 IF jsonb_array_length(p_changes) NOT BETWEEN 1 AND 100 THEN
   RAISE EXCEPTION 'INVALID_BATCH_SIZE' USING ERRCODE='23514'; END IF;
 FOR c IN SELECT value FROM jsonb_array_elements(p_changes) LOOP
   IF jsonb_typeof(c)<>'object' OR NOT (c ?& ARRAY['cellId','value','reason'])
   OR (c-ARRAY['cellId','value','reason'])<>'{}'::jsonb
   OR jsonb_typeof(c->'cellId')<>'string' OR (c->>'cellId')!~'^[1-9][0-9]{0,18}$'
   OR jsonb_typeof(c->'reason')<>'string' THEN
     RAISE EXCEPTION 'INVALID_CHANGE' USING ERRCODE='23514'; END IF;
   cell_id:=(c->>'cellId')::bigint;
   IF cell_id=ANY(seen) THEN RAISE EXCEPTION 'DUPLICATE_CELL' USING ERRCODE='23514'; END IF;
   seen:=array_append(seen,cell_id);
   reason:=btrim(c->>'reason');
   IF length(reason) NOT BETWEEN 1 AND 500 THEN RAISE EXCEPTION 'INVALID_REASON' USING ERRCODE='23514'; END IF;
   IF c->'value'='null'::jsonb THEN v:=NULL;
   ELSE
     IF jsonb_typeof(c->'value')<>'string' OR (c->>'value')!~'^(10[.]0|[0-9][.][0-9])$' THEN
       RAISE EXCEPTION 'INVALID_GRADE' USING ERRCODE='23514'; END IF;
     v:=public.kiem_tra_gia_tri_diem((c->>'value')::numeric);
   END IF;
   SELECT * INTO d FROM public.diem_thanh_phan WHERE ma_diem=cell_id AND ma_bang_diem=p_book;
   IF NOT FOUND THEN RAISE EXCEPTION 'CELL_OUTSIDE_BOOK' USING ERRCODE='P0002'; END IF;
   PERFORM public.kiem_thoi_gian_nhap(p_book,d.ma_thanh_phan);
   IF NOT EXISTS(SELECT 1 FROM public.hoc_sinh WHERE ma_hoc_sinh=d.ma_hoc_sinh AND ma_lop=b.ma_lop AND dang_theo_hoc)
   OR NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem WHERE ma_thanh_phan=d.ma_thanh_phan AND ma_mon=b.ma_mon)
   -- Kiểm tra cột điểm có đang được Admin cho phép nhập không
   OR NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem WHERE ma_thanh_phan=d.ma_thanh_phan AND ma_mon=b.ma_mon AND cho_phep_nhap)
   OR d.trang_thai='CHO_DOI_CHIEU' OR EXISTS(SELECT 1 FROM public.phieu_nhan_dien
     WHERE ma_bang_diem=p_book AND ma_thanh_phan=d.ma_thanh_phan AND trang_thai IN ('DANG_XU_LY','CHO_DOI_CHIEU')) THEN
     RAISE EXCEPTION 'CELL_NOT_EDITABLE' USING ERRCODE='23514'; END IF;
   IF d.gia_tri IS DISTINCT FROM v THEN
     UPDATE public.diem_thanh_phan SET gia_tri=v,
       trang_thai=CASE WHEN v IS NULL THEN 'CHUA_CO'::public."TrangThaiDiem" ELSE 'DA_DUYET'::public."TrangThaiDiem" END,
       nguon_nhap='NHAP_TAY' WHERE ma_diem=cell_id;
     INSERT INTO public.lich_su_sua_diem(ma_diem,nguoi_sua,gia_tri_cu,gia_tri_moi,ly_do)
       VALUES(cell_id,actor_id,d.gia_tri,v,reason);
   END IF;
   SELECT * INTO d FROM public.diem_thanh_phan WHERE ma_diem=cell_id;
   items:=items || jsonb_build_array(jsonb_build_object('id',d.ma_diem::text,
     'value',d.gia_tri::text,'status',d.trang_thai,'source',d.nguon_nhap));
 END LOOP;
 UPDATE public.bang_diem SET version=version+1 WHERE ma_bang_diem=p_book;
 INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'GRADES_UPDATED','bang_diem:'||p_book);
 RETURN jsonb_build_object('items',items,'bookId',p_book,'version',b.version+1);
END $$;
CREATE OR REPLACE FUNCTION public.duyet_phieu_nhan_dien(
  p_phien text,
  p_book integer,
  p_ticket bigint,
  p_ticket_version integer,
  p_book_version integer,
  p_decisions jsonb,
  p_idempotency_key text,
  p_request_hash text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  b public.bang_diem;
  ticket public.phieu_nhan_dien;
  evidence public.ket_qua_dong;
  grade public.diem_thanh_phan;
  prior public.khoa_idempotency;
  item jsonb;
  actor_id integer;
  row_id bigint;
  final_value numeric;
  reason text;
  seen bigint[] := '{}';
  reviewed integer := 0;
  machine_matched integer := 0;
  error_rows integer := 0;
  result jsonb;
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001';
  END IF;
  IF p_ticket_version < 0 OR p_book_version < 0
     OR p_request_hash !~ '^[0-9a-f]{64}$'
     OR length(p_idempotency_key) NOT BETWEEN 1 AND 64
     OR p_idempotency_key !~ '^[a-zA-Z0-9_-]+$'
     OR jsonb_typeof(p_decisions) <> 'array'
     OR jsonb_array_length(p_decisions) NOT BETWEEN 1 AND 500 THEN
    RAISE EXCEPTION 'INVALID_REVIEW_REQUEST' USING ERRCODE='23514';
  END IF;

  SELECT u.ma_nguoi_dung INTO actor_id
  FROM public.phien_lam_viec s
  JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='GIAO_VIEN'
    AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501';
  END IF;

  SELECT * INTO b FROM public.bang_diem
  WHERE ma_bang_diem=p_book FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.phan_cong_giang_day pc
    WHERE pc.ma_giao_vien=actor_id AND pc.ma_lop=b.ma_lop
      AND pc.ma_mon=b.ma_mon AND pc.ma_hoc_ky=b.ma_hoc_ky) THEN
    RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501';
  END IF;

  SELECT * INTO prior FROM public.khoa_idempotency
  WHERE ma_nguoi_dung=actor_id AND thao_tac='RECOGNITION_APPROVE'
    AND khoa=p_idempotency_key;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau <> p_request_hash THEN
      RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505';
    END IF;
    RETURN prior.ket_qua;
  END IF;

  IF b.trang_thai <> 'DANG_NHAP_LIEU' OR b.version <> p_book_version THEN
    RAISE EXCEPTION 'GRADEBOOK_VERSION_OR_STATE_CONFLICT' USING ERRCODE='23514';
  END IF;
  SELECT * INTO ticket FROM public.phieu_nhan_dien
  WHERE ma_phieu=p_ticket AND ma_bang_diem=p_book FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'TICKET_NOT_FOUND' USING ERRCODE='P0002'; END IF;
  PERFORM public.kiem_thoi_gian_nhap(p_book,ticket.ma_thanh_phan);
  IF ticket.trang_thai <> 'CHO_DOI_CHIEU'
     OR ticket.version <> p_ticket_version THEN
    RAISE EXCEPTION 'TICKET_VERSION_OR_STATE_CONFLICT' USING ERRCODE='23514';
  END IF;
  IF jsonb_array_length(p_decisions) <>
     (SELECT count(*) FROM public.ket_qua_dong WHERE ma_phieu=p_ticket) THEN
    RAISE EXCEPTION 'ALL_ROWS_REQUIRED' USING ERRCODE='23514';
  END IF;

  FOR item IN SELECT value FROM jsonb_array_elements(p_decisions) LOOP
    IF jsonb_typeof(item) <> 'object'
       OR NOT (item ?& ARRAY['rowId','value','reason'])
       OR (item-ARRAY['rowId','value','reason']) <> '{}'::jsonb
       OR jsonb_typeof(item->'rowId') <> 'string'
       OR (item->>'rowId') !~ '^[1-9][0-9]{0,18}$'
       OR (item->>'rowId')::numeric > 9223372036854775807
       OR jsonb_typeof(item->'reason') <> 'string' THEN
      RAISE EXCEPTION 'INVALID_REVIEW_DECISION' USING ERRCODE='23514';
    END IF;
    row_id := (item->>'rowId')::bigint;
    IF row_id=ANY(seen) THEN
      RAISE EXCEPTION 'DUPLICATE_REVIEW_ROW' USING ERRCODE='23514';
    END IF;
    seen := array_append(seen,row_id);
    reason := btrim(item->>'reason');
    IF length(reason) NOT BETWEEN 1 AND 500 THEN
      RAISE EXCEPTION 'INVALID_REVIEW_REASON' USING ERRCODE='23514';
    END IF;
    IF item->'value'='null'::jsonb THEN
      final_value := NULL;
    ELSE
      IF jsonb_typeof(item->'value') <> 'string'
         OR (item->>'value') !~ '^(10[.]0|[0-9][.][0-9])$' THEN
        RAISE EXCEPTION 'INVALID_REVIEW_GRADE' USING ERRCODE='23514';
      END IF;
      final_value := public.kiem_tra_gia_tri_diem((item->>'value')::numeric);
    END IF;

    SELECT * INTO evidence FROM public.ket_qua_dong
    WHERE ma_dong=row_id AND ma_phieu=p_ticket FOR UPDATE;
    IF NOT FOUND OR evidence.nguoi_duyet IS NOT NULL OR evidence.ma_diem IS NOT NULL THEN
      RAISE EXCEPTION 'REVIEW_ROW_NOT_AVAILABLE' USING ERRCODE='P0002';
    END IF;
    SELECT d.* INTO grade FROM public.diem_thanh_phan d
    JOIN public.hoc_sinh hs ON hs.ma_hoc_sinh=d.ma_hoc_sinh
    WHERE d.ma_bang_diem=p_book
      AND d.ma_hoc_sinh=evidence.ma_hoc_sinh
      AND d.ma_thanh_phan=ticket.ma_thanh_phan
      AND hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc
    FOR UPDATE OF d;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'GRADE_CELL_NOT_FOUND' USING ERRCODE='P0002';
    END IF;

    IF grade.gia_tri IS DISTINCT FROM final_value THEN
      INSERT INTO public.lich_su_sua_diem(
        ma_diem,nguoi_sua,gia_tri_cu,gia_tri_moi,ly_do
      ) VALUES (grade.ma_diem,actor_id,grade.gia_tri,final_value,reason);
    END IF;
    UPDATE public.diem_thanh_phan SET
      gia_tri=final_value,
      trang_thai=CASE WHEN final_value IS NULL
        THEN 'CHUA_CO'::public."TrangThaiDiem"
        ELSE 'DA_DUYET'::public."TrangThaiDiem" END,
      nguon_nhap='NHAN_DIEN'
    WHERE ma_diem=grade.ma_diem;
    UPDATE public.ket_qua_dong SET
      ma_diem=grade.ma_diem,
      gia_tri_chot=final_value,
      nguoi_duyet=actor_id,
      thoi_diem_duyet=statement_timestamp()
    WHERE ma_dong=row_id;

    reviewed := reviewed+1;
    IF evidence.muc_phan_loai='XANH'
       AND final_value IS NOT DISTINCT FROM evidence.gia_tri_kenh_a
       AND final_value IS NOT DISTINCT FROM evidence.gia_tri_kenh_b THEN
      machine_matched := machine_matched+1;
    END IF;
    IF evidence.muc_phan_loai='DO' THEN error_rows := error_rows+1; END IF;
  END LOOP;

  UPDATE public.phieu_nhan_dien SET
    trang_thai='DA_DUYET',version=version+1
  WHERE ma_phieu=p_ticket;
  UPDATE public.bang_diem SET version=version+1 WHERE ma_bang_diem=p_book;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
    VALUES(actor_id,'RECOGNITION_APPROVED','phieu_nhan_dien:'||p_ticket::text);
  result := jsonb_build_object(
    'ticketId',p_ticket::text,
    'ticketVersion',ticket.version+1,
    'gradebookId',p_book,
    'gradebookVersion',b.version+1,
    'reviewedRows',reviewed,
    'machineMatchedRows',machine_matched,
    'humanCorrectedRows',reviewed-machine_matched,
    'errorRows',error_rows,
    'status','DA_DUYET'
  );
  INSERT INTO public.khoa_idempotency(
    khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua
  ) VALUES (
    p_idempotency_key,actor_id,'RECOGNITION_APPROVE',p_request_hash,result
  );
  RETURN result;
END $$;
COMMIT;
-- Forward-only rollback: revoke deadline executor using a reviewed migration; preserve zero-fill audit and closed columns.
