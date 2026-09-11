# Giai đoạn 3 — Pipeline nhận dạng UC11–12

## Phạm vi phần 1

Phần đầu ổn định contract miền trước khi có file trọng số. Hai kênh Điểm số và Điểm chữ giữ riêng raw output, giá trị chuẩn hóa và confidence. Hàm phân loại không trả điểm chốt và không ghi `diem_thanh_phan`.

Acceptance criteria:

- Điểm hợp lệ 0.0–10.0 với tối đa một chữ số thập phân; `0.0` khác ô trống.
- Hai kênh khớp và cùng đạt ngưỡng cấu hình được phân Xanh; khớp nhưng confidence thấp, lệch hoặc chỉ một kênh đọc được là Vàng.
- Cả hai kênh trống/không đọc được là Đỏ và không có giá trị gợi ý tùy tiện.
- Ngưỡng confidence được truyền vào policy. Giá trị `0.85` trong test chỉ là fixture development, chưa phải quyết định production.
- Unit test miền chạy không cần model, Redis, MinIO hoặc PostgreSQL.

## Phần tiếp theo

Thực hiện theo chiều dọc: upload đã kiểm MIME/checksum → object private → phiếu và outbox cùng transaction → BullMQ worker idempotent → FastAPI contract → lưu từng dòng. Fake adapter chỉ bật rõ ràng ở development/test. Production khi thiếu weights phải trả model unavailable và chuyển phiếu sang `LOI`; worker không bao giờ ghi điểm chính thức.
