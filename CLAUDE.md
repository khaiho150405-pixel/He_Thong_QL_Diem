# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@AGENTS.md

`AGENTS.md` là nguồn chính về nghiệp vụ, bất biến (mục 7), module và quy trình; không lặp lại ở đây. Tệp này chỉ thêm lệnh, kiến trúc "phải đọc nhiều file mới thấy" và quy tắc riêng cho đợt đang làm. Khi người dùng nhắn `continue`, đọc `docs/development/CONTINUE.md` (nhật ký bàn giao, mới nhất ở đầu) và đối chiếu `git status` trước.

## Lệnh thường dùng

Luôn chạy từ thư mục gốc repo (không `cd` vào `apps/api` hay `database`). Trên PowerShell dùng `pnpm.cmd` nếu `pnpm` bị chặn.

| Việc                                                              | Lệnh                                                                                                      |
| ----------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| Cổng kiểm tra API (format + lint + typecheck + unit test + build) | `pnpm check`                                                                                              |
| Một file test API                                                 | `pnpm exec tsx --test apps/api/test/review.test.ts`                                                       |
| Contract OpenAPI không drift                                      | `pnpm contracts:check`                                                                                    |
| Lint riêng (gồm `scripts/check-boundaries.mjs`)                   | `pnpm lint`                                                                                               |
| Test DB / tích hợp (cần Postgres thật, xem dưới)                  | `pnpm test:db`, `pnpm test:integration`                                                                   |
| Sinh lại OpenAPI + Dart client                                    | `pnpm api:export` rồi `pnpm client:generate`                                                              |
| Dịch vụ nhận dạng (Python 3.12)                                   | trong `apps/recognition-service`: `../../.local/venv-ml/Scripts/python.exe -m unittest discover -s tests` |
| Một file test Python                                              | thêm `-p test_template_recovery.py` vào lệnh trên                                                         |
| Flutter (format + analyze + test)                                 | `dart run melos run check`                                                                                |
| Một file test Flutter                                             | trong `apps/client_flutter`: `flutter test test/<đường dẫn>_test.dart`                                    |
| Công cụ đo nhận dạng (có test riêng, không thuộc gate `py`)       | `scripts/recognition/evaluate_pages.py`, test ở `scripts/recognition/tests`                               |

Chạy dev: `pnpm infra:up` (Postgres/Redis/MinIO) → `pnpm db:migrate` → `pnpm dev:api`. Pipeline nhận dạng cần thêm 3 tiến trình: `dev:recognition-service`, `dev:recognition-dispatcher`, `dev:recognition-worker`. Web: `dart run melos run dev:web` (cổng 8080).

DB test: `pnpm` script không tự tạo DB. `TEST_ADMIN_URL` (kết thúc `/postgres`) → `scripts/prepare-test-db.mjs` tạo `quan_ly_diem_test`; `TEST_MIGRATION_URL` và `TEST_RUNTIME_URL` phải trỏ DB tên kết thúc `_test`, đã migrate và seed. Không dùng DB dev đang nhập liệu.

## Kiến trúc cần biết thêm

- **Nghiệp vụ điểm nằm trong hàm SQL, không phải service TypeScript.** Role `app_runtime` bị cấm DML trực tiếp lên bảng/ô điểm; nhập, chốt, duyệt phiếu, tính tổng kết, xử lý hạn đều đi qua hàm DB (`cap_nhat_diem`, `duyet_phieu_nhan_dien`, `tinh_ket_qua_bang_diem`, `xu_ly_han_nhap_diem`, …) có kiểm phiên/phân công, version và audit. Muốn đổi hành vi thì viết migration mới `CREATE OR REPLACE` hàm đó (xem `database/migrations/2026102*`), rồi bổ sung `database/tests/constraints.test.ts`. API chỉ gọi hàm qua Prisma/pg; không thêm DML trực tiếp và không dùng tài khoản `app_migration` cho API.
- **Học sinh thuộc lớp qua ghi danh** (`hoc_sinh_lop`, ADR-0018). `hoc_sinh.ma_lop`/`dang_theo_hoc` là DEPRECATED và được trigger đồng bộ, chặn sửa trực tiếp; mọi truy vấn "học sinh của lớp" dùng hàm `hoc_sinh_cua_lop` hoặc module `enrollments`.
- **Mã lỗi ổn định** khai báo ở `apps/api/src/common/coded-error.ts`; `ErrorFilter` toàn cục đọc `code`/`details`. Lỗi mới thêm vào đó, không ném chuỗi tự do. Lỗi Prisma khi update theo model không mang `DETAIL` của Postgres, nên chỗ cần chi tiết phải dựng lại bằng hàm DB (ví dụ `TERM_RESULTS_INCOMPLETE`).
- **Ranh giới module do script kiểm tra**: `scripts/check-boundaries.mjs` (chạy trong `pnpm lint`) cấm import tương đối vào `infrastructure|domain|presentation` của module khác. Dùng điểm vào công khai (`public.ts`, service ở `application`).
- **Pipeline nhận dạng 3 tiến trình**: API ghi `phieu_nhan_dien` + outbox → `dispatch.ts` đẩy BullMQ → `run-worker.ts` gọi dịch vụ FastAPI (`apps/recognition-service`, qua `infrastructure/http-model.ts`). Luồng theo lô/mẫu nằm ở `application/batch-*.ts`; ghép dòng-học sinh ở `domain/row-matching.ts`. Dịch vụ Python tách `adapters/` (CRNN, VietOCR), `pipeline/` (lưới, mẫu, khớp cột) và `domain/` (phân loại, chữ → điểm). Fake adapter chỉ bật ở development/test; thiếu trọng số ở production là `MODEL_UNAVAILABLE`. Test cần torch tự bỏ qua khi thiếu nhóm `[ml]`.
- **Flutter** (`apps/client_flutter/lib/features/*`) gọi API qua `packages/api_client_dart`, sinh từ OpenAPI; sửa DTO ở NestJS rồi sinh lại, không sửa tay. Cấu hình môi trường qua `--dart-define-from-file=config/*.json`. Quy tắc UI: `docs/design/ui-rules.md`.
- Migration đặt tên `YYYYMMDDNNNN_ten`, đã chạy thì không sửa; thay đổi tiếp bằng migration mới.

# Đợt hiện tại: Mẫu bảng điểm (ADR-0016)

Đợt này thêm "Mẫu bảng điểm" để nhận dạng được nhiều loại tờ, nhiều cột, nhiều trang. Công việc chia thành phase P1–P7 trong `automation/phases/` (P7 là sửa khớp cột khi lưới mất/dính vạch dọc), thường chạy tự động bằng `automation/run.py`. Trạng thái và rủi ro còn lại của từng phase ghi ở đầu `docs/development/CONTINUE.md`.

Trước khi làm, đọc theo thứ tự:

1. `AGENTS.md`: bất biến mục 7 luôn thắng mọi tài liệu khác.
2. `automation/decisions.md`: quyết định của chủ dự án cho đợt này.
3. `docs/adr/0016-form-templates.md`: thiết kế (kèm "Ghi chú hiện thực" và "Kết quả đánh giá").
4. File phase đang làm, đặc biệt các mục "Phạm vi được sửa", "Không được đụng" và "Tiêu chí nghiệm thu".
5. Khi sửa Flutter: `docs/design/ui-rules.md`.

## Quy tắc chung

- Phase cho phép sửa backend, migration mới, dịch vụ Python, client sinh lại hoặc Flutter ở đâu thì chỉ sửa ở đó. Không sửa ngoài phạm vi phase.
- Không sửa migration đã có. Không sửa tay `packages/api_client_dart` (dùng `pnpm client:generate`).
- Không thêm dependency (npm, pub, pip) nếu phase không cho phép rõ ràng. Không cài gì lên ổ C.
- Không sửa thư mục `automation/` ngoài file báo cáo trong `automation/runs/`.
- Khi chạy qua `automation/run.py`: **không** `git commit` / `git push` / `git reset` / `git stash`. Script tự commit.
- Thiếu thông tin thì chọn phương án theo ADR-0016 và `decisions.md`, giữ hành vi cũ ở những chỗ không thuộc phase, rồi ghi giả định vào báo cáo. Không dừng lại để hỏi.
- Kết thúc phần việc: cập nhật `docs/development/CONTINUE.md` (AGENTS.md mục 11).
- Số liệu đo nhận dạng: không chạy lại tập TEST sau khi đã chạy một lần; không đổi cách tính `regression_checks` trong `scripts/recognition/evaluate_pages.py`.
