CREATE TABLE phien_lam_viec (
  ma_bam CHAR(64) PRIMARY KEY,
  ma_nguoi_dung INTEGER NOT NULL REFERENCES nguoi_dung(ma_nguoi_dung) ON DELETE RESTRICT ON UPDATE RESTRICT,
  csrf CHAR(64) NOT NULL,
  het_han TIMESTAMPTZ(6) NOT NULL,
  hoat_dong_cuoi TIMESTAMPTZ(6) NOT NULL
);
CREATE INDEX phien_lam_viec_ma_nguoi_dung_idx ON phien_lam_viec(ma_nguoi_dung);
CREATE TABLE nhat_ky_bao_mat (
  ma_su_kien BIGSERIAL PRIMARY KEY,
  ma_tac_nhan INTEGER,
  hanh_dong VARCHAR(64) NOT NULL,
  doi_tuong VARCHAR(100) NOT NULL,
  thoi_diem TIMESTAMPTZ(6) NOT NULL DEFAULT now()
);
CREATE TABLE gioi_han_dang_nhap (
  ma_bam CHAR(64) PRIMARY KEY,
  so_lan INTEGER NOT NULL CHECK (so_lan >= 0),
  het_han TIMESTAMPTZ(6) NOT NULL
);
CREATE FUNCTION bao_ve_nhat_ky_bao_mat() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'Security audit is append-only'; END $$;
CREATE TRIGGER nhat_ky_bao_mat_append_only BEFORE UPDATE OR DELETE OR TRUNCATE ON nhat_ky_bao_mat
FOR EACH STATEMENT EXECUTE FUNCTION bao_ve_nhat_ky_bao_mat();
GRANT SELECT, INSERT, UPDATE, DELETE ON phien_lam_viec, gioi_han_dang_nhap TO app_runtime;
GRANT SELECT, INSERT ON nhat_ky_bao_mat TO app_runtime;
GRANT USAGE, SELECT ON SEQUENCE nhat_ky_bao_mat_ma_su_kien_seq TO app_runtime;
GRANT INSERT, UPDATE ON nguoi_dung TO app_runtime;
GRANT INSERT, UPDATE, DELETE ON nam_hoc, hoc_ky, lop, hoc_sinh, mon_hoc, thanh_phan_diem, giao_vien, phan_cong_giang_day TO app_runtime;
GRANT USAGE, SELECT ON SEQUENCE nguoi_dung_ma_nguoi_dung_seq, nam_hoc_ma_nam_hoc_seq,
  hoc_ky_ma_hoc_ky_seq, lop_ma_lop_seq, hoc_sinh_ma_hoc_sinh_seq, mon_hoc_ma_mon_seq,
  thanh_phan_diem_ma_thanh_phan_seq, phan_cong_giang_day_ma_phan_cong_seq TO app_runtime;
-- Forward-only: retain security audit and active business data. See ADR-0005.
