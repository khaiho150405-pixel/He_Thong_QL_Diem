-- Migration 202609200001_timetable: Add timetable / schedule table for all roles
CREATE TABLE public.thoi_khoa_bieu (
  ma_tiet_hoc SERIAL PRIMARY KEY,
  ma_lop INTEGER NOT NULL REFERENCES public.lop(ma_lop) ON DELETE RESTRICT,
  ma_mon INTEGER NOT NULL REFERENCES public.mon_hoc(ma_mon) ON DELETE RESTRICT,
  ma_giao_vien INTEGER NOT NULL REFERENCES public.giao_vien(ma_giao_vien) ON DELETE RESTRICT,
  ma_hoc_ky INTEGER NOT NULL REFERENCES public.hoc_ky(ma_hoc_ky) ON DELETE RESTRICT,
  thu SMALLINT NOT NULL CHECK (thu BETWEEN 2 AND 7), -- Thứ 2 đến Thứ 7
  tiet SMALLINT NOT NULL CHECK (tiet BETWEEN 1 AND 10), -- Tiết 1 đến Tiết 10
  phong_hoc VARCHAR(30),
  ghi_chu VARCHAR(200),
  CONSTRAINT uq_lop_tiet_hoc UNIQUE(ma_lop, ma_hoc_ky, thu, tiet),
  CONSTRAINT uq_gv_tiet_hoc UNIQUE(ma_giao_vien, ma_hoc_ky, thu, tiet)
);

CREATE INDEX idx_thoi_khoa_bieu_lop ON public.thoi_khoa_bieu(ma_lop, ma_hoc_ky);
CREATE INDEX idx_thoi_khoa_bieu_gv ON public.thoi_khoa_bieu(ma_giao_vien, ma_hoc_ky);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.thoi_khoa_bieu TO app_runtime;
GRANT USAGE, SELECT ON SEQUENCE public.thoi_khoa_bieu_ma_tiet_hoc_seq TO app_runtime;
