# Giai đoạn 2 — Bảng điểm UC09–10

Theo yêu cầu chủ dự án, triển khai và dừng sau **phần 1**, lưu bàn giao ở [CONTINUE.md](CONTINUE.md). Nền là Phase 1 commit `2b124de`; CI Phase 1 đã xanh ở [run 34476245620](https://github.com/khaiho150405-pixel/He_Thong_QL_Diem/actions/runs/34476245620). Nhánh riêng: `codex/phase-2-part-1-gradebooks`.

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

## Kết quả kiểm chứng

Phần 1 hoàn tất local ngày 2026-09-10:

- `pnpm check`: format, lint, module boundaries, typecheck, 5 unit/HTTP tests và build API đạt.
- Migration nâng cấp từ đủ 3 migration Phase 1 trên `qld_phase1_fresh_test` đạt; chạy cả 4 migration từ rỗng trên `qld_phase2_fresh_test` đạt.
- `pnpm test:db` trên DB mới đạt; test PostgreSQL `gradebooks.test.ts` và hồi quy `identity-catalog.test.ts` đạt. Các ca bao gồm thiếu roster/thành phần, lệch năm học, session hết hạn/khóa, IDOR, 52 ô phân trang 50+2, tạo lại/tạo đồng thời, rollback, quyền DB và NULL/0.0.
- `pnpm api:export` và kiểm diff xác nhận OpenAPI/client không đổi. `node scripts/check-repository.mjs` và `git diff --check` đạt.
- Không đổi Flutter nên không chạy lại native local. Test dependency Redis/MinIO toàn stack và CI của nhánh Phase 2 chưa được dùng làm bằng chứng hoàn tất local; kiểm trạng thái GitHub trước review/merge.

Điểm tiếp tục là phần 2. Chưa coi toàn bộ UC09–10/Phase 2 đã hoàn tất vì hiện chỉ có backend nội bộ tạo/đọc lưới.
