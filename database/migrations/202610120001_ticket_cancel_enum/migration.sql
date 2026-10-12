-- Hủy mềm phiếu nhận dạng (ADR-0015): thêm trạng thái DA_HUY. Giá trị enum mới không dùng được trong cùng giao dịch
-- với lệnh ADD VALUE nên migration này đứng riêng; cột, chỉ mục và hàm dùng giá trị này nằm ở 202610120002_ticket_cancel.
--
-- ROLLBACK (không tự động): PostgreSQL không hỗ trợ xóa giá trị khỏi enum. Nếu chưa có phiếu DA_HUY thì để nguyên giá trị
-- là vô hại; muốn gỡ hẳn phải tạo enum mới, chuyển cột phieu_nhan_dien.trang_thai sang enum đó rồi bỏ enum cũ.
ALTER TYPE public."TrangThaiPhieu" ADD VALUE IF NOT EXISTS 'DA_HUY';
