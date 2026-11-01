-- Tự tạo bảng điểm khi giáo viên được phân công lớp-môn-học kỳ (thay cho nút "Tạo bảng điểm" thủ công).
--   * dam_bao_bang_diem: tạo lưới điểm trống (qua tao_luoi_diem_noi_bo) khi chưa có bảng, học kỳ chưa công bố, lớp thuộc năm học
--     của học kỳ, lớp có học sinh đang học và môn có thành phần điểm. Không đủ điều kiện thì bỏ qua (không làm hỏng việc phân công).
--   * Trigger trên phan_cong_giang_day (thêm hoặc đổi lớp/môn/học kỳ) gọi hàm trên; nhật ký ghi tác nhân NULL (hệ thống).
--   * dam_bao_bang_diem_cua_toi: giáo viên mở danh sách bảng điểm thì bổ sung các bảng còn thiếu (lớp đông học sinh sau phân công).
--   * Bù dữ liệu: mọi phân công hiện có chưa có bảng điểm được tạo bảng.
-- Không đổi điểm, không đụng bảng đã có. Chạy lặp an toàn (hàm trả về khi bảng đã tồn tại).
--
-- ROLLBACK (chỉ tiến): DROP TRIGGER tg_phan_cong_tao_bang_diem_* ON public.phan_cong_giang_day và DROP FUNCTION các hàm dưới đây
-- bằng migration mới; bảng điểm đã tạo là dữ liệu hợp lệ nên được giữ nguyên.
BEGIN;

CREATE FUNCTION public.dam_bao_bang_diem(p_lop integer,p_mon integer,p_term integer) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
  IF EXISTS(SELECT 1 FROM public.bang_diem WHERE ma_lop=p_lop AND ma_mon=p_mon AND ma_hoc_ky=p_term) THEN RETURN false; END IF;
  IF EXISTS(SELECT 1 FROM public.hoc_ky WHERE ma_hoc_ky=p_term AND da_cong_bo) THEN RETURN false; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.lop l JOIN public.hoc_ky hk ON hk.ma_nam_hoc=l.ma_nam_hoc
                WHERE l.ma_lop=p_lop AND hk.ma_hoc_ky=p_term) THEN RETURN false; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.hoc_sinh_cua_lop(p_lop,p_term) s WHERE s.con_hoc)
     OR NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem WHERE ma_mon=p_mon) THEN RETURN false; END IF;
  PERFORM public.tao_luoi_diem_noi_bo(NULL,p_lop,p_mon,p_term);
  RETURN true;
END $$;
REVOKE ALL ON FUNCTION public.dam_bao_bang_diem(integer,integer,integer) FROM PUBLIC;

CREATE FUNCTION public.tg_phan_cong_tao_bang_diem() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
  PERFORM public.dam_bao_bang_diem(NEW.ma_lop,NEW.ma_mon,NEW.ma_hoc_ky);
  RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION public.tg_phan_cong_tao_bang_diem() FROM PUBLIC;

CREATE TRIGGER tg_phan_cong_tao_bang_diem_them AFTER INSERT ON public.phan_cong_giang_day
  FOR EACH ROW EXECUTE FUNCTION public.tg_phan_cong_tao_bang_diem();
CREATE TRIGGER tg_phan_cong_tao_bang_diem_sua AFTER UPDATE OF ma_lop,ma_mon,ma_hoc_ky ON public.phan_cong_giang_day
  FOR EACH ROW EXECUTE FUNCTION public.tg_phan_cong_tao_bang_diem();

-- Giáo viên đang đăng nhập: bổ sung bảng điểm còn thiếu cho các phân công của mình. Trả về số bảng vừa tạo.
CREATE FUNCTION public.dam_bao_bang_diem_cua_toi(p_phien text) RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE actor_id integer; a record; n integer:=0;
BEGIN
  SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='GIAO_VIEN' AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  FOR a IN SELECT pc.ma_lop,pc.ma_mon,pc.ma_hoc_ky FROM public.phan_cong_giang_day pc
    WHERE pc.ma_giao_vien=actor_id
      AND NOT EXISTS(SELECT 1 FROM public.bang_diem b WHERE b.ma_lop=pc.ma_lop AND b.ma_mon=pc.ma_mon AND b.ma_hoc_ky=pc.ma_hoc_ky)
    ORDER BY pc.ma_hoc_ky,pc.ma_lop,pc.ma_mon LOOP
    IF public.dam_bao_bang_diem(a.ma_lop,a.ma_mon,a.ma_hoc_ky) THEN n:=n+1; END IF;
  END LOOP;
  RETURN n;
END $$;
REVOKE ALL ON FUNCTION public.dam_bao_bang_diem_cua_toi(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.dam_bao_bang_diem_cua_toi(text) TO app_runtime;

-- Bù cho các phân công đã có.
DO $$
DECLARE a record;
BEGIN
  FOR a IN SELECT pc.ma_lop,pc.ma_mon,pc.ma_hoc_ky FROM public.phan_cong_giang_day pc
    ORDER BY pc.ma_hoc_ky,pc.ma_lop,pc.ma_mon LOOP
    PERFORM public.dam_bao_bang_diem(a.ma_lop,a.ma_mon,a.ma_hoc_ky);
  END LOOP;
END $$;

COMMIT;
