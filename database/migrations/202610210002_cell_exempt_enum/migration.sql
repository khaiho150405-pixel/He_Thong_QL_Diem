-- Trạng thái ô "Miễn" (MIEN): ô được miễn không có điểm, khác "chưa có điểm". Giá trị enum mới không dùng được trong cùng
-- giao dịch với ADD VALUE nên migration này đứng riêng; ràng buộc, bảng và hàm dùng giá trị nằm ở 202610210003_cell_exempt.
--
-- ROLLBACK (không tự động): PostgreSQL không hỗ trợ xóa giá trị khỏi enum. Nếu chưa có ô MIEN thì để nguyên giá trị là vô hại.
ALTER TYPE public."TrangThaiDiem" ADD VALUE IF NOT EXISTS 'MIEN';
