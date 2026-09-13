# Giai đoạn 6 — Hardening và phát hành

Phase 6 không thay đổi nghiệp vụ UC01–UC18. Mục tiêu là chứng minh hệ thống có thể vận hành, phục hồi và phát hành mà vẫn giữ các bất biến bảo mật/dữ liệu trong AGENTS.md.

## Phần 1 — Baseline bảo mật production

- API trả `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy` và `Cache-Control: no-store` trên mọi response.
- Staging/production thêm CSP cho API và HSTS; TLS phải được terminate trước API.
- Cấu hình ngoài development chỉ chấp nhận PostgreSQL có `sslmode=require|verify-ca|verify-full`, Redis `rediss://`, S3 HTTPS và recognition service HTTPS.
- Development local vẫn dùng loopback HTTP theo Compose; không dùng cấu hình development làm mẫu production.

## Phần 2 — Khôi phục và tải

- Công cụ PostgreSQL tạo custom dump nguyên tử, manifest SHA-256 không chứa credential, xác minh catalog trước restore và giữ ACL/quyền runtime.
- Restore rehearsal bị khóa cứng vào database có hậu tố `_restore_test`; CI tạo database cô lập rồi chạy lại constraint và quyền runtime trên dữ liệu khôi phục.
- Diễn tập runbook PostgreSQL + object storage theo cặp nhất quán. Backup production phải mã hóa, có checksum, retention và quyền đọc riêng.
- Restore chỉ được thử trên database/bucket cô lập; xác nhận migration version, row counts, audit append-only, object checksum và signed URL trước khi ghi nhận đạt.
- Chốt RPO/RTO, tải dự kiến và SLA với nhà trường trước khi đặt ngưỡng load test. Không tuyên bố khả năng chịu tải chỉ từ health endpoint.

## Phần 3 — Phát hành

- Build Flutter Web production với HTTPS API thật và kiểm fallback `index.html` cho client-side routing.
- Android phát hành qua internal testing trước; khóa signing nằm trong secret store của CI, không commit.
- iOS cần macOS/Xcode, App Store Connect và signing hợp lệ; đưa lên TestFlight trước App Store.
- Deployment production cần môi trường/hosting, DNS, TLS, secret manager, bucket private, database backup và chính sách dữ liệu đã được chủ dự án xác nhận.

## Điều kiện hoàn tất

- Security/IDOR/upload regression, dependency readiness và full CI đều xanh.
- Có bằng chứng backup/restore trên môi trường cô lập và kết quả load test theo tải đã chốt.
- Có runbook sự cố, rollback bằng forward migration và người chịu trách nhiệm vận hành.
- Bốn quyết định đang dùng mặc định development ở ADR-0010 đã được chốt: làm tròn/xếp loại, thiếu điểm, mẫu Excel và lịch sử chuyển lớp.
- Web staging, Android internal testing và iOS TestFlight đã được smoke test bằng tài khoản giả.
