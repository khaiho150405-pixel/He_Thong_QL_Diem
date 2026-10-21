-- Ô "Miễn" (MIEN) và xử lý học sinh vào lớp sau khi cột đã chốt (ADR-0014 bổ sung).
-- Ô MIEN luôn có gia_tri NULL, khác "chưa có điểm"; không bị ghi 0 khi hết hạn, không nhận điểm qua nhập tay/duyệt nhận dạng,
-- bị bỏ khỏi tử số, mẫu số và danh sách thiếu cột bắt buộc khi tổng kết.
--
-- ROLLBACK (chỉ tiến): không xóa lich_su_mien_diem hay ô MIEN đã tạo. Muốn gỡ tính năng, tạo migration mới thu hồi EXECUTE
-- của dat_mien_diem/them_hoc_sinh_sau_chot và khôi phục các hàm cũ (xem 202610210001_semester_deadlines,
-- 202610040003_grade_deadlines, 202610070001_review_skip_rows, 202610040001_school_workflow).
BEGIN;

-- Ô MIEN, như ô CHUA_CO, không có giá trị.
ALTER TABLE public.diem_thanh_phan DROP CONSTRAINT diem_trang_thai;
ALTER TABLE public.diem_thanh_phan ADD CONSTRAINT diem_trang_thai CHECK (
  (trang_thai IN ('CHUA_CO','MIEN') AND gia_tri IS NULL)
  OR (trang_thai NOT IN ('CHUA_CO','MIEN') AND gia_tri IS NOT NULL)
);

-- Lịch sử đặt/bỏ miễn: chỉ thêm, runtime chỉ đọc.
CREATE TABLE public.lich_su_mien_diem (
  ma bigserial PRIMARY KEY,
  ma_diem bigint NOT NULL REFERENCES public.diem_thanh_phan(ma_diem) ON DELETE RESTRICT,
  hanh_dong varchar(10) NOT NULL CHECK (hanh_dong IN ('MIEN','BO_MIEN')),
  ly_do varchar(500) NOT NULL CHECK (length(btrim(ly_do)) > 0),
  nguoi_thuc_hien integer NOT NULL REFERENCES public.nguoi_dung(ma_nguoi_dung) ON DELETE RESTRICT,
  thoi_diem timestamptz(6) NOT NULL DEFAULT now()
);
CREATE INDEX lich_su_mien_diem_diem_idx ON public.lich_su_mien_diem(ma_diem, ma DESC);
GRANT SELECT ON public.lich_su_mien_diem TO app_runtime;
CREATE FUNCTION public.khong_sua_lich_su_mien() RETURNS trigger LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN RAISE EXCEPTION 'EXEMPTION_HISTORY_APPEND_ONLY' USING ERRCODE='23514'; END $$;
CREATE TRIGGER exemption_history_append_only BEFORE UPDATE OR DELETE ON public.lich_su_mien_diem
  FOR EACH ROW EXECUTE FUNCTION public.khong_sua_lich_su_mien();
CREATE TRIGGER exemption_history_no_truncate BEFORE TRUNCATE ON public.lich_su_mien_diem
  FOR EACH STATEMENT EXECUTE FUNCTION public.khong_sua_lich_su_mien();

-- Chỉ them_hoc_sinh_sau_chot (đặt cờ giao dịch cục bộ) mới được INSERT ô MIEN; đặt miễn ô sẵn có là UPDATE trong cột còn mở.
CREATE FUNCTION public.kiem_o_mien_khi_tao() RETURNS trigger LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN
  IF NEW.trang_thai='MIEN' AND coalesce(current_setting('qld.cho_phep_o_mien',true),'')<>'on' THEN
    RAISE EXCEPTION 'EXEMPT_CELL_FORBIDDEN' USING ERRCODE='23514'; END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER exempt_cell_insert_guard BEFORE INSERT ON public.diem_thanh_phan
  FOR EACH ROW EXECUTE FUNCTION public.kiem_o_mien_khi_tao();

-- Học sinh đang học của lớp còn thiếu ít nhất một ô trong bảng điểm.
CREATE FUNCTION public.hoc_sinh_thieu_o(p_book integer) RETURNS TABLE(ma_hoc_sinh integer, ho_ten text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
  SELECT hs.ma_hoc_sinh, hs.ho_ten::text
  FROM public.bang_diem b JOIN public.hoc_sinh hs ON hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc
  WHERE b.ma_bang_diem=p_book
    AND EXISTS(SELECT 1 FROM public.thanh_phan_diem tp WHERE tp.ma_mon=b.ma_mon
      AND NOT EXISTS(SELECT 1 FROM public.diem_thanh_phan d WHERE d.ma_bang_diem=b.ma_bang_diem
        AND d.ma_hoc_sinh=hs.ma_hoc_sinh AND d.ma_thanh_phan=tp.ma_thanh_phan))
  ORDER BY hs.ma_hoc_sinh
$$;
REVOKE ALL ON FUNCTION public.hoc_sinh_thieu_o(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.hoc_sinh_thieu_o(integer) TO app_runtime;

-- GV phụ trách đặt/bỏ miễn ô khi cột còn mở. Chỉ miễn được ô đang NULL (CHUA_CO).
CREATE FUNCTION public.dat_mien_diem(p_phien text,p_book integer,p_version integer,p_changes jsonb,p_idem text,p_hash text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE b public.bang_diem; d public.diem_thanh_phan; c jsonb; w record; prior public.khoa_idempotency;
  actor_id integer; seen bigint[]:='{}'; cell_id bigint; reason text; wants boolean; ids jsonb:='[]'::jsonb; result jsonb;
BEGIN
  IF current_setting('transaction_isolation')<>'serializable' THEN RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
  IF p_version IS NULL OR p_version<0 OR p_hash IS NULL OR p_hash !~ '^[0-9a-f]{64}$'
     OR p_idem IS NULL OR length(p_idem) NOT BETWEEN 1 AND 64 OR p_idem !~ '^[a-zA-Z0-9_-]+$'
     OR p_changes IS NULL OR jsonb_typeof(p_changes)<>'array' OR jsonb_array_length(p_changes) NOT BETWEEN 1 AND 100 THEN
    RAISE EXCEPTION 'INVALID_EXEMPTION_REQUEST' USING ERRCODE='23514'; END IF;
  SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='GIAO_VIEN' AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  SELECT * INTO b FROM public.bang_diem WHERE ma_bang_diem=p_book FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.phan_cong_giang_day pc WHERE pc.ma_giao_vien=actor_id AND pc.ma_lop=b.ma_lop
    AND pc.ma_mon=b.ma_mon AND pc.ma_hoc_ky=b.ma_hoc_ky) THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  SELECT * INTO prior FROM public.khoa_idempotency WHERE ma_nguoi_dung=actor_id AND thao_tac='GRADE_EXEMPT' AND khoa=p_idem;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau<>p_hash THEN RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505'; END IF;
    RETURN prior.ket_qua;
  END IF;
  IF b.trang_thai='DA_CHOT' OR b.version<>p_version THEN
    RAISE EXCEPTION 'EXEMPTION_VERSION_OR_STATE_CONFLICT' USING ERRCODE='23514'; END IF;
  b:=public.kiem_quyen_ghi_bang(p_phien,p_book,p_version);
  FOR c IN SELECT value FROM jsonb_array_elements(p_changes) LOOP
    IF jsonb_typeof(c)<>'object' OR NOT (c ?& ARRAY['cellId','exempt','reason'])
       OR (c-ARRAY['cellId','exempt','reason'])<>'{}'::jsonb
       OR jsonb_typeof(c->'cellId')<>'string' OR (c->>'cellId')!~'^[1-9][0-9]{0,18}$'
       OR (c->>'cellId')::numeric>9223372036854775807
       OR jsonb_typeof(c->'exempt')<>'boolean' OR jsonb_typeof(c->'reason')<>'string' THEN
      RAISE EXCEPTION 'INVALID_EXEMPTION_CHANGE' USING ERRCODE='23514'; END IF;
    cell_id:=(c->>'cellId')::bigint;
    IF cell_id=ANY(seen) THEN RAISE EXCEPTION 'DUPLICATE_CELL' USING ERRCODE='23514'; END IF;
    seen:=array_append(seen,cell_id);
    reason:=btrim(c->>'reason');
    IF length(reason) NOT BETWEEN 1 AND 500 THEN RAISE EXCEPTION 'INVALID_REASON' USING ERRCODE='23514'; END IF;
    wants:=(c->>'exempt')::boolean;
    SELECT * INTO d FROM public.diem_thanh_phan WHERE ma_diem=cell_id AND ma_bang_diem=p_book FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'CELL_OUTSIDE_BOOK' USING ERRCODE='P0002'; END IF;
    IF NOT EXISTS(SELECT 1 FROM public.hoc_sinh WHERE ma_hoc_sinh=d.ma_hoc_sinh AND ma_lop=b.ma_lop AND dang_theo_hoc)
       OR NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem WHERE ma_thanh_phan=d.ma_thanh_phan AND ma_mon=b.ma_mon) THEN
      RAISE EXCEPTION 'CELL_NOT_EDITABLE' USING ERRCODE='23514'; END IF;
    SELECT * INTO w FROM public.lich_hieu_luc(p_book,d.ma_thanh_phan);
    IF EXISTS(SELECT 1 FROM public.chot_cot_diem WHERE ma_bang_diem=p_book AND ma_thanh_phan=d.ma_thanh_phan)
       OR NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem WHERE ma_thanh_phan=d.ma_thanh_phan AND cho_phep_nhap)
       OR (w.dong_luc IS NOT NULL AND (clock_timestamp()<w.mo_luc OR clock_timestamp()>=w.dong_luc)) THEN
      RAISE EXCEPTION 'COLUMN_NOT_OPEN' USING ERRCODE='23514'; END IF;
    IF EXISTS(SELECT 1 FROM public.phieu_nhan_dien WHERE ma_bang_diem=p_book AND ma_thanh_phan=d.ma_thanh_phan
       AND trang_thai IN ('DANG_XU_LY','CHO_DOI_CHIEU')) THEN
      RAISE EXCEPTION 'RECOGNITION_PENDING' USING ERRCODE='23514'; END IF;
    IF wants THEN
      IF d.trang_thai<>'MIEN' THEN
        IF d.gia_tri IS NOT NULL OR d.trang_thai<>'CHUA_CO' THEN
          RAISE EXCEPTION 'CELL_HAS_VALUE' USING ERRCODE='23514'; END IF;
        UPDATE public.diem_thanh_phan SET trang_thai='MIEN' WHERE ma_diem=cell_id;
        INSERT INTO public.lich_su_mien_diem(ma_diem,hanh_dong,ly_do,nguoi_thuc_hien) VALUES(cell_id,'MIEN',reason,actor_id);
      END IF;
    ELSE
      IF d.trang_thai<>'MIEN' THEN RAISE EXCEPTION 'CELL_NOT_EXEMPT' USING ERRCODE='23514'; END IF;
      UPDATE public.diem_thanh_phan SET trang_thai='CHUA_CO' WHERE ma_diem=cell_id;
      INSERT INTO public.lich_su_mien_diem(ma_diem,hanh_dong,ly_do,nguoi_thuc_hien) VALUES(cell_id,'BO_MIEN',reason,actor_id);
    END IF;
    ids:=ids||to_jsonb(cell_id::text);
  END LOOP;
  UPDATE public.bang_diem SET version=version+1 WHERE ma_bang_diem=p_book;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'GRADE_CELLS_EXEMPTION_CHANGED','bang_diem:'||p_book);
  result:=jsonb_build_object('bookId',p_book,'version',b.version+1,'cellIds',ids);
  INSERT INTO public.khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua) VALUES(p_idem,actor_id,'GRADE_EXEMPT',p_hash,result);
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.dat_mien_diem(text,integer,integer,jsonb,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.dat_mien_diem(text,integer,integer,jsonb,text,text) TO app_runtime;

-- QTV xử lý học sinh vào lớp SAU khi cột đã chốt: tạo ô còn thiếu (cột đã chốt → MIEN, cột còn mở → CHUA_CO).
-- Không đổi ô đã tồn tại; chặn khi học kỳ đã công bố.
CREATE FUNCTION public.them_hoc_sinh_sau_chot(p_phien text,p_book integer,p_student integer,p_reason text,p_idem text,p_hash text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE b public.bang_diem; prior public.khoa_idempotency; comp record; actor_id integer; reason text; new_id bigint;
  created integer:=0; exempted integer:=0; result jsonb;
BEGIN
  IF current_setting('transaction_isolation')<>'serializable' THEN RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
  reason:=btrim(coalesce(p_reason,''));
  IF p_student IS NULL OR p_student<1 OR length(reason) NOT BETWEEN 1 AND 500 OR p_hash IS NULL OR p_hash !~ '^[0-9a-f]{64}$'
     OR p_idem IS NULL OR length(p_idem) NOT BETWEEN 1 AND 64 OR p_idem !~ '^[a-zA-Z0-9_-]+$' THEN
    RAISE EXCEPTION 'INVALID_LATE_STUDENT_REQUEST' USING ERRCODE='23514'; END IF;
  SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='QUAN_TRI_VIEN' AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  SELECT * INTO b FROM public.bang_diem WHERE ma_bang_diem=p_book FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  SELECT * INTO prior FROM public.khoa_idempotency WHERE ma_nguoi_dung=actor_id AND thao_tac='LATE_STUDENT' AND khoa=p_idem;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau<>p_hash THEN RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505'; END IF;
    RETURN prior.ket_qua;
  END IF;
  IF EXISTS(SELECT 1 FROM public.hoc_ky WHERE ma_hoc_ky=b.ma_hoc_ky AND da_cong_bo) THEN
    RAISE EXCEPTION 'TERM_ALREADY_PUBLISHED' USING ERRCODE='23514'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.hoc_sinh WHERE ma_hoc_sinh=p_student AND ma_lop=b.ma_lop AND dang_theo_hoc) THEN
    RAISE EXCEPTION 'STUDENT_NOT_IN_CLASS' USING ERRCODE='23514'; END IF;
  PERFORM set_config('qld.cho_phep_o_mien','on',true);
  FOR comp IN SELECT tp.ma_thanh_phan FROM public.thanh_phan_diem tp WHERE tp.ma_mon=b.ma_mon
    AND NOT EXISTS(SELECT 1 FROM public.diem_thanh_phan d WHERE d.ma_bang_diem=p_book AND d.ma_hoc_sinh=p_student
      AND d.ma_thanh_phan=tp.ma_thanh_phan)
    ORDER BY tp.thu_tu_hien_thi,tp.ma_thanh_phan LOOP
    IF EXISTS(SELECT 1 FROM public.chot_cot_diem WHERE ma_bang_diem=p_book AND ma_thanh_phan=comp.ma_thanh_phan) THEN
      INSERT INTO public.diem_thanh_phan(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan,gia_tri,trang_thai,nguon_nhap)
      VALUES(p_book,p_student,comp.ma_thanh_phan,NULL,'MIEN','NHAP_TAY') RETURNING ma_diem INTO new_id;
      INSERT INTO public.lich_su_mien_diem(ma_diem,hanh_dong,ly_do,nguoi_thuc_hien) VALUES(new_id,'MIEN',reason,actor_id);
      exempted:=exempted+1;
    ELSE
      INSERT INTO public.diem_thanh_phan(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan) VALUES(p_book,p_student,comp.ma_thanh_phan);
    END IF;
    created:=created+1;
  END LOOP;
  PERFORM set_config('qld.cho_phep_o_mien','off',true);
  IF created>0 THEN UPDATE public.bang_diem SET version=version+1 WHERE ma_bang_diem=p_book; END IF;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'LATE_STUDENT_ADDED','bang_diem:'||p_book||':'||p_student);
  result:=jsonb_build_object('bookId',p_book,'version',b.version+CASE WHEN created>0 THEN 1 ELSE 0 END,
    'createdCells',created,'exemptedCells',exempted);
  INSERT INTO public.khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua) VALUES(p_idem,actor_id,'LATE_STUDENT',p_hash,result);
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.them_hoc_sinh_sau_chot(text,integer,integer,text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.them_hoc_sinh_sau_chot(text,integer,integer,text,text,text) TO app_runtime;

-- Hết hạn: ô MIEN không bị ghi 0 (phần còn lại giữ nguyên từ 202610210001_semester_deadlines).
CREATE OR REPLACE FUNCTION public.xu_ly_han_nhap_diem() RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE w record; b public.bang_diem; d public.diem_thanh_phan; n integer:=0;
BEGIN
 IF current_setting('transaction_isolation')<>'serializable' THEN RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
 IF NOT pg_try_advisory_xact_lock(714042026) THEN RETURN 0; END IF;
 FOR w IN SELECT bd.ma_bang_diem,t.ma_thanh_phan,t.bat_buoc,e.nguoi_dat
 FROM public.bang_diem bd
 JOIN public.thanh_phan_diem t ON t.ma_mon=bd.ma_mon
 CROSS JOIN LATERAL public.lich_hieu_luc(bd.ma_bang_diem,t.ma_thanh_phan) e
 WHERE bd.trang_thai='DANG_NHAP_LIEU' AND e.dong_luc<=clock_timestamp()
 AND NOT EXISTS(SELECT 1 FROM public.chot_cot_diem c WHERE c.ma_bang_diem=bd.ma_bang_diem AND c.ma_thanh_phan=t.ma_thanh_phan)
 ORDER BY bd.ma_bang_diem,t.ma_thanh_phan LIMIT 100 LOOP
 SELECT * INTO b FROM public.bang_diem WHERE ma_bang_diem=w.ma_bang_diem FOR UPDATE;
 IF b.trang_thai='DA_CHOT' OR EXISTS(SELECT 1 FROM public.chot_cot_diem WHERE ma_bang_diem=w.ma_bang_diem AND ma_thanh_phan=w.ma_thanh_phan) THEN CONTINUE; END IF;
 -- Sync newly enrolled students before assigning an explicit zero to missing grades.
 INSERT INTO public.diem_thanh_phan(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan)
 SELECT b.ma_bang_diem,hs.ma_hoc_sinh,w.ma_thanh_phan FROM public.hoc_sinh hs WHERE hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc
 ON CONFLICT(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan) DO NOTHING;
 IF w.bat_buoc THEN
 FOR d IN SELECT g.* FROM public.diem_thanh_phan g JOIN public.hoc_sinh hs USING(ma_hoc_sinh)
 WHERE g.ma_bang_diem=b.ma_bang_diem AND g.ma_thanh_phan=w.ma_thanh_phan AND hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc AND g.trang_thai<>'MIEN' AND (g.gia_tri IS NULL OR g.trang_thai<>'DA_DUYET') FOR UPDATE OF g LOOP
 UPDATE public.diem_thanh_phan SET gia_tri=0.0,trang_thai='DA_DUYET',nguon_nhap='NHAP_TAY' WHERE ma_diem=d.ma_diem;
 INSERT INTO public.lich_su_sua_diem(ma_diem,nguoi_sua,gia_tri_cu,gia_tri_moi,ly_do)
 VALUES(d.ma_diem,w.nguoi_dat,d.gia_tri,0.0,'Hệ thống tự ghi 0 do hết hạn nhập điểm do nhà trường đặt; ô thiếu hoặc chưa được duyệt.');
 END LOOP;
 END IF;
 UPDATE public.phieu_nhan_dien SET trang_thai='LOI',ma_loi='GRADE_DEADLINE_EXPIRED',version=version+1 WHERE ma_bang_diem=b.ma_bang_diem AND ma_thanh_phan=w.ma_thanh_phan AND trang_thai IN ('DANG_XU_LY','CHO_DOI_CHIEU');
 INSERT INTO public.chot_cot_diem(ma_bang_diem,ma_thanh_phan,nguoi_chot) VALUES(b.ma_bang_diem,w.ma_thanh_phan,w.nguoi_dat);
 UPDATE public.bang_diem SET version=version+1,trang_thai=CASE WHEN NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem t WHERE t.ma_mon=b.ma_mon AND NOT EXISTS(SELECT 1 FROM public.chot_cot_diem c WHERE c.ma_bang_diem=b.ma_bang_diem AND c.ma_thanh_phan=t.ma_thanh_phan)) THEN 'DA_CHOT'::public."TrangThaiBangDiem" ELSE trang_thai END WHERE ma_bang_diem=b.ma_bang_diem;
 INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(NULL,'GRADE_COLUMN_AUTO_LOCKED',b.ma_bang_diem::text||':'||w.ma_thanh_phan::text);
 n:=n+1;
 END LOOP;
 RETURN n;
END $$;

-- Nhập tay vào ô MIEN → CELL_EXEMPT (phần còn lại giữ nguyên từ 202610040003_grade_deadlines).
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
   IF d.trang_thai='MIEN' THEN RAISE EXCEPTION 'CELL_EXEMPT' USING ERRCODE='23514'; END IF;
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

-- Duyệt nhận dạng: dòng của học sinh được miễn chỉ nhận giá trị null (giữ nguyên từ 202610070001_review_skip_rows).
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
    IF final_value IS NULL THEN
      -- Không ghi điểm cho dòng này (ví dụ học sinh vắng): không động tới diem_thanh_phan của học sinh đó,
      -- chỉ lưu người duyệt, thời điểm và lý do bắt buộc trên chính dòng kết quả.
      UPDATE public.ket_qua_dong SET
        nguoi_duyet=actor_id,
        thoi_diem_duyet=statement_timestamp(),
        ly_do_duyet=reason
      WHERE ma_dong=row_id;
    ELSE
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
      IF grade.trang_thai='MIEN' THEN
        RAISE EXCEPTION 'ROW_STUDENT_EXEMPT' USING ERRCODE='23514';
      END IF;

      IF grade.gia_tri IS DISTINCT FROM final_value THEN
        INSERT INTO public.lich_su_sua_diem(
          ma_diem,nguoi_sua,gia_tri_cu,gia_tri_moi,ly_do
        ) VALUES (grade.ma_diem,actor_id,grade.gia_tri,final_value,reason);
      END IF;
      UPDATE public.diem_thanh_phan SET
        gia_tri=final_value,
        trang_thai='DA_DUYET'::public."TrangThaiDiem",
        nguon_nhap='NHAN_DIEN'
      WHERE ma_diem=grade.ma_diem;
      UPDATE public.ket_qua_dong SET
        ma_diem=grade.ma_diem,
        gia_tri_chot=final_value,
        nguoi_duyet=actor_id,
        thoi_diem_duyet=statement_timestamp(),
        ly_do_duyet=reason
      WHERE ma_dong=row_id;
    END IF;

    reviewed := reviewed+1;
    IF evidence.muc_phan_loai='XANH'
       AND final_value IS NOT NULL
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

-- Tổng kết: bỏ ô MIEN khỏi thiếu cột bắt buộc; học sinh miễn mọi ô vào exempted (giữ nguyên từ 202610040001_school_workflow).
CREATE OR REPLACE FUNCTION public.tinh_ket_qua_bang_diem(
  p_phien text,
  p_book integer,
  p_version integer,
  p_reason text,
  p_idempotency_key text,
  p_request_hash text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  b public.bang_diem;
  pass_fail boolean;
  actor_id integer;
  policy public.chinh_sach_xep_loai;
  prior public.khoa_idempotency;
  student record;
  old_result public.ket_qua_tong_ket;
  saved_result public.ket_qua_tong_ket;
  weight_snapshot jsonb;
  policy_snapshot jsonb;
  full_snapshot jsonb;
  weight_version varchar(20);
  total numeric;
  denominator numeric;
  rounded numeric(3,1);
  classification varchar(20);
  missing jsonb;
  results jsonb := '[]'::jsonb;
  skipped jsonb := '[]'::jsonb;
  exempted jsonb := '[]'::jsonb;
  calculated integer := 0;
  result jsonb;
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001';
  END IF;
  IF p_version IS NULL OR p_version < 0
     OR length(btrim(p_reason)) NOT BETWEEN 1 AND 500
     OR p_request_hash !~ '^[0-9a-f]{64}$'
     OR length(p_idempotency_key) NOT BETWEEN 1 AND 64
     OR p_idempotency_key !~ '^[a-zA-Z0-9_-]+$' THEN
    RAISE EXCEPTION 'INVALID_FINAL_RESULT_REQUEST' USING ERRCODE='23514';
  END IF;

  SELECT u.ma_nguoi_dung INTO actor_id
  FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='GIAO_VIEN'
    AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;

  SELECT * INTO b FROM public.bang_diem WHERE ma_bang_diem=p_book FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.phan_cong_giang_day pc
    WHERE pc.ma_giao_vien=actor_id AND pc.ma_lop=b.ma_lop
      AND pc.ma_mon=b.ma_mon AND pc.ma_hoc_ky=b.ma_hoc_ky) THEN
    RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501';
  END IF;

  SELECT * INTO prior FROM public.khoa_idempotency
  WHERE ma_nguoi_dung=actor_id AND thao_tac='FINAL_RESULTS'
    AND khoa=p_idempotency_key;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau<>p_request_hash THEN
      RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505';
    END IF;
    RETURN prior.ket_qua;
  END IF;
  IF b.trang_thai<>'DA_CHOT' OR b.version<>p_version THEN
    RAISE EXCEPTION 'GRADEBOOK_VERSION_OR_STATE_CONFLICT' USING ERRCODE='23514';
  END IF;
  IF EXISTS (SELECT 1 FROM public.diem_thanh_phan
             WHERE ma_bang_diem=p_book AND trang_thai='CHO_DOI_CHIEU') THEN
    RAISE EXCEPTION 'PENDING_REVIEW' USING ERRCODE='23514';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.thanh_phan_diem WHERE ma_mon=b.ma_mon)
     OR EXISTS (SELECT 1 FROM public.thanh_phan_diem
                WHERE ma_mon=b.ma_mon AND he_so<=0) THEN
    RAISE EXCEPTION 'INVALID_WEIGHTS' USING ERRCODE='23514';
  END IF;

  IF EXISTS(SELECT 1 FROM public.hoc_ky WHERE ma_hoc_ky=b.ma_hoc_ky AND da_cong_bo) THEN
    RAISE EXCEPTION 'TERM_ALREADY_PUBLISHED' USING ERRCODE='23514'; END IF;
  SELECT danh_gia_dat INTO pass_fail FROM public.mon_hoc WHERE ma_mon=b.ma_mon;
  SELECT * INTO policy FROM public.chinh_sach_xep_loai WHERE dang_ap_dung;
  IF NOT FOUND OR NOT EXISTS (SELECT 1 FROM public.tieu_chi_xep_loai
                              WHERE ma_chinh_sach=policy.ma_chinh_sach AND diem_toi_thieu=0.0) THEN
    RAISE EXCEPTION 'CLASSIFICATION_POLICY_UNAVAILABLE' USING ERRCODE='23514';
  END IF;
  SELECT coalesce(jsonb_agg(jsonb_build_object(
           'componentId',tp.ma_thanh_phan,'name',tp.ten_thanh_phan,
           'coefficient',public.he_so_ap_dung(tp.ma_thanh_phan,b.ma_hoc_ky)::text,'required',tp.bat_buoc)
           ORDER BY tp.thu_tu_hien_thi,tp.ma_thanh_phan),'[]'::jsonb),
         ('W-'||substr(md5(string_agg(tp.ma_thanh_phan::text||':'||public.he_so_ap_dung(tp.ma_thanh_phan,b.ma_hoc_ky)::text||':'||tp.bat_buoc::text,
                          ',' ORDER BY tp.thu_tu_hien_thi,tp.ma_thanh_phan)),1,18))::varchar(20)
  INTO weight_snapshot,weight_version
  FROM public.thanh_phan_diem tp WHERE tp.ma_mon=b.ma_mon;
  SELECT jsonb_build_object('version',policy.phien_ban,'roundingDigits',policy.so_chu_so_lam_tron,
           'criteria',jsonb_agg(jsonb_build_object('code',c.ma_xep_loai,
             'minimum',c.diem_toi_thieu::text) ORDER BY c.diem_toi_thieu DESC))
  INTO policy_snapshot
  FROM public.tieu_chi_xep_loai c WHERE c.ma_chinh_sach=policy.ma_chinh_sach;
  full_snapshot:=jsonb_build_object('weights',weight_snapshot,'classificationPolicy',policy_snapshot,'assessmentMode',CASE WHEN pass_fail THEN 'PASS_FAIL' ELSE 'NUMERIC' END);

  FOR student IN SELECT hs.ma_hoc_sinh,hs.ho_ten FROM public.hoc_sinh hs
                 WHERE hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc ORDER BY hs.ma_hoc_sinh LOOP
    -- Học sinh được miễn MỌI ô của bảng: không tạo kết quả (khác học sinh bị bỏ qua vì thiếu điểm).
    IF EXISTS(SELECT 1 FROM public.diem_thanh_phan d WHERE d.ma_bang_diem=p_book AND d.ma_hoc_sinh=student.ma_hoc_sinh)
       AND NOT EXISTS(SELECT 1 FROM public.diem_thanh_phan d WHERE d.ma_bang_diem=p_book
         AND d.ma_hoc_sinh=student.ma_hoc_sinh AND d.trang_thai<>'MIEN') THEN
      exempted:=exempted||jsonb_build_array(jsonb_build_object(
        'studentId',student.ma_hoc_sinh,'studentName',student.ho_ten));
      CONTINUE;
    END IF;
    SELECT coalesce(jsonb_agg(jsonb_build_object('componentId',tp.ma_thanh_phan,'name',tp.ten_thanh_phan)
             ORDER BY tp.thu_tu_hien_thi),'[]'::jsonb)
    INTO missing
    FROM public.thanh_phan_diem tp LEFT JOIN public.diem_thanh_phan d
      ON d.ma_bang_diem=p_book AND d.ma_hoc_sinh=student.ma_hoc_sinh
     AND d.ma_thanh_phan=tp.ma_thanh_phan
    WHERE tp.ma_mon=b.ma_mon AND tp.bat_buoc
      AND (d.ma_diem IS NULL OR (d.trang_thai<>'MIEN' AND (d.gia_tri IS NULL OR d.trang_thai<>'DA_DUYET')));
    IF jsonb_array_length(missing)>0 THEN
      skipped:=skipped||jsonb_build_array(jsonb_build_object(
        'studentId',student.ma_hoc_sinh,'studentName',student.ho_ten,'missingComponents',missing));
      CONTINUE;
    END IF;

    SELECT sum(d.gia_tri*public.he_so_ap_dung(tp.ma_thanh_phan,b.ma_hoc_ky)),sum(public.he_so_ap_dung(tp.ma_thanh_phan,b.ma_hoc_ky))
    INTO total,denominator
    FROM public.diem_thanh_phan d JOIN public.thanh_phan_diem tp USING(ma_thanh_phan)
    WHERE d.ma_bang_diem=p_book AND d.ma_hoc_sinh=student.ma_hoc_sinh
      AND tp.ma_mon=b.ma_mon AND d.trang_thai='DA_DUYET' AND d.gia_tri IS NOT NULL;
    IF denominator IS NULL OR denominator<=0 THEN
      skipped:=skipped||jsonb_build_array(jsonb_build_object(
        'studentId',student.ma_hoc_sinh,'studentName',student.ho_ten,'missingComponents','[]'::jsonb));
      CONTINUE;
    END IF;
    rounded:=round(total/denominator,policy.so_chu_so_lam_tron)::numeric(3,1);
    SELECT c.ma_xep_loai INTO classification FROM public.tieu_chi_xep_loai c
    WHERE c.ma_chinh_sach=policy.ma_chinh_sach AND rounded>=c.diem_toi_thieu
    ORDER BY c.diem_toi_thieu DESC LIMIT 1;
    IF pass_fail THEN
      IF total/denominator >= 5.0 THEN rounded:=10.0; classification:='DAT';
      ELSE rounded:=0.0; classification:='CHUA_DAT'; END IF;
    END IF;
    IF classification IS NULL THEN
      RAISE EXCEPTION 'CLASSIFICATION_POLICY_GAP' USING ERRCODE='23514';
    END IF;

    SELECT * INTO old_result FROM public.ket_qua_tong_ket
    WHERE ma_hoc_sinh=student.ma_hoc_sinh AND ma_mon=b.ma_mon AND ma_hoc_ky=b.ma_hoc_ky FOR UPDATE;
    INSERT INTO public.ket_qua_tong_ket(ma_hoc_sinh,ma_mon,ma_hoc_ky,diem_tong_ket,xep_loai,
      phien_ban_he_so,bo_he_so,ngay_tinh)
    VALUES(student.ma_hoc_sinh,b.ma_mon,b.ma_hoc_ky,rounded,classification,weight_version,
      full_snapshot,statement_timestamp())
    ON CONFLICT(ma_hoc_sinh,ma_mon,ma_hoc_ky) DO UPDATE SET
      diem_tong_ket=excluded.diem_tong_ket,xep_loai=excluded.xep_loai,
      phien_ban_he_so=excluded.phien_ban_he_so,bo_he_so=excluded.bo_he_so,ngay_tinh=excluded.ngay_tinh
    RETURNING * INTO saved_result;
    INSERT INTO public.lich_su_tong_ket(ma_ket_qua,nguoi_tinh,diem_cu,xep_loai_cu,bo_he_so_cu,
      diem_moi,xep_loai_moi,bo_he_so_moi,ly_do)
    VALUES(saved_result.ma_ket_qua,actor_id,old_result.diem_tong_ket,old_result.xep_loai,old_result.bo_he_so,
      rounded,classification,full_snapshot,btrim(p_reason));
    calculated:=calculated+1;
    results:=results||jsonb_build_array(jsonb_build_object(
      'id',saved_result.ma_ket_qua::text,'studentId',student.ma_hoc_sinh,'studentName',student.ho_ten,
      'finalScore',rounded::text,'classification',classification,'weightVersion',weight_version,
      'policyVersion',policy.phien_ban,'calculatedAt',to_char(saved_result.ngay_tinh AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"')));
  END LOOP;

  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
    VALUES(actor_id,'FINAL_RESULTS_CALCULATED','bang_diem:'||p_book::text);
  result:=jsonb_build_object('gradebookId',p_book,'gradebookVersion',b.version,
    'weightVersion',weight_version,'policyVersion',policy.phien_ban,
    'calculatedStudents',calculated,'skippedStudents',jsonb_array_length(skipped),
    'results',results,'skipped',skipped,
    'exemptedStudents',jsonb_array_length(exempted),'exempted',exempted);
  INSERT INTO public.khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua)
  VALUES(p_idempotency_key,actor_id,'FINAL_RESULTS',p_request_hash,result);
  RETURN result;
END $$;
COMMIT;
