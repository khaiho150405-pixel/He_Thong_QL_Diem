# Giai đoạn 7 — Tổng hợp thay đổi chức năng nhận dạng bảng điểm từ ảnh

Nhánh: `codex/recognition-row-matching` (tách từ `2612be9`, sau PR #10). Cập nhật: 2026-10-07.
Hướng dẫn cài và chạy cho máy khác: [phase-7-huong-dan-chay.md](phase-7-huong-dan-chay.md).

## 1. Mục tiêu và ràng buộc

- **Mục tiêu:** giáo viên chụp ảnh bảng điểm giấy → hệ thống tự đọc **cột Điểm số và cột Điểm chữ**, gán **đúng từng học sinh** → chuyển sang **màn hình kiểm tra riêng** để giáo viên đối chiếu và duyệt.
- **Không sửa sơ đồ phân cấp chức năng.** Mọi thay đổi nằm trong nhánh 4 (Nhận dạng, 4.1–4.9) và nhánh 5 (Đối chiếu/duyệt, 5.1–5.8).
- Bảng điểm cấp 3 **không có mã học sinh** trên giấy, nên hệ thống ghép theo **họ tên** với danh sách lớp.
- Đọc STT **không** phải mục tiêu và đã tắt (BE-19b).
- Máy chỉ **đề xuất**. Điểm chỉ được ghi khi giáo viên duyệt; dòng Đỏ không có giá trị gợi ý.

## 2. Lỗi gốc đã xử lý

Hàm SQL cũ `luu_ket_qua_nhan_dien` (migration `202609120001`) gán dòng thứ _n_ trên ảnh cho học sinh thứ _n_ theo `ORDER BY ma_hoc_sinh OFFSET n-1`. Trong khi đó, giấy in theo STT (tên → họ tên). Hai thứ tự này lệch nhau, nên điểm có thể **ghi nhầm người**.

**Cách sửa:**

1. Lúc tải ảnh, hệ thống chụp lại danh sách lớp của phiếu (bảng `danh_sach_phieu`).
2. Máy đọc họ tên in trên từng dòng.
3. API ghép một-một dòng ↔ học sinh theo độ giống họ tên. Thuật toán cho phép hai dòng đổi chỗ cho nhau.
4. Kết quả được lưu theo `ma_hoc_sinh` đã ghép, không theo vị trí dòng.

Thứ tự STT dùng chung một hàm duy nhất: `apps/api/src/common/student-order.ts`, sắp theo tên → họ tên → mã, collator tiếng Việt.

## 3. Luồng hoạt động mới

1. **(4.1)** Giáo viên mở bảng điểm → mục **Nhận dạng bảng điểm từ ảnh** → chọn **Thành phần điểm** → chọn ảnh (PNG/JPEG ≤ 10 MB) → **Tải ảnh & Nhận dạng**. Không cần nhập số dòng.
2. API tạo phiếu `DANG_XU_LY`, lưu ảnh vào MinIO, chụp danh sách lớp và ghi outbox. Mỗi cặp (bảng điểm, thành phần) chỉ có **một** phiếu đang chờ.
3. **dispatcher** đẩy phiếu từ outbox vào hàng đợi Redis (BullMQ). **worker** lấy phiếu ra và gọi `POST /v1/recognize` của dịch vụ Python.
4. **Dịch vụ nhận dạng** (FastAPI) xử lý ảnh:
   - kiểm tra chất lượng ảnh → nắn phẳng trang → dò lưới bảng;
   - xác định cột qua từ khóa tiêu đề → cắt ô → nhận biết dòng bị gạch;
   - đọc **Điểm số** bằng CRNN, **Điểm chữ** bằng VietOCR tinh chỉnh, **Họ tên** bằng VietOCR gốc;
   - hợp nhất hai kênh điểm thành Xanh/Vàng/Đỏ.
5. **worker** ghép dòng ↔ học sinh (`row-matching.ts`) rồi lưu kết quả qua `luu_ket_qua_nhan_dien` → phiếu chuyển sang `CHO_DOI_CHIEU`.
6. **(5.x)** Màn hình **Đối chiếu nhận dạng #id** hiển thị:
   - ảnh gốc;
   - bộ lọc theo mức Xanh/Vàng/Đỏ;
   - cho mỗi dòng: ảnh ô họ tên, ô điểm số, ô điểm chữ (bấm để phóng to), ký tự thô, giá trị, độ tin cậy, ghi chú ghép;
   - ô **Điểm cuối** và **Lý do**. Để trống điểm cuối nghĩa là không ghi điểm cho học sinh đó (ví dụ vắng), khi đó bắt buộc ghi lý do.

   **Duyệt** ghi toàn bộ điểm trong một giao dịch, có kiểm tra version, idempotency và ghi audit.

## 4. Luật phân loại (theo `hop_nhat.py` của phần nghiên cứu)

| Trường hợp                                                   | Mức  | Gợi ý                                        |
| ------------------------------------------------------------ | ---- | -------------------------------------------- |
| Hai kênh đọc ra **cùng giá trị**                             | Xanh | giá trị đó                                   |
| Chỉ một kênh đủ tin cậy (Điểm số ≥ 0,95; Điểm chữ ≥ 0,90)    | Vàng | giá trị kênh đó (`suggestedSource` = SO/CHU) |
| Hai kênh chắc nhưng mâu thuẫn, cùng yếu, hoặc không đọc được | Đỏ   | không gợi ý                                  |

- Ngưỡng nằm trong `.env`: `RECOGNITION_NUMERIC_THRESHOLD=0.95`, `RECOGNITION_WRITTEN_THRESHOLD=0.90`, `RECOGNITION_*_FLOOR=0`.
- Ngưỡng ghép tên: `NAME_STRONG` 0,85; `NAME_WEAK` 0,60; `NEIGHBOR_MARGIN` 0,15; `MAX_RED_RATIO` 0,34.
- **Mức cuối của dòng = mức thấp hơn** giữa mức điểm và mức ghép tên.
- Phiếu báo `ROW_MATCH_FAILED` khi còn dòng có điểm chưa ghép được, khi trùng học sinh, hoặc khi quá nhiều dòng Đỏ.
- **Ký tự thô** là chuỗi mô hình đọc được. **Giá trị** là điểm đổi từ chuỗi đó, ví dụ "ba một" → 3.1, "bảy rưỡi" → 7.5, "8." → 8.0.

## 5. Các bước đã làm

| Bước                         | Nội dung                                                                                                                                                                      | Commit          |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- |
| BE-00 → BE-19, FE-01 → FE-05 | ADR-0015, snapshot danh sách lớp, hàm SQL mới, ghép dòng, pipeline ảnh (port từ nghiên cứu), nạp CRNN/VietOCR an toàn (SHA-256, `weights_only=True`), màn hình kiểm tra riêng | `edf09a3`       |
| BE-19b                       | Tắt đọc STT; torch thành phụ thuộc tùy chọn `[ml]`; màn hình kiểm tra báo lỗi version thay vì mặc định 1                                                                      | `977be63`       |
| BE-16 (phương án A)          | Dựng lưới từ đường kẻ dọc + ≥ 3 đường ngang, xử lý bảng ngắn trang 2                                                                                                          | trong `edf09a3` |
| BE-20, BE-20b, BE-20c        | Stack thử cục bộ; VietOCR gốc cho họ tên + thu khe họ đệm/tên; ghép một-một toàn cục (cho phép đổi chéo)                                                                      | `4aea439`       |
| Cách A                       | Duyệt dòng không ghi điểm, bắt buộc lý do (migration `202610070001_review_skip_rows`)                                                                                         | `4aea439`       |
| BE-21, BE-22                 | Luật hợp nhất theo nghiên cứu, `suggestedSource` (migration `202610070002`), đánh giá DEV/TEST                                                                                | `4aea439`       |
| BE-23                        | Thu khe ô họ tên cho ảnh điện thoại: bù nền, bỏ đường kẻ ngang, bỏ nhiễu mép                                                                                                  | **chưa commit** |
| Sửa lỗi                      | API chi tiết phiếu thiếu `suggestedSource` → app báo "Không thể kết nối dịch vụ" (`service.ts`)                                                                               | **chưa commit** |
| Công cụ                      | `stack.ps1` cho đổi thư mục trọng số/DB bằng biến môi trường; thêm `check-ticket.ps1`                                                                                         | **chưa commit** |

## 6. Thay đổi theo khu vực

**Database** (`database/migrations`, không sửa migration cũ)

- `202610060001_recognition_roster_snapshot`: bảng `danh_sach_phieu`, chỉ được ghi thêm.
- `202610060002_recognition_roster_function`: `tao_phieu_nhan_dien` nhận `p_roster`. Kiểm tra `DUPLICATE_FILE` (ảnh trùng SHA) và `RECOGNITION_ALREADY_PENDING` (thành phần đã có phiếu chờ).
- `202610060003_recognition_roster_results`: `luu_ket_qua_nhan_dien` lưu theo snapshot và học sinh đã ghép.
- `202610070001_review_skip_rows`: cột `ly_do_duyet`, duyệt dòng không ghi điểm.
- `202610070002_recognition_suggestion`: cột `kenh_goi_y`.

**API** (`apps/api`)

- `recognition/domain/row-matching.ts`: ghép một-một theo độ giống họ tên.
- `recognition/application/worker.ts`, `infrastructure/http-model.ts`: kiểm tra phản hồi của mô hình. Timeout `RECOGNITION_TIMEOUT_MS`, mặc định 120000.
- `recognition/application/service.ts`, `presentation/controller.ts`: DTO chi tiết phiếu (ảnh ký 300 giây, ô họ tên, `suggestedSource`).
- `common/student-order.ts`: thứ tự STT dùng chung.

**Dịch vụ nhận dạng** (`apps/recognition-service`)

- `src/pipeline/`:
  - `page.py`: nắn phẳng trang;
  - `quality.py`: kiểm tra chất lượng ảnh;
  - `grid.py`: dò lưới, nhận diện cột;
  - `rows.py`: cắt dòng, dòng bị gạch, `compact_name_cell`.
- `src/adapters/`:
  - `crnn.py`: mô hình Điểm số;
  - `vietocr_reader.py` (cùng `vietocr_vgg_seq2seq.yml`): mô hình Điểm chữ và Họ tên;
  - `model.py`: chế độ `fake`/`weights`.
- `src/domain/`:
  - `written_grade.py`: đổi chuỗi đọc được thành điểm, nắn về từ điển;
  - `classification.py`: luật Xanh/Vàng/Đỏ.

**Giao diện Flutter** (`apps/client_flutter`)

- `features/recognition/recognition_panel.dart`: chọn thành phần, chọn ảnh, lịch sử phiếu.
- `features/recognition/review_screen.dart`, route `/gradebooks/:id/recognition/:ticketId`: màn hình đối chiếu.
- `features/recognition/image_preview.dart`, `repository.dart`.
- Client API (`packages/api_client_dart`) sinh lại từ OpenAPI, không sửa tay.

**Script** (`scripts/recognition`)

- `pilot/stack.ps1`: bật/tắt 5 dịch vụ.
- `pilot/setup.ts db|book|more`: tạo lớp thử.
- `pilot/reset-tickets.ts`: xóa phiếu chưa duyệt.
- `pilot/cleanup.ts`: xóa lớp thử.
- `pilot/order-check.ts`.
- `pilot/check-ticket.ps1`: kiểm tra JSON phiếu theo OpenAPI.
- `try_pipeline.py`, `evaluate_pages.py`, `evaluate_matching.ts`: đánh giá trên DEV/TEST.

**Tài liệu**

- `docs/adr/0015-recognition-row-matching.md`, `AGENTS.md` (bất biến 4 và 5).
- `docs/development/phase-7-*.md`, `CONTINUE.md`, `recognition-checkpoints.md`, `docs/ux/recognition-capture.md`.

## 7. Kết quả đo (mẫu E0330113 của trường đại học; chưa có bảng điểm cấp 3 thật)

Tập dữ liệu:

- DEV: P05, R03, T03.
- TEST: P08, R04, R05, T06, T07. Đo một lần, không chỉnh ngưỡng theo TEST.

| Chỉ số                             | DEV                           | TEST                             |
| ---------------------------------- | ----------------------------- | -------------------------------- |
| Đọc đúng từng kênh (số / chữ)      | 99,1% / 98,8%                 | 90,6% / 90,7%                    |
| Ô họ tên được thu khe (sau BE-23)  | 97,0%                         | 98,2%                            |
| Xanh / Vàng / Đỏ cuối, trước BE-23 | 534 / 157 / 32                | 495 / 421 / 184                  |
| Xanh / Vàng / Đỏ cuối, sau BE-23   | **705 / 14 / 6** (Xanh 97,5%) | **816 / 176 / 113** (Xanh 73,8%) |
| Gán nhầm học sinh                  | 0                             | 0 / 1105 dòng                    |
| Dòng Xanh nhưng sai                | 0                             | 2 (≈ 0,25% số dòng Xanh)         |

Thời gian khoảng 1,5–2 giây/trang. Lần đầu sau khi bật dịch vụ mất khoảng 20–25 giây để nạp mô hình.

## 8. Hạn chế và việc còn lại

- Chưa thử trên bảng điểm cấp 3 thật. Phiếu phải có cả cột Đ.số và cột Điểm chữ.
- Lỗi im lặng: hai kênh cùng đọc sai thành cùng một giá trị (≈ 0,25% số dòng Xanh trên TEST). Giáo viên vẫn phải duyệt cả phiếu.
- Một mẫu trang bị chọn nhầm cột "Lớp" làm cột họ tên. Đề xuất BE-24: chọn cột họ tên theo mức khớp với danh sách lớp.
- Ảnh điện thoại có bóng đổ nặng vẫn có thể ra nhiều dòng Vàng/Đỏ.
- Thông báo lỗi `RECOGNITION_ALREADY_PENDING` / `DUPLICATE_FILE` trên giao diện còn chung chung ("vi phạm ràng buộc nghiệp vụ").
- Cần thêm test bảo đảm DTO chi tiết phiếu có đủ trường `required` theo OpenAPI.
