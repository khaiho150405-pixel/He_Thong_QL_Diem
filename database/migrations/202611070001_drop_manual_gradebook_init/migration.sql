-- Bỏ chức năng tạo bảng điểm thủ công: nút "Khởi tạo bảng điểm còn thiếu" của quản trị viên không còn.
-- Bảng điểm do hệ thống tự tạo khi phân công giáo viên (trigger dam_bao_bang_diem) và được bổ sung khi
-- giáo viên mở danh sách bảng điểm (dam_bao_bang_diem_cua_toi), nên hàm khởi tạo hàng loạt không còn dùng.
-- Giữ nguyên tao_luoi_diem_trong / tao_luoi_diem_noi_bo vì luồng tự tạo vẫn dùng tới.
--
-- ROLLBACK (chỉ tiến): tạo lại khoi_tao_bang_diem_hoc_ky bằng thân trong migration 202610230001_student_enrollment
-- và cấp lại EXECUTE cho app_runtime; không có dữ liệu nào bị mất khi bỏ hàm này.
BEGIN;

DROP FUNCTION IF EXISTS public.khoi_tao_bang_diem_hoc_ky(text, integer, text, text);

COMMIT;
