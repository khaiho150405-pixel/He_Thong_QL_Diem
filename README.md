# Hệ thống Quản lý Điểm

Giai đoạn 1 đã triển khai tài khoản và danh mục UC01–08 theo [kế hoạch Phase 1](docs/development/phase-1.md). [Phase 2](docs/development/phase-2.md) đã được merge qua PR #3, gồm API và giao diện Flutter cho danh sách/lưới, nhập hàng loạt, lịch sử, đồng bộ sĩ số và chốt bảng. Bản sửa CI sau merge chạy các integration suite dùng chung PostgreSQL theo thứ tự để tránh xung đột giả giữa các giao dịch `SERIALIZABLE`. [Phase 3](docs/development/phase-3.md) đã có upload private, outbox/worker BullMQ, contract FastAPI hai kênh, chặn lệch lưới và lưu bằng chứng chờ con người đối chiếu mà chưa phụ thuộc file trọng số. Nhắn `continue` trong Codex để tiếp tục từ [note bàn giao](docs/development/CONTINUE.md) theo [AGENTS.md](AGENTS.md). [Plan Giai đoạn 0](implementation_plan1.md) được giữ để báo cáo lịch sử. Chưa nối mô hình OCR thật hoặc triển khai tổng kết.

## Cấu trúc

- apps/api: NestJS modular monolith, 14 module ownership, error/request logging và health.
- apps/client_flutter: Material 3, Riverpod, GoRouter, cấu hình web/Android/iOS.
- database: Prisma schema 16 bảng, migrations, seed giả và tests PostgreSQL thật.
- packages/api_client_dart: sinh từ OpenAPI; không sửa tay.
- infrastructure: PostgreSQL/Redis/MinIO local; docs/adr lưu quyết định và đánh đổi.

## Công cụ

Node 24.19.0, pnpm 11.19.0, Flutter 3.35.7 (Dart 3.9.2), Java 17+ (Android Studio JBR 21 dùng được), Docker Engine/Desktop với Compose v2. Node trên PATH của terminal và scripts phải cùng phiên bản. iOS cần macOS/Xcode; Windows không build/chạy iOS simulator.

Dependencies được khóa bằng pnpm-lock.yaml và pubspec.lock. Xem [toolchain](docs/development/toolchain.md), [onboarding](docs/development/onboarding.md), [quy trình đóng góp](CONTRIBUTING.md).

## Chạy lần đầu

Chạy từ repository root, không cd vào database hoặc apps/api:

```sh
pnpm install --frozen-lockfile
pnpm setup:local
pnpm infra:up
pnpm db:generate
pnpm db:migrate
pnpm db:seed
python -m pip install -e apps/recognition-service
pnpm dev:api
```

Để chạy pipeline nhận dạng development, mở thêm ba terminal tại root và chạy `pnpm dev:recognition-service`, `pnpm dev:recognition-dispatcher`, `pnpm dev:recognition-worker`. Fake adapter chỉ được bật trong development/test; production thiếu weights trả `MODEL_UNAVAILABLE`.

setup:local tạo .env với mật khẩu ngẫu nhiên, không in secret, không ghi đè file có sẵn. Bạn có thể chỉnh mật khẩu local trước khi khởi tạo volume PostgreSQL. Port DB mặc định 5433 để tránh PostgreSQL cài sẵn tại 5432. infra:down giữ volume; không tự chạy down -v.

Ở terminal thứ hai, từ root:

```sh
pnpm api:export
pnpm client:generate
dart pub get
dart run melos bootstrap
dart run melos run dev:web
```

Web tại http://localhost:8080; API http://localhost:3000/api/v1/health/live; readiness /api/v1/health/ready; Swagger development /api/docs; MinIO console http://localhost:9001. Readiness trả 503 nếu PostgreSQL, Redis hoặc bucket private không sẵn sàng. Liveness 200 không chứng minh nghiệp vụ hoặc dependency hoạt động.

Android: từ apps/client_flutter chạy `flutter run --flavor development --dart-define-from-file=config/android-development.json`. Emulator dùng 10.0.2.2 thay localhost; máy thật cần URL LAN và allowed origins phù hợp. iOS simulator dùng config/development.json trên macOS. HTTP Android chỉ cho debug; staging/production yêu cầu HTTPS và endpoint thực thay example.invalid. Không đưa secret vào config Dart.

## pgAdmin và database cá nhân

pgAdmin trên Windows kết nối PostgreSQL Docker bằng host localhost, port 5433, maintenance database quan_ly_diem_dev, username postgres, password POSTGRES_PASSWORD trong .env. Đây là tài khoản PostgreSQL của cụm Docker; mật khẩu pgAdmin/master password không thay mật khẩu PostgreSQL.

API dùng app_runtime; migrations dùng app_migration với mật khẩu riêng. Bạn vẫn quản trị bằng postgres trong pgAdmin. Không sửa schema thủ công trong pgAdmin rồi bỏ qua migration. Có thể xem dữ liệu/schema/role và chạy truy vấn đọc để đối chiếu.

POSTGRES_PASSWORD chỉ có tác dụng khởi tạo volume mới; thay .env không tự đổi mật khẩu role của volume hiện hữu. Muốn đổi cần ALTER ROLE trên đúng cụm và cập nhật URL tương ứng, không xóa volume để đổi mật khẩu. Khi password có ký tự đặc biệt, URL phải percent-encode password. Script setup dùng chuỗi hex để tránh lỗi này.

Máy chưa có Docker vẫn có thể chạy unit/build/client và dùng PostgreSQL riêng để test (xem onboarding); chưa thể coi readiness stack hoàn tất. Không tự dùng database cá nhân cho automated tests.

## Kiểm tra

```sh
pnpm check
pnpm contracts:check
dart run melos run check
python -m unittest discover -s apps/recognition-service/tests
```

DB tests yêu cầu TEST_MIGRATION_URL và TEST_RUNTIME_URL cùng trỏ DB có tên kết thúc \_test, đã migrate và seed. Không dùng DB development đang nhập liệu. `pnpm test:db` kiểm NULL/0, miền điểm, unique/FK, lưới, quyền runtime, audit append-only và rollback fixture. `pnpm test:integration` cần đầy đủ stack thật và cấu hình .env.

Runtime không được DML trực tiếp bảng/ô điểm. Tạo/nhập/chốt/đồng bộ đi qua hàm DB có kiểm phiên/phân công, version, transaction và audit. API nhập tay nhận điểm dạng chuỗi `0.0`–`10.0` hoặc `null`, lý do và expectedVersion; mutation nhập/chốt/sync cần `x-idempotency-key`. Xem [hướng dẫn API phần 2](docs/development/phase-2-api.md). Không sử dụng tài khoản migration cho API để vượt giới hạn.

## Smoke lỗi kết nối và Thử lại

Chạy API ở cổng 3000 như hướng dẫn trên. Trong terminal khác, bật proxy chỉ dành kiểm thử:

```powershell
$env:CONNECTION_SMOKE_TEST='1'
node scripts/testing/connection-proxy.mjs
```

Trên Linux/macOS dùng `CONNECTION_SMOKE_TEST=1 node scripts/testing/connection-proxy.mjs`. Proxy loopback cổng 3001 trả 503 một lần rồi chuyển tiếp tới API thật; endpoint `/__ready` không tiêu thụ lỗi này. Khởi động lại proxy trước mỗi lượt test, không mở trang health của proxy trước khi test.

Tại `apps/client_flutter`, chạy `flutter test integration_test/connection_test.dart -d <device-id> --dart-define-from-file=config/smoke-local.json` trên iOS; Android dùng `--flavor development --dart-define-from-file=config/smoke-android.json`. CI tự chạy proxy. Với Web, tại thư mục app chạy `flutter build web --dart-define-from-file=config/smoke-local.json`, sau đó từ root chạy `node scripts/serve-web.mjs`, mở localhost:8080 và xác nhận lỗi rồi bấm Thử lại. Nếu trình duyệt giữ bản build cũ trong cache, nạp lại trang để nhận bản mới. Cấu hình smoke không dùng cho bản phát hành; dừng proxy bằng Ctrl+C sau test.

## GitHub

Repository đích: https://github.com/khaiho150405-pixel/He_Thong_QL_Diem. Issue/PR templates và CI nằm trong .github. CODEOWNERS khai báo @trongv2310 và @caohaidang157; yêu cầu số lượt Approve phải cấu hình riêng trong branch protection. Phase 0 đã merge qua PR #1. Không có license đã được chủ dự án chọn và không deploy production tự động.
