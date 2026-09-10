# Điểm tiếp tục dự án

Chủ dự án chỉ cần nhắn **`continue` trong Codex tại workspace này**. Agent đọc AGENTS.md và note này, đối chiếu git, rồi tiếp tục đúng phần còn lại. Không cần người dùng dán lại lịch sử chat. Đây không phải lệnh PowerShell hay tác vụ tự chạy nền.

## Trạng thái bàn giao

- Yêu cầu hiện tại: Phase 2 đến hết phần 1 (migration/backend khởi tạo bảng), rồi dừng.
- Nhánh: `codex/phase-2-part-1-gradebooks`, nền Phase 1 `2b124de`. Không tự merge main; kiểm tra trạng thái remote trước khi chọn base PR.
- Phase 1: tài khoản/danh mục đã có mã và CI xanh. Không xây lại Phase 0/1.
- Phase 2 phần 1: hoàn tất kiểm chứng local ngày 2026-09-10; xem [phase-2.md](phase-2.md) và [ADR-0006](../adr/0006-gradebook-grid.md). Điểm tiếp tục: phần 2.

## Khi nhận continue

1. Đọc AGENTS.md, README.md, phase-2.md, ADR-0002/0004/0006 và trạng thái git. Giữ mọi thay đổi chưa commit; không reset hoặc sửa migration đã chạy.
2. Nếu phần 1 còn kiểm tra thất bại/đang dở được ghi bên dưới, giải quyết trước. Nếu đã đạt, bắt đầu **Phase 2 phần 2** theo checklist: API + write port nhập/chốt, audit và kiểm thử; chưa triển khai Flutter phần 3 hoặc OCR.
3. Duy trì NULL khác 0.0, quyền phân công ở service, session còn hiệu lực, ghi điểm + audit cùng transaction, version/idempotency, khóa bảng đã chốt, bigint/decimal chuỗi. Không cấp runtime DML điểm trực tiếp để vượt kiểm tra bước 0.1.
4. Kết thúc phần 2: lưu kết quả/lệnh test và phần còn lại vào note này, để lần `continue` kế tiếp làm phần 3. Không tiêu thụ credit reset nếu chưa có yêu cầu riêng.

## Công cụ và dữ liệu test trên máy hiện tại

- PowerShell; Node 24.19.0/pnpm 11.19.0, Flutter 3.35.7 ở `C:\src\flutter\bin`; giữ phiên bản lockfile.
- Nếu PATH của agent thiếu Node: thêm `C:\Users\Ho Si Khai\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin` vào PATH cho tiến trình hiện tại. Java cho generator: Android Studio `jbr\bin`.
- PostgreSQL test riêng: `.local/pg-test`, loopback `127.0.0.1:55432`, PostgreSQL 18; không dùng DB cá nhân cổng 5432 hoặc DB development có dữ liệu nhập thật.
- Database nâng cấp: `qld_phase1_fresh_test`; database cài rỗng phần 1: `qld_phase2_fresh_test`. Dùng role `app_migration` cho migration, `app_runtime` cho service/test quyền. Cụm test loopback này dùng trust; không suy rộng cấu hình này sang production.
- URL test: `postgresql://app_migration@127.0.0.1:55432/qld_phase2_fresh_test` và tương ứng `app_runtime`. Đặt TEST_MIGRATION_URL/TEST_RUNTIME_URL; migration dùng MIGRATION_DATABASE_URL. Không in/commit `.env` hoặc lấy mật khẩu PG làm mật khẩu ứng dụng.
- Lệnh kiểm: `pnpm check`, `pnpm test:db`, `pnpm exec tsx --test apps/api/test/integration/gradebooks.test.ts apps/api/test/integration/identity-catalog.test.ts`. Test dependency toàn stack cần Redis/MinIO; Docker trên máy này chưa có theo lần kiểm gần nhất.
- AGENTS.md yêu cầu schema thay đổi kiểm cả nâng cấp và DB rỗng. Không drop database test để chạy lại: fixture dùng tên ngẫu nhiên; database mới chỉ tạo khi cần kiểm từ rỗng.
- Git elevated có thể cần `git -c safe.directory='C:/Users/Ho Si Khai/Downloads/Ki_1_nam_4/KLCN/system' ...`; không chỉnh global safe.directory.
- Connector GitHub từng trả 403 khi tạo PR. Nếu quyền chưa đổi, bàn giao link compare; không tự tìm credential hoặc merge.

## Kết quả cuối và công việc dở

Đã hoàn thành migration `202609100002_gradebook_grid`, public service `GradebooksService.create/list/cells`, kiểm quyền phiên/phân công, tạo bảng + ô NULL + audit nguyên tử, cursor và chống tạo trùng. QTV chỉ đọc; học sinh không đọc toàn bảng. Runtime vẫn không được DML trực tiếp điểm/bảng. Không sửa migration Phase 0/1, không thay schema Prisma hoặc OpenAPI/Flutter.

Đã đạt: `pnpm check` (5 test + build), migration upgrade Phase 1 và cài từ rỗng, `pnpm test:db`, PostgreSQL gradebooks integration trên cả hai DB, identity/catalog regression, export OpenAPI không đổi và repository scan. Test phát hiện driver Prisma 7 đặt SQLSTATE trong `meta.driverAdapterError.cause.originalCode`; đã sửa cách chuyển lỗi và retry serialization. Không còn lỗi local đã biết trong phạm vi phần 1.

Không có tác vụ backend phần 1 đang chạy dở. Cụm PG test được dừng sau kiểm chứng; kiểm `pg_ctl status` trước khi khởi động lại bằng binary PostgreSQL 18. Dữ liệu fixture giả được giữ trong DB test để truy vết, không xóa DB. Script chẩn đoán tạm đã gỡ.

Trước khi mở phần 2, kiểm GitHub CI của HEAD nhánh phần 1 và trạng thái merge Phase 1. Chưa có bằng chứng CI Phase 2 trong note này; không suy từ CI Phase 1. Công việc chưa làm có chủ đích: HTTP/API nhập/chốt điểm, write port/audit lịch sử, version/idempotency cho mutation, đồng bộ sĩ số, generated client và Flutter. Checklist chi tiết nằm trong phase-2.md. Không cần chạy lại toàn bộ kiểm thử phần 1 nếu không sửa mã liên quan.
