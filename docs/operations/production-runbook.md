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

## Flutter Web

- Đặt `WEB_API_BASE_URL` bằng HTTPS origin thật của API rồi chạy `pnpm release:web:build`. Script từ chối HTTP, loopback, domain `.invalid`, credential, query và path để tránh phát hành artifact trỏ nhầm môi trường hoặc nhúng secret.
- Artifact nằm ở `apps/client_flutter/build/web`. Cấu hình mẫu `infrastructure/web/nginx.conf` phục vụ thư mục này tại `/usr/share/nginx/html`, chặn dotfile, thêm security headers và dùng `try_files ... /index.html` cho client-side routing.
- `index.html`, bootstrap và service worker không cache dài; asset tĩnh cache một giờ để bản phát hành mới không bị giữ quá lâu. CDN/hosting phải giữ cùng nguyên tắc khi chuyển cấu hình khỏi Nginx.
- Trước khi chuyển traffic, truy cập trực tiếp một URL client-side không tồn tại trên filesystem và xác nhận trả nội dung `index.html`; sau đó đăng nhập bằng tài khoản giả và kiểm API request đi đúng production/staging origin.

## Backup và restore

- PostgreSQL backup ở định dạng custom bằng `pg_dump`, bỏ ownership nhưng giữ ACL để phục hồi đúng quyền runtime; object storage được snapshot/version theo cùng mốc. Mã hóa cả hai và giữ checksum ngoài nơi chứa backup.
- Đặt `BACKUP_DATABASE_URL` bằng role chỉ đọc rồi chạy `pnpm ops:backup -- <thư-mục-đã-mã-hóa>`. Kiểm lại bằng `pnpm ops:verify-backup -- <file.dump>`; manifest không chứa URL hoặc mật khẩu.
- `pg_dump`/`pg_restore` phải cùng major với PostgreSQL server. CI đặt `PG_CLIENT_IMAGE=postgres:18.0-bookworm` để dùng client cô lập đúng phiên bản; production phải ghim image/client theo phiên bản server thực tế.
- Tạo sẵn database cô lập có hậu tố `_restore_test`, đặt `RESTORE_DATABASE_URL`, rồi chạy `pnpm ops:restore-rehearsal -- <file.dump>`. Script từ chối mọi tên database không đúng hậu tố và không tự tạo/drop database.
- Đặt cấu hình S3 nguồn rồi chạy `pnpm ops:storage-backup -- <thư-mục-đã-mã-hóa>` và `pnpm ops:storage-verify -- <manifest.json>`. Công cụ lưu object bằng tên file băm để object key không thể thoát khỏi thư mục backup.
- Tạo sẵn bucket rỗng có hậu tố `-restore-test`, đặt `RESTORE_S3_BUCKET`, rồi chạy `pnpm ops:storage-restore-rehearsal -- <manifest.json>`. S3 không cho dấu gạch dưới trong tên bucket; script từ chối bucket đích trùng nguồn, không đúng hậu tố hoặc đã chứa dữ liệu.
- Restore rehearsal không dùng database hoặc bucket production làm mục tiêu thử.
- Sau restore, chạy migration ở chế độ deploy rồi kiểm các constraint, quyền runtime, audit/history append-only, số bản ghi trọng yếu và checksum object.
- Không coi backup thành công cho đến khi một restore rehearsal hoàn tất trong RTO đã chốt.

## Kiểm thử tải

- Dùng tài khoản giả có đúng phân công trên staging và lấy access token qua luồng đăng nhập; truyền token bằng `LOAD_AUTHORIZATION`, không ghi token vào script, file kết quả hoặc log.
- Đặt `LOAD_BASE_URL`, `LOAD_PATH`, `LOAD_DURATION_SECONDS`, `LOAD_CONCURRENCY`, `LOAD_REQUEST_TIMEOUT_MS`, `LOAD_MAX_P95_MS` và `LOAD_MAX_ERROR_RATE`, rồi chạy `pnpm test:load-smoke`. Host từ xa cần HTTPS và `LOAD_ALLOW_REMOTE=1`.
- Chạy ít nhất một endpoint đọc nghiệp vụ đại diện như danh sách hoặc lưới bảng điểm. Công cụ chủ động từ chối health endpoint vì health check không chứng minh tải nghiệp vụ.
- Lưu JSON kết quả cùng commit, cấu hình staging và thời điểm chạy nhưng loại bỏ token/PII. Chỉ ghi nhận đạt khi p95 và error rate thỏa SLA đã được nhà trường chốt.

## Sự cố và rollback

- Nếu readiness lỗi, ngừng nhận traffic mới và giữ liveness để chẩn đoán; tra dependency theo `requestId`.
- Migration đã chạy ở môi trường chung không được sửa hoặc rollback bằng xóa dữ liệu. Tạo forward migration; chỉ restore khi runbook sự cố và chủ dữ liệu cho phép.
- Nếu recognition lỗi, dừng worker/retry hữu hạn; giữ phiếu ở trạng thái lỗi/chờ, không ghi kết quả máy vào điểm chính thức.
- Nếu nghi lộ secret, thu hồi/rotate secret và session trước, sau đó audit phạm vi ảnh hưởng. Không dán secret vào issue, PR hoặc log.
