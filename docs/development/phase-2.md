# Giai đoạn 2 — Bảng điểm UC09–10

Phần 1–2 backend đã hoàn tất; phần 3 Flutter đã triển khai local và đang chờ CI/review để nghiệm thu toàn Phase 2. Nền là Phase 1 commit `2b124de`; phần 1 commit `0ae7fbc` có [CI xanh](https://github.com/khaiho150405-pixel/He_Thong_QL_Diem/actions/runs/34483146888), phần 2 commit `3ad0865` có [CI xanh](https://github.com/khaiho150405-pixel/He_Thong_QL_Diem/actions/runs/34506274659). Giữ nhánh `codex/phase-2-part-1-gradebooks`; không tự merge main.

## Phần 1 — Migration và application backend khởi tạo bảng

Acceptance criteria:

- Tạo bảng lớp–môn–học kỳ cùng đầy đủ ô NULL cho học sinh đang học × thành phần môn; lỗi rollback cả bảng/ô/audit.
- Giáo viên đúng phân công mới tạo/đọc được; QTV chỉ đọc; học sinh và giáo viên khác bị từ chối. Kiểm lại phiên ngay trong service và quyền tạo ở DB.
- Cùng bộ định danh tạo lại không trùng dữ liệu/nhật ký, không mất điểm hoặc mở lại bảng DA_CHOT; kiểm tạo đồng thời.
- Đọc cursor 50 phần tử, bigint/decimal dạng chuỗi, phân biệt NULL với 0.0; giữ hàng ngừng học và đánh dấu inactive.
- Runtime không có ghi trực tiếp bảng/ô điểm, không được sửa/xóa/truncate lịch sử. Không nhận giá trị điểm từ input tạo bảng.
- Migration kiểm nâng cấp từ Phase 1 và cài mới từ DB rỗng, PostgreSQL integration thật, unit policy và backend checks.

Mã: `GradebooksService` public application; `GradebookStore` port; adapter Prisma cùng transaction serializable; migration `202609100002_gradebook_grid`. [ADR-0006](../adr/0006-gradebook-grid.md) nêu quyền DB, idempotency và rollback. Chưa có controller/DTO mới nên OpenAPI và Dart client không đổi; không có thay đổi Flutter cần build native.

## Phần 2 — API và nghiệp vụ nhập/chốt, audit

- HTTP list/create/grid với DTO/OpenAPI, error envelope/requestId, CSRF và kiểm quyền âm tính qua HTTP.
- Batch nhập/sửa/xóa giá trị về NULL: điểm 0–10 bước 0.1, lý do bắt buộc, NHAP_TAY, trạng thái nhất quán; phân biệt ô thiếu với số 0. Chốt chính sách trạng thái điểm nhập tay trong ADR.
- Write port kiểm validator trước numeric coercion, kiểm phân công/phiên và version trong transaction, lịch sử append-only cho mọi thay đổi; rollback khi ghi điểm hoặc audit lỗi.
- Idempotency key bền vững và request hash cho batch/chốt; tránh ghi lịch sử lặp. Tranh chấp version trả conflict.
- Chốt bảng có version/nhật ký, cấm ghi bảng đã chốt và test đồng thời sửa/chốt. Chưa tự quyết quy tắc cho phép chốt khi thiếu điểm hoặc còn CHO_DOI_CHIEU; ghi rõ quy tắc trước triển khai.
- UC09 A3 đồng bộ học sinh mới qua thao tác ghi riêng, giữ dòng cũ; không tạo ô bằng GET hoặc mở khóa bảng đã chốt.
- UC10 API lịch sử có cursor và đúng scope, không endpoint update/delete. Ghi audit lần truy cập ngoài phân công theo HTML A1.
- Sinh lại Dart client từ OpenAPI và contract test bigint/decimal/null; integration PostgreSQL/HTTP/IDOR/race/idempotency.

## Phần 3 — Flutter và nghiệm thu Phase 2

Danh sách bảng, lưới responsive, nhập nhiều ô, lịch sử, xác nhận chốt, loading/empty/error/retry/conflict; dùng client sinh tự động. Widget/integration và kiểm web/Android/iOS theo AGENTS.md. Review và CI phải đạt trước khi merge. Không bắt đầu OCR/Phase 3 trong phạm vi này.

Đã triển khai:

- Route danh sách/chi tiết bảng điểm cho quản trị viên và giáo viên; học sinh bị guard khỏi màn hình toàn bảng.
- Giáo viên tạo bảng từ danh mục lớp/môn/học kỳ, nhập tối đa 100 ô với lý do, đồng bộ sĩ số và xác nhận chốt. Quản trị viên chỉ đọc theo quyền backend.
- Lưới ngang cho web và thẻ theo học sinh cho mobile; giữ riêng ô trống `NULL` và chuỗi `0.0`, khóa ô của học sinh ngừng theo học/đang chờ đối chiếu và toàn bảng `DA_CHOT`.
- Lịch sử hiển thị giá trị cũ/mới, người sửa, lý do, thời điểm. Mutation dùng version hiện tại và idempotency key; lỗi 409 hiển thị banner bắt buộc tải lại để đối chiếu, không tự ghi đè.
- Repository tải hết các trang ô/lịch sử và phát hiện cursor lặp; màn hình danh sách có phân trang và trạng thái loading/empty/error/retry.

## Kết quả kiểm chứng

Phần 1 hoàn tất local ngày 2026-09-10:

- `pnpm check`: format, lint, module boundaries, typecheck, 5 unit/HTTP tests và build API đạt.
- Migration nâng cấp từ đủ 3 migration Phase 1 trên `qld_phase1_fresh_test` đạt; chạy cả 4 migration từ rỗng trên `qld_phase2_fresh_test` đạt.
- `pnpm test:db` trên DB mới đạt; test PostgreSQL `gradebooks.test.ts` và hồi quy `identity-catalog.test.ts` đạt. Các ca bao gồm thiếu roster/thành phần, lệch năm học, session hết hạn/khóa, IDOR, 52 ô phân trang 50+2, tạo lại/tạo đồng thời, rollback, quyền DB và NULL/0.0.
- `pnpm api:export` và kiểm diff xác nhận OpenAPI/client không đổi. `node scripts/check-repository.mjs` và `git diff --check` đạt.
- Không đổi Flutter nên không chạy lại native local. Test dependency Redis/MinIO toàn stack và CI của nhánh Phase 2 chưa được dùng làm bằng chứng hoàn tất local; kiểm trạng thái GitHub trước review/merge.

Phần 2 đã có toàn bộ API trong [hướng dẫn review](phase-2-api.md), chính sách tại [ADR-0007](../adr/0007-gradebook-write.md). Kiểm chứng ngày 2026-09-11: nâng cấp database phần 1 và cài mới năm migration trên `qld_phase2_write_fresh_test`; constraint test và ba integration suite (identity/catalog, grid, write HTTP) đạt. Đã kiểm rollback thực khi trigger audit phát lỗi, version và idempotency khi gửi đồng thời, sai bảng/ô, CSRF, hết phiên, đồng bộ sĩ số và chốt thiếu điểm/chờ review. Backend check đạt 6 tests/build; Flutter analyze và 9 tests đạt, gồm contract bigint/NULL/0.0. OpenAPI/client được sinh lại; `pnpm contracts:check` đạt, không có drift.

Phần 3 kiểm local ngày 2026-09-11: `dart run melos run check` đạt analyzer và 13 tests; bốn widget test mới đạt ở 390px/1280px cho NULL/0.0, batch/version/idempotency, retry giữ nguyên key, conflict, lịch sử và chốt. `flutter build web --dart-define-from-file=config/development.json` đạt. Android local dừng trước biên dịch do Gradle/JVM trên máy không tạo được kết nối loopback; lỗi toolchain này cũng từng được ghi ở trạng thái Phase 0. CI commit `23df8fe` có foundation xanh gồm APK/emulator nhưng smoke iOS chạm timeout 10 phút sau khi build simulator đạt; lượt xanh trước chạy bước này 77 giây. Tăng giới hạn riêng của smoke iOS lên 15 phút và phải kiểm lượt CI tiếp theo trước khi coi Phase 2 hoàn tất. Chưa merge main và chưa bắt đầu OCR.
