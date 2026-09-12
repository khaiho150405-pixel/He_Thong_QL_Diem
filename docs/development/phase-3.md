# Giai đoạn 3 — Pipeline nhận dạng UC11–12

## Phạm vi phần 1

Phần đầu ổn định contract miền trước khi có file trọng số. Hai kênh Điểm số và Điểm chữ giữ riêng raw output, giá trị chuẩn hóa và confidence. Hàm phân loại không trả điểm chốt và không ghi `diem_thanh_phan`.

Acceptance criteria:

- Điểm hợp lệ 0.0–10.0 với tối đa một chữ số thập phân; `0.0` khác ô trống.
- Hai kênh khớp và cùng đạt ngưỡng cấu hình được phân Xanh; khớp nhưng confidence thấp, lệch hoặc chỉ một kênh đọc được là Vàng.
- Cả hai kênh trống/không đọc được là Đỏ và không có giá trị gợi ý tùy tiện.
- Ngưỡng confidence được truyền vào policy. Giá trị `0.85` trong test chỉ là fixture development, chưa phải quyết định production.
- Unit test miền chạy không cần model, Redis, MinIO hoặc PostgreSQL.

## Phần 2 — Upload, storage và queue bền vững

Đã triển khai endpoint `POST /api/v1/gradebooks/{gradebookId}/recognition-tickets` trả `202`, nhận multipart gồm ảnh, thành phần điểm và số dòng khai báo. Ảnh được kiểm theo nội dung thật, giới hạn kích thước/độ phân giải, băm SHA-256 rồi lưu bằng UUID trong object storage private. Chỉ giáo viên đúng phân công được upload cho bảng đang nhập liệu; thành phần và sĩ số được kiểm lại trong PostgreSQL.

Migration `202609110001_recognition_upload_outbox` tạo bảng kỹ thuật `recognition_outbox` và hàm ghi nguyên tử phiếu + audit + idempotency + outbox. Dispatcher claim có lease/retry hữu hạn và thêm BullMQ job bằng ID ổn định. Upload lặp cùng key trả ticket cũ, checksum lặp hoặc cùng key khác payload trả conflict; runtime không có INSERT trực tiếp vào phiếu/outbox.

Đã kiểm migration nâng cấp từ Phase 2 và cài mới từ database rỗng. Unit test bao phủ MIME/chữ ký/kích thước, cleanup replay và dispatcher. Integration test HTTP multipart trên PostgreSQL thật kiểm `202`, quyền phân công, checksum/idempotency, đúng một phiếu/outbox/audit và dispatcher không phát lại event đã xác nhận. OpenAPI và Dart client đã sinh lại.

Chi tiết đánh đổi và rollback tại [ADR-0008](../adr/0008-recognition-upload-outbox.md).

## Phần 3 — Worker và contract dịch vụ nhận dạng

Worker BullMQ tải ảnh gốc private, gọi `POST /v1/recognize` của FastAPI với timeout và kiểm schema response. Chỉ khi `detectedRows`, số phần tử và thứ tự dòng khớp sĩ số khai báo, worker mới lưu ảnh ô cắt cùng raw/value/confidence riêng cho Điểm số và Điểm chữ. Hàm PostgreSQL chạy `SERIALIZABLE`, khóa phiếu, ghi toàn bộ dòng + audit rồi chuyển phiếu sang `CHO_DOI_CHIEU`. Job chạy lại không tạo dòng hoặc audit trùng.

Sai số dòng chuyển ngay sang `LOI/GRID_ROW_COUNT_MISMATCH`. Timeout/payload sai được BullMQ retry tối đa ba lần rồi chuyển `LOI`; model unavailable chuyển lỗi ngay. Adapter `fake-dev-v1` chỉ được chọn khi `RECOGNITION_MODEL_MODE=fake` và `APP_ENV` là development/test. Production thiếu weights trả HTTP 503. Kết quả worker luôn để `ma_diem`, `gia_tri_chot`, người và thời điểm duyệt là `NULL`; không sửa `diem_thanh_phan`.

Migration `202609120001_recognition_results` đã được kiểm cả nâng cấp và cài bảy migration từ database rỗng. Unit/contract test bao phủ hai kênh, 0.0, lệch lưới, malformed response, timeout và model unavailable. Integration PostgreSQL kiểm lưu nguyên tử, idempotency và không có điểm chính thức.

## Phần tiếp theo

Phase 3 phần 4 bổ sung API trạng thái/chi tiết phiếu và signed URL ảnh ô, polling từ Flutter, trạng thái loading/error/retry và màn hình upload cơ bản. Việc duyệt/chốt giá trị vẫn thuộc Phase 4 (UC13).
