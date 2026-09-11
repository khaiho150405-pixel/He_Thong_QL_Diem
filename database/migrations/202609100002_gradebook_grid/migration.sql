-- Phase 2 part 1: the only new runtime write capability creates NULL cells.
-- No direct INSERT/UPDATE/DELETE on gradebooks or grades is granted.
BEGIN;
CREATE FUNCTION public.tao_luoi_diem_trong(
  p_phien text, p_lop integer, p_mon integer, p_hoc_ky integer
) RETURNS SETOF public.bang_diem
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog AS $$
DECLARE
  v_actor integer;
  v_book public.bang_diem;
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE = '25001';
  END IF;
  SELECT u.ma_nguoi_dung INTO v_actor
  FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING (ma_nguoi_dung)
  WHERE s.ma_bam = p_phien AND u.trang_thai AND u.vai_tro = 'GIAO_VIEN'
    AND s.het_han > statement_timestamp()
    AND s.hoat_dong_cuoi > statement_timestamp() - interval '30 minutes';
  IF v_actor IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.phan_cong_giang_day pc
    WHERE pc.ma_giao_vien = v_actor AND pc.ma_lop = p_lop
      AND pc.ma_mon = p_mon AND pc.ma_hoc_ky = p_hoc_ky
  ) THEN
    RAISE EXCEPTION 'GRADEBOOK_FORBIDDEN' USING ERRCODE = '42501';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.lop l JOIN public.hoc_ky hk ON hk.ma_nam_hoc = l.ma_nam_hoc
    WHERE l.ma_lop = p_lop AND hk.ma_hoc_ky = p_hoc_ky
  ) THEN
    RAISE EXCEPTION 'GRADEBOOK_YEAR_MISMATCH' USING ERRCODE = '23514';
  END IF;

  SELECT * INTO v_book FROM public.bang_diem
    WHERE ma_lop = p_lop AND ma_mon = p_mon AND ma_hoc_ky = p_hoc_ky;
  IF FOUND THEN
    -- A retry never overwrites cells, reopens a locked book or duplicates audit.
    RETURN NEXT v_book;
    RETURN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.hoc_sinh WHERE ma_lop = p_lop AND dang_theo_hoc)
    OR NOT EXISTS (SELECT 1 FROM public.thanh_phan_diem WHERE ma_mon = p_mon) THEN
    RAISE EXCEPTION 'GRADEBOOK_EMPTY_ROSTER_OR_COMPONENTS' USING ERRCODE = '23514';
  END IF;

  INSERT INTO public.bang_diem (ma_lop, ma_mon, ma_hoc_ky)
    VALUES (p_lop, p_mon, p_hoc_ky) RETURNING * INTO v_book;
  INSERT INTO public.diem_thanh_phan
    (ma_bang_diem, ma_hoc_sinh, ma_thanh_phan, gia_tri, trang_thai, nguon_nhap)
    SELECT v_book.ma_bang_diem, hs.ma_hoc_sinh, tp.ma_thanh_phan,
      NULL, 'CHUA_CO', 'NHAP_TAY'
    FROM public.hoc_sinh hs CROSS JOIN public.thanh_phan_diem tp
    WHERE hs.ma_lop = p_lop AND hs.dang_theo_hoc AND tp.ma_mon = p_mon;
  INSERT INTO public.nhat_ky_bao_mat (ma_tac_nhan, hanh_dong, doi_tuong)
    VALUES (v_actor, 'GRADEBOOK_CREATED', 'bang_diem:' || v_book.ma_bang_diem);
  RETURN NEXT v_book;
END;
$$;
REVOKE ALL ON FUNCTION public.tao_luoi_diem_trong(text, integer, integer, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tao_luoi_diem_trong(text, integer, integer, integer) TO app_runtime;
COMMIT;
-- Forward-only for shared environments: retain created books, NULL cells and audit.
-- Emergency disable: REVOKE EXECUTE on this signature from app_runtime in a new migration.
