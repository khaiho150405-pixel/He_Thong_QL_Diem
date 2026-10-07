# Giai đoạn 7 — Prompt giao việc cho AI, chia Backend (BE) và Frontend (FE)

File này chia kế hoạch `docs/development/phase-7-nhan-dang-ghep-hoc-sinh.md` thành hai phần:

- **Phần A — Backend (BE):** database/migration (`database/`), API NestJS + worker (`apps/api`), dịch vụ nhận dạng Python (`apps/recognition-service`), tài liệu/ADR. Gồm BE-00 → BE-22.
- **Phần B — Frontend (FE):** ứng dụng Flutter (`apps/client_flutter`). Gồm FE-01 → FE-05. FE chỉ dùng Dart client sinh từ OpenAPI, nên mỗi bước FE phụ thuộc bước BE đã đổi API.

Mỗi bước có một prompt đầy đủ, ghi rõ **Phụ thuộc**. Chỉ làm một bước khi mọi bước phụ thuộc đã đánh dấu [x].

## Cách dùng

- **Chạy một bước:** `Thực hiện bước BE-05 trong docs/development/phase-7-prompts.md.` (hoặc `FE-02`...)
- **Chạy riêng phần BE:** `Đọc docs/development/phase-7-prompts.md, làm bước BE chưa [x] đầu tiên có đủ phụ thuộc. Xong một bước thì dừng và báo cáo.`
- **Chạy riêng phần FE:** `Đọc docs/development/phase-7-prompts.md, làm bước FE chưa [x] đầu tiên có đủ phụ thuộc. Nếu phụ thuộc BE chưa xong thì dừng và báo bước BE còn thiếu.`
- **Tự động theo thứ tự đề xuất:** `continue` — agent lấy bước chưa [x] đầu tiên trong mục **Thứ tự đề xuất** ở cuối file.
- **Không chạy hai agent cùng lúc trong cùng thư mục repo** (cùng nhánh, dễ ghi đè nhau). Muốn song song thì một người/agent làm BE, xong mỗi mốc mới giao FE.

## Prompt chạy toàn bộ Phần A — Backend

Dán nguyên khối dưới đây vào AI agent tại thư mục gốc repo:

```text
Bạn là AI agent phụ trách PHẦN A — BACKEND của Giai đoạn 7 trong repo He_Thong_QL_Diem.

TÀI LIỆU PHẢI ĐỌC TRƯỚC:
- AGENTS.md
- docs/development/CONTINUE.md
- docs/development/phase-7-nhan-dang-ghep-hoc-sinh.md (mục 0 và các Phần liên quan)
- docs/development/phase-7-prompts.md (KHỐI CHUNG, Phần A, mục Tiến độ)

NHIỆM VỤ:
Thực hiện lần lượt các bước BE chưa đánh dấu [x] trong mục "Tiến độ > Phần A — Backend" của
docs/development/phase-7-prompts.md, theo đúng thứ tự BE-00 → BE-19. Với mỗi bước:
1. Đọc prompt của bước đó trong file và áp dụng KHỐI CHUNG.
2. Kiểm tra mọi bước trong dòng "Phụ thuộc" đã [x]; thiếu thì dừng và báo.
3. Làm đúng phạm vi bước, không làm trước việc của bước sau.
4. Chạy các lệnh kiểm tra của bước, ghi kết quả thật.
5. Cập nhật docs/development/CONTINUE.md (mục mới nhất ở đầu) và đánh dấu [x] bước đó.
6. In báo cáo ngắn của bước (file đổi, hành vi mới, lệnh kiểm tra + kết quả, rủi ro), rồi chuyển sang bước BE tiếp theo.

PHẠM VI ĐƯỢC SỬA: database/, apps/api/, apps/recognition-service/, packages/api_client_dart/ (chỉ qua
`pnpm client:generate`), docs/, AGENTS.md, README.md, .env.example, scripts/recognition/.
KHÔNG sửa apps/client_flutter/ (thuộc Phần B — Frontend). Nếu đổi API làm Flutter không biên dịch được,
ghi lại vào CONTINUE.md để bước FE xử lý, không tự sửa Flutter.

DỪNG NGAY VÀ BÁO NGƯỜI DÙNG KHI:
- Gặp một điều kiện dừng trong KHỐI CHUNG (thiếu trọng số/ảnh mẫu/Docker/PostgreSQL test, test đỏ sau 2 lần sửa,
  cần quyết định nghiệp vụ mới).
- Không đọc được thư mục nguồn thuật toán D:\HocTap\KhoaLuan\App\KLCN_2026\07_CONG_CU_VA_SCRIPT hoặc trọng số
  D:\HocTap\KhoaLuan\App\weights ở các bước BE-13 → BE-19.
- Đã xong BE-19. KHÔNG làm BE-20 → BE-22 vì chúng cần Phần B — Frontend hoàn tất trước.

TUYỆT ĐỐI KHÔNG:
- Commit, push, merge, tạo Pull Request, deploy.
- Sửa migration đã tồn tại, reset hoặc seed lại DB development, dùng DB không có hậu tố _test cho test.
- Sửa sơ đồ phân cấp chức năng; đưa họ tên/ảnh học sinh thật vào test, fixture, log.
- Hạ torch.load xuống weights_only=False; tải mô hình từ Internet lúc chạy.

KẾT THÚC (khi dừng vì bất kỳ lý do nào):
Báo cáo tổng hợp bằng tiếng Việt: các bước đã [x], bước đang dở và lý do dừng, danh sách file đã đổi,
kết quả các lệnh kiểm tra, việc cần người dùng làm tiếp (nếu có).
```

Tiếp tục sau khi dừng: `Tiếp tục Phần A — Backend theo docs/development/phase-7-prompts.md từ bước BE chưa [x] đầu tiên.`

## Prompt chạy toàn bộ Phần B — Frontend

Dán nguyên khối dưới đây vào AI agent tại thư mục gốc repo (chỉ chạy khi không có agent Backend nào đang làm việc trong cùng thư mục):

```text
Bạn là AI agent phụ trách PHẦN B — FRONTEND (Flutter) của Giai đoạn 7 trong repo He_Thong_QL_Diem.

TÀI LIỆU PHẢI ĐỌC TRƯỚC:
- AGENTS.md
- docs/development/CONTINUE.md (đặc biệt mục "Việc cho FE" do Backend ghi lại)
- docs/development/phase-7-nhan-dang-ghep-hoc-sinh.md (mục 0 và Phần 7.1, 7.5)
- docs/development/phase-7-prompts.md (KHỐI CHUNG, Phần B, mục Tiến độ)
- docs/adr/0015-recognition-row-matching.md

NHIỆM VỤ:
Thực hiện lần lượt FE-01 → FE-05 (các bước chưa [x] trong "Tiến độ > Phần B — Frontend"). Với mỗi bước:
1. Đọc prompt của bước và áp dụng KHỐI CHUNG.
2. Kiểm tra các bước BE trong dòng "Phụ thuộc" đã [x]; thiếu thì dừng và báo.
3. Làm đúng phạm vi bước. Chỉ dùng Dart client sinh sẵn trong packages/api_client_dart; thiếu trường API thì
   dừng và báo bước BE tương ứng, không tự sửa backend hay sửa tay client.
4. Sửa các fixture JSON trong test Flutter cho khớp contract mới (stt, greenRows/yellowRows/redRows,
   declaredRows nullable, các trường ghép dòng) theo ghi chú "Việc cho FE" trong CONTINUE.md.
5. Chạy `dart run melos run check`; bước có UI mới chạy thêm
   `flutter build web --dart-define-from-file=config/development.json` trong apps/client_flutter. Ghi kết quả thật.
6. Cập nhật CONTINUE.md (mục mới nhất ở đầu), đánh dấu [x] bước, in báo cáo ngắn, rồi sang bước FE tiếp theo.

PHẠM VI ĐƯỢC SỬA: apps/client_flutter/ (lib, test, integration_test), docs/ux/, docs/development/CONTINUE.md,
docs/development/phase-7-prompts.md (chỉ ô Tiến độ). KHÔNG sửa apps/api, database, apps/recognition-service,
packages/api_client_dart.

YÊU CẦU GIAO DIỆN:
- Giữ chuẩn control trong docs/ux/ui-control-standard.md (AppFilterDropdown, AppActionButton, chiều cao 48).
- Responsive: test widget ở 320, 390, 1280 px với chữ 130%; không overflow.
- Dòng Đỏ không điền sẵn giá trị; giáo viên phải xem mọi dòng trước khi duyệt (giữ logic hiện có).
- Không hiển thị mã đối tượng lưu trữ; ảnh chỉ qua signed URL từ API.

DỪNG NGAY VÀ BÁO KHI: gặp điều kiện dừng của KHỐI CHUNG; API thiếu trường cần cho màn hình; đã xong FE-05.

TUYỆT ĐỐI KHÔNG: commit, push, merge, tạo PR, deploy; sửa backend; đưa họ tên/ảnh học sinh thật vào test.

KẾT THÚC: báo cáo tổng hợp bằng tiếng Việt (bước đã [x], bước dở và lý do, file đã đổi, kết quả kiểm tra,
ảnh chụp màn hình nếu có thể chụp từ web build).
```

Tiếp tục sau khi dừng: `Tiếp tục Phần B — Frontend theo docs/development/phase-7-prompts.md từ bước FE chưa [x] đầu tiên.`

## KHỐI CHUNG (áp dụng cho mọi bước)

```text
Bạn là AI agent phát triển repo He_Thong_QL_Diem (NestJS + Prisma/PostgreSQL, Flutter, FastAPI Python).

TRƯỚC KHI SỬA:
1. Đọc AGENTS.md, docs/development/CONTINUE.md, docs/development/phase-7-nhan-dang-ghep-hoc-sinh.md
   (mục 0 và Phần tương ứng với bước), docs/adr/0015-recognition-row-matching.md (nếu đã có).
2. Chạy `git status` và `git branch --show-current`. Phải đứng trên nhánh
   codex/recognition-row-matching (trừ bước BE-00 tạo nhánh). Không ghi đè thay đổi chưa commit của người dùng.
3. Đọc dòng "Phụ thuộc" của bước được giao; mọi bước trong đó phải đã [x] ở mục Tiến độ. Nếu chưa, dừng và báo
   bước còn thiếu. Bước FE chỉ sửa apps/client_flutter (trừ khi prompt ghi khác); bước BE không sửa apps/client_flutter.

RÀNG BUỘC:
- Không sửa sơ đồ phân cấp chức năng; mọi thay đổi nằm trong nút 3.2, 4.1–4.9, 5.1–5.8.
- Không sửa migration đã tồn tại; thay đổi schema bằng migration mới.
- Không sửa tay packages/api_client_dart; đổi API thì chạy `pnpm api:export` rồi `pnpm client:generate`.
- Không đặt business rule trong controller hoặc widget Flutter.
- Không đưa họ tên/ảnh học sinh thật vào test, fixture, log, commit. Ảnh trong
  D:\HocTap\KhoaLuan\data\05_BANG_DIEM_GOC chỉ dùng thử local.
- Không commit, push, merge, deploy, reset hay seed lại DB development. DB test phải có tên kết thúc _test.
- Chỉ làm đúng phạm vi bước được giao.

ĐIỀU KIỆN DỪNG (dừng, ghi CONTINUE.md, báo người dùng, không đoán):
- Thiếu trọng số, ảnh mẫu, Docker/PostgreSQL test hoặc công cụ cần thiết.
- Test đỏ không rõ nguyên nhân sau 2 lần sửa.
- Gặp quyết định nghiệp vụ chưa có trong kế hoạch hoặc ADR-0015.

KẾT THÚC BƯỚC:
1. Chạy các lệnh kiểm tra của bước; ghi lại kết quả thật (không tuyên bố đạt nếu chưa chạy).
2. Thêm mục mới nhất ở đầu docs/development/CONTINUE.md: bước đã làm, file đổi, lệnh + kết quả, việc còn dở.
3. Đánh dấu [x] bước này (theo mã BE-xx/FE-xx) trong mục Tiến độ của docs/development/phase-7-prompts.md.
4. Báo cáo ngắn bằng tiếng Việt: file đã đổi, hành vi mới, lệnh kiểm tra + kết quả, rủi ro/chưa làm.
```

Lệnh kiểm tra tham chiếu (Windows dùng `pnpm.cmd`):
`pnpm check` · `pnpm test:db` · `pnpm test:integration` · `pnpm contracts:check` · `dart run melos run check` · `python -m unittest discover -s apps/recognition-service/tests`

---

## PHẦN A — BACKEND (BE)

Phạm vi: `database/`, `apps/api`, `apps/recognition-service`, `docs/`, `AGENTS.md`, `.env.example`, `README.md`. Sau mỗi bước đổi API phải chạy `pnpm api:export` và `pnpm client:generate` để FE dùng được.

#### A0. Chuẩn bị

### BE-00 — Tạo nhánh, ADR-0015, cập nhật bất biến

_Phụ thuộc: —. (Mục kế hoạch gốc: Phần 7.0.)_

```text
Mã bước: BE-00. Phụ thuộc (phải [x] trước): —.
Áp dụng KHỐI CHUNG (bỏ qua yêu cầu đứng trên nhánh, vì bước này tạo nhánh).

Nhiệm vụ:
1. Tạo nhánh codex/recognition-row-matching từ HEAD hiện tại.
2. Viết docs/adr/0015-recognition-row-matching.md theo mẫu các ADR hiện có, gồm:
   - Vấn đề: luu_ket_qua_nhan_dien gán dòng theo ORDER BY ma_hoc_sinh; 4 cách sắp học sinh khác nhau;
     declaredRows = sĩ số chặn lớp nhiều trang/dòng gạch. Mô phỏng seed: 10A1 sai 37/41 dòng.
   - Quyết định: hàm STT chung ở API; chốt danh sách lớp (STT → học sinh) khi tạo phiếu; bỏ số dòng khai báo;
     ghép dòng theo STT + họ tên đọc trên giấy; mức dòng = min(mức điểm, mức ghép); ghép thất bại → phiếu LOI;
     màn hình kiểm tra riêng tự mở; không sửa sơ đồ phân cấp chức năng.
   - Đánh đổi, kế hoạch migration, tiêu chí nghiệm thu (lấy từ mục BE-04–BE-06 và BE-10–BE-12 của kế hoạch).
3. Sửa bất biến 5 trong AGENTS.md thành: "Số dòng không do giáo viên khai báo. Mọi dòng có điểm phát hiện được
   phải ghép được với danh sách lớp đã chốt của phiếu; ghép thất bại thì dừng xử lý, yêu cầu ảnh khác, không đoán
   (ADR-0015)." Sửa mục "UC11–UC12" bước 1 và 4 của AGENTS.md cho khớp.
4. Thêm mục "Ghép dòng nhận dạng (ADR-0015)" vào docs/architecture/traceability.md.

Không sửa code.
Kiểm tra: pnpm format:check (hoặc prettier cho các file md đã đổi).
Hoàn tất khi: nhánh tồn tại, ADR-0015 + AGENTS.md + traceability đã cập nhật.
```

#### A1. Thứ tự STT chung (nút 3.2)

### BE-01 — Hàm STT chung ở API

_Phụ thuộc: BE-00. (Mục kế hoạch gốc: Phần 7.1.)_

```text
Mã bước: BE-01. Phụ thuộc (phải [x] trước): BE-00.
Áp dụng KHỐI CHUNG. Nút cây: 3.2.

Nhiệm vụ:
1. Tạo apps/api/src/common/student-order.ts. Chuyển compareStudentRows từ apps/api/src/common/catalog.ts sang
   (quy tắc: tên = từ cuối → họ tên đầy đủ → ma_hoc_sinh; Intl.Collator("vi", { sensitivity: "variant" })).
2. Xuất:
   - compareStudents(a, b)
   - classStudentOrder(students): Map<ma_hoc_sinh, stt> chỉ tính học sinh dang_theo_hoc, STT bắt đầu 1, theo lớp.
3. Sửa catalog.ts (buildStudentOrderNumbers) dùng hàm chung; kết quả stt_lop/stt_toan_truong không đổi.

Test: apps/api/test/student-order.test.ts với tên giả:
   tên khác nhau có dấu (An, Ánh, Bảo, Đạt), trùng tên khác họ, trùng hoàn toàn họ tên (phân định bằng mã),
   học sinh nghỉ không có STT, hai lớp đánh STT độc lập.
Kiểm tra: pnpm check.
Hoàn tất khi: test mới đạt, test cũ của catalog không đổi kết quả.
```

### BE-02 — Trả STT trong API lưới điểm

_Phụ thuộc: BE-01. (Mục kế hoạch gốc: Phần 7.1.)_

```text
Mã bước: BE-02. Phụ thuộc (phải [x] trước): BE-01.
Áp dụng KHỐI CHUNG. Nút cây: 3.2.

Nhiệm vụ:
1. Thêm trường stt (integer, nullable) vào GradeCellDto (apps/api/src/modules/gradebooks/presentation/controller.ts)
   và vào dữ liệu trả từ store/service của GET /gradebooks/:id/cells. Tính bằng classStudentOrder (bước BE-01)
   cho lớp của bảng điểm; học sinh đã nghỉ trả null.
2. Không thay đổi phân trang, quyền, version.
3. pnpm api:export; pnpm client:generate.

Test: cập nhật integration test lưới điểm (apps/api/test/integration/gradebooks.test.ts) kiểm stt đúng thứ tự tên
khi thứ tự mã khác thứ tự tên.
Kiểm tra: pnpm check, pnpm contracts:check, pnpm test:integration (file gradebooks).
```

### BE-03 — Báo cáo dùng STT chung

_Phụ thuộc: BE-01. (Mục kế hoạch gốc: Phần 7.1.)_

```text
Mã bước: BE-03. Phụ thuộc (phải [x] trước): BE-01.
Áp dụng KHỐI CHUNG. Nút cây: 3.2 (ảnh hưởng 6.7).

Nhiệm vụ:
1. apps/api/src/modules/reports/application/service.ts: bỏ compareVietnameseNames; summary và export.xlsx
   sắp học sinh theo STT từ classStudentOrder; cột STT trong Excel lấy đúng STT này.
2. Xóa code/test chỉ phục vụ compareVietnameseNames nếu không còn dùng.

Test: cập nhật test report/export để kiểm thứ tự theo STT, có ca trùng họ tên.
Kiểm tra: pnpm check, pnpm test:integration (file liên quan reports/final-results).
```

#### A2. Database: chốt danh sách lớp (nút 4.2)

### BE-04 — Migration: bảng danh sách phiếu và cột mới

_Phụ thuộc: BE-00. (Mục kế hoạch gốc: Phần 7.2.)_

```text
Mã bước: BE-04. Phụ thuộc (phải [x] trước): BE-00.
Áp dụng KHỐI CHUNG. Nút cây: 4.2.

Nhiệm vụ: tạo migration mới database/migrations/<yyyyMMddHHmm>_recognition_roster_snapshot/migration.sql
1. Bảng kỹ thuật danh_sach_phieu(ma_phieu bigint FK phieu_nhan_dien, stt integer CHECK > 0,
   ma_hoc_sinh integer FK hoc_sinh, ho_ten varchar(100) NOT NULL, PRIMARY KEY(ma_phieu, stt),
   UNIQUE(ma_phieu, ma_hoc_sinh)). Trigger chặn UPDATE/DELETE (theo mẫu chan_sua_lich_su).
   Role runtime chỉ SELECT, không INSERT/UPDATE/DELETE trực tiếp.
2. ket_qua_dong thêm cột NULL: stt_giay integer, ho_ten_doc_duoc varchar(150), do_tin_cay_ghep numeric(5,4)
   CHECK 0..1, duong_dan_anh_o_ten varchar(512), ghi_chu_ghep varchar(200).
3. Sửa CHECK phieu_luoi: phiếu CHO_DOI_CHIEU/DA_DUYET cần so_dong_nhan_dien BETWEEN 1 AND so_dong_khai_bao.
   Ghi chú: so_dong_khai_bao từ nay = sĩ số snapshot.
4. Ghi hướng rollback ở đầu file.
5. Cập nhật database/prisma/schema.prisma; pnpm db:generate.

Không đổi hàm SQL trong bước này.
Test: database/tests/constraints.test.ts thêm kiểm append-only và quyền runtime trên danh_sach_phieu.
Kiểm tra: chạy migration trên DB rỗng *_test và nâng cấp DB *_test gần nhất; pnpm test:db; pnpm check.
```

### BE-05 — Migration: hàm tạo phiếu nhận danh sách lớp

_Phụ thuộc: BE-01, BE-04. (Mục kế hoạch gốc: Phần 7.2.)_

```text
Mã bước: BE-05. Phụ thuộc (phải [x] trước): BE-01, BE-04.
Áp dụng KHỐI CHUNG. Nút cây: 4.2.

Nhiệm vụ: migration mới thay hàm tao_phieu_nhan_dien:
1. Signature mới: (p_phien text, p_book integer, p_component integer, p_checksum text, p_object_key text,
   p_roster jsonb, p_idempotency_key text, p_request_hash text). Giữ nguyên toàn bộ kiểm tra cũ (phiên, phân công,
   trạng thái bảng, lịch nhập, cột khóa, môn định tính, rate limit, idempotency, outbox, audit) — đọc bản cũ trong
   202609110001_recognition_upload_outbox và các migration sau đã thay thế nó.
2. Bỏ p_declared_rows và kiểm tra "bằng sĩ số".
3. Kiểm p_roster = mảng {stt, studentId, fullName}: mọi studentId thuộc lớp của bảng điểm và dang_theo_hoc;
   stt liên tục 1..n; không trùng; n = sĩ số đang học. Sai → RAISE 'INVALID_ROSTER_SNAPSHOT' (23514).
4. Ghi danh_sach_phieu; so_dong_khai_bao = n.
5. DROP hàm cũ (signature cũ), REVOKE/GRANT như bản cũ.

Chưa đổi API trong bước này (API sẽ đổi ở BE-07); nếu build/test API gãy do signature, tạm cập nhật store gọi hàm mới
với roster tính bằng classStudentOrder — ghi rõ trong báo cáo.
Test: database tests/integration cho roster hợp lệ, sai lớp, học sinh nghỉ, STT không liên tục, trùng.
Kiểm tra: pnpm test:db, pnpm test:integration (recognition-upload), pnpm check.
```

### BE-06 — Migration: lưu kết quả tra học sinh theo danh sách đã chốt

_Phụ thuộc: BE-05. (Mục kế hoạch gốc: Phần 7.2.)_

```text
Mã bước: BE-06. Phụ thuộc (phải [x] trước): BE-05.
Áp dụng KHỐI CHUNG. Nút cây: 4.4, 5.7.

Nhiệm vụ: migration mới thay luu_ket_qua_nhan_dien(p_ticket, p_model_version, p_rows):
1. Mỗi row có: order (vị trí trên ảnh, 1..k, không trùng), stt (STT hệ thống đã ghép), các trường cũ, và thêm
   sttOnPaper, nameRead, matchConfidence, matchNote, nameCropKey (regex recognition/crops/<ticket>/<n>-name.png).
2. Tra ma_hoc_sinh từ danh_sach_phieu theo (ticket, stt). STT không có trong snapshot hoặc trùng giữa các row →
   'MALFORMED_RECOGNITION_RESULT'. BỎ hoàn toàn ORDER BY ma_hoc_sinh OFFSET.
3. Cho phép số row từ 1 đến so_dong_khai_bao. so_dong_nhan_dien = số row.
4. Lưu các cột mới của ket_qua_dong.
5. Giữ idempotent (phiếu đã CHO_DOI_CHIEU/DA_DUYET thì RETURN), serializable, audit.

Test (dữ liệu giả): thứ tự mã ≠ thứ tự tên → gán đúng; thêm học sinh mới / cho nghỉ học SAU khi tạo phiếu → ánh xạ
không đổi; stt ngoài snapshot bị từ chối; duyệt (duyet_phieu_nhan_dien) ghi điểm đúng học sinh.
Kiểm tra: pnpm test:db, pnpm test:integration.
```

#### A3. API, contract, worker (nút 4.1, 4.2, 4.4)

### BE-07 — API upload bỏ số dòng khai báo, tạo snapshot

_Phụ thuộc: BE-05. (Mục kế hoạch gốc: Phần 7.3.)_

```text
Mã bước: BE-07. Phụ thuộc (phải [x] trước): BE-05.
Áp dụng KHỐI CHUNG. Nút cây: 4.1, 4.2.

Nhiệm vụ:
1. apps/api/src/modules/recognition/presentation/controller.ts: declaredRows không còn required (đánh dấu
   deprecated, bỏ qua nếu client cũ gửi). Cập nhật schema multipart OpenAPI.
2. application/service.ts + infrastructure/prisma-store.ts: tính roster bằng classStudentOrder cho lớp của bảng
   điểm, gọi tao_phieu_nhan_dien signature mới. Request hash idempotency gồm gradebookId, componentId, checksum
   (không còn declaredRows).
3. pnpm api:export; pnpm client:generate.

Test: recognition-upload integration: upload không cần declaredRows; snapshot ghi đúng STT; replay idempotent.
Kiểm tra: pnpm check, pnpm contracts:check, pnpm test:integration.
```

### BE-08 — Contract dịch vụ nhận dạng và fake adapter

_Phụ thuộc: BE-00. (Mục kế hoạch gốc: Phần 7.3.)_

```text
Mã bước: BE-08. Phụ thuộc (phải [x] trước): BE-00.
Áp dụng KHỐI CHUNG. Nút cây: 4.4–4.9 (contract).

Nhiệm vụ (apps/recognition-service):
1. Request POST /v1/recognize: chỉ nhận image (multipart). declaredRows trở thành tùy chọn và bị bỏ qua.
   Dịch vụ KHÔNG nhận danh sách học sinh.
2. Response: { modelVersion, pageStartStt: int|null, rows: [ { rowIndex, struck: bool,
   stt: { raw, value:int|null, confidence }, name: { raw, confidence }, numeric: {...cũ}, written: {...cũ},
   numericCropBase64, writtenCropBase64, nameCropBase64, comparison, reviewLevel } ] }.
3. Fake adapter (chỉ development/test): trả 6 dòng mặc định, mỗi dòng giá trị điểm KHÁC nhau, STT liên tục từ
   FAKE_START_STT (mặc định 1), họ tên giả (vd "Học sinh 01") — cấu hình được dòng gạch qua FAKE_STRUCK_ROWS.
4. Cập nhật tests/test_api.py.

Kiểm tra: python -m unittest discover -s apps/recognition-service/tests.
```

### BE-09 — Phía API đọc contract mới và cấu hình thời gian chờ

_Phụ thuộc: BE-08. (Mục kế hoạch gốc: Phần 7.3.)_

```text
Mã bước: BE-09. Phụ thuộc (phải [x] trước): BE-08.
Áp dụng KHỐI CHUNG.

Nhiệm vụ:
1. apps/api/src/modules/recognition/infrastructure/http-model.ts: parse/validate contract mới (BE-08); dữ liệu sai
   → MALFORMED_RESPONSE. Không gửi declaredRows.
2. application/port.ts: cập nhật kiểu kết quả mô hình.
3. Timeout: RECOGNITION_TIMEOUT_MS trong apps/api/src/common/config.ts, mặc định 120000, giới hạn hợp lý;
   thêm vào .env.example.

Test: unit test contract (thiếu trường, kiểu sai, base64 hỏng, timeout, 503 MODEL_UNAVAILABLE).
Kiểm tra: pnpm check.
```

#### A4. Ghép dòng ↔ học sinh (nút 4.4, 4.9)

### BE-10 — Thuật toán ghép dòng ↔ học sinh (miền thuần)

_Phụ thuộc: BE-00. (Mục kế hoạch gốc: Phần 7.4.)_

```text
Mã bước: BE-10. Phụ thuộc (phải [x] trước): BE-00.
Áp dụng KHỐI CHUNG. Nút cây: 4.4, 4.9.

Nhiệm vụ: tạo apps/api/src/modules/recognition/domain/row-matching.ts (không import NestJS/Prisma):
1. Input: rows (rowIndex, struck, sttValue|null, sttConfidence, nameRaw, nameConfidence, hasGradeInk, hasNameInk)
   và roster [{stt, studentId, fullName}].
2. Bỏ dòng struck và dòng không mực ở cả ô điểm và ô tên.
3. Căn chỉnh quy hoạch động giữ thứ tự giữa rows và roster: điểm = độ giống họ tên chuẩn hóa (NFC, bỏ dấu,
   chữ thường, gộp khoảng trắng; 1 - khoảng cách sửa / độ dài) + thưởng khi sttValue khớp stt; khoảng trống
   đầu/cuối roster không phạt; khoảng trống giữa bị phạt.
4. Output mỗi row: stt, studentId, matchConfidence (0..1), matchLevel (XANH/VANG/DO), note.
   - Khớp cao (tên giống ≥ NAME_STRONG và STT không mâu thuẫn) → XANH.
   - Giống một phần hoặc trùng họ tên trong lớp → VANG.
   - Tên khớp dòng kề tốt hơn, hoặc STT mâu thuẫn → DO.
5. Thất bại → trả lỗi ROW_MATCH_FAILED khi: row có hasGradeInk nhưng không ghép được; hai row cùng studentId;
   tỷ lệ row DO > MAX_RED_RATIO.
6. Tất cả ngưỡng là hằng số có tên (NAME_STRONG, NAME_WEAK, MAX_RED_RATIO...) kèm chú thích
   "giá trị khởi điểm, dò lại ở bước BE-21–BE-22".
7. Hàm combineLevel(gradeLevel, matchLevel) = mức thấp hơn (DO < VANG < XANH).

Test apps/api/test/row-matching.test.ts (dữ liệu giả): đúng thứ tự; trang 2 bắt đầu STT 39; dòng gạch; giấy lệch
1 dòng; OCR sai 1–2 ký tự; trùng họ tên; không đọc được STT (chỉ tên); sai lớp → ROW_MATCH_FAILED; hai row cùng
học sinh → lỗi.
Kiểm tra: pnpm check.
```

### BE-11 — Worker dùng thuật toán ghép

_Phụ thuộc: BE-06, BE-07, BE-09, BE-10. (Mục kế hoạch gốc: Phần 7.4.)_

```text
Mã bước: BE-11. Phụ thuộc (phải [x] trước): BE-06, BE-07, BE-09, BE-10.
Áp dụng KHỐI CHUNG. Nút cây: 4.4, 4.9.

Nhiệm vụ:
1. apps/api/src/modules/recognition/application/worker.ts: bỏ kiểm detectedRows === declaredRows và
   row.order === index+1. Đọc snapshot danh_sach_phieu của phiếu (qua store), gọi row-matching.
2. ROW_MATCH_FAILED → danh_dau_phieu_nhan_dien_loi(ticket, 'ROW_MATCH_FAILED'); không ghi kết quả.
3. Thành công: reviewLevel cuối = combineLevel(mức điểm, mức ghép); lưu ảnh ô họ tên
   recognition/crops/<ticket>/<rowIndex>-name.png; gọi luu_ket_qua_nhan_dien mới. Upload ảnh lỗi thì dọn ảnh đã ghi
   như hiện tại.
4. Giữ idempotent khi job chạy lại.

Test integration (fake adapter BE-08): upload → worker → CHO_DOI_CHIEU, mỗi dòng đúng học sinh theo STT; dòng gạch
bị bỏ; FAKE_START_STT sai lớp → LOI ROW_MATCH_FAILED; diem_thanh_phan không bị ghi trước duyệt.
Kiểm tra: pnpm check, pnpm test:integration.
```

### BE-12 — API chi tiết phiếu trả thông tin ghép

_Phụ thuộc: BE-11. (Mục kế hoạch gốc: Phần 7.4.)_

```text
Mã bước: BE-12. Phụ thuộc (phải [x] trước): BE-11.
Áp dụng KHỐI CHUNG. Nút cây: 5.1, 5.2.

Nhiệm vụ:
1. RecognitionTicketDetail/RecognitionEvidenceRow thêm: stt, sttOnPaper, nameRead, nameCropUrl (signed URL 300s
   như ảnh ô điểm), matchConfidence, matchNote. Sắp dòng theo stt.
2. Danh sách phiếu: thêm số dòng nhận dạng, số Xanh/Vàng/Đỏ (nếu đơn giản) và errorCode.
3. pnpm api:export; pnpm client:generate.

Test: integration chi tiết phiếu có trường mới; IDOR (giáo viên khác/học sinh) vẫn bị chặn.
Kiểm tra: pnpm check, pnpm contracts:check, pnpm test:integration.
```

#### A5. Dịch vụ nhận dạng: pipeline ảnh (nút 4.3–4.5)

### BE-13 — Port kiểm định ảnh và nắn trang

_Phụ thuộc: BE-08. (Mục kế hoạch gốc: Phần 7.6.)_

```text
Mã bước: BE-13. Phụ thuộc (phải [x] trước): BE-08.
Áp dụng KHỐI CHUNG. Nút cây: 4.3, 4.4.

Nguồn (ngoài repo): D:\HocTap\KhoaLuan\App\KLCN_2026\07_CONG_CU_VA_SCRIPT\label_tool\kiem_dinh_anh.py,
tien_xu_ly_v3.py. Nếu không đọc được thư mục nguồn → dừng và báo.

Nhiệm vụ (apps/recognition-service/src/pipeline/):
1. quality.py ← danh_gia_chat_luong, do_net (+ hằng số ngưỡng). Trả mã lỗi IMAGE_QUALITY_LOW kèm chi tiết.
2. page.py ← các hàm cần cho nan_trang (mẫu bất kỳ) của tien_xu_ly_v3: đọc ảnh (bỏ HEIC nếu không cần), dò giấy,
   nắn theo lưới, nắn cong. BỎ QUAD_OVERRIDES và mọi tham số ten_file. Giữ tất định.
3. Chỉ dùng OpenCV + NumPy; thêm opencv-python-headless, numpy vào pyproject.toml.
4. Ghi nguồn gốc (file + hàm) ở docstring mỗi module.

Test: tests/test_pipeline_page.py với ảnh tổng hợp sinh bằng code (bảng kẻ trên nền giấy, xoay 5°, phối cảnh nhẹ):
trang nắn có vạch ngang gần thẳng; ảnh mờ → IMAGE_QUALITY_LOW.
Kiểm tra: python -m unittest discover -s apps/recognition-service/tests.
```

### BE-14 — Port dò lưới và định danh cột

_Phụ thuộc: BE-13. (Mục kế hoạch gốc: Phần 7.6.)_

```text
Mã bước: BE-14. Phụ thuộc (phải [x] trước): BE-13.
Áp dụng KHỐI CHUNG. Nút cây: 4.4, 4.5.

Nguồn: ...\label_tool\luoi_tong_quat.py.

Nhiệm vụ: apps/recognition-service/src/pipeline/grid.py
1. Port trich_luoi, cot_cua_hang, cat_o, doc_hang_tieu_de, dinh_danh_cot, chon_cot_diem, kiem_tra_la_bang_diem,
   khop_tu_khoa, bo_dau.
2. OCR tiêu đề nhận qua tham số hàm (callable) — KHÔNG import easyocr/tesseract/vietocr ở đây, không tải gì từ mạng.
   Không có OCR thì dùng đường lui hình học.
3. Bổ sung TU_KHOA cấp 3: ma_hs (mahs, mahocsinh), diem_qua_trinh (kiemtra15phut, mieng, ddgtx), diem_so
   (ddggk, ddgck, giuaky, cuoiky), ho_ten (hotenhocsinh).
4. Mã lỗi: GRID_NOT_FOUND, NOT_A_GRADEBOOK, SCORE_COLUMN_NOT_FOUND.

Test: ảnh tổng hợp có tiêu đề in "STT | Họ và tên | Đ.số | Điểm chữ", OCR giả trả đúng chữ tiêu đề → định danh
đúng 4 cột; OCR None → đường lui chọn cột hẹp làm điểm số.
Kiểm tra: python tests.
```

### BE-15 — Tách dòng, dòng gạch, cắt ô

_Phụ thuộc: BE-14. (Mục kế hoạch gốc: Phần 7.6.)_

```text
Mã bước: BE-15. Phụ thuộc (phải [x] trước): BE-14.
Áp dụng KHỐI CHUNG. Nút cây: 4.4, 4.5.

Nguồn: ...\label_tool\nhan_dang_ca_to.py (_la_gach_ngang, _suy_stt_bat_dau, _quy_ve_hang_cat),
tien_xu_ly_v3.do_dam_muc.

Nhiệm vụ: apps/recognition-service/src/pipeline/rows.py
1. Từ lưới + cột đã định danh, sinh danh sách dòng dữ liệu: rowIndex, ảnh ô STT, Họ tên, Đ.số, Điểm chữ,
   struck, hasGradeInk, hasNameInk.
2. pageStartStt(stt_doc_duoc_theo_dong) theo _suy_stt_bat_dau (bỏ phiếu, chịu lỗi OCR).
3. Hàm analyze_page(image_bytes, ocr=None) -> PageAnalysis gom BE-13–BE-15.

Test: ảnh tổng hợp 10 dòng, 1 dòng gạch, 1 dòng trống → struck/hasGradeInk đúng; pageStartStt với dữ liệu có 2 giá
trị đọc sai vẫn ra đúng.
Kiểm tra: python tests.
```

### BE-16 — Thử local trên ảnh mẫu (chỉ báo cáo)

_Phụ thuộc: BE-15. (Mục kế hoạch gốc: Phần 7.6.)_

```text
Mã bước: BE-16. Phụ thuộc (phải [x] trước): BE-15.
Áp dụng KHỐI CHUNG. Không commit ảnh hay kết quả có tên học sinh.

Nhiệm vụ:
1. Viết script local scripts/recognition/try_pipeline.py (không chạy trong CI) nhận thư mục ảnh, chạy analyze_page,
   in tóm tắt: số dòng, cột định danh được, số dòng gạch, thời gian. Không in họ tên.
2. Chạy trên 80 ảnh P01–P04 trong D:\HocTap\KhoaLuan\data_BANG_DIEM_GOC (BAN_PHONE và BAN_SCAN).
3. So sánh với JSON tham chiếu trong D:\HocTap\KhoaLuan\data_ANH_O_CAT\BAN_1_THEO_LINE_A4.

Tiêu chí đạt (chủ dự án chốt, thay tiêu chí "tách đúng ≥ 80% số dòng"): đo số dòng CÓ ĐIỂM so với tham chiếu
(dòng trống thừa được chấp nhận vì bước ghép đã bỏ UNMATCHED_BLANK). Đạt khi: trang 1 vẫn 100%; trang 2 không còn
GRID_NOT_FOUND trên ảnh rõ; tổng tỷ lệ đúng số dòng có điểm ≥ 95%; không ảnh nào THIẾU dòng có điểm.
Báo cáo tách riêng: trang 1 / trang 2, phone / scan, thừa dòng trống / thiếu dòng / GRID_NOT_FOUND.
Sau 2 lần điều chỉnh vẫn không đạt → dừng, báo số liệu và nguyên nhân, không hạ tiêu chí.

Ghi kết quả tổng hợp vào CONTINUE.md.
```

#### A6. Dịch vụ nhận dạng: mô hình (nút 4.6–4.8)

### BE-17 — Adapter CRNN

_Phụ thuộc: BE-08. (Mục kế hoạch gốc: Phần 7.7.)_

```text
Mã bước: BE-17. Phụ thuộc (phải [x] trước): BE-08.
Áp dụng KHỐI CHUNG. Nút cây: 4.6.

Nguồn: ...\ket_hop\suy_luan_hai_mo_hinh.py (class CRNN, tien_xu_ly_anh, decode_ctc_voi_do_tin_cay).

Nhiệm vụ: apps/recognition-service/src/adapters/crnn.py
1. Sao chép đúng kiến trúc CRNN, CHARSET ['.','0'..'9'], blank 0, tiền xử lý 32×128 xám, pad trắng giữa,
   chuẩn hóa (x/255-0.5)/0.5, giải mã greedy + conf_mean.
2. load(path, expected_sha256): kiểm SHA-256; torch.load(map_location, weights_only=True); lấy
   model_state_dict. Không nạp được với weights_only=True → raise ModelUnavailableError (không hạ xuống False).
3. read_cells(images) theo lô; dùng cho ô Đ.số và ô STT (STT: chỉ chấp nhận số nguyên).
4. Thêm torch, torchvision vào pyproject.toml.

Test: sai hash → ModelUnavailableError; test nạp thật skip khi biến RECOGNITION_CRNN_WEIGHTS không có.
Thử local với D:\HocTap\KhoaLuan\App\weights\crnn_num_best_dot5.pth (ghi hash vào báo cáo).
Kiểm tra: python tests.
```

### BE-18 — Adapter VietOCR và đổi chữ thành số

_Phụ thuộc: BE-08. (Mục kế hoạch gốc: Phần 7.7.)_

```text
Mã bước: BE-18. Phụ thuộc (phải [x] trước): BE-08.
Áp dụng KHỐI CHUNG. Nút cây: 4.7.

Nguồn: ...\ket_hop\vietocr_vgg_seq2seq.yml, suy_luan_hai_mo_hinh.nap_cau_hinh_vietocr, hop_nhat.py,
cau_hinh_hop_nhat.json.

Nhiệm vụ:
1. Copy vietocr_vgg_seq2seq.yml vào apps/recognition-service/src/adapters/ (cấu hình, không phải trọng số).
2. src/adapters/vietocr_reader.py: cfg image_height 32, min 32, max 384, beamsearch False, cnn.pretrained False,
   weights = đường dẫn local; kiểm SHA-256; tuyệt đối không tải gì từ Internet (pretrain/weights URL trong yml phải
   bị ghi đè). read_cells(images) -> [(text NFC, prob)]. Dùng cho ô Điểm chữ và ô Họ tên.
3. src/domain/written_grade.py ← so_tu_chuoi_so, so_tu_chuoi_chu, hau_xu_ly_tu_dien + từ điển 133 cụm.
4. pyproject: vietocr==0.3.13 (ghi chú cài --no-deps), einops, pyyaml, pillow.

Test: written_grade (tám rưỡi → 8.5, mười → 10.0, chín chẵn → 9.0, sai → None); adapter skip khi không có weights.
Thử local với vietocr_best_tang4.pth.
Kiểm tra: python tests.
```

### BE-19 — Phân loại hai kênh và nối mô hình thật

_Phụ thuộc: BE-12, BE-15, BE-17, BE-18. (Mục kế hoạch gốc: Phần 7.7.)_

```text
Mã bước: BE-19. Phụ thuộc (phải [x] trước): BE-12, BE-15, BE-17, BE-18.
Áp dụng KHỐI CHUNG. Nút cây: 4.8, 4.9.

Nhiệm vụ:
1. src/domain/classification.py: ngưỡng riêng RECOGNITION_NUMERIC_THRESHOLD (mặc định 0.95) và
   RECOGNITION_WRITTEN_THRESHOLD (0.90). Không dùng nhánh trọng tài chọn giá trị của hop_nhat khi cả hai yếu
   (Đỏ không gợi ý giá trị).
2. src/adapters/model.py: WeightsRecognitionModel = analyze_page (BE-13–BE-15) + CRNN (Đ.số, STT) + VietOCR (Điểm chữ,
   Họ tên) + written_grade + classification; trả contract 7.3b. configured_model mode weights đọc
   RECOGNITION_CRNN_WEIGHTS, RECOGNITION_CRNN_SHA256, RECOGNITION_VIETOCR_WEIGHTS, RECOGNITION_VIETOCR_SHA256;
   thiếu/sai → MODEL_UNAVAILABLE. modelVersion = "crnn-dot5+vietocr-tang4:<12 ký tự hash>".
3. Lỗi pipeline (IMAGE_QUALITY_LOW, GRID_NOT_FOUND, ...) trả HTTP 422 với mã lỗi; worker đánh dấu phiếu LOI đúng mã
   (cập nhật http-model.ts/worker.ts nếu cần).
4. Cập nhật .env.example, README (mục nhận dạng), docs/development/recognition-checkpoints.md.

Test: classification theo ngưỡng mới; configured_model các nhánh; API trả 422 có mã.
Kiểm tra: python tests; pnpm check.
```

#### A7. Kiểm thử đầu-cuối và mẫu cấp 3 (cần FE xong)

### BE-20 — Chạy đầu-cuối local và đo hiệu năng

_Phụ thuộc: BE-19, FE-01 → FE-05. (Mục kế hoạch gốc: Phần 7.8.)_

```text
Mã bước: BE-20. Phụ thuộc (phải [x] trước): BE-19, FE-01 → FE-05.
Áp dụng KHỐI CHUNG.

Nhiệm vụ:
1. Khởi động đủ stack theo README: API, recognition-service mode weights (đường dẫn + hash trọng số thật),
   dispatcher, worker, web.
2. Dùng DB *_test riêng hoặc lớp giả trong DB development đã sao lưu (không sửa dữ liệu thật). Tạo bảng điểm có lịch
   nhập đang mở.
3. Thử 3–5 ảnh mẫu E0330113: đo thời gian/phiếu, số dòng ghép được, số Xanh/Vàng/Đỏ, có tự mở màn hình kiểm tra.
4. Đặt RECOGNITION_TIMEOUT_MS theo đo thực tế (≥ 2 lần thời gian lớn nhất).
5. Ghi kết quả tổng hợp (không tên học sinh) vào CONTINUE.md.

Hoàn tất khi: luồng chụp → tự mở màn hình kiểm tra → duyệt → điểm vào đúng học sinh chạy được local.
```

### BE-21 — Bộ dữ liệu thay thế và thử mẫu bố cục khác

_Phụ thuộc: BE-20. (Mục kế hoạch gốc: Phần 7.9.) Cập nhật 2026-10-07: chủ dự án CHƯA có ảnh bảng điểm cấp 3 thật,
dùng dữ liệu thay thế dưới đây. Mục tiêu chính là độ chính xác hai kênh ĐIỂM SỐ và ĐIỂM CHỮ; STT không phải mục tiêu._

```text
Mã bước: BE-21. Phụ thuộc (phải [x] trước): BE-20.
Áp dụng KHỐI CHUNG.

DỮ LIỆU (chỉ đọc, không commit, không in họ tên):
- Tập DEV (dò ngưỡng) = người viết của tập valid nghiên cứu: P05, R03 trong
  D:\HocTap\KhoaLuan\data\05_BANG_DIEM_GOC\BAN_PHONE|BAN_SCAN\PERSON_<người>; nhãn ô trong
  D:\HocTap\KhoaLuan\data\MOI\valid\manifest_val_num.csv và manifest_val_txt.csv.
- Tập TEST (chỉ đo, không dùng chọn tham số) = người viết chưa từng dùng huấn luyện: P08, R04, R05 trong
  D:\HocTap\KhoaLuan\data\du_lieu_moi\data\05_BANG_DIEM_GOC\BAN_PHONE|BAN_SCAN\PERSON_<người> (60 ảnh);
  nhãn trong D:\HocTap\KhoaLuan\data\MOI\test\manifest_test_num.csv và manifest_test_txt.csv.
- Không dùng P01–P04, P06, P07, R01, R02 để đo (đã dùng huấn luyện/chỉnh thuật toán).
- Thiếu thư mục hoặc nhãn → dừng và báo.

NHIỆM VỤ:
1. Viết scripts/recognition/evaluate_pages.py (chạy cục bộ, không chạy trong CI): chạy toàn bộ pipeline + mô hình
   thật trên từng ảnh trang, ghép kết quả với nhãn theo (người, tờ, trang, stt), báo cho từng kênh: tỷ lệ đúng,
   phân bố độ tin cậy, số dòng Xanh/Vàng/Đỏ, số dòng Xanh SAI (lỗi im lặng), tách phone/scan. Không in họ tên.
2. Chạy trên DEV và TEST với ngưỡng hiện tại (0.95/0.90); ghi số liệu vào CONTINUE.md.
3. Thử bố cục khác: tạo bằng code 3–5 ảnh tổng hợp mô phỏng phiếu cấp 3
   (STT | Họ và tên | Ngày sinh | Đ.số | Điểm chữ | Ghi chú, họ tên giả, chữ viết tay mô phỏng bằng font) để kiểm
   định danh cột và cắt ô đúng; thêm vào test Python. Ảnh này chỉ kiểm cấu trúc, KHÔNG dùng để dò ngưỡng.
4. Ghi rõ trong ADR-0015 mục "Giới hạn đánh giá": đánh giá trên mẫu E0330113 của trường đại học và ảnh tổng hợp
   mô phỏng bố cục cấp 3; chưa đánh giá trên bảng điểm cấp 3 thật. Phiếu dùng với hệ thống phải có cột Đ.số và
   cột Điểm chữ.
```

### BE-22 — Dò và khóa ngưỡng hai kênh, hoàn thiện tài liệu

_Phụ thuộc: BE-21. (Mục kế hoạch gốc: Phần 7.9.)_

```text
Mã bước: BE-22. Phụ thuộc (phải [x] trước): BE-21.
Áp dụng KHỐI CHUNG.

NHIỆM VỤ:
1. Dò ngưỡng hai kênh (RECOGNITION_NUMERIC_THRESHOLD, RECOGNITION_WRITTEN_THRESHOLD) CHỈ trên tập DEV của BE-21
   theo lưới 0.70–1.00 bước 0.01. Tiêu chí theo thứ tự ưu tiên: (1) không có dòng Xanh sai trên DEV;
   (2) độ chính xác giá trị cuối cao nhất; (3) ít dòng Vàng/Đỏ nhất; (4) hòa thì chọn ngưỡng cao hơn.
   Ngưỡng ghép tên (NAME_STRONG, NAME_WEAK, MAX_RED_RATIO) chỉ chỉnh nếu số liệu DEV cho thấy ghép sai/dư Đỏ.
2. Khóa ngưỡng vào code/.env.example; đo MỘT LẦN trên TEST và báo: độ chính xác từng kênh, độ chính xác giá trị cuối,
   % Xanh/Vàng/Đỏ, số dòng Xanh sai, phone/scan. Không chỉnh ngưỡng sau khi đã xem TEST.
3. Ghi kết quả và giới hạn đánh giá vào ADR-0015; cập nhật README, docs/ux/recognition-capture.md (hướng dẫn chụp,
   yêu cầu phiếu có cột Đ.số và Điểm chữ), docs/architecture/traceability.md, recognition-checkpoints.md.
4. Chạy toàn bộ: pnpm check, pnpm test:db, pnpm test:integration, pnpm contracts:check, dart run melos run check,
   Python tests. Chuẩn bị mô tả PR nhưng KHÔNG tạo PR/push nếu người dùng chưa yêu cầu.
```

---

## PHẦN B — FRONTEND (FE)

Phạm vi: `apps/client_flutter` (và test Flutter). Không sửa backend; thiếu trường API thì dừng và báo bước BE tương ứng.

### FE-01 — Flutter lưới điểm dùng STT từ API

_Phụ thuộc: BE-02. (Mục kế hoạch gốc: Phần 7.1.)_

```text
Mã bước: FE-01. Phụ thuộc (phải [x] trước): BE-02.
Áp dụng KHỐI CHUNG. Nút cây: 3.2.

Nhiệm vụ:
1. apps/client_flutter/lib/features/gradebooks/gradebook_screen.dart: bỏ sắp học sinh bằng
   VietnameseCollation.compareStudentNames (khoảng dòng 385–400); sắp theo stt từ GradeCellDto, học sinh
   stt null (đã nghỉ) xếp cuối. Cột STT (desktop) và nhãn "STT n" (mobile) hiển thị stt từ API.
2. Giữ vietnamese_sort.dart cho các danh sách khác (giáo viên, môn, tìm kiếm).
3. Kiểm excel_import_dialog.dart: mẫu Excel tải về dùng STT từ API.

Test: widget test trong test/phase2_gradebooks_test.dart (hoặc file mới) với dữ liệu giả có thứ tự mã ≠ thứ tự
tên: lưới hiển thị đúng STT từ API.
Kiểm tra: dart run melos run check.
```

### FE-02 — Khối nhận dạng: bỏ số dòng khai báo

_Phụ thuộc: BE-07, BE-09. (Mục kế hoạch gốc: Phần 7.5.)_

```text
Mã bước: FE-02. Phụ thuộc (phải [x] trước): BE-07, BE-09.
Áp dụng KHỐI CHUNG. Nút cây: 4.1, 4.2.

Nhiệm vụ (apps/client_flutter/lib/features/recognition/recognition_panel.dart, gradebook_screen.dart):
1. Bỏ tham số/hiển thị "Số dòng khai báo"; repository không gửi declaredRows.
2. Đổi dòng hướng dẫn thành: "Chụp thẳng toàn bộ bảng, đủ sáng, rõ các cột STT, Họ tên, Điểm số, Điểm chữ.
   PNG hoặc JPEG, tối đa 10 MB. Hệ thống tự xác định học sinh theo STT và họ tên."
3. Hiển thị lỗi ROW_MATCH_FAILED: "Không xác định được học sinh cho một số dòng. Kiểm tra đúng lớp và chụp lại rõ
   cột STT, Họ tên."

Test: cập nhật recognition_upload_ux_test.dart, phase3_recognition_test.dart.
Kiểm tra: dart run melos run check.
```

### FE-03 — Màn hình kiểm tra riêng (route mới)

_Phụ thuộc: FE-02. (Mục kế hoạch gốc: Phần 7.5.)_

```text
Mã bước: FE-03. Phụ thuộc (phải [x] trước): FE-02.
Áp dụng KHỐI CHUNG. Nút cây: 5.1–5.8.

Nhiệm vụ:
1. Tạo apps/client_flutter/lib/features/recognition/review_screen.dart: chuyển nội dung _RecognitionDetailDialog
   (recognition_panel.dart, khoảng dòng 573–1060) thành màn hình riêng; giữ nguyên logic duyệt (version,
   idempotency, phải xem mọi dòng, Đỏ không điền sẵn, làm mới signed URL).
2. Route /gradebooks/:id/recognition/:ticketId trong app/app.dart; học sinh bị chặn như /gradebooks.
3. Danh sách phiếu trong khối nhận dạng mở màn hình này thay cho dialog.
4. Duyệt xong quay về bảng điểm và tải lại.

Test widget: mở màn hình từ danh sách phiếu; duyệt gửi đúng request; HS bị redirect.
Kiểm tra: dart run melos run check.
```

### FE-04 — Tự chuyển sang màn hình kiểm tra

_Phụ thuộc: FE-03, BE-12. (Mục kế hoạch gốc: Phần 7.5.)_

```text
Mã bước: FE-04. Phụ thuộc (phải [x] trước): FE-03, BE-12.
Áp dụng KHỐI CHUNG. Nút cây: 4.2 → 5.1.

Nhiệm vụ:
1. Sau khi gửi ảnh, khối nhận dạng hiển thị tiến độ (polling 3 giây hiện có).
2. Phiếu vừa gửi chuyển CHO_DOI_CHIEU → tự điều hướng tới /gradebooks/:id/recognition/:ticketId
   (chỉ khi người dùng vẫn đang ở màn bảng điểm đó).
3. Phiếu LOI → hiện lý do theo errorCode và nút "Chụp lại".
4. Thẻ "OCR chờ duyệt" ở trang chủ giáo viên dẫn tới bảng điểm có phiếu chờ (nếu API có sẵn dữ liệu; không thì ghi
   lại trong CONTINUE.md, không tự thêm API ngoài kế hoạch).

Test widget: trạng thái DANG_XU_LY → CHO_DOI_CHIEU tự điều hướng; LOI hiện lý do; rời màn hình thì không điều hướng.
Kiểm tra: dart run melos run check.
```

### FE-05 — Hiển thị thông tin ghép học sinh

_Phụ thuộc: FE-03, BE-12. (Mục kế hoạch gốc: Phần 7.5.)_

```text
Mã bước: FE-05. Phụ thuộc (phải [x] trước): FE-03, BE-12.
Áp dụng KHỐI CHUNG. Nút cây: 5.1–5.3.

Nhiệm vụ trong review_screen.dart:
1. Mỗi dòng: STT, tên hệ thống gán, ảnh ô họ tên trên giấy (nameCropUrl, phóng to được), ảnh Đ.số/Điểm chữ,
   hai kênh + độ tin cậy, matchNote, màu cuối.
2. Mặc định hiện Vàng/Đỏ trước; bộ lọc 3 màu; sắp theo STT.
3. Responsive 320/390/1280, chữ 130%.

Test widget: ảnh họ tên hiển thị; dòng Đỏ do ghép có ghi chú; lọc màu đúng.
Kiểm tra: dart run melos run check; flutter build web --dart-define-from-file=config/development.json.
```

---

## Tiến độ

### Phần A — Backend

- [x] BE-00 Tạo nhánh, ADR-0015, cập nhật bất biến
- [x] BE-01 Hàm STT chung ở API
- [x] BE-02 Trả STT trong API lưới điểm
- [x] BE-03 Báo cáo dùng STT chung
- [x] BE-04 Migration: bảng danh sách phiếu và cột mới
- [x] BE-05 Migration: hàm tạo phiếu nhận danh sách lớp
- [x] BE-06 Migration: lưu kết quả tra học sinh theo danh sách đã chốt
- [x] BE-07 API upload bỏ số dòng khai báo, tạo snapshot
- [x] BE-08 Contract dịch vụ nhận dạng và fake adapter
- [x] BE-09 Phía API đọc contract mới và cấu hình thời gian chờ
- [x] BE-10 Thuật toán ghép dòng ↔ học sinh (miền thuần)
- [x] BE-11 Worker dùng thuật toán ghép
- [x] BE-12 API chi tiết phiếu trả thông tin ghép
- [x] BE-13 Port kiểm định ảnh và nắn trang
- [x] BE-14 Port dò lưới và định danh cột
- [x] BE-15 Tách dòng, dòng gạch, cắt ô
- [x] BE-16 Thử local trên ảnh mẫu (chỉ báo cáo)
- [x] BE-17 Adapter CRNN
- [x] BE-18 Adapter VietOCR và đổi chữ thành số
- [x] BE-19 Phân loại hai kênh và nối mô hình thật
- [ ] BE-20 Chạy đầu-cuối local và đo hiệu năng
- [ ] BE-21 Bộ dữ liệu thay thế và thử mẫu bố cục khác
- [ ] BE-22 Dò và khóa ngưỡng hai kênh, hoàn thiện tài liệu

### Phần B — Frontend

- [x] FE-01 Flutter lưới điểm dùng STT từ API
- [x] FE-02 Khối nhận dạng: bỏ số dòng khai báo
- [x] FE-03 Màn hình kiểm tra riêng (route mới)
- [x] FE-04 Tự chuyển sang màn hình kiểm tra
- [x] FE-05 Hiển thị thông tin ghép học sinh

## Thứ tự đề xuất (khi dùng `continue`)

1. BE-00 → BE-01 → BE-02 → **FE-01**
2. BE-03 → BE-04 → BE-05 → BE-06 → BE-07 → BE-08 → BE-09 → **FE-02 → FE-03**
3. BE-10 → BE-11 → BE-12 → **FE-04 → FE-05**
4. BE-13 → BE-14 → BE-15 → BE-16 → BE-17 → BE-18 → BE-19
5. BE-20 → BE-21 (dữ liệu thay thế: DEV P05/R03, TEST P08/R04/R05) → BE-22
