-- UC09–10: least-privilege writes. Migration not previously deployed.
BEGIN;
CREATE TABLE public.khoa_idempotency (
  khoa VARCHAR(64) NOT NULL,
  ma_nguoi_dung INTEGER NOT NULL REFERENCES public.nguoi_dung(ma_nguoi_dung) ON DELETE RESTRICT,
  thao_tac VARCHAR(32) NOT NULL,
  ma_bam_yeu_cau CHAR(64) NOT NULL,
  ket_qua JSONB NOT NULL,
  het_han TIMESTAMPTZ(6) NOT NULL DEFAULT now() + interval '24 hours',
  PRIMARY KEY (ma_nguoi_dung, thao_tac, khoa)
);
CREATE INDEX khoa_idempotency_het_han_idx ON public.khoa_idempotency(het_han);
GRANT SELECT, INSERT ON public.khoa_idempotency TO app_runtime;

CREATE FUNCTION public.kiem_quyen_ghi_bang(p_phien text, p_book integer, p_version integer)
RETURNS public.bang_diem LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE b public.bang_diem; actor_id integer;
BEGIN
 IF current_setting('transaction_isolation') <> 'serializable' THEN
   RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
 SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
 WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='GIAO_VIEN'
 AND s.het_han>statement_timestamp() AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
 IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
 SELECT * INTO b FROM public.bang_diem WHERE ma_bang_diem=p_book FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.phan_cong_giang_day pc WHERE pc.ma_giao_vien=actor_id
 AND pc.ma_lop=b.ma_lop AND pc.ma_mon=b.ma_mon AND pc.ma_hoc_ky=b.ma_hoc_ky) THEN
   RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
 IF p_version IS NULL OR p_version<0 OR b.version<>p_version OR b.trang_thai='DA_CHOT' THEN
   RAISE EXCEPTION 'VERSION_OR_STATE_CONFLICT' USING ERRCODE='23514'; END IF;
 RETURN b;
END $$;

CREATE FUNCTION public.cap_nhat_diem(p_phien text,p_book integer,p_version integer,p_changes jsonb)
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
   IF NOT EXISTS(SELECT 1 FROM public.hoc_sinh WHERE ma_hoc_sinh=d.ma_hoc_sinh AND ma_lop=b.ma_lop AND dang_theo_hoc)
   OR NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem WHERE ma_thanh_phan=d.ma_thanh_phan AND ma_mon=b.ma_mon)
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

CREATE FUNCTION public.dong_bo_si_so(p_phien text,p_book integer,p_version integer)
RETURNS SETOF public.bang_diem LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE b public.bang_diem; actor_id integer;
BEGIN
 b:=public.kiem_quyen_ghi_bang(p_phien,p_book,p_version);
 SELECT ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec WHERE ma_bam=p_phien;
 INSERT INTO public.diem_thanh_phan(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan)
 SELECT p_book,hs.ma_hoc_sinh,tp.ma_thanh_phan FROM public.hoc_sinh hs CROSS JOIN public.thanh_phan_diem tp
 WHERE hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc AND tp.ma_mon=b.ma_mon
 ON CONFLICT(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan) DO NOTHING;
 UPDATE public.bang_diem SET version=version+1 WHERE ma_bang_diem=p_book;
 INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'GRADEBOOK_ROSTER_SYNCED','bang_diem:'||p_book);
 RETURN QUERY SELECT * FROM public.bang_diem WHERE ma_bang_diem=p_book;
END $$;

CREATE FUNCTION public.chot_bang_diem(p_phien text,p_book integer,p_version integer)
RETURNS SETOF public.bang_diem LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE b public.bang_diem; actor_id integer;
BEGIN
 b:=public.kiem_quyen_ghi_bang(p_phien,p_book,p_version);
 SELECT ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec WHERE ma_bam=p_phien;
 IF EXISTS(SELECT 1 FROM public.diem_thanh_phan WHERE ma_bang_diem=p_book AND trang_thai='CHO_DOI_CHIEU')
 OR EXISTS(SELECT 1 FROM public.phieu_nhan_dien WHERE ma_bang_diem=p_book AND trang_thai IN ('DANG_XU_LY','CHO_DOI_CHIEU')) THEN
   RAISE EXCEPTION 'PENDING_REVIEW' USING ERRCODE='23514'; END IF;
 -- Conservative development policy: require every mandatory grade of each active student.
 IF EXISTS(SELECT 1 FROM public.hoc_sinh hs CROSS JOIN public.thanh_phan_diem tp
 LEFT JOIN public.diem_thanh_phan d ON d.ma_bang_diem=p_book AND d.ma_hoc_sinh=hs.ma_hoc_sinh AND d.ma_thanh_phan=tp.ma_thanh_phan
 WHERE hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc AND tp.ma_mon=b.ma_mon
 AND (d.ma_diem IS NULL OR (tp.bat_buoc AND (d.gia_tri IS NULL OR d.trang_thai<>'DA_DUYET')))) THEN
   RAISE EXCEPTION 'INCOMPLETE_ROSTER_OR_REQUIRED_GRADES' USING ERRCODE='23514'; END IF;
 UPDATE public.bang_diem SET trang_thai='DA_CHOT',version=version+1 WHERE ma_bang_diem=p_book;
 INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'GRADEBOOK_LOCKED','bang_diem:'||p_book);
 RETURN QUERY SELECT * FROM public.bang_diem WHERE ma_bang_diem=p_book;
END $$;

REVOKE ALL ON FUNCTION public.kiem_quyen_ghi_bang(text,integer,integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.cap_nhat_diem(text,integer,integer,jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.dong_bo_si_so(text,integer,integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.chot_bang_diem(text,integer,integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cap_nhat_diem(text,integer,integer,jsonb),public.dong_bo_si_so(text,integer,integer),public.chot_bang_diem(text,integer,integer) TO app_runtime;
-- Forward-only rollback: revoke EXECUTE through a new migration; preserve grades and history.
COMMIT;
