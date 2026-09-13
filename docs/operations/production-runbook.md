# Runbook production

## Điều kiện trước triển khai

1. Dùng secret manager để cấp `DATABASE_URL`, `REDIS_URL`, S3 credentials và endpoint recognition. Không sao chép `.env` development lên server.
2. PostgreSQL dùng role migration riêng với role runtime; runtime không có DML trực tiếp vào điểm, lịch sử, policy hoặc audit.
3. Redis dùng TLS; bucket private, bật versioning/lifecycle và signed URL ngắn hạn; API/recognition dùng HTTPS.
4. Chụp backup database và object storage nhất quán trước migration. Ghi checksum, thời điểm UTC, migration hiện tại và người thực hiện.

## Triển khai

1. Build artifact từ commit đã được `foundation`, `ios`, `required-checks` xác nhận; không build lại từ working tree cá nhân.
2. Chạy migration bằng `app_migration`, rồi khởi động API bằng `app_runtime`.
3. Kiểm `/api/v1/health/live`, sau đó `/api/v1/health/ready`; readiness phải xác nhận PostgreSQL, Redis và bucket private.
4. Smoke test bằng dữ liệu giả: đăng nhập, phân quyền âm tính, bảng điểm, upload, đối chiếu, tổng kết, Excel và học sinh xem chính mình.
5. Theo dõi log JSON theo `requestId`; không ghi token, cookie, ảnh hoặc dữ liệu điểm đầy đủ.

## Backup và restore

- PostgreSQL backup ở định dạng custom bằng `pg_dump`; object storage được snapshot/version theo cùng mốc. Mã hóa cả hai và giữ checksum ngoài nơi chứa backup.
- Restore rehearsal dùng database và bucket có hậu tố `_restore_test`; không dùng production làm mục tiêu thử.
- Sau restore, chạy migration ở chế độ deploy rồi kiểm các constraint, quyền runtime, audit/history append-only, số bản ghi trọng yếu và checksum object.
- Không coi backup thành công cho đến khi một restore rehearsal hoàn tất trong RTO đã chốt.

## Sự cố và rollback

- Nếu readiness lỗi, ngừng nhận traffic mới và giữ liveness để chẩn đoán; tra dependency theo `requestId`.
- Migration đã chạy ở môi trường chung không được sửa hoặc rollback bằng xóa dữ liệu. Tạo forward migration; chỉ restore khi runbook sự cố và chủ dữ liệu cho phép.
- Nếu recognition lỗi, dừng worker/retry hữu hạn; giữ phiếu ở trạng thái lỗi/chờ, không ghi kết quả máy vào điểm chính thức.
- Nếu nghi lộ secret, thu hồi/rotate secret và session trước, sau đó audit phạm vi ảnh hưởng. Không dán secret vào issue, PR hoặc log.
