-- Quản trị viên xóa thông tin học sinh (quyết định chủ dự án 27/11/2026):
-- học sinh chưa có dữ liệu thì xóa hẳn; đã có điểm/lịch sử/phiếu thì ẩn danh và giữ điểm.
-- Rollback: gỡ hàm xoa_hoc_sinh và trigger student_removed_guard, khôi phục hai hàm trigger
-- khong_xoa_ghi_danh, chan_sua_danh_sach_phieu bản cũ rồi bỏ cột da_xoa_luc. Hồ sơ đã ẩn danh
-- hoặc đã xóa không phục hồi được ngoài bản sao lưu.
BEGIN;

ALTER TABLE public.hoc_sinh ADD COLUMN da_xoa_luc timestamptz(6);

CREATE OR REPLACE FUNCTION public.khong_xoa_ghi_danh() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN
  IF TG_OP='DELETE' AND current_user<>'app_runtime'
     AND current_setting('qld.student_removal',true)=OLD.ma_hoc_sinh::text THEN
    RETURN OLD;
  END IF;
  RAISE EXCEPTION 'ENROLLMENT_APPEND_ONLY' USING ERRCODE='23514';
END $$;

CREATE OR REPLACE FUNCTION public.chan_sua_danh_sach_phieu() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN
  IF TG_OP='UPDATE' AND current_user<>'app_runtime'
     AND coalesce(current_setting('qld.student_removal',true),'')<>'' THEN
    RETURN NULL;
  END IF;
  RAISE EXCEPTION 'ROSTER_APPEND_ONLY' USING ERRCODE='42501';
END $$;

CREATE FUNCTION public.chan_sua_hoc_sinh_da_xoa() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN
  IF OLD.da_xoa_luc IS NOT NULL
     AND (NEW.ho_ten,NEW.ngay_sinh,NEW.ma_nguoi_dung,NEW.da_xoa_luc)
       IS DISTINCT FROM (OLD.ho_ten,OLD.ngay_sinh,OLD.ma_nguoi_dung,OLD.da_xoa_luc) THEN
    RAISE EXCEPTION 'STUDENT_REMOVED_READONLY' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER student_removed_guard BEFORE UPDATE ON public.hoc_sinh
  FOR EACH ROW EXECUTE FUNCTION public.chan_sua_hoc_sinh_da_xoa();

CREATE FUNCTION public.xoa_hoc_sinh(p_phien text,p_student integer,p_reason text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE actor_id integer; why text; st public.hoc_sinh; has_data boolean; outcome text;
BEGIN
  IF current_setting('transaction_isolation')<>'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
  why:=btrim(coalesce(p_reason,''));
  IF p_student IS NULL OR length(why) NOT BETWEEN 1 AND 500 THEN
    RAISE EXCEPTION 'INVALID_REMOVAL_REQUEST' USING ERRCODE='23514'; END IF;
  SELECT u.ma_nguoi_dung INTO actor_id
  FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='QUAN_TRI_VIEN'
    AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  SELECT * INTO st FROM public.hoc_sinh WHERE ma_hoc_sinh=p_student FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  IF st.da_xoa_luc IS NOT NULL THEN
    RAISE EXCEPTION 'STUDENT_ALREADY_REMOVED' USING ERRCODE='23514'; END IF;

  has_data:=
    EXISTS(SELECT 1 FROM public.diem_thanh_phan d WHERE d.ma_hoc_sinh=p_student
      AND (d.gia_tri IS NOT NULL OR d.trang_thai<>'CHUA_CO'
        OR EXISTS(SELECT 1 FROM public.lich_su_sua_diem h WHERE h.ma_diem=d.ma_diem)
        OR EXISTS(SELECT 1 FROM public.lich_su_mien_diem m WHERE m.ma_diem=d.ma_diem)
        OR EXISTS(SELECT 1 FROM public.dong_dieu_chinh a WHERE a.ma_diem=d.ma_diem)))
    OR EXISTS(SELECT 1 FROM public.ket_qua_tong_ket WHERE ma_hoc_sinh=p_student)
    OR EXISTS(SELECT 1 FROM public.ket_qua_dong WHERE ma_hoc_sinh=p_student)
    OR EXISTS(SELECT 1 FROM public.danh_sach_phieu WHERE ma_hoc_sinh=p_student);

  PERFORM set_config('qld.student_removal',p_student::text,true);
  IF has_data THEN
    UPDATE public.hoc_sinh_lop SET trang_thai='NGHI_HOC',
      den_ngay=greatest(CURRENT_DATE,tu_ngay),ly_do=why,nguoi_thuc_hien=actor_id
    WHERE ma_hoc_sinh=p_student AND trang_thai='DANG_HOC';
    UPDATE public.danh_sach_phieu SET ho_ten='Học sinh đã xóa #'||p_student
    WHERE ma_hoc_sinh=p_student;
    UPDATE public.ket_qua_dong SET ho_ten_doc_duoc=NULL
    WHERE ma_hoc_sinh=p_student AND ho_ten_doc_duoc IS NOT NULL;
    UPDATE public.hoc_sinh SET ho_ten='Học sinh đã xóa #'||p_student,
      ngay_sinh=DATE '1900-01-01',ma_nguoi_dung=NULL,da_xoa_luc=now(),dang_theo_hoc=false
    WHERE ma_hoc_sinh=p_student;
    outcome:='ANONYMIZED';
  ELSE
    DELETE FROM public.diem_thanh_phan WHERE ma_hoc_sinh=p_student;
    DELETE FROM public.hoc_sinh_lop WHERE ma_hoc_sinh=p_student;
    DELETE FROM public.hoc_sinh WHERE ma_hoc_sinh=p_student;
    outcome:='DELETED';
  END IF;
  PERFORM set_config('qld.student_removal','',true);

  IF st.ma_nguoi_dung IS NOT NULL THEN
    DELETE FROM public.phien_lam_viec WHERE ma_nguoi_dung=st.ma_nguoi_dung;
    DELETE FROM public.phien_ghi_nho WHERE ma_nguoi_dung=st.ma_nguoi_dung;
    UPDATE public.nguoi_dung SET ten_dang_nhap='da_xoa_'||ma_nguoi_dung,
      mat_khau_ma_hoa='removed',trang_thai=false WHERE ma_nguoi_dung=st.ma_nguoi_dung;
  END IF;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
  VALUES(actor_id,'STUDENT_'||outcome,'hoc_sinh:'||p_student);
  RETURN jsonb_build_object('mode',outcome);
END $$;
REVOKE ALL ON FUNCTION public.xoa_hoc_sinh(text,integer,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.xoa_hoc_sinh(text,integer,text) TO app_runtime;

COMMIT;
