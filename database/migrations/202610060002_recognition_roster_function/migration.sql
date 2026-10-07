-- ADR-0015: tao_phieu_nhan_dien nhận danh sách lớp đã chốt (p_roster) thay cho số dòng khai báo.
--
-- ROLLBACK (không tự động): hàm cũ (có p_declared_rows) nằm ở 202609110001_recognition_upload_outbox.
-- Để quay lại: DROP hàm mới, tạo lại hàm cũ từ file đó, GRANT EXECUTE cho app_runtime. Việc này chỉ nên làm khi
-- chưa có phiếu tạo bằng hàm mới (mọi phiếu mới có danh_sach_phieu không thể hợp lệ với hàm cũ). Cách an toàn
-- hơn là sửa tiến bằng migration mới; không xóa danh_sach_phieu đã dùng.
BEGIN;

DROP FUNCTION public.tao_phieu_nhan_dien(text,integer,integer,text,text,integer,text,text);

CREATE FUNCTION public.tao_phieu_nhan_dien(
  p_phien text,
  p_book integer,
  p_component integer,
  p_checksum text,
  p_object_key text,
  p_roster jsonb,
  p_idempotency_key text,
  p_request_hash text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  b public.bang_diem;
  actor_id integer;
  active_rows integer;
  roster_rows integer;
  ticket_id bigint;
  prior public.khoa_idempotency;
  result jsonb;
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001';
  END IF;
  IF p_checksum !~ '^[0-9a-f]{64}$' OR p_request_hash !~ '^[0-9a-f]{64}$'
     OR p_object_key !~ '^recognition/original/[0-9a-f-]{36}[.](png|jpg)$'
     OR length(p_idempotency_key) NOT BETWEEN 1 AND 64
     OR p_idempotency_key !~ '^[a-zA-Z0-9_-]+$' THEN
    RAISE EXCEPTION 'INVALID_RECOGNITION_REQUEST' USING ERRCODE='23514';
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
  IF b.trang_thai <> 'DANG_NHAP_LIEU'
     OR NOT EXISTS (SELECT 1 FROM public.phan_cong_giang_day pc
       WHERE pc.ma_giao_vien=actor_id AND pc.ma_lop=b.ma_lop
         AND pc.ma_mon=b.ma_mon AND pc.ma_hoc_ky=b.ma_hoc_ky)
     OR NOT EXISTS (SELECT 1 FROM public.thanh_phan_diem tp
       WHERE tp.ma_thanh_phan=p_component AND tp.ma_mon=b.ma_mon) THEN
    RAISE EXCEPTION 'FORBIDDEN_OR_STATE_CONFLICT' USING ERRCODE='42501';
  END IF;

  SELECT * INTO prior FROM public.khoa_idempotency
  WHERE ma_nguoi_dung=actor_id AND thao_tac='RECOGNITION_UPLOAD'
    AND khoa=p_idempotency_key;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau <> p_request_hash THEN
      RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505';
    END IF;
    RETURN prior.ket_qua;
  END IF;

  -- Hình dạng snapshot: mảng 1..2000 object đúng ba khóa {stt, studentId, fullName}.
  IF p_roster IS NULL OR jsonb_typeof(p_roster) <> 'array'
     OR jsonb_array_length(p_roster) NOT BETWEEN 1 AND 2000
     OR EXISTS (
       SELECT 1 FROM jsonb_array_elements(p_roster) e
       WHERE jsonb_typeof(e) <> 'object'
         OR (SELECT count(*) FROM jsonb_object_keys(e)) <> 3
         OR NOT (e ?& ARRAY['stt','studentId','fullName'])
         OR jsonb_typeof(e->'stt') <> 'number'
         OR jsonb_typeof(e->'studentId') <> 'number'
         OR jsonb_typeof(e->'fullName') <> 'string'
         OR (e->>'stt') !~ '^[1-9][0-9]{0,8}$'
         OR (e->>'studentId') !~ '^[1-9][0-9]{0,8}$'
         OR length(e->>'fullName') NOT BETWEEN 1 AND 100
     ) THEN
    RAISE EXCEPTION 'INVALID_ROSTER_SNAPSHOT' USING ERRCODE='23514';
  END IF;
  roster_rows := jsonb_array_length(p_roster);
  SELECT count(*)::integer INTO active_rows FROM public.hoc_sinh
  WHERE ma_lop=b.ma_lop AND dang_theo_hoc;
  -- n = sĩ số đang học; STT liên tục 1..n không trùng; học sinh không trùng, thuộc lớp, đang học, đúng họ tên.
  IF roster_rows <> active_rows
     OR (SELECT count(DISTINCT (e->>'stt')::integer) FROM jsonb_array_elements(p_roster) e) <> roster_rows
     OR (SELECT min((e->>'stt')::integer) FROM jsonb_array_elements(p_roster) e) <> 1
     OR (SELECT max((e->>'stt')::integer) FROM jsonb_array_elements(p_roster) e) <> roster_rows
     OR (SELECT count(DISTINCT (e->>'studentId')::integer) FROM jsonb_array_elements(p_roster) e) <> roster_rows
     OR (SELECT count(*) FROM jsonb_array_elements(p_roster) e
         JOIN public.hoc_sinh hs ON hs.ma_hoc_sinh=(e->>'studentId')::integer
          AND hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc AND hs.ho_ten=(e->>'fullName')) <> roster_rows THEN
    RAISE EXCEPTION 'INVALID_ROSTER_SNAPSHOT' USING ERRCODE='23514';
  END IF;

  IF EXISTS (SELECT 1 FROM public.phieu_nhan_dien WHERE ma_bam_tep=p_checksum) THEN
    RAISE EXCEPTION 'DUPLICATE_FILE' USING ERRCODE='23505';
  END IF;
  IF EXISTS (SELECT 1 FROM public.phieu_nhan_dien
    WHERE ma_bang_diem=p_book AND ma_thanh_phan=p_component
      AND trang_thai IN ('DANG_XU_LY','CHO_DOI_CHIEU')) THEN
    RAISE EXCEPTION 'RECOGNITION_ALREADY_PENDING' USING ERRCODE='23514';
  END IF;

  -- so_dong_khai_bao từ nay là sĩ số snapshot.
  INSERT INTO public.phieu_nhan_dien(
    ma_bang_diem,ma_thanh_phan,nguoi_tai,ma_bam_tep,
    duong_dan_anh_goc,so_dong_khai_bao
  ) VALUES (
    p_book,p_component,actor_id,p_checksum,p_object_key,roster_rows
  ) RETURNING ma_phieu INTO ticket_id;
  INSERT INTO public.danh_sach_phieu(ma_phieu,stt,ma_hoc_sinh,ho_ten)
  SELECT ticket_id,(e->>'stt')::integer,(e->>'studentId')::integer,e->>'fullName'
  FROM jsonb_array_elements(p_roster) e;
  result := jsonb_build_object(
    'ticketId',ticket_id::text,
    'jobId','recognition-'||ticket_id::text,
    'status','DANG_XU_LY',
    'storedObjectKey',p_object_key
  );
  INSERT INTO public.recognition_outbox(loai_su_kien,ma_phieu,du_lieu)
    VALUES('RECOGNITION_REQUESTED',ticket_id,result);
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
    VALUES(actor_id,'RECOGNITION_UPLOADED','phieu_nhan_dien:'||ticket_id::text);
  INSERT INTO public.khoa_idempotency(
    khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua
  ) VALUES (
    p_idempotency_key,actor_id,'RECOGNITION_UPLOAD',p_request_hash,result
  );
  RETURN result;
END $$;

REVOKE ALL ON FUNCTION public.tao_phieu_nhan_dien(
  text,integer,integer,text,text,jsonb,text,text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tao_phieu_nhan_dien(
  text,integer,integer,text,text,jsonb,text,text
) TO app_runtime;

COMMIT;
