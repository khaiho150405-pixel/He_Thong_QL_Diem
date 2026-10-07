-- ADR-0015: chốt danh sách lớp (STT -> học sinh) cho từng phiếu nhận dạng.
--
-- ROLLBACK (không tự động):
--   Chỉ an toàn khi chưa có phiếu nào dùng snapshot (bảng danh_sach_phieu rỗng). Khi đã có phiếu dùng
--   snapshot, dữ liệu này là bằng chứng ánh xạ dòng -> học sinh và không được xóa: sửa tiến bằng migration mới.
--   Nếu bảng còn rỗng:
--     1. Gỡ trigger/hàm: DROP TRIGGER danh_sach_phieu_append_only ON public.danh_sach_phieu;
--        DROP FUNCTION public.chan_sua_danh_sach_phieu();
--     2. DROP TABLE public.danh_sach_phieu;
--     3. ALTER TABLE ket_qua_dong DROP COLUMN stt_giay, DROP COLUMN ho_ten_doc_duoc,
--        DROP COLUMN do_tin_cay_ghep, DROP COLUMN duong_dan_anh_o_ten, DROP COLUMN ghi_chu_ghep;
--        (nếu đã có cột chứa dữ liệu thì không xóa; giữ cột và ghi lý do).
--     4. Khôi phục CHECK cũ: ALTER TABLE phieu_nhan_dien DROP CONSTRAINT phieu_luoi;
--        ALTER TABLE phieu_nhan_dien ADD CONSTRAINT phieu_luoi CHECK (trang_thai NOT IN
--        ('CHO_DOI_CHIEU','DA_DUYET') OR (so_dong_nhan_dien IS NOT NULL AND so_dong_nhan_dien = so_dong_khai_bao));
--        (chỉ đạt khi mọi phiếu CHO_DOI_CHIEU/DA_DUYET có so_dong_nhan_dien = so_dong_khai_bao).
BEGIN;

-- Bảng kỹ thuật, ngoài 16 bảng nghiệp vụ.
CREATE TABLE public.danh_sach_phieu (
 ma_phieu bigint NOT NULL,
 stt integer NOT NULL,
 ma_hoc_sinh integer NOT NULL,
 ho_ten varchar(100) NOT NULL,
 CONSTRAINT danh_sach_phieu_pkey PRIMARY KEY (ma_phieu, stt),
 CONSTRAINT danh_sach_phieu_stt_duong CHECK (stt > 0),
 CONSTRAINT danh_sach_phieu_ma_phieu_fkey FOREIGN KEY (ma_phieu) REFERENCES public.phieu_nhan_dien(ma_phieu) ON DELETE RESTRICT ON UPDATE RESTRICT,
 CONSTRAINT danh_sach_phieu_ma_hoc_sinh_fkey FOREIGN KEY (ma_hoc_sinh) REFERENCES public.hoc_sinh(ma_hoc_sinh) ON DELETE RESTRICT ON UPDATE RESTRICT
);
CREATE UNIQUE INDEX danh_sach_phieu_ma_phieu_ma_hoc_sinh_key ON public.danh_sach_phieu(ma_phieu, ma_hoc_sinh);
CREATE INDEX danh_sach_phieu_ma_hoc_sinh_idx ON public.danh_sach_phieu(ma_hoc_sinh);

-- Append-only theo mẫu chan_sua_lich_su: chặn UPDATE/DELETE/TRUNCATE kể cả với chủ sở hữu.
CREATE FUNCTION public.chan_sua_danh_sach_phieu() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog AS $$
BEGIN RAISE EXCEPTION 'ROSTER_APPEND_ONLY' USING ERRCODE='42501'; END;
$$;
CREATE TRIGGER danh_sach_phieu_append_only BEFORE UPDATE OR DELETE OR TRUNCATE ON public.danh_sach_phieu
FOR EACH STATEMENT EXECUTE FUNCTION public.chan_sua_danh_sach_phieu();

-- Runtime chỉ đọc; chỉ hàm SECURITY DEFINER tao_phieu_nhan_dien (migration kế tiếp) được ghi.
REVOKE ALL ON public.danh_sach_phieu FROM PUBLIC;
GRANT SELECT ON public.danh_sach_phieu TO app_runtime;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.danh_sach_phieu FROM app_runtime;

-- Thông tin ghép dòng với học sinh (nullable: phiếu cũ không có).
ALTER TABLE public.ket_qua_dong
 ADD COLUMN stt_giay integer,
 ADD COLUMN ho_ten_doc_duoc varchar(150),
 ADD COLUMN do_tin_cay_ghep numeric(5,4),
 ADD COLUMN duong_dan_anh_o_ten varchar(512),
 ADD COLUMN ghi_chu_ghep varchar(200),
 ADD CONSTRAINT dong_do_tin_cay_ghep CHECK (do_tin_cay_ghep IS NULL OR do_tin_cay_ghep BETWEEN 0 AND 1);

-- so_dong_khai_bao từ nay là sĩ số snapshot; số dòng nhận dạng có thể ít hơn (dòng gạch, trang chỉ chứa một đoạn lớp).
ALTER TABLE public.phieu_nhan_dien DROP CONSTRAINT phieu_luoi;
ALTER TABLE public.phieu_nhan_dien ADD CONSTRAINT phieu_luoi CHECK (
 trang_thai NOT IN ('CHO_DOI_CHIEU','DA_DUYET')
 OR (so_dong_nhan_dien IS NOT NULL AND so_dong_nhan_dien BETWEEN 1 AND so_dong_khai_bao)
);

COMMIT;
