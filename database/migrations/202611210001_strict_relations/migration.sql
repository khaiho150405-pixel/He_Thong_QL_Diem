-- Ràng buộc liên kết chặt hơn giữa các bảng ở tầng database (trước đây chỉ có ở API hoặc trong từng hàm nghiệp vụ).
-- Mọi kiểm tra chỉ áp cho bản ghi thêm/sửa từ nay, không đụng dữ liệu cũ; lỗi dùng mã 23514 như các ràng buộc khác.
--
-- ROLLBACK (chỉ tiến): DROP TRIGGER của các trigger nêu dưới đây rồi DROP FUNCTION các hàm kiem_*/giu_*; tạo lại các chỉ số đã gỡ:
--   hoc_ky_ma_nam_hoc_idx, lop_ma_nam_hoc_idx, thanh_phan_diem_ma_mon_idx, phan_cong_giang_day_ma_lop_idx,
--   bang_diem_ma_lop_idx, diem_thanh_phan_ma_bang_diem_idx, ket_qua_tong_ket_ma_hoc_sinh_idx, ket_qua_dong_ma_phieu_idx.
-- Không có dữ liệu nào bị mất khi quay lại.
BEGIN;

CREATE FUNCTION public.kiem_lop_cung_nam_hoc_ky() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.lop l JOIN public.hoc_ky h ON h.ma_nam_hoc=l.ma_nam_hoc
    WHERE l.ma_lop=NEW.ma_lop AND h.ma_hoc_ky=NEW.ma_hoc_ky
  ) THEN
    RAISE EXCEPTION '%', TG_ARGV[0] USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER gradebook_year_guard BEFORE INSERT OR UPDATE OF ma_lop, ma_hoc_ky ON public.bang_diem
  FOR EACH ROW EXECUTE FUNCTION public.kiem_lop_cung_nam_hoc_ky('GRADEBOOK_YEAR_MISMATCH');
CREATE TRIGGER assignment_year_guard BEFORE INSERT OR UPDATE OF ma_lop, ma_hoc_ky ON public.phan_cong_giang_day
  FOR EACH ROW EXECUTE FUNCTION public.kiem_lop_cung_nam_hoc_ky('ASSIGNMENT_YEAR_MISMATCH');
CREATE TRIGGER timetable_a_year_guard BEFORE INSERT OR UPDATE OF ma_lop, ma_hoc_ky ON public.thoi_khoa_bieu
  FOR EACH ROW EXECUTE FUNCTION public.kiem_lop_cung_nam_hoc_ky('TIMETABLE_YEAR_MISMATCH');

CREATE FUNCTION public.kiem_tkb_co_phan_cong() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.phan_cong_giang_day pc
    WHERE pc.ma_lop=NEW.ma_lop AND pc.ma_mon=NEW.ma_mon
      AND pc.ma_hoc_ky=NEW.ma_hoc_ky AND pc.ma_giao_vien=NEW.ma_giao_vien
  ) THEN
    RAISE EXCEPTION 'TIMETABLE_ASSIGNMENT_REQUIRED' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER timetable_b_assignment_guard
  BEFORE INSERT OR UPDATE OF ma_lop, ma_mon, ma_giao_vien, ma_hoc_ky ON public.thoi_khoa_bieu
  FOR EACH ROW EXECUTE FUNCTION public.kiem_tkb_co_phan_cong();

CREATE FUNCTION public.giu_phan_cong_trong_tkb() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
  IF TG_OP='UPDATE'
     AND NEW.ma_lop=OLD.ma_lop AND NEW.ma_mon=OLD.ma_mon
     AND NEW.ma_hoc_ky=OLD.ma_hoc_ky AND NEW.ma_giao_vien=OLD.ma_giao_vien THEN
    RETURN NEW;
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.thoi_khoa_bieu t
    WHERE t.ma_lop=OLD.ma_lop AND t.ma_mon=OLD.ma_mon
      AND t.ma_hoc_ky=OLD.ma_hoc_ky AND t.ma_giao_vien=OLD.ma_giao_vien
  ) THEN
    RAISE EXCEPTION 'ASSIGNMENT_IN_TIMETABLE' USING ERRCODE='23514';
  END IF;
  IF TG_OP='DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER assignment_timetable_guard
  BEFORE UPDATE OF ma_lop, ma_mon, ma_giao_vien, ma_hoc_ky OR DELETE ON public.phan_cong_giang_day
  FOR EACH ROW EXECUTE FUNCTION public.giu_phan_cong_trong_tkb();

CREATE FUNCTION public.kiem_cot_thuoc_mon() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.bang_diem b JOIN public.thanh_phan_diem tp ON tp.ma_mon=b.ma_mon
    WHERE b.ma_bang_diem=NEW.ma_bang_diem AND tp.ma_thanh_phan=NEW.ma_thanh_phan
  ) THEN
    RAISE EXCEPTION 'COMPONENT_SUBJECT_MISMATCH' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER grade_component_subject_guard BEFORE INSERT OR UPDATE OF ma_bang_diem, ma_thanh_phan ON public.diem_thanh_phan
  FOR EACH ROW EXECUTE FUNCTION public.kiem_cot_thuoc_mon();
CREATE TRIGGER ticket_component_subject_guard BEFORE INSERT OR UPDATE OF ma_bang_diem, ma_thanh_phan ON public.phieu_nhan_dien
  FOR EACH ROW EXECUTE FUNCTION public.kiem_cot_thuoc_mon();
CREATE TRIGGER deadline_component_subject_guard BEFORE INSERT OR UPDATE OF ma_bang_diem, ma_thanh_phan ON public.lich_nhap_diem
  FOR EACH ROW EXECUTE FUNCTION public.kiem_cot_thuoc_mon();
CREATE TRIGGER column_lock_component_subject_guard BEFORE INSERT OR UPDATE OF ma_bang_diem, ma_thanh_phan ON public.chot_cot_diem
  FOR EACH ROW EXECUTE FUNCTION public.kiem_cot_thuoc_mon();

CREATE FUNCTION public.kiem_o_diem_hoc_sinh_trong_lop() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.bang_diem b JOIN public.hoc_sinh_lop g ON g.ma_lop=b.ma_lop
    WHERE b.ma_bang_diem=NEW.ma_bang_diem AND g.ma_hoc_sinh=NEW.ma_hoc_sinh
  ) THEN
    RAISE EXCEPTION 'GRADE_STUDENT_NOT_ENROLLED' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER grade_student_enrollment_guard BEFORE INSERT OR UPDATE OF ma_bang_diem, ma_hoc_sinh ON public.diem_thanh_phan
  FOR EACH ROW EXECUTE FUNCTION public.kiem_o_diem_hoc_sinh_trong_lop();

CREATE FUNCTION public.kiem_phieu_theo_lo() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
  IF NEW.ma_lo IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.lo_nhan_dien l
    WHERE l.ma_lo=NEW.ma_lo AND l.ma_bang_diem=NEW.ma_bang_diem AND l.ma_mau IS NOT DISTINCT FROM NEW.ma_mau
  ) THEN
    RAISE EXCEPTION 'TICKET_BATCH_MISMATCH' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER ticket_batch_guard BEFORE INSERT OR UPDATE OF ma_lo, ma_bang_diem, ma_mau ON public.phieu_nhan_dien
  FOR EACH ROW EXECUTE FUNCTION public.kiem_phieu_theo_lo();

CREATE FUNCTION public.kiem_dong_thuoc_phieu() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  ticket public.phieu_nhan_dien;
BEGIN
  IF EXISTS (SELECT 1 FROM public.danh_sach_phieu d WHERE d.ma_phieu=NEW.ma_phieu)
     AND NOT EXISTS (
       SELECT 1 FROM public.danh_sach_phieu d
       WHERE d.ma_phieu=NEW.ma_phieu AND d.ma_hoc_sinh=NEW.ma_hoc_sinh
     ) THEN
    RAISE EXCEPTION 'ROW_STUDENT_NOT_IN_ROSTER' USING ERRCODE='23514';
  END IF;
  IF NEW.ma_diem IS NOT NULL THEN
    SELECT * INTO ticket FROM public.phieu_nhan_dien WHERE ma_phieu=NEW.ma_phieu;
    IF NOT EXISTS (
      SELECT 1 FROM public.diem_thanh_phan c
      WHERE c.ma_diem=NEW.ma_diem AND c.ma_bang_diem=ticket.ma_bang_diem
        AND c.ma_thanh_phan=ticket.ma_thanh_phan AND c.ma_hoc_sinh=NEW.ma_hoc_sinh
    ) THEN
      RAISE EXCEPTION 'ROW_CELL_MISMATCH' USING ERRCODE='23514';
    END IF;
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER result_row_ticket_guard BEFORE INSERT OR UPDATE OF ma_phieu, ma_hoc_sinh, ma_diem ON public.ket_qua_dong
  FOR EACH ROW EXECUTE FUNCTION public.kiem_dong_thuoc_phieu();

CREATE FUNCTION public.kiem_dong_dieu_chinh_thuoc_bang() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.phieu_dieu_chinh p JOIN public.diem_thanh_phan d ON d.ma_bang_diem=p.ma_bang_diem
    WHERE p.ma=NEW.ma_phieu AND d.ma_diem=NEW.ma_diem
  ) THEN
    RAISE EXCEPTION 'ADJUSTMENT_LINE_BOOK_MISMATCH' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER adjustment_line_book_guard BEFORE INSERT ON public.dong_dieu_chinh
  FOR EACH ROW EXECUTE FUNCTION public.kiem_dong_dieu_chinh_thuoc_bang();

CREATE FUNCTION public.kiem_ho_so_dung_vai_tro() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  account_id integer;
  wanted public."VaiTro";
BEGIN
  IF TG_TABLE_NAME='giao_vien' THEN
    account_id:=NEW.ma_giao_vien; wanted:='GIAO_VIEN';
  ELSE
    account_id:=NEW.ma_nguoi_dung; wanted:='HOC_SINH';
  END IF;
  IF account_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.nguoi_dung u WHERE u.ma_nguoi_dung=account_id AND u.vai_tro=wanted
  ) THEN
    RAISE EXCEPTION 'PROFILE_ROLE_MISMATCH' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER teacher_account_role_guard BEFORE INSERT OR UPDATE OF ma_giao_vien ON public.giao_vien
  FOR EACH ROW EXECUTE FUNCTION public.kiem_ho_so_dung_vai_tro();
CREATE TRIGGER student_account_role_guard BEFORE INSERT OR UPDATE OF ma_nguoi_dung ON public.hoc_sinh
  FOR EACH ROW EXECUTE FUNCTION public.kiem_ho_so_dung_vai_tro();

CREATE FUNCTION public.giu_vai_tro_khi_co_ho_so() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
  IF NEW.vai_tro<>OLD.vai_tro AND (
    EXISTS (SELECT 1 FROM public.giao_vien WHERE ma_giao_vien=OLD.ma_nguoi_dung)
    OR EXISTS (SELECT 1 FROM public.hoc_sinh WHERE ma_nguoi_dung=OLD.ma_nguoi_dung)
  ) THEN
    RAISE EXCEPTION 'PROFILE_ROLE_MISMATCH' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER account_role_profile_guard BEFORE UPDATE OF vai_tro ON public.nguoi_dung
  FOR EACH ROW EXECUTE FUNCTION public.giu_vai_tro_khi_co_ho_so();

CREATE FUNCTION public.kiem_hoc_ky_trong_nam() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
  IF TG_TABLE_NAME='hoc_ky' THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.nam_hoc y
      WHERE y.ma_nam_hoc=NEW.ma_nam_hoc AND NEW.ngay_bat_dau>=y.ngay_bat_dau AND NEW.ngay_ket_thuc<=y.ngay_ket_thuc
    ) THEN
      RAISE EXCEPTION 'TERM_OUTSIDE_YEAR' USING ERRCODE='23514';
    END IF;
  ELSIF EXISTS (
    SELECT 1 FROM public.hoc_ky h
    WHERE h.ma_nam_hoc=NEW.ma_nam_hoc AND (h.ngay_bat_dau<NEW.ngay_bat_dau OR h.ngay_ket_thuc>NEW.ngay_ket_thuc)
  ) THEN
    RAISE EXCEPTION 'YEAR_RANGE_EXCLUDES_TERM' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER term_inside_year_guard BEFORE INSERT OR UPDATE OF ma_nam_hoc, ngay_bat_dau, ngay_ket_thuc ON public.hoc_ky
  FOR EACH ROW EXECUTE FUNCTION public.kiem_hoc_ky_trong_nam();
CREATE TRIGGER year_contains_terms_guard BEFORE UPDATE OF ngay_bat_dau, ngay_ket_thuc ON public.nam_hoc
  FOR EACH ROW EXECUTE FUNCTION public.kiem_hoc_ky_trong_nam();

CREATE FUNCTION public.kiem_ma_xep_loai() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
  IF NEW.xep_loai IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.tieu_chi_xep_loai c WHERE c.ma_xep_loai=NEW.xep_loai
  ) THEN
    RAISE EXCEPTION 'UNKNOWN_CLASSIFICATION' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER result_classification_guard BEFORE INSERT OR UPDATE OF xep_loai ON public.ket_qua_tong_ket
  FOR EACH ROW EXECUTE FUNCTION public.kiem_ma_xep_loai();

DROP INDEX IF EXISTS public.hoc_ky_ma_nam_hoc_idx;
DROP INDEX IF EXISTS public.lop_ma_nam_hoc_idx;
DROP INDEX IF EXISTS public.thanh_phan_diem_ma_mon_idx;
DROP INDEX IF EXISTS public.phan_cong_giang_day_ma_lop_idx;
DROP INDEX IF EXISTS public.bang_diem_ma_lop_idx;
DROP INDEX IF EXISTS public.diem_thanh_phan_ma_bang_diem_idx;
DROP INDEX IF EXISTS public.ket_qua_tong_ket_ma_hoc_sinh_idx;
DROP INDEX IF EXISTS public.ket_qua_dong_ma_phieu_idx;

COMMIT;
