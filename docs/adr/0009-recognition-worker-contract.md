# ADR-0009: Contract worker và dịch vụ nhận dạng

## Trạng thái

Accepted cho Phase 3 development; ngưỡng confidence và model production chưa được chốt.

## Quyết định

BullMQ worker thuộc deployable backend đọc ảnh từ object storage và gửi multipart nội bộ tới FastAPI. Response giữ riêng raw output, giá trị chuẩn hóa, confidence và ảnh cắt của hai kênh cho từng dòng. Worker kiểm schema, thứ tự và số dòng trước khi ghi.

Ảnh ô cắt được worker lưu lại private; PostgreSQL chỉ giữ object key. Một hàm `SECURITY DEFINER` chạy trong transaction `SERIALIZABLE` ghi tất cả `ket_qua_dong`, audit và trạng thái phiếu. Hàm không nhận hoặc cập nhật giá trị điểm chính thức. Replay trên phiếu đã chờ đối chiếu trả thành công mà không ghi trùng.

Fake adapter chỉ chạy khi cấu hình rõ `fake` ở development/test. Ở production, không có weights hoặc cấu hình fake đều trả `MODEL_UNAVAILABLE`. Lệch lưới không tạo kết quả dòng và đánh dấu phiếu lỗi.

## Đánh đổi

Base64 cho ảnh ô làm payload nội bộ lớn hơn nhưng giữ contract đơn giản trong giai đoạn chưa có model thật. Giới hạn 2 MiB mỗi crop và timeout ngăn payload không giới hạn. Khi model thật ổn định có thể thay bằng gói binary hoặc streaming qua phiên bản contract mới.

Migration là forward-only: nếu dừng worker, thu hồi quyền execute trong migration mới và giữ nguyên bằng chứng/audit đã tạo.
