# Hệ thống Quản lý Điểm

Giai đoạn 1 đã triển khai tài khoản và danh mục UC01–08 theo [kế hoạch Phase 1](docs/development/phase-1.md). [Phase 2](docs/development/phase-2.md) đã merge qua PR #3, gồm API và giao diện Flutter cho danh sách/lưới, nhập hàng loạt, lịch sử, đồng bộ sĩ số và chốt bảng. [Phase 3](docs/development/phase-3.md) đã merge qua PR #5, gồm upload private, outbox/worker BullMQ, contract FastAPI hai kênh, chặn lệch lưới, signed URL và giao diện theo dõi phiếu. [Phase 4](docs/development/phase-4.md) đã merge qua PR #6 với đối chiếu và duyệt nguyên tử có con người quyết định. [Phase 5](docs/development/phase-5.md) đã merge qua PR #7 với tổng kết, xếp loại có phiên bản, thống kê, Excel và tra cứu cá nhân. [Phase 6](docs/development/phase-6.md) đang hardening và chuẩn bị phát hành. Nhắn `continue` trong Codex để tiếp tục từ [note bàn giao](docs/development/CONTINUE.md) theo [AGENTS.md](AGENTS.md). [Plan Giai đoạn 0](implementation_plan1.md) được giữ để báo cáo lịch sử. Mô hình OCR thật vẫn chờ file trọng số.

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
# Chỉ khi chạy mô hình thật (chế độ weights); chế độ fake không cần torch:
# python -m pip install -e "apps/recognition-service[ml]" && python -m pip install --no-deps vietocr==0.3.13
pnpm dev:api
```

Để chạy pipeline nhận dạng development, mở thêm ba terminal tại root và chạy `pnpm dev:recognition-service`, `pnpm dev:recognition-dispatcher`, `pnpm dev:recognition-worker`. Fake adapter chỉ được bật trong development/test; production thiếu weights trả `MODEL_UNAVAILABLE`. Chạy nhận dạng bằng mô hình thật trên máy mới: xem [hướng dẫn Giai đoạn 7](docs/development/phase-7-huong-dan-chay.md); tóm tắt thay đổi tại [phase-7-tong-hop-thay-doi.md](docs/development/phase-7-tong-hop-thay-doi.md).

Giáo viên mở một bảng điểm đang nhập liệu và bung mục **Nhận dạng bảng điểm từ ảnh** để chọn thành phần, chụp trên điện thoại hoặc chọn ảnh PNG/JPEG, xem trước/phóng to rồi gửi job. Client kiểm ảnh trước khi gửi, hiển thị tiến độ và tự kiểm tra trạng thái mỗi 3 giây khi phiếu còn xử lý. Chi tiết chỉ dùng signed URL 5 phút cho ảnh gốc/ảnh ô và vẫn là dữ liệu đề xuất; giáo viên phải đối chiếu, duyệt rồi chốt bảng. Xem [hướng dẫn chụp và kiểm thử mobile](docs/ux/recognition-capture.md). Mô hình thật chạy ở chế độ `weights` (xem [kiểm kê và cấu hình mô hình](docs/development/recognition-checkpoints.md)): dịch vụ nhận dạng nắn ảnh, dò bảng, đọc điểm số bằng CRNN, điểm chữ bằng VietOCR tinh chỉnh và họ tên in bằng VietOCR gốc (`RECOGNITION_NAME_WEIGHTS`, bắt buộc) rồi API ghép từng dòng với danh sách lớp đã chốt của phiếu (ADR-0015); màu Xanh/Vàng/Đỏ theo luật hợp nhất hai kênh (hai kênh độc lập đồng thuận → Xanh; chỉ một kênh đủ tin cậy → Vàng và gợi ý giá trị kênh đó; mâu thuẫn hoặc cùng yếu → Đỏ, không gợi ý), đã đo trên mẫu E0330113 của trường đại học, chưa đo trên bảng điểm cấp 3 thật; phiếu phải có cột Đ.số và Điểm chữ (ADR-0015). Bảng đã chốt có khối tổng kết, thống kê và xuất Excel. Học sinh dùng **Điểm của tôi** để chỉ xem điểm đã duyệt của chính tài khoản.

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

## Hệ số, lịch nhập và công bố học kỳ

QTV mở **Hệ số học kỳ**, chọn TX/GK/CK, học kỳ kèm năm và hệ số. Cấu hình áp dụng cho tất cả môn của học kỳ, mặc định TX=1, GK=2, CK=3. Chỉ sửa trước khi có cột chốt. Chọn loại hệ số của từng thành phần trong **Thành phần điểm**. Cấu hình cũ theo môn được giữ để truy vết nhưng không còn dùng cho lần tính mới.

Trong **Môn học**, bật **Đánh giá Đạt/Không đạt** trước khi tạo bảng điểm. Môn này nhập Đạt/Không đạt; tỷ lệ hệ số Đạt ≥50% thì tổng kết Đạt, thiếu cột bắt buộc thì chưa tổng kết; không cộng vào ĐTB. Excel hiển thị chữ.

QTV mở **Bảng điểm toàn trường** → một bảng → **Lịch nhập điểm của nhà trường**, đặt thời điểm mở và hạn nhập cho từng cột. Giờ trên biểu mẫu theo thiết bị, API lưu UTC. Giáo viên nhập/lưu trong thời gian được phép, không chốt thủ công. Đến hạn, ô thiếu/chưa duyệt được ghi 0 có nhật ký; điểm đã duyệt giữ nguyên, phiếu OCR chưa duyệt chuyển lỗi. Cột khóa, tất cả cột khóa thì bảng tự chốt. API kiểm hạn chính xác; tác vụ nền xử lý điểm 0/khóa mỗi 30 giây và khi khởi động, kể cả bỏ lỡ thời hạn khi tắt máy. Để tự khóa toàn bảng, đặt lịch cho **tất cả cột**; bảng cũ chưa có lịch vẫn theo cổng nhập hiện có, không tự đặt hạn hoặc ghi 0 vào dữ liệu đang dùng. Không mở lại cột đã khóa. Tính tổng kết theo phân công. Sau khi các bảng và tổng kết hoàn tất, QTV sửa **Học kỳ** và bật **Đã công bố** để công bố xếp loại. Trước đó học sinh có thể xem điểm của mình nhưng chưa thấy xếp loại.

Tài khoản giáo viên/học sinh mới dùng số điện thoại 10 chữ số bắt đầu bằng 0. Mẫu `mau_tai_khoan_so_dien_thoai.xlsx` giữ username dạng văn bản để không mất số 0. Tài khoản cũ giữ nguyên. Hai vai trò không đổi tên; học sinh không đổi mật khẩu. Danh mục quản trị chỉ QTV thấy/mở. Học sinh không thấy phòng học trong lịch; QTV có tùy chọn nhóm lớp/phòng.

Migration tiến tiếp `202610040001_school_workflow` và `202610040002_workflow_guards` giữ dữ liệu hiện có; chạy `pnpm.cmd db:migrate`, không reset hoặc seed lại DB đang dùng. Xem [ADR-0013](docs/adr/0013-school-workflow.md).

## GitHub và cộng tác

Repository đích: https://github.com/khaiho150405-pixel/He_Thong_QL_Diem. Issue/PR templates và CI nằm trong .github. CODEOWNERS khai báo @trongv2310 và @caohaidang157; yêu cầu số lượt Approve phải cấu hình riêng trong branch protection. Phase 0 đã merge qua PR #1. Không có license đã được chủ dự án chọn và không deploy production tự động.

Trong bảng điểm toàn trường đã bỏ **Chọn & sắp xếp môn** và **Quản lý môn học**. Danh mục môn vẫn quản lý tại mục riêng của QTV. Bộ lọc admin tải đầy đủ các trang bảng điểm. Trong từng bảng, **Lịch nhập điểm của nhà trường** hiển thị các cột trên một hàng cuộn ngang, gồm tên cột, giờ mở/hạn và nút đặt/sửa lịch cho QTV.

Thời khóa biểu QTV: bấm **Thêm môn vào lịch** hoặc ô trống trong lưới để thêm với ngày/tiết/lớp được chọn sẵn. Bấm ô có môn để **Sửa môn / giáo viên**, **Chuyển ngày / tiết** hoặc **Xóa khỏi lịch** (có xác nhận). Chuyển tiết giữ nguyên phân công; chọn môn khác dùng chức năng sửa. Form chỉ dùng phân công hợp lệ, có Chủ nhật và buổi chiều; màn nhỏ tự bố trí phần chọn buổi theo chiều dọc. Lọc theo lớp/học kỳ giới hạn phân công trong form. Backend tiếp tục kiểm trùng lớp/giáo viên và quy tắc lịch. GV/HS chỉ xem.

Bộ lọc **Lớp học** và **Giáo viên** trong thời khóa biểu dùng ô chuẩn cao 48 px; mở danh sách để xem đầy đủ tên và tìm ngay khi gõ, không cần Enter. Chọn **Tất cả** để bỏ lọc; đóng danh sách giữ lựa chọn hiện tại. Tên dài trong ô đóng có tooltip, danh sách mở cho phép xuống dòng và cuộn riêng.

Migration `202610040003_grade_deadlines` bổ sung lịch nhập và quyền thực thi riêng; giữ lịch sử và trường hệ số cũ trong DB để truy vết, loại khỏi form/badge và không dùng trong tính mới. Chi tiết [ADR-0014](docs/adr/0014-grade-entry-deadlines.md).
