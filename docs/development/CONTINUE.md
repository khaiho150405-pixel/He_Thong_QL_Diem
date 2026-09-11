# Điểm tiếp tục dự án

Chủ dự án chỉ cần nhắn **`continue` trong Codex tại workspace này**. Agent đọc AGENTS.md và note này, đối chiếu git, rồi tiếp tục đúng phần còn lại. Không cần người dùng dán lại lịch sử chat. Đây không phải lệnh PowerShell hay tác vụ tự chạy nền.

## Trạng thái bàn giao

- Yêu cầu mới nhất: sửa CI đỏ sau khi Phase 2 đã merge, cung cấp demo Web và tiếp tục sang nền Phase 3 mà chưa cần file trọng số OCR.
- Nhánh: `codex/phase-3-recognition-foundation`, xây trên hotfix `codex/phase-2-ci-demo`. Hotfix commit `850c72a` đã xanh toàn bộ ở [GitHub Actions](https://github.com/khaiho150405-pixel/He_Thong_QL_Diem/actions/runs/34598089241); merge hotfix vào main trước rồi mới mở PR Phase 3.
- Phase 1: tài khoản/danh mục đã có mã và CI xanh. Không xây lại Phase 0/1.
- Phase 2 phần 1 commit `0ae7fbc`, phần 2 `3ad0865`, phần 3 `23df8fe`; PR #3 đã merge. Hotfix hiện tại chạy integration files tuần tự vì chúng dùng chung PostgreSQL `SERIALIZABLE`; chạy song song đã tái hiện 2 đạt/1 lỗi, chạy tuần tự đạt 3/3.
- Demo local đã được kiểm tra với Flutter Web, API thật và PostgreSQL test cô lập: giáo viên tạo bảng #25, nhập `8.5`, lưu lịch sử và tăng version. Mật khẩu demo chỉ được đặt trong database test local, không commit.
- Phase 3 phần 1 đã có domain contract Python cho hai kênh và policy Xanh/Vàng/Đỏ ở `apps/recognition-service`; ngưỡng confidence được truyền vào và chưa chốt production. Sáu unit test bao phủ khớp, lệch, confidence thấp, một kênh, ô trống, NULL/0.0 và input sai.
- Phase 3 phần 2 đã có upload multipart PNG/JPEG, kiểm nội dung/kích thước/độ phân giải, S3 object private, phiếu + audit + idempotency + outbox cùng transaction và BullMQ dispatcher có lease/retry hữu hạn. Endpoint trả `202` với ticket/job ID, không lộ object key. OpenAPI và Dart client đã sinh lại.

## Khi nhận continue

1. Đọc AGENTS.md, README.md, phase-2.md, ADR-0002/0004/0006/0007 và trạng thái git. Giữ mọi thay đổi chưa commit; không reset hoặc sửa migration đã chạy.
2. Chỉ chốt hotfix khi GitHub `foundation`, `ios` và `required-checks` đều xanh. Local đã đạt `pnpm test:db` và ba suite nghiệp vụ tuần tự; máy thiếu Docker nên GitHub phải xác nhận probe Redis/MinIO, APK/emulator và iOS.
3. Duy trì NULL khác 0.0, quyền phân công ở service, session còn hiệu lực, ghi điểm + audit cùng transaction, version/idempotency, khóa bảng đã chốt, bigint/decimal chuỗi. Không cấp runtime DML điểm trực tiếp để vượt kiểm tra bước 0.1.
4. Tiếp tục Phase 3 phần 3 bằng BullMQ worker, FastAPI contract, kiểm lưới/số dòng, fake adapter development/test và lưu riêng hai kênh/ảnh ô cắt. Chưa nối model thật khi chưa có weights; production thiếu weights phải trả model unavailable và worker không được ghi điểm chính thức.

## Công cụ và dữ liệu test trên máy hiện tại

- PowerShell; Node 24.19.0/pnpm 11.19.0, Flutter 3.35.7 ở `C:\src\flutter\bin`; giữ phiên bản lockfile.
- Nếu PATH của agent thiếu Node: thêm cả `C:\Users\Ho Si Khai\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin` và `C:\Users\Ho Si Khai\.cache\codex-runtimes\codex-primary-runtime\dependencies\bin\fallback` vào PATH cho tiến trình hiện tại. Java cho generator: Android Studio `jbr\bin`.
- PostgreSQL test riêng: `.local/pg-test`, loopback `127.0.0.1:55433` trong lượt hiện tại vì cổng 55432 không bind được, PostgreSQL 18; không dùng DB cá nhân cổng 5432 hoặc DB development có dữ liệu nhập thật.
- Database nâng cấp phần 2: `qld_phase2_fresh_test`; database cài từ rỗng phần 2: `qld_phase2_write_fresh_test`. Dùng role `app_migration` cho migration, `app_runtime` cho service/test quyền. Cụm test loopback này dùng trust; không suy rộng cấu hình này sang production.
- URL test dùng `127.0.0.1:55433` với role `app_migration`/`app_runtime`. Đặt TEST_MIGRATION_URL/TEST_RUNTIME_URL; migration dùng MIGRATION_DATABASE_URL. Không in/commit `.env` hoặc lấy mật khẩu PG làm mật khẩu ứng dụng.
- Lệnh kiểm: `pnpm check`, `pnpm test:db`, `pnpm exec tsx --test apps/api/test/integration/gradebooks.test.ts apps/api/test/integration/gradebook-write.test.ts apps/api/test/integration/identity-catalog.test.ts`. Test dependency toàn stack cần Redis/MinIO; Docker trên máy này chưa có theo lần kiểm gần nhất.
- Database Phase 3 mới: `qld_phase3_upload_fresh_test` tại cổng local thực tế `55433`; cả sáu migration từ rỗng và seed giả đã đạt. Database `qld_phase2_write_fresh_test` đã kiểm nâng cấp migration Phase 3. Integration upload HTTP/PostgreSQL đạt; MinIO/Redis thật vẫn để GitHub CI xác nhận vì máy không có Docker.
- AGENTS.md yêu cầu schema thay đổi kiểm cả nâng cấp và DB rỗng. Không drop database test để chạy lại: fixture dùng tên ngẫu nhiên; database mới chỉ tạo khi cần kiểm từ rỗng.
- Git elevated có thể cần `git -c safe.directory='C:/Users/Ho Si Khai/Downloads/Ki_1_nam_4/KLCN/system' ...`; không chỉnh global safe.directory.
- Connector GitHub từng trả 403 khi tạo PR. Nếu quyền chưa đổi, bàn giao link compare; không tự tìm credential hoặc merge.

## Kết quả cuối và công việc dở

Phần 2: migration 202609100003_gradebook_write; service/controller/DTO tạo/đọc bảng, batchUpdate, lock, syncRoster và history. Body mutation có expectedVersion bắt buộc; batch có changes tối đa 100 ô với cellId chuỗi, value NULL hoặc chuỗi chuẩn 0.0–10.0 và reason. Header x-idempotency-key theo người dùng/thao tác. Replay vẫn kiểm quyền; cùng key khác body trả 409. PostgreSQL khóa bảng và tăng version đúng một lần, ghi điểm/lịch sử/audit/idempotency nguyên tử; runtime không có DML điểm trực tiếp.

Không chốt khi thiếu điểm bắt buộc/thiếu ô sĩ số hoặc còn chờ review. Đây là mặc định development bảo thủ, cần xác nhận trước production (ADR-0007), không tự quy thiếu điểm thành 0. Có API sync-roster riêng; GET không ghi dữ liệu. Giữ ô ngừng học, active=false. Nhập tay gặp phiếu pending bị chặn 409; luồng lựa chọn tiếp tục/ghi đè nhận dạng thuộc Phase 3–4. Record idempotency hiện được giữ kể cả quá mốc 24 giờ; không có cleanup tự động.

Đã đạt local: migration upgrade từ phần 1 và cài mới năm migration; pnpm test:db; cả ba integration suite PostgreSQL/HTTP (identity/catalog, grid, write), gồm trigger gây lỗi audit và race edit/edit, edit/lock, cùng key. pnpm check đạt 6 tests + build; Flutter analyze và 9 tests đạt gồm serialization bigint/decimal/NULL. OpenAPI/Dart client đã sinh lại. Kiểm drift và trạng thái CI ghi trong phase-2.md; không coi CI phần 1 là bằng chứng phần 2.

UI phần 3 nằm ở `apps/client_flutter/lib/features/gradebooks/`: danh sách/tạo bảng, lưới responsive, nhập hàng loạt có lý do, lịch sử, sync và chốt. Repository chỉ dùng generated client, tải hết trang ô/lịch sử và không tự retry conflict bằng version mới. Test ở `apps/client_flutter/test/phase2_gradebooks_test.dart` bao phủ 390px/1280px, NULL/0.0, request version/idempotency, banner conflict, lịch sử và trạng thái chốt.

Local đã đạt `dart run melos run check` (13 tests) và Flutter Web build. Android local vẫn gặp lỗi môi trường `Unable to establish loopback connection` trước biên dịch; CI commit `23df8fe` đã xác nhận foundation/APK/emulator xanh. iOS build simulator xanh nhưng smoke test chạm timeout 10 phút; workflow tăng giới hạn riêng lên 15 phút. Lượt follow-up commit `887155c` đã xác nhận iOS và required-checks xanh. Bước còn lại là review/PR theo quyết định của chủ dự án; không merge hoặc bắt đầu Phase 3 tự động.

Cụm PostgreSQL test đang nghe ở `127.0.0.1:55433`; kiểm cổng/process trước khi khởi động thêm. Giữ fixture giả ở DB test, không xóa DB; trigger gây lỗi chỉ dùng test và đã gỡ trong finally.

Phase 3 phần 2 đã hoàn tất kiểm tra local trên `codex/phase-3-recognition-foundation`: `pnpm check` đạt 9 unit/HTTP tests + build, `pnpm test:db` đạt, bốn integration suite PostgreSQL Phase 1–3 chạy tuần tự đạt, HTTP upload trả `202`, `pnpm contracts:check` không drift, Dart client analyze đạt và Python domain đạt 6/6. Integration Redis/MinIO thật đã được thêm vào CI nhưng chưa chạy local vì máy thiếu Docker; xem kết quả GitHub mới nhất trước khi review. Không mở hoặc merge PR Phase 3 trước khi hotfix Phase 2 đã vào `main`.
