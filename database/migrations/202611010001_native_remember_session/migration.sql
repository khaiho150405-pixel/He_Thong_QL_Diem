-- Ghi nhớ đăng nhập cho app di động (Android/iOS): thiết bị giữ một mã ghi nhớ dài hạn (30 ngày) để xin phiên mới khi mở lại app.
-- Phiên làm việc vẫn hết hạn sau 8 giờ / 30 phút không hoạt động như cũ (các hàm SQL điểm không đổi); chỉ mã ghi nhớ sống lâu hơn.
-- Mã chỉ lưu dạng băm SHA-256, dùng một lần (xoay vòng mỗi lần mở lại app) và bị xóa khi đăng xuất, đổi mật khẩu hoặc khóa/đổi vai tài khoản.
--
-- ROLLBACK: DROP TABLE public.phien_ghi_nho; (chỉ mất khả năng giữ đăng nhập, không ảnh hưởng dữ liệu điểm).
BEGIN;

CREATE TABLE public.phien_ghi_nho (
  ma_bam CHAR(64) PRIMARY KEY,
  ma_nguoi_dung INTEGER NOT NULL REFERENCES public.nguoi_dung(ma_nguoi_dung) ON DELETE RESTRICT ON UPDATE RESTRICT,
  het_han TIMESTAMPTZ(6) NOT NULL,
  tao_luc TIMESTAMPTZ(6) NOT NULL DEFAULT now()
);
CREATE INDEX phien_ghi_nho_ma_nguoi_dung_idx ON public.phien_ghi_nho(ma_nguoi_dung);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.phien_ghi_nho TO app_runtime;

COMMIT;
