# Giai đoạn 6 — Hardening và phát hành

Phase 6 không thay đổi nghiệp vụ UC01–UC18. Mục tiêu là chứng minh hệ thống có thể vận hành, phục hồi và phát hành mà vẫn giữ các bất biến bảo mật/dữ liệu trong AGENTS.md.

## Phần 1 — Baseline bảo mật production

- API trả `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy` và `Cache-Control: no-store` trên mọi response.
- Staging/production thêm CSP cho API và HSTS; TLS phải được terminate trước API.
- Cấu hình ngoài development chỉ chấp nhận PostgreSQL có `sslmode=require|verify-ca|verify-full`, Redis `rediss://`, S3 HTTPS và recognition service HTTPS.
- Development local vẫn dùng loopback HTTP theo Compose; không dùng cấu hình development làm mẫu production.
- Upload ảnh nhận dạng có hạn mức dùng chung giữa các API instance, mặc định `10` lượt/phút/tài khoản và cấu hình bằng `UPLOAD_RATE_LIMIT_PER_MINUTE`. Chỉ request đã qua kiểm tra session, vai trò, phân công, trạng thái bảng điểm và thành phần mới tiêu thụ hạn mức.
- Bộ đếm nằm trong PostgreSQL và được cập nhật nguyên tử qua hàm `SECURITY DEFINER`; role runtime không có DML trực tiếp trên bảng kỹ thuật `gioi_han_tac_vu`. API trả error envelope `429 RATE_LIMITED` trước khi ghi object khi vượt ngưỡng.

## Phần 2 — Khôi phục và tải

- Công cụ PostgreSQL tạo custom dump nguyên tử, manifest SHA-256 không chứa credential, xác minh catalog trước restore và giữ ACL/quyền runtime.
- Restore rehearsal bị khóa cứng vào database có hậu tố `_restore_test`; CI tạo database cô lập rồi chạy lại constraint và quyền runtime trên dữ liệu khôi phục.
- Object storage backup ghi từng object vào tên file SHA-256 an toàn cùng manifest chứa key, kích thước, content type và checksum; không chứa endpoint hoặc credential.
- Object restore bị khóa vào bucket có hậu tố `-restore-test`, yêu cầu bucket tồn tại và rỗng, rồi kiểm inventory, checksum từng object và signed URL. CI chạy diễn tập này với MinIO thật.
- Diễn tập runbook PostgreSQL + object storage theo cùng mốc vận hành. Backup production phải mã hóa, có checksum, retention và quyền đọc riêng.
- Restore chỉ được thử trên database/bucket cô lập; xác nhận migration version, row counts, audit append-only, object checksum và signed URL trước khi ghi nhận đạt.
- Chốt RPO/RTO, tải dự kiến và SLA với nhà trường trước khi đặt ngưỡng load test. Không tuyên bố khả năng chịu tải chỉ từ health endpoint.
- Load harness chỉ chạy GET trên endpoint nghiệp vụ `/api/v1` có Bearer token, có giới hạn duration/concurrency/timeout và không in token. Nó từ chối health endpoint và từ chối host từ xa nếu chưa bật chủ động `LOAD_ALLOW_REMOTE=1`.
- CI chạy smoke profile ngắn trên danh sách bảng điểm bằng giáo viên seed để phát hiện lỗi kết nối/auth hoặc response chậm bất thường. Kết quả này xác nhận harness, không thay thế load test staging theo tải đã chốt.

## Phần 3 — Phát hành

- Build Flutter Web production với HTTPS API thật và kiểm fallback `index.html` cho client-side routing.
- Lệnh `pnpm release:web:build` chỉ nhận HTTPS origin thật qua `WEB_API_BASE_URL`; artifact không dùng file `production.json` placeholder. Cấu hình Nginx mẫu đặt cache ngắn, security headers, chặn dotfile và fallback mọi client-side route về `index.html`.
- CI khởi động Nginx thật với artifact Web, so sánh response của đường dẫn client-side trực tiếp với `index.html`, kiểm `X-Frame-Options` và xác nhận dotfile bị từ chối.
- Android phát hành qua internal testing trước; khóa signing nằm trong secret store của CI, không commit.
- iOS cần macOS/Xcode, App Store Connect và signing hợp lệ; đưa lên TestFlight trước App Store.
- Deployment production cần môi trường/hosting, DNS, TLS, secret manager, bucket private, database backup và chính sách dữ liệu đã được chủ dự án xác nhận.

## Điều kiện hoàn tất

Theo dõi người chịu trách nhiệm, giá trị cần chốt và bằng chứng của từng môi trường trong `docs/operations/release-readiness.md`.

- Security/IDOR/upload regression, dependency readiness và full CI đều xanh.
- Có bằng chứng backup/restore trên môi trường cô lập và kết quả load test theo tải đã chốt.
- Có runbook sự cố, rollback bằng forward migration và người chịu trách nhiệm vận hành.
- Bốn quyết định đang dùng mặc định development ở ADR-0010 đã được chốt: làm tròn/xếp loại, thiếu điểm, mẫu Excel và lịch sử chuyển lớp.
- Web staging, Android internal testing và iOS TestFlight đã được smoke test bằng tài khoản giả.
