-- Custom constraints complement Prisma's structural migration.
CREATE UNIQUE INDEX nam_hoc_mot_hien_hanh ON nam_hoc (hien_hanh) WHERE hien_hanh;
ALTER TABLE nam_hoc ADD CONSTRAINT nam_hoc_ngay CHECK (ngay_bat_dau < ngay_ket_thuc);
ALTER TABLE hoc_ky ADD CONSTRAINT hoc_ky_ngay CHECK (ngay_bat_dau < ngay_ket_thuc AND thu_tu > 0);
ALTER TABLE thanh_phan_diem ADD CONSTRAINT he_so_duong CHECK (he_so > 0);
ALTER TABLE nguoi_dung ADD CONSTRAINT so_lan_sai_khong_am CHECK (so_lan_dang_nhap_sai >= 0);
ALTER TABLE bang_diem ADD CONSTRAINT version_khong_am CHECK (version >= 0);
ALTER TABLE diem_thanh_phan ADD CONSTRAINT diem_hop_le CHECK (gia_tri BETWEEN 0 AND 10);
ALTER TABLE diem_thanh_phan ADD CONSTRAINT diem_trang_thai CHECK ((trang_thai = 'CHUA_CO' AND gia_tri IS NULL) OR (trang_thai <> 'CHUA_CO' AND gia_tri IS NOT NULL));
ALTER TABLE lich_su_sua_diem ADD CONSTRAINT lich_su_gia_tri CHECK ((gia_tri_cu IS NULL OR gia_tri_cu BETWEEN 0 AND 10) AND (gia_tri_moi IS NULL OR gia_tri_moi BETWEEN 0 AND 10) AND length(trim(ly_do)) > 0);
ALTER TABLE ket_qua_tong_ket ADD CONSTRAINT tong_ket_hop_le CHECK (diem_tong_ket BETWEEN 0 AND 10 AND jsonb_typeof(bo_he_so) = 'object');
ALTER TABLE tu_dien_diem_chu ADD CONSTRAINT tu_dien_gia_tri CHECK (gia_tri BETWEEN 0 AND 10);
ALTER TABLE phieu_nhan_dien ADD CONSTRAINT phieu_metadata CHECK (ma_bam_tep ~ '^[0-9a-f]{64}$' AND so_dong_khai_bao > 0 AND (so_dong_nhan_dien IS NULL OR so_dong_nhan_dien >= 0) AND version >= 0);
ALTER TABLE phieu_nhan_dien ADD CONSTRAINT phieu_luoi CHECK (trang_thai NOT IN ('CHO_DOI_CHIEU', 'DA_DUYET') OR (so_dong_nhan_dien IS NOT NULL AND so_dong_nhan_dien = so_dong_khai_bao));
ALTER TABLE ket_qua_dong ADD CONSTRAINT dong_gia_tri CHECK ((gia_tri_kenh_a IS NULL OR gia_tri_kenh_a BETWEEN 0 AND 10) AND (gia_tri_kenh_b IS NULL OR gia_tri_kenh_b BETWEEN 0 AND 10) AND (gia_tri_chot IS NULL OR gia_tri_chot BETWEEN 0 AND 10) AND (do_tin_cay_a IS NULL OR do_tin_cay_a BETWEEN 0 AND 1) AND (do_tin_cay_b IS NULL OR do_tin_cay_b BETWEEN 0 AND 1) AND thu_tu_dong > 0);
ALTER TABLE ket_qua_dong ADD CONSTRAINT dong_duyet_day_du CHECK (
 (ma_diem IS NULL AND gia_tri_chot IS NULL AND nguoi_duyet IS NULL AND thoi_diem_duyet IS NULL)
 OR (ma_diem IS NOT NULL AND gia_tri_chot IS NOT NULL AND nguoi_duyet IS NOT NULL AND thoi_diem_duyet IS NOT NULL)
);

-- This validator accepts unrestricted numeric, BEFORE assignment to numeric(3,1).
CREATE FUNCTION public.kiem_tra_gia_tri_diem(value numeric) RETURNS numeric
LANGUAGE plpgsql IMMUTABLE SET search_path = pg_catalog AS $$
BEGIN
 IF value IS NOT NULL AND (value::text IN ('NaN','Infinity','-Infinity') OR value < 0 OR value > 10 OR value * 10 <> trunc(value * 10)) THEN
  RAISE EXCEPTION 'INVALID_GRADE' USING ERRCODE = '23514';
 END IF;
 RETURN value;
END;
$$;

-- In phase 0 there is no authorized grade-writing use case. Runtime receives
-- no grade DML privileges, preventing bypass of the pre-coercion validator.
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;
GRANT SELECT ON nguoi_dung,giao_vien,nam_hoc,hoc_ky,lop,hoc_sinh,mon_hoc,thanh_phan_diem,phan_cong_giang_day,bang_diem,diem_thanh_phan,lich_su_sua_diem,ket_qua_tong_ket,phieu_nhan_dien,ket_qua_dong,tu_dien_diem_chu TO app_runtime;
GRANT INSERT ON lich_su_sua_diem TO app_runtime;
GRANT USAGE, SELECT ON SEQUENCE lich_su_sua_diem_ma_lich_su_seq TO app_runtime;
GRANT EXECUTE ON FUNCTION public.kiem_tra_gia_tri_diem(numeric) TO app_runtime;
REVOKE UPDATE, DELETE, TRUNCATE ON lich_su_sua_diem FROM app_runtime;

CREATE FUNCTION public.chan_sua_lich_su() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog AS $$
BEGIN RAISE EXCEPTION 'AUDIT_APPEND_ONLY' USING ERRCODE='42501'; END;
$$;
CREATE TRIGGER lich_su_append_only BEFORE UPDATE OR DELETE OR TRUNCATE ON lich_su_sua_diem
FOR EACH STATEMENT EXECUTE FUNCTION public.chan_sua_lich_su();
