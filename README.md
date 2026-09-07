# Hệ thống Quản lý Điểm

Nền móng Giai đoạn 0 theo [Implementation Plan](implementation_plan1.md) và [AGENTS.md](AGENTS.md). API hiện chỉ có health; chưa có đăng nhập, nhập điểm, OCR hoặc tổng kết. Xem [trạng thái kiểm chứng](docs/development/status.md) để phân biệt phần đã chạy và phần còn cần môi trường.

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
pnpm dev:api
```

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
```

DB tests yêu cầu TEST_MIGRATION_URL và TEST_RUNTIME_URL cùng trỏ DB có tên kết thúc \_test, đã migrate và seed. Không dùng DB development đang nhập liệu. `pnpm test:db` kiểm NULL/0, miền điểm, unique/FK, lưới, quyền runtime, audit append-only và rollback fixture. `pnpm test:integration` cần đầy đủ stack thật và cấu hình .env.

Giai đoạn 0 không cấp quyền runtime ghi điểm; validator kiểm bước 0.1 trước numeric coercion. Giai đoạn 2 phải triển khai write port có authorization/audit/transaction trước cấp quyền. Không sử dụng tài khoản migration cho API để vượt giới hạn.

## GitHub

Repository đích: https://github.com/khaiho150405-pixel/He_Thong_QL_Diem. Issue/PR templates và CI nằm trong .github. CODEOWNERS đang chờ username reviewer. Branch protection là thiết lập GitHub riêng, không tự bật bằng commit workflow. Không có license đã được chủ dự án chọn và không deploy production tự động.
