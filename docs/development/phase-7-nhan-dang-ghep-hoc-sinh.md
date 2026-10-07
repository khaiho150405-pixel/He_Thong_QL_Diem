# Giai đoạn 7 — Nhận dạng tự động và ghép đúng học sinh

Kế hoạch chia nhỏ để AI agent (Codex hoặc agent khác) thực hiện tự động từng phần. **Prompt chi tiết, chia Phần A Backend (BE-xx) và Phần B Frontend (FE-xx), cùng mục Tiến độ chính thức nằm ở `docs/development/phase-7-prompts.md`; mục Tiến độ cuối file này chỉ để tham khảo.** Mỗi phần nhỏ, theo chiều dọc, kiểm thử được độc lập. Chủ dự án chốt phương án ngày 2026-10-06.

## 0. Bối cảnh bắt buộc đọc

### Mục tiêu

Giáo viên mở bảng điểm → chọn **Thành phần điểm** → chụp/chọn ảnh → gửi. Hệ thống tự nhận dạng Điểm số + Điểm chữ, **tự gán đúng từng học sinh**, rồi **tự mở màn hình kiểm tra riêng** để giáo viên đối chiếu và duyệt.

### Ràng buộc của chủ dự án

1. **Không sửa sơ đồ phân cấp chức năng** (nhánh 1–6). Mọi thay đổi nằm bên trong các nút hiện có: 3.2, 4.1–4.9, 5.1–5.8.
2. Trường cấp 3: giấy **không có mã học sinh**. Ghép học sinh dựa trên **STT và họ tên** in trên giấy.
3. Giữ nguyên bất biến AGENTS.md, trừ bất biến 5 được diễn giải lại ở phần 7.0 (ADR-0015).

### Lỗi gốc cần sửa

`luu_ket_qua_nhan_dien` (migration `202609120001_recognition_results`, dòng 49–53) gán dòng thứ n cho học sinh bằng `ORDER BY hs.ma_hoc_sinh OFFSET n-1`, trong khi giấy ghi theo STT (thứ tự tên). Mô phỏng trên dữ liệu seed: 10A1 sai 37/41 dòng, 10A2 29/41, 10A3 37/41. Fake adapter trả 8.0 cho mọi dòng nên lỗi không lộ.

Nguyên nhân phụ: có 4 cách sắp học sinh khác nhau — SQL (`ma_hoc_sinh`), `apps/api/src/common/catalog.ts` (`compareStudentRows`), `apps/api/src/modules/reports/application/service.ts` (`compareVietnameseNames`, không xét mã), Flutter `apps/client_flutter/lib/core/vietnamese_sort.dart` + `gradebook_screen.dart` (dòng ~390). Ứng dụng tự gửi `declaredRows` = sĩ số (`gradebook_screen.dart` ~516) và `tao_phieu_nhan_dien` bắt bằng sĩ số → lớp nhiều trang hoặc có dòng gạch không nhận dạng được.

### Nguồn thuật toán và trọng số (ngoài repo, KHÔNG commit)

| Thành phần                                | Đường dẫn trên máy chủ dự án                                                                                                                              |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Nắn ảnh mẫu bất kỳ                        | `D:\HocTap\KhoaLuan\App\KLCN_2026\07_CONG_CU_VA_SCRIPT\label_tool\tien_xu_ly_v3.py` (`nan_trang`, `nan_va_tach_luoi`, `do_dam_muc`)                       |
| Dò lưới + định danh cột theo tiêu đề      | `...\label_tool\luoi_tong_quat.py` (`trich_luoi`, `dinh_danh_cot`, `chon_cot_diem`, `cat_o`, `TU_KHOA`)                                                   |
| Phân tích cả tờ, suy STT trang, dòng gạch | `...\label_tool\nhan_dang_ca_to.py` (`phan_tich_trang`, `_suy_stt_bat_dau`, `_la_gach_ngang`, `nhan_dang_trang`)                                          |
| Kiểm định ảnh                             | `...\label_tool\kiem_dinh_anh.py` (`danh_gia_chat_luong`, `danh_gia_la_bang_diem`)                                                                        |
| CRNN + tiền xử lý + giải mã CTC           | `...\ket_hop\suy_luan_hai_mo_hinh.py` (class `CRNN`, `tien_xu_ly_anh`, `decode_ctc_voi_do_tin_cay`)                                                       |
| VietOCR cấu hình                          | `...\ket_hop\vietocr_vgg_seq2seq.yml`; `nap_cau_hinh_vietocr` (image_height 32, min 32, max 384, beamsearch False, cnn.pretrained False), vietocr==0.3.13 |
| Chữ → số, từ điển                         | `...\ket_hop\hop_nhat.py` (`so_tu_chuoi_so`, `so_tu_chuoi_chu`, `hau_xu_ly_tu_dien`), `...\ket_hop\cau_hinh_hop_nhat.json`                                |
| Ngưỡng hai kênh                           | `...\ket_hop\ket_qua\tang4\cau_hinh_hop_nhat_dev_co_mai.json`: τ số 0.95, τ chữ 0.90                                                                      |
| Trọng số dùng thật                        | `D:\HocTap\KhoaLuan\App\weights\crnn_num_best_dot5.pth`, `vietocr_best_tang4.pth`. **Không** dùng bản `*_dev.pth` (chỉ để dò ngưỡng).                     |
| Ảnh mẫu (có PII thật)                     | `D:\HocTap\KhoaLuan\data\05_BANG_DIEM_GOC` — chỉ dùng thử local, không commit, không đưa vào log/fixture                                                  |

### Quy tắc chung cho mọi phần

- Làm trên nhánh `codex/recognition-row-matching` (tạo ở 7.0). Không commit/push/merge/deploy trừ khi chủ dự án yêu cầu. Giữ thay đổi chưa commit của người dùng.
- Mỗi phần: migration → backend → `pnpm api:export` + `pnpm client:generate` → UI → test, khi phần đó cần đủ lớp.
- Không sửa migration đã chạy; tạo migration mới. Kiểm migration từ DB rỗng và nâng cấp từ DB test gần nhất (không dùng DB development đang có dữ liệu).
- Không sửa tay `packages/api_client_dart`.
- Không đặt business rule trong controller hoặc widget.
- Không đưa PII thật vào test fixture, snapshot, log.
- Kết thúc mỗi phần: chạy lệnh kiểm tra của phần đó, cập nhật `docs/development/CONTINUE.md` (mục mới nhất ở trên cùng) và đánh dấu ô tiến độ ở cuối file này.
- **Điều kiện dừng chung:** thiếu dữ liệu/trọng số/ảnh mẫu, test đỏ không rõ nguyên nhân sau 2 lần sửa, hoặc cần quyết định nghiệp vụ mới → dừng, ghi vào CONTINUE.md và báo chủ dự án. Không đoán.

### Lệnh kiểm tra (Windows dùng `pnpm.cmd`)

```sh
pnpm check                      # format, lint, typecheck, unit/HTTP, build
pnpm test:db                    # cần TEST_MIGRATION_URL/TEST_RUNTIME_URL trỏ DB *_test
pnpm test:integration           # PostgreSQL/Redis/MinIO thật
pnpm contracts:check            # OpenAPI ↔ Dart client không drift
dart run melos run check        # Flutter format/analyze/test
python -m unittest discover -s apps/recognition-service/tests
```

---

## Phần 7.0 — Chuẩn bị và ADR-0015

**Nút cây:** không đổi chức năng. **Loại:** tài liệu.

Việc làm:

1. Tạo nhánh `codex/recognition-row-matching` từ HEAD hiện tại.
2. Viết `docs/adr/0015-recognition-row-matching.md`: vấn đề (mục 0), quyết định (STT chung, snapshot danh sách khi tạo phiếu, ghép theo STT + họ tên, bỏ số dòng khai báo, màn hình kiểm tra riêng), đánh đổi, kế hoạch migration, tiêu chí nghiệm thu.
3. Sửa bất biến 5 trong `AGENTS.md`: "Số dòng không do giáo viên khai báo. Mọi dòng có điểm phát hiện được phải ghép được với danh sách lớp đã chốt của phiếu; ghép thất bại thì dừng xử lý, yêu cầu ảnh khác, không đoán." Ghi chú tham chiếu ADR-0015.
4. Thêm mục vào `docs/architecture/traceability.md`.

Tiêu chí xong: ADR, AGENTS.md, traceability cập nhật; `pnpm format:check` đạt.

---

## Phần 7.1 — Hàm STT chung (nút 3.2)

**Mục tiêu:** một nguồn STT duy nhất cho học sinh trong lớp.

Việc làm:

1. Tạo `apps/api/src/common/student-order.ts`: chuyển `compareStudentRows` từ `catalog.ts` sang; quy tắc **tên (từ cuối) → họ tên đầy đủ → ma_hoc_sinh**, `Intl.Collator("vi", { sensitivity: "variant" })`. Xuất `classStudentOrder(students) → Map<ma_hoc_sinh, stt>` (chỉ học sinh `dang_theo_hoc`).
2. `catalog.ts` dùng hàm chung (kết quả `stt_lop` không đổi).
3. API lưới điểm: thêm `stt` (số nguyên) vào `GradeCellDto` (`gradebooks/presentation/controller.ts`) và store; ô của học sinh đã nghỉ trả `stt: null`.
4. `reports/application/service.ts`: bỏ `compareVietnameseNames`, sắp theo `stt` từ hàm chung (summary + export Excel).
5. `pnpm api:export`, `pnpm client:generate`.
6. Flutter `gradebook_screen.dart`: bỏ sort bằng `VietnameseCollation` cho học sinh trong lớp; sắp và hiển thị theo `stt` từ API. Giữ `vietnamese_sort.dart` cho các danh sách khác.

Test:

- Unit `apps/api/test/student-order.test.ts`: dấu tiếng Việt, tên trùng (xét mã), họ tên trùng hoàn toàn, học sinh nghỉ không có STT.
- Cập nhật test report/xuất Excel cho thứ tự mới.
- Widget test lưới điểm hiển thị đúng STT từ API.

Tiêu chí xong: `pnpm check`, `pnpm contracts:check`, `dart run melos run check` đạt.

---

## Phần 7.2 — Chốt danh sách lớp khi tạo phiếu (nút 4.2) — migration

**Mục tiêu:** ánh xạ STT → học sinh cố định từ lúc tải ảnh.

Migration mới `database/migrations/<timestamp>_recognition_roster_snapshot/`:

1. Bảng kỹ thuật `danh_sach_phieu(ma_phieu bigint FK, stt integer > 0, ma_hoc_sinh integer FK, ho_ten varchar(100), PRIMARY KEY(ma_phieu, stt), UNIQUE(ma_phieu, ma_hoc_sinh))`. Append-only (trigger chặn UPDATE/DELETE như `lich_su_sua_diem`); runtime không DML trực tiếp.
2. Hàm mới `tao_phieu_nhan_dien` (signature mới, giữ `SECURITY DEFINER`, serializable, idempotency, outbox, audit như bản cũ) nhận `p_roster jsonb` = `[{stt, studentId, fullName}]` do API tính. Hàm kiểm: mọi học sinh thuộc lớp của bảng điểm và đang học; STT liên tục 1..n; số phần tử = sĩ số đang học. Ghi `danh_sach_phieu`. **Bỏ** tham số và kiểm tra `p_declared_rows`.
3. `phieu_nhan_dien.so_dong_khai_bao` đổi nghĩa thành **sĩ số snapshot** (giữ cột để tương thích). Sửa CHECK `phieu_luoi`: phiếu `CHO_DOI_CHIEU/DA_DUYET` cần `so_dong_nhan_dien BETWEEN 1 AND so_dong_khai_bao`.
4. `ket_qua_dong` thêm cột: `stt_giay integer NULL` (STT đọc được), `ho_ten_doc_duoc varchar(150) NULL`, `do_tin_cay_ghep numeric(5,4) NULL`, `duong_dan_anh_o_ten varchar(512) NULL`, `ghi_chu_ghep varchar(200) NULL`.
5. `luu_ket_qua_nhan_dien` mới: mỗi row có `stt` (STT hệ thống đã ghép) → tra `danh_sach_phieu`; từ chối STT không có trong snapshot hoặc trùng; cho phép số dòng < sĩ số; **bỏ** `ORDER BY ma_hoc_sinh OFFSET`. Lưu các cột mới. `thu_tu_dong` = vị trí dòng trên ảnh.
6. Cập nhật `database/prisma/schema.prisma`, `pnpm db:generate`.
7. Ghi rõ hướng rollback trong file migration (hoặc lý do không rollback được).

Test (`database/tests`, `apps/api/test/integration/recognition-*.test.ts`):

- Thứ tự mã ≠ thứ tự tên: kết quả gán đúng học sinh theo STT.
- Thêm học sinh/cho nghỉ học **giữa** tạo phiếu và worker lưu: ánh xạ không đổi.
- Snapshot sai lớp/STT không liên tục/thiếu học sinh → bị từ chối.
- Runtime không UPDATE/DELETE `danh_sach_phieu`.
- Duyệt (`duyet_phieu_nhan_dien`) ghi đúng học sinh trong snapshot.
- Migration chạy từ DB rỗng và nâng cấp DB test gần nhất.

Tiêu chí xong: `pnpm test:db`, `pnpm test:integration` đạt trên DB `*_test`.

---

## Phần 7.3 — API, contract và worker (nút 4.1, 4.2, 4.4)

**Mục tiêu:** nối snapshot vào luồng upload/worker, đổi contract nhận dạng. Chưa cần mô hình thật.

Việc làm:

1. Upload (`recognition/presentation/controller.ts`, `application/service.ts`): bỏ `declaredRows` khỏi required (giữ optional deprecated, bỏ qua giá trị). Service tính snapshot bằng hàm 7.1 và gọi hàm SQL mới.
2. Contract dịch vụ nhận dạng `POST /v1/recognize` trả mỗi dòng phát hiện (theo vị trí trên ảnh): `rowIndex`, `struck` (dòng gạch), `sttRaw`/`sttValue`/`sttConfidence`, `nameRaw`/`nameConfidence`, `numeric`, `written`, `numericCropBase64`, `writtenCropBase64`, `nameCropBase64`, `comparison`, `reviewLevel`; cộng `pageStartStt` (suy từ cột STT, có thể null). **Dịch vụ Python không nhận danh sách học sinh** (không gửi PII sang dịch vụ ML).
3. `infrastructure/http-model.ts`: parse/validate contract mới; timeout cấu hình `RECOGNITION_TIMEOUT_MS` (mặc định 120000) trong `common/config.ts` và `.env.example`.
4. Worker (`application/worker.ts`): bỏ kiểm `detectedRows === declaredRows`; gọi bước ghép 7.4; lưu ảnh ô họ tên `recognition/crops/<ticket>/<row>-name.png` (cập nhật regex kiểm key trong hàm SQL 7.2); gọi `luu_ket_qua_nhan_dien` mới.
5. Fake adapter Python (`src/adapters/model.py`): trả **giá trị khác nhau mỗi dòng**, có cột STT và tên giả (không phải PII), có thể cấu hình dòng gạch — để test phát hiện lệch.
6. Chi tiết phiếu (`RecognitionTicketDetail`): mỗi dòng thêm `stt`, `studentName`, `nameCropUrl` (signed 300s), `matchConfidence`, `matchNote`, `sttOnPaper`.
7. `pnpm api:export`, `pnpm client:generate`.

Test: contract (malformed, thiếu trường, timeout, model unavailable), worker idempotent, IDOR không đổi.

Tiêu chí xong: `pnpm check`, `pnpm contracts:check`, `pnpm test:integration`, Python tests đạt.

---

## Phần 7.4 — Ghép dòng ↔ học sinh (nút 4.4 và 4.9)

**Mục tiêu:** hàm miền thuần, không phụ thuộc framework, nằm ở API (business rule thuộc backend).

Tạo `apps/api/src/modules/recognition/domain/row-matching.ts`:

1. Đầu vào: dòng phát hiện (thứ tự trên ảnh, `struck`, STT đọc được + tin cậy, họ tên đọc được + tin cậy, có mực ở ô điểm hay không) và snapshot `[{stt, studentId, fullName}]`.
2. Bỏ dòng gạch và dòng trống hoàn toàn (không mực ở ô điểm và ô tên).
3. Căn chỉnh **quy hoạch động** giữ thứ tự (kiểu Needleman–Wunsch) giữa dòng trên ảnh và danh sách theo STT: điểm ghép = độ giống họ tên đã chuẩn hóa (NFC, bỏ dấu, chữ thường, khoảng cách sửa) + thưởng khi STT đọc được khớp; khoảng trống đầu/cuối danh sách không phạt (trang chỉ chứa một đoạn lớp), khoảng trống giữa bị phạt.
4. Mỗi dòng nhận `matchConfidence` và ghi chú: khớp cao → giữ mức; giống một phần hoặc trùng họ tên trong lớp → tối đa Vàng; nghi lệch (tên khớp dòng kề hơn) → Đỏ.
5. **Dừng (phiếu LOI, mã `ROW_MATCH_FAILED`)** khi: dòng có mực ở ô điểm không ghép được; hai dòng ghép cùng học sinh; tỷ lệ dòng tin cậy thấp vượt ngưỡng. Không đoán.
6. Mức cuối của dòng = mức thấp hơn giữa mức điểm (4.8) và mức ghép.
7. Tất cả ngưỡng là hằng số có tên, ghi chú "chờ dò trên dữ liệu thật (phần 7.9)".

Test `apps/api/test/row-matching.test.ts` (dữ liệu giả, không PII): đúng thứ tự; trang 2 bắt đầu STT 39; dòng gạch; giấy lệch 1 dòng; OCR sai vài chữ; họ tên trùng; sai lớp → LOI; không có cột STT đọc được (chỉ tên).

Tiêu chí xong: `pnpm check` đạt; độ phủ đủ các tình huống trên.

---

## Phần 7.5 — Màn hình kiểm tra riêng (nút 4.1, 5.1–5.8)

Việc làm (Flutter, chỉ dùng generated client):

1. Khối "Nhận dạng bảng điểm từ ảnh" (`features/recognition/recognition_panel.dart`): bỏ dòng "Số dòng khai báo"; đổi hướng dẫn thành "Chụp thẳng toàn bộ bảng, rõ cột STT, Họ tên, Điểm số, Điểm chữ. Hệ thống tự xác định học sinh theo STT và họ tên."; không gửi `declaredRows`.
2. Route mới `/gradebooks/:id/recognition/:ticketId` trong `app/app.dart` (giáo viên; HS bị chặn như route bảng điểm). Tách nội dung `_RecognitionDetailDialog` thành màn hình riêng `features/recognition/review_screen.dart`.
3. Sau khi gửi: hiện tiến độ (polling 3s có sẵn); phiếu chuyển `CHO_DOI_CHIEU` → **tự điều hướng** sang màn hình kiểm tra; `LOI` → hiện lý do (gồm `ROW_MATCH_FAILED`) và nút chụp lại. Danh sách phiếu vẫn mở lại được.
4. Màn hình kiểm tra: mỗi dòng STT, tên hệ thống gán, **ảnh ô họ tên trên giấy**, ảnh Đ.số/Điểm chữ, hai kênh + độ tin cậy, ghi chú ghép, màu; mặc định Vàng/Đỏ trước; lọc 3 màu (5.3); Đỏ không điền sẵn giá trị; giữ quy tắc phải xem mọi dòng trước khi duyệt; nút Duyệt dùng API approve hiện có.
5. Thẻ "OCR chờ duyệt" ở trang chủ giáo viên dẫn tới phiếu chờ (nếu đơn giản; không thì ghi vào CONTINUE.md).

Test widget: 320/390/1280, chữ 130%; tự điều hướng khi trạng thái đổi; Đỏ không có giá trị gợi ý; ảnh họ tên hiển thị; duyệt gửi đúng version/idempotency.

Tiêu chí xong: `dart run melos run check` đạt; Web development build đạt.

---

## Phần 7.6 — Pipeline ảnh Python, phần không dùng mô hình (nút 4.3–4.5)

Đưa vào `apps/recognition-service/src/pipeline/` (chỉ OpenCV/NumPy):

1. `quality.py` ← `kiem_dinh_anh.danh_gia_chat_luong`, `danh_gia_la_bang_diem`.
2. `page.py` ← `tien_xu_ly_v3` (nắn trang mẫu bất kỳ). **Bỏ `QUAD_OVERRIDES`** và mọi logic phụ thuộc tên file.
3. `grid.py` ← `luoi_tong_quat` (`trich_luoi`, `dinh_danh_cot`, `chon_cot_diem`, `cat_o`). Bổ sung từ khóa cấp 3: `mahs`, `mahocsinh`, `kiemtra15phut`, `mieng`, `giuaky`, `cuoiky`, `ddgtx`, `ddggk`, `ddgck`.
4. `rows.py` ← `_la_gach_ngang`, `do_dam_muc`, `_suy_stt_bat_dau` (nhận STT đọc được từ 7.7).
5. Định danh cột bằng OCR tiêu đề sẽ dùng adapter OCR ở 7.7; khi không có thì dùng đường lui hình học. Không tải mô hình từ Internet lúc chạy.
6. Kết quả trung gian: danh sách dòng với ảnh ô STT, Họ tên, Đ.số, Điểm chữ.
7. Ảnh không đạt chất lượng → mã lỗi rõ ràng (`IMAGE_QUALITY_LOW`, `NOT_A_GRADEBOOK`, `GRID_NOT_FOUND`, `SCORE_COLUMN_NOT_FOUND`).

Test: ảnh **tổng hợp** sinh bằng code (vẽ bảng có STT, họ tên giả, điểm in giả, nghiêng/phối cảnh nhẹ, một dòng gạch). Không commit ảnh thật. Thử local trên `05_BANG_DIEM_GOC` và ghi kết quả (không ghi tên học sinh) vào CONTINUE.md.

Tiêu chí xong: Python tests đạt; thử local tách đúng cột trên các ảnh mẫu E0330113.

---

## Phần 7.7 — Adapter mô hình thật (nút 4.6, 4.7, 4.8)

1. `src/adapters/crnn.py`: kiến trúc `CRNN`, tiền xử lý 32×128, giải mã CTC + độ tin cậy (sao chép đúng từ `suy_luan_hai_mo_hinh.py`). Nạp `torch.load(..., weights_only=True)`; nếu không nạp được với `weights_only=True` thì dừng và báo, không hạ xuống `weights_only=False`.
2. `src/adapters/vietocr_reader.py`: VietOCR với `vietocr_vgg_seq2seq.yml` copy vào repo (cấu hình, không phải trọng số), trọng số tang4.
3. Đọc ô: Đ.số và STT bằng CRNN; Điểm chữ và Họ tên bằng VietOCR (đọc theo từng ô đã cắt, không cần OCR khối).
4. `src/domain/written_grade.py` ← `so_tu_chuoi_so`, `so_tu_chuoi_chu`, `hau_xu_ly_tu_dien` + từ điển 133 cụm.
5. Phân loại (`src/domain/classification.py`): ngưỡng **riêng từng kênh** `RECOGNITION_NUMERIC_THRESHOLD=0.95`, `RECOGNITION_WRITTEN_THRESHOLD=0.90`. Không dùng nhánh "tie-break chọn giá trị" của `hop_nhat` (trái bất biến Đỏ không gợi ý).
6. `configured_model`: mode `weights` đọc `RECOGNITION_CRNN_WEIGHTS`, `RECOGNITION_VIETOCR_WEIGHTS` + SHA-256 kỳ vọng; thiếu file/sai hash → `MODEL_UNAVAILABLE`. `modelVersion` = tên + 12 ký tự đầu hash.
7. `pyproject.toml`: thêm torch, torchvision, opencv-python-headless, numpy, pillow, vietocr==0.3.13 (cài `--no-deps` theo hướng dẫn) + einops, pyyaml. Ghi lý do trong ADR-0015.
8. `.env.example`, README, `docs/development/recognition-checkpoints.md` cập nhật.

Test: sai hash → 503; thiếu file → 503; test nạp thật được **skip** khi không có trọng số (CI không có weights).

Tiêu chí xong: Python tests đạt; local nạp được hai trọng số thật.

---

## Phần 7.8 — Chạy đầu-cuối local và hiệu năng

1. Chạy đủ stack local (API, recognition-service mode weights, dispatcher, worker, web) theo README.
2. Dùng DB development **đã sao lưu** hoặc DB thử riêng với lớp giả; tạo bảng điểm có lịch nhập mở.
3. Thử 3–5 ảnh mẫu E0330113 trên máy: đo thời gian xử lý/phiếu, số dòng ghép đúng, số Vàng/Đỏ. Điều chỉnh `RECOGNITION_TIMEOUT_MS` theo đo thực tế.
4. Ghi kết quả tổng hợp (không tên học sinh) vào CONTINUE.md.

Tiêu chí xong: luồng chụp → tự mở màn hình kiểm tra → duyệt → điểm vào đúng học sinh chạy được local.

---

## Phần 7.9 — Mẫu bảng điểm cấp 3 và dò ngưỡng (CẦN dữ liệu chủ dự án)

**Điều kiện bắt đầu:** chủ dự án cung cấp ảnh bảng điểm cấp 3 thật (bản trắng + bản đã ghi điểm có cột Đ.số và Điểm chữ). Thiếu thì **dừng** và báo.

1. Thử pipeline 7.6 trên mẫu cấp 3; bổ sung từ khóa/hình học cột nếu cần.
2. Dò ngưỡng ghép tên (7.4) và ngưỡng hai kênh trên tập dev tách khỏi tập test, theo cách đã làm ở `tang4_hieu_chinh_hop_nhat.py`. Khóa ngưỡng, ghi vào ADR-0015.
3. Cập nhật README (hướng dẫn chụp), `docs/ux/recognition-capture.md`, traceability.
4. Chạy toàn bộ lệnh kiểm tra; chuẩn bị PR khi chủ dự án yêu cầu.

---

## Tiến độ

- [ ] 7.0 Chuẩn bị và ADR-0015
- [ ] 7.1 Hàm STT chung
- [ ] 7.2 Snapshot danh sách và migration
- [ ] 7.3 API, contract, worker
- [ ] 7.4 Ghép dòng ↔ học sinh
- [ ] 7.5 Màn hình kiểm tra riêng
- [ ] 7.6 Pipeline ảnh (không mô hình)
- [ ] 7.7 Adapter mô hình thật
- [ ] 7.8 Chạy đầu-cuối local
- [ ] 7.9 Mẫu cấp 3 và dò ngưỡng

## Câu lệnh giao việc cho AI

Dán một trong các câu sau vào agent tại thư mục repo:

- Bắt đầu: `Đọc AGENTS.md và docs/development/phase-7-nhan-dang-ghep-hoc-sinh.md, thực hiện Phần 7.0.`
- Phần cụ thể: `Thực hiện Phần 7.N trong docs/development/phase-7-nhan-dang-ghep-hoc-sinh.md. Tuân thủ quy tắc chung và điều kiện dừng; xong thì cập nhật CONTINUE.md và ô tiến độ.`
- Tiếp tục tự động: `continue` — agent đọc CONTINUE.md, tìm phần chưa đánh dấu đầu tiên trong mục Tiến độ và làm tiếp.
