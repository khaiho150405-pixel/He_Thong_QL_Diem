# Giai đoạn 4 — Đối chiếu và duyệt UC13

## Phần 1 — Duyệt nguyên tử và giao diện đối chiếu

Giáo viên đúng phân công mở phiếu `CHO_DOI_CHIEU`, xem ảnh gốc cùng ảnh ô của hai kênh, nhập giá trị cuối và lý do cho từng dòng, rồi xác nhận đã kiểm tra toàn bộ. Giao diện ưu tiên Đỏ, Vàng trước Xanh, hỗ trợ bàn phím và không tự điền giá trị cho dòng lệch hoặc không đọc được. Điểm `0.0` được giữ riêng với ô trống `NULL`.

Endpoint `POST /api/v1/gradebooks/{gradebookId}/recognition-tickets/{ticketId}/approve` yêu cầu `x-idempotency-key`, version bảng điểm, version phiếu và đúng một quyết định cho mỗi dòng. Giá trị chỉ nhận `NULL` hoặc chuỗi chuẩn `0.0`–`10.0` với một chữ số thập phân; mỗi quyết định cần lý do.

Hàm PostgreSQL `duyet_phieu_nhan_dien` chạy `SERIALIZABLE`, khóa bảng điểm và phiếu, kiểm lại phiên giáo viên cùng phân công, rồi thực hiện trong một giao dịch:

1. Ánh xạ từng kết quả dòng vào đúng ô điểm theo bảng–học sinh–thành phần.
2. Ghi điểm chính thức và nguồn `NHAN_DIEN`; `NULL` giữ trạng thái `CHUA_CO`, điểm số chuyển `DA_DUYET`.
3. Thêm lịch sử append-only khi giá trị thay đổi.
4. Gắn ô điểm, giá trị cuối, người và thời điểm duyệt vào kết quả dòng.
5. Chuyển phiếu sang `DA_DUYET`, tăng version phiếu/bảng, ghi audit và idempotency result.

Nếu bất kỳ bước nào lỗi, toàn bộ thay đổi rollback. Replay cùng key và payload trả kết quả cũ; cùng key khác payload, version cũ, bảng đã chốt, phiếu sai trạng thái hoặc giáo viên ngoài phân công đều bị từ chối. Response tóm tắt tổng dòng, số dòng Xanh khớp máy, số dòng cần quyết định/sửa của người và số dòng Đỏ.

Migration có rollback tiến tiếp: thu hồi quyền `EXECUTE` bằng migration mới và giữ nguyên điểm, lịch sử, bằng chứng duyệt, audit cùng idempotency đã commit. Không sửa migration đã chạy ở môi trường dùng chung.

## Kiểm chứng

- Cài mới đủ tám migration và nâng cấp từ database Phase 3 đều thành công.
- PostgreSQL runtime chỉ gọi hàm duyệt; không được cấp DML trực tiếp vào điểm hoặc lịch sử.
- Integration test gây lỗi có chủ đích tại bước audit và xác nhận điểm, lịch sử, dòng cùng trạng thái phiếu đều rollback.
- Integration test xác nhận quyền âm tính, `NULL`/`0.0`, sửa kết quả máy, replay idempotent và payload trùng key bị 409.
- Widget test xác nhận giáo viên phải đánh dấu đã xem tất cả dòng trước khi gửi quyết định qua generated client.

## Phần 2 — Hardening UC13

- Luồng integration chạy xuyên suốt upload HTTP → outbox → worker → bằng chứng → duyệt, đồng thời CI kiểm Redis/BullMQ và MinIO thật. Signed URL được tải thật từ bucket private trong test hạ tầng.
- Khi ảnh gốc hoặc ảnh ô hết hạn/không tải được, dialog cho phép xin bộ signed URL mới từ API. Điểm và lý do giáo viên đang nhập được giữ nguyên qua lần tải lại.
- Hai yêu cầu duyệt đồng thời với cùng version chỉ có một giao dịch thành công; giao dịch còn lại nhận `409` và không tạo lịch sử/audit trùng.
- Khi duyệt cạnh tranh với chốt bảng, phiếu đang chờ ngăn thao tác chốt. Duyệt hoàn tất nguyên tử, còn thao tác chốt dùng version cũ nhận `409`; bảng không rơi vào trạng thái vừa chốt vừa còn phiếu chưa duyệt.

Phase 4 hoàn tất khi full CI của commit hardening xanh `foundation`, `ios` và `required-checks`. Sau đó có thể mở review/merge Phase 4 trước khi tạo nhánh Phase 5 tổng kết và ứng dụng học sinh.
