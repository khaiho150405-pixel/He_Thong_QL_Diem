-- Ghi danh học sinh, đợt B (ADR-0018): lên lớp cuối năm, chuyển lớp giữa năm, nghỉ học, học lại. Chỉ QTV.
-- Quy ước ngày: ghi danh cũ đóng với den_ngay = ngày hiệu lực − 1; ghi danh mới có tu_ngay = ngày hiệu lực. Các hàm chỉ ghi
-- hoc_sinh_lop (trigger đợt A tự đồng bộ hoc_sinh.ma_lop/dang_theo_hoc); không đụng điểm, tổng kết hay công bố của năm cũ.
-- Lỗi nghiệp vụ có kèm mã học sinh dưới dạng 'MA_LOI:<ma_hoc_sinh>' để API trả details { studentId, reason }.
--
-- ROLLBACK (chỉ tiến): thu hồi EXECUTE của bốn hàm bằng migration mới; không xóa ghi danh đã tạo vì là lịch sử học tập.
BEGIN;

-- Lên lớp cuối năm theo lớp nguồn: p_items = [{studentId, action, targetClassId, reason}] (1–100), một dòng sai → hủy cả lô.
CREATE FUNCTION public.xep_lop_nam_moi(p_phien text,p_lop integer,p_target_year integer,p_items jsonb,p_idem text,p_hash text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE actor_id integer; src_class public.lop; src_year public.nam_hoc; tgt_year public.nam_hoc; tgt_class public.lop;
  prior public.khoa_idempotency; src public.hoc_sinh_lop; item jsonb; sid integer; act text; tcid integer; why text;
  seen integer[]:='{}'; promoted integer:=0; retained integer:=0; graduated integer:=0; withdrawn integer:=0; result jsonb;
BEGIN
  IF current_setting('transaction_isolation')<>'serializable' THEN RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
  IF p_lop IS NULL OR p_target_year IS NULL OR p_hash IS NULL OR p_hash !~ '^[0-9a-f]{64}$'
     OR p_idem IS NULL OR length(p_idem) NOT BETWEEN 1 AND 64 OR p_idem !~ '^[a-zA-Z0-9_-]+$'
     OR p_items IS NULL OR jsonb_typeof(p_items)<>'array' OR jsonb_array_length(p_items) NOT BETWEEN 1 AND 100 THEN
    RAISE EXCEPTION 'INVALID_ENROLLMENT_REQUEST' USING ERRCODE='23514'; END IF;
  SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='QUAN_TRI_VIEN' AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  SELECT * INTO src_class FROM public.lop WHERE ma_lop=p_lop;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  SELECT * INTO tgt_year FROM public.nam_hoc WHERE ma_nam_hoc=p_target_year;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  SELECT * INTO src_year FROM public.nam_hoc WHERE ma_nam_hoc=src_class.ma_nam_hoc;
  SELECT * INTO prior FROM public.khoa_idempotency WHERE ma_nguoi_dung=actor_id AND thao_tac='ENROLL_PROMOTE' AND khoa=p_idem;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau<>p_hash THEN RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505'; END IF;
    RETURN prior.ket_qua;
  END IF;
  IF tgt_year.ngay_bat_dau <= src_year.ngay_ket_thuc THEN RAISE EXCEPTION 'TARGET_YEAR_NOT_AFTER' USING ERRCODE='23514'; END IF;
  FOR item IN SELECT value FROM jsonb_array_elements(p_items) LOOP
    IF jsonb_typeof(item)<>'object' OR NOT (item ?& ARRAY['studentId','action'])
       OR (item-ARRAY['studentId','action','targetClassId','reason'])<>'{}'::jsonb
       OR jsonb_typeof(item->'studentId')<>'number' OR (item->>'studentId')!~'^[1-9][0-9]{0,9}$'
       OR (item->>'studentId')::numeric>2147483647
       OR jsonb_typeof(item->'action')<>'string'
       OR jsonb_typeof(coalesce(item->'targetClassId','null'::jsonb)) NOT IN ('number','null')
       OR jsonb_typeof(coalesce(item->'reason','null'::jsonb)) NOT IN ('string','null') THEN
      RAISE EXCEPTION 'INVALID_ENROLLMENT_REQUEST' USING ERRCODE='23514'; END IF;
    sid:=(item->>'studentId')::integer;
    act:=item->>'action';
    IF act NOT IN ('LEN_LOP','LUU_BAN','TOT_NGHIEP','NGHI_HOC') THEN RAISE EXCEPTION 'INVALID_ENROLLMENT_REQUEST' USING ERRCODE='23514'; END IF;
    why:=nullif(btrim(coalesce(item->>'reason','')),'');
    IF length(coalesce(why,''))>500 THEN RAISE EXCEPTION 'INVALID_ENROLLMENT_REQUEST' USING ERRCODE='23514'; END IF;
    IF sid=ANY(seen) THEN RAISE EXCEPTION 'DUPLICATE_STUDENT:%',sid USING ERRCODE='23514'; END IF;
    seen:=array_append(seen,sid);
    SELECT * INTO src FROM public.hoc_sinh_lop WHERE ma_hoc_sinh=sid AND ma_lop=p_lop AND trang_thai='DANG_HOC' FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'ENROLLMENT_NOT_ACTIVE:%',sid USING ERRCODE='23514'; END IF;
    tcid:=CASE WHEN jsonb_typeof(coalesce(item->'targetClassId','null'::jsonb))='number' THEN (item->>'targetClassId')::integer END;
    IF act IN ('LEN_LOP','LUU_BAN') AND tcid IS NULL THEN RAISE EXCEPTION 'TARGET_CLASS_REQUIRED:%',sid USING ERRCODE='23514'; END IF;
    IF act IN ('TOT_NGHIEP','NGHI_HOC') AND tcid IS NOT NULL THEN RAISE EXCEPTION 'TARGET_CLASS_NOT_ALLOWED:%',sid USING ERRCODE='23514'; END IF;
    IF act='TOT_NGHIEP' AND src_class.khoi<>12 THEN RAISE EXCEPTION 'GRADUATION_ONLY_GRADE_12:%',sid USING ERRCODE='23514'; END IF;
    IF EXISTS(SELECT 1 FROM public.hoc_sinh_lop WHERE ma_hoc_sinh=sid AND ma_nam_hoc=p_target_year) THEN
      RAISE EXCEPTION 'STUDENT_ALREADY_ENROLLED:%',sid USING ERRCODE='23514'; END IF;
    IF tcid IS NOT NULL THEN
      SELECT * INTO tgt_class FROM public.lop WHERE ma_lop=tcid;
      IF NOT FOUND OR tgt_class.ma_nam_hoc<>p_target_year THEN RAISE EXCEPTION 'TARGET_CLASS_WRONG_YEAR:%',sid USING ERRCODE='23514'; END IF;
      IF (act='LEN_LOP' AND tgt_class.khoi<>src_class.khoi+1) OR (act='LUU_BAN' AND tgt_class.khoi<>src_class.khoi) THEN
        RAISE EXCEPTION 'PROMOTION_GRADE_MISMATCH:%',sid USING ERRCODE='23514'; END IF;
    END IF;
    UPDATE public.hoc_sinh_lop SET trang_thai=act::public."TrangThaiGhiDanh",den_ngay=src_year.ngay_ket_thuc,
      ly_do=why,nguoi_thuc_hien=actor_id WHERE ma=src.ma;
    IF tcid IS NOT NULL THEN
      INSERT INTO public.hoc_sinh_lop(ma_hoc_sinh,ma_lop,tu_ngay,trang_thai,ly_do,nguoi_thuc_hien)
      VALUES(sid,tcid,tgt_year.ngay_bat_dau,'DANG_HOC',why,actor_id);
    END IF;
    IF act='LEN_LOP' THEN promoted:=promoted+1; ELSIF act='LUU_BAN' THEN retained:=retained+1;
    ELSIF act='TOT_NGHIEP' THEN graduated:=graduated+1; ELSE withdrawn:=withdrawn+1; END IF;
  END LOOP;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'ENROLLMENT_PROMOTED','lop:'||p_lop||'>nam:'||p_target_year);
  result:=jsonb_build_object('processed',promoted+retained+graduated+withdrawn,'promoted',promoted,'retained',retained,
    'graduated',graduated,'withdrawn',withdrawn);
  INSERT INTO public.khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua) VALUES(p_idem,actor_id,'ENROLL_PROMOTE',p_hash,result);
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.xep_lop_nam_moi(text,integer,integer,jsonb,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.xep_lop_nam_moi(text,integer,integer,jsonb,text,text) TO app_runtime;

-- Chuyển lớp giữa năm: cùng năm, cùng khối, khác lớp.
CREATE FUNCTION public.chuyen_lop_hoc_sinh(p_phien text,p_student integer,p_target_class integer,p_effective date,p_reason text,p_idem text,p_hash text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE actor_id integer; why text; cur public.hoc_sinh_lop; cur_class public.lop; tgt public.lop; yr public.nam_hoc;
  prior public.khoa_idempotency; new_id bigint; affected jsonb; result jsonb;
BEGIN
  IF current_setting('transaction_isolation')<>'serializable' THEN RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
  why:=btrim(coalesce(p_reason,''));
  IF p_student IS NULL OR p_target_class IS NULL OR p_effective IS NULL OR length(why) NOT BETWEEN 1 AND 500
     OR p_hash IS NULL OR p_hash !~ '^[0-9a-f]{64}$'
     OR p_idem IS NULL OR length(p_idem) NOT BETWEEN 1 AND 64 OR p_idem !~ '^[a-zA-Z0-9_-]+$' THEN
    RAISE EXCEPTION 'INVALID_ENROLLMENT_REQUEST' USING ERRCODE='23514'; END IF;
  SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='QUAN_TRI_VIEN' AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.hoc_sinh WHERE ma_hoc_sinh=p_student) THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  SELECT * INTO tgt FROM public.lop WHERE ma_lop=p_target_class;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  SELECT * INTO prior FROM public.khoa_idempotency WHERE ma_nguoi_dung=actor_id AND thao_tac='ENROLL_TRANSFER' AND khoa=p_idem;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau<>p_hash THEN RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505'; END IF;
    RETURN prior.ket_qua;
  END IF;
  SELECT * INTO cur FROM public.hoc_sinh_lop WHERE ma_hoc_sinh=p_student AND trang_thai='DANG_HOC'
  ORDER BY tu_ngay DESC,ma DESC LIMIT 1 FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'ENROLLMENT_NOT_ACTIVE:%',p_student USING ERRCODE='23514'; END IF;
  SELECT * INTO cur_class FROM public.lop WHERE ma_lop=cur.ma_lop;
  IF tgt.ma_nam_hoc<>cur.ma_nam_hoc THEN RAISE EXCEPTION 'TARGET_CLASS_WRONG_YEAR:%',p_student USING ERRCODE='23514'; END IF;
  IF tgt.ma_lop=cur.ma_lop THEN RAISE EXCEPTION 'TRANSFER_SAME_CLASS:%',p_student USING ERRCODE='23514'; END IF;
  IF tgt.khoi<>cur_class.khoi THEN RAISE EXCEPTION 'TRANSFER_GRADE_MISMATCH:%',p_student USING ERRCODE='23514'; END IF;
  SELECT * INTO yr FROM public.nam_hoc WHERE ma_nam_hoc=cur.ma_nam_hoc;
  IF p_effective < yr.ngay_bat_dau OR p_effective > yr.ngay_ket_thuc OR p_effective <= cur.tu_ngay THEN
    RAISE EXCEPTION 'EFFECTIVE_DATE_OUT_OF_RANGE:%',p_student USING ERRCODE='23514'; END IF;
  IF EXISTS(SELECT 1 FROM public.hoc_sinh_lop WHERE ma_hoc_sinh=p_student AND ma_lop=p_target_class) THEN
    RAISE EXCEPTION 'STUDENT_ALREADY_ENROLLED:%',p_student USING ERRCODE='23514'; END IF;
  IF EXISTS(SELECT 1 FROM public.diem_thanh_phan d JOIN public.bang_diem b ON b.ma_bang_diem=d.ma_bang_diem
      JOIN public.hoc_ky k ON k.ma_hoc_ky=b.ma_hoc_ky
      WHERE b.ma_lop=cur.ma_lop AND d.ma_hoc_sinh=p_student AND d.gia_tri IS NOT NULL AND k.ngay_bat_dau>=p_effective) THEN
    RAISE EXCEPTION 'TRANSFER_HAS_LATER_GRADES:%',p_student USING ERRCODE='23514'; END IF;
  UPDATE public.hoc_sinh_lop SET trang_thai='DA_CHUYEN_LOP',den_ngay=p_effective-1,ly_do=why,nguoi_thuc_hien=actor_id WHERE ma=cur.ma;
  INSERT INTO public.hoc_sinh_lop(ma_hoc_sinh,ma_lop,tu_ngay,trang_thai,ly_do,nguoi_thuc_hien)
  VALUES(p_student,p_target_class,p_effective,'DANG_HOC',why,actor_id) RETURNING ma INTO new_id;
  -- Bảng điểm lớp mới thuộc các học kỳ từ ngày hiệu lực (ô điểm không được tự tạo).
  SELECT coalesce(jsonb_agg(jsonb_build_object('id',b.ma_bang_diem,'subjectName',m.ten_mon,'termName',k.ten)
    ORDER BY k.thu_tu,m.ten_mon),'[]'::jsonb) INTO affected
  FROM public.bang_diem b JOIN public.hoc_ky k ON k.ma_hoc_ky=b.ma_hoc_ky JOIN public.mon_hoc m ON m.ma_mon=b.ma_mon
  WHERE b.ma_lop=p_target_class AND k.ngay_ket_thuc>=p_effective;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'ENROLLMENT_TRANSFERRED','hoc_sinh:'||p_student||'>lop:'||p_target_class);
  result:=jsonb_build_object('enrollmentId',new_id::text,'affectedGradebooks',affected);
  INSERT INTO public.khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua) VALUES(p_idem,actor_id,'ENROLL_TRANSFER',p_hash,result);
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.chuyen_lop_hoc_sinh(text,integer,integer,date,text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.chuyen_lop_hoc_sinh(text,integer,integer,date,text,text,text) TO app_runtime;

-- Nghỉ học: DANG_HOC → NGHI_HOC, không khóa tài khoản.
CREATE FUNCTION public.cho_nghi_hoc(p_phien text,p_student integer,p_effective date,p_reason text,p_idem text,p_hash text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE actor_id integer; why text; cur public.hoc_sinh_lop; yr public.nam_hoc; prior public.khoa_idempotency; result jsonb;
BEGIN
  IF current_setting('transaction_isolation')<>'serializable' THEN RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
  why:=btrim(coalesce(p_reason,''));
  IF p_student IS NULL OR p_effective IS NULL OR length(why) NOT BETWEEN 1 AND 500 OR p_hash IS NULL OR p_hash !~ '^[0-9a-f]{64}$'
     OR p_idem IS NULL OR length(p_idem) NOT BETWEEN 1 AND 64 OR p_idem !~ '^[a-zA-Z0-9_-]+$' THEN
    RAISE EXCEPTION 'INVALID_ENROLLMENT_REQUEST' USING ERRCODE='23514'; END IF;
  SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='QUAN_TRI_VIEN' AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.hoc_sinh WHERE ma_hoc_sinh=p_student) THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  SELECT * INTO prior FROM public.khoa_idempotency WHERE ma_nguoi_dung=actor_id AND thao_tac='ENROLL_WITHDRAW' AND khoa=p_idem;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau<>p_hash THEN RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505'; END IF;
    RETURN prior.ket_qua;
  END IF;
  SELECT * INTO cur FROM public.hoc_sinh_lop WHERE ma_hoc_sinh=p_student AND trang_thai='DANG_HOC'
  ORDER BY tu_ngay DESC,ma DESC LIMIT 1 FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'ENROLLMENT_NOT_ACTIVE:%',p_student USING ERRCODE='23514'; END IF;
  SELECT * INTO yr FROM public.nam_hoc WHERE ma_nam_hoc=cur.ma_nam_hoc;
  IF p_effective < yr.ngay_bat_dau OR p_effective > yr.ngay_ket_thuc OR p_effective <= cur.tu_ngay THEN
    RAISE EXCEPTION 'EFFECTIVE_DATE_OUT_OF_RANGE:%',p_student USING ERRCODE='23514'; END IF;
  UPDATE public.hoc_sinh_lop SET trang_thai='NGHI_HOC',den_ngay=p_effective-1,ly_do=why,nguoi_thuc_hien=actor_id WHERE ma=cur.ma;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'ENROLLMENT_WITHDRAWN','hoc_sinh:'||p_student);
  result:=jsonb_build_object('enrollmentId',cur.ma::text);
  INSERT INTO public.khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua) VALUES(p_idem,actor_id,'ENROLL_WITHDRAW',p_hash,result);
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.cho_nghi_hoc(text,integer,date,text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cho_nghi_hoc(text,integer,date,text,text,text) TO app_runtime;

-- Học lại: cùng lớp của ghi danh NGHI_HOC gần nhất → mở lại ghi danh đó (giá trị cũ ghi vào nhật ký); lớp khác → ghi danh mới.
CREATE FUNCTION public.cho_hoc_lai(p_phien text,p_student integer,p_class integer,p_effective date,p_reason text,p_idem text,p_hash text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE actor_id integer; why text; cls public.lop; yr public.nam_hoc; last_out public.hoc_sinh_lop; prior public.khoa_idempotency;
  enrollment_id bigint; result jsonb;
BEGIN
  IF current_setting('transaction_isolation')<>'serializable' THEN RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
  why:=btrim(coalesce(p_reason,''));
  IF p_student IS NULL OR p_class IS NULL OR p_effective IS NULL OR length(why) NOT BETWEEN 1 AND 500
     OR p_hash IS NULL OR p_hash !~ '^[0-9a-f]{64}$'
     OR p_idem IS NULL OR length(p_idem) NOT BETWEEN 1 AND 64 OR p_idem !~ '^[a-zA-Z0-9_-]+$' THEN
    RAISE EXCEPTION 'INVALID_ENROLLMENT_REQUEST' USING ERRCODE='23514'; END IF;
  SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='QUAN_TRI_VIEN' AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.hoc_sinh WHERE ma_hoc_sinh=p_student) THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  SELECT * INTO cls FROM public.lop WHERE ma_lop=p_class;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  SELECT * INTO prior FROM public.khoa_idempotency WHERE ma_nguoi_dung=actor_id AND thao_tac='ENROLL_REENROLL' AND khoa=p_idem;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau<>p_hash THEN RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505'; END IF;
    RETURN prior.ket_qua;
  END IF;
  SELECT * INTO yr FROM public.nam_hoc WHERE ma_nam_hoc=cls.ma_nam_hoc;
  IF p_effective < yr.ngay_bat_dau OR p_effective > yr.ngay_ket_thuc THEN
    RAISE EXCEPTION 'TARGET_CLASS_WRONG_YEAR:%',p_student USING ERRCODE='23514'; END IF;
  IF EXISTS(SELECT 1 FROM public.hoc_sinh_lop WHERE ma_hoc_sinh=p_student AND ma_nam_hoc=cls.ma_nam_hoc AND trang_thai='DANG_HOC') THEN
    RAISE EXCEPTION 'STUDENT_ALREADY_ENROLLED:%',p_student USING ERRCODE='23514'; END IF;
  SELECT * INTO last_out FROM public.hoc_sinh_lop WHERE ma_hoc_sinh=p_student AND trang_thai='NGHI_HOC'
  ORDER BY den_ngay DESC,ma DESC LIMIT 1 FOR UPDATE;
  IF FOUND AND last_out.ma_lop=p_class THEN
    UPDATE public.hoc_sinh_lop SET trang_thai='DANG_HOC',den_ngay=NULL,ly_do=why,nguoi_thuc_hien=actor_id WHERE ma=last_out.ma;
    enrollment_id:=last_out.ma;
    INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
    VALUES(actor_id,'ENROLLMENT_REOPENED','hoc_sinh_lop:'||last_out.ma||':nghi='||last_out.den_ngay||':'||left(coalesce(last_out.ly_do,''),40));
  ELSE
    IF EXISTS(SELECT 1 FROM public.hoc_sinh_lop WHERE ma_hoc_sinh=p_student AND ma_lop=p_class) THEN
      RAISE EXCEPTION 'STUDENT_ALREADY_ENROLLED:%',p_student USING ERRCODE='23514'; END IF;
    INSERT INTO public.hoc_sinh_lop(ma_hoc_sinh,ma_lop,tu_ngay,trang_thai,ly_do,nguoi_thuc_hien)
    VALUES(p_student,p_class,p_effective,'DANG_HOC',why,actor_id) RETURNING ma INTO enrollment_id;
    INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'ENROLLMENT_REENROLLED','hoc_sinh:'||p_student||'>lop:'||p_class);
  END IF;
  result:=jsonb_build_object('enrollmentId',enrollment_id::text);
  INSERT INTO public.khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua) VALUES(p_idem,actor_id,'ENROLL_REENROLL',p_hash,result);
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.cho_hoc_lai(text,integer,integer,date,text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cho_hoc_lai(text,integer,integer,date,text,text,text) TO app_runtime;

COMMIT;
