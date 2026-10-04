# ADR-0012 — Hệ số thành phần riêng theo học kỳ

> Phạm vi cấu hình đã được thay thế ngày 2026-10-04 bởi [ADR-0013](0013-school-workflow.md). Giữ tài liệu và migration cũ để truy vết lịch sử.

## Quyết định được chủ dự án xác nhận

Cấu hình hệ số thường xuyên, giữa kỳ và cuối kỳ riêng cho mỗi học kỳ; không phải hệ số cộng điểm cả năm giữa HK1 và HK2. Thành phần điểm hiện hữu vẫn thuộc môn học. Bảng cấu hình bổ sung `he_so_hoc_ky` có một bản ghi duy nhất theo `(ma_thanh_phan, ma_hoc_ky)`. Không tạo lại thành phần hay ô điểm cũ.

Hệ số áp dụng do hàm SQL `he_so_ap_dung` trả về: dùng cấu hình của học kỳ nếu có, ngược lại dùng hệ số mặc định của thành phần. Giá trị từ 0.01 đến 9.99, hai chữ số thập phân. Bảng điểm, kết quả cá nhân, xuất Excel và tính tổng kết dùng cùng hàm này. Tính trung bình vẫn chỉ dùng điểm `DA_DUYET`, giữ nguyên quy tắc NULL, thiếu điểm và làm tròn hiện hành.

QTV thêm/sửa/xóa qua danh mục **Hệ số học kỳ** và API `/api/v1/catalog/semester-weights`. Giáo viên chỉ đọc; học sinh không đọc danh mục, chỉ nhận hệ số áp dụng trong điểm của mình. Thay đổi có audit danh mục. Hệ số mặc định vẫn bị khóa theo quy tắc thành phần hiện hữu.

Khi bất kỳ bảng điểm của môn–học kỳ đã `DA_CHOT`, không thêm, sửa hoặc xóa cấu hình hệ số liên quan. Trigger kiểm cả phạm vi cũ/mới khi chuyển cấu hình, khóa các bảng điểm theo thứ tự ID; transaction SERIALIZABLE retry xung đột theo cơ chế sẵn có. Kỳ khác vẫn sửa được. Kết quả tổng kết tiếp tục lưu bộ hệ số và hash phiên bản cùng policy trong snapshot; không tự tính lại dữ liệu đã chốt.

## Migration và kiểm chứng

Migration `202610030001_semester_weights` chỉ thêm bảng/hàm/trigger và thay hàm tính tổng kết; không ghi đè điểm hay seed DB đang dùng. Đây là bảng cấu hình ngoài 16 bảng nghiệp vụ baseline. Rollback môi trường dùng chung bằng migration tiến tiếp; không xóa cấu hình đã dùng hoặc snapshot cũ.

Acceptance UC07, UC14–UC18: hai kỳ độc lập; fallback khi chưa cấu hình; tính đúng điểm và snapshot; hiển thị hệ số thống nhất; từ chối giáo viên ghi/học sinh đọc; từ chối thay đổi sau chốt kể cả DML trực tiếp. Kiểm chứng bằng `semester-weights.test.ts` trên PostgreSQL thật, suite final-results hiện hữu, và `semester_weights_test.dart` qua generated client trên profile Android/iOS/desktop.
