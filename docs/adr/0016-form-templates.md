# ADR-0016 — Mẫu bảng điểm: nhận dạng theo mẫu khai báo, nhiều cột, nhiều trang

## Trạng thái

Accepted (2026-10-19, sau phase P6; xem "Kết quả đánh giá"). Đề xuất 2026-10-18, chủ dự án chốt hướng. Các phase P1–P6 trong `automation/phases/` hiện thực hóa ADR này. Mọi chỗ ghi "QUYẾT ĐỊNH MỞ" phải theo `automation/decisions.md`; chưa có quyết định thì giữ phương án mặc định ghi ở đây.

## Vấn đề

1. `adapters/model.py` gọi `analyze_page(image, None)`: không đọc tiêu đề cột, nên `chon_cot_diem_bat_buoc` luôn rơi vào đường lui hình học `chon_cot_diem_hinh_hoc` (cột hẹp 4,5–13 mm đứng trước cột rộng > 15 mm). Đó là chữ ký của mẫu E0330113, nên hệ thống thực tế chỉ nhận một mẫu.
2. `/v1/recognize` chỉ nhận ảnh. Dịch vụ tự chọn "cột điểm chính" và không biết giáo viên đang nhập thành phần nào. Với tờ có nhiều cột điểm (TX1–TX4, GK, CK), máy có thể đọc nhầm cột. Nếu hai kênh vẫn khớp thì đây là lỗi im lặng.
3. Một phiếu = một ảnh = một thành phần. Lớp có hai trang phải tải, duyệt rồi mới tải trang sau (`RECOGNITION_ALREADY_PENDING`). Muốn nhập sáu cột của một tờ thì phải chụp sáu lần.
4. Bảng chỉ có cột điểm số (phổ biến ở cấp 3) không có kênh thứ hai, nên mọi dòng tối đa chỉ được Vàng. Luật hiện tại (bất biến 4) đã xử lý đúng trường hợp này; chỉ cần hệ thống biết trước cột nào có cột chữ đi kèm.

## Quyết định

### 1. Mẫu bảng điểm do QTV khai báo

- Một **mẫu** gồm: tên, mô tả, ảnh mẫu (object storage private), **chữ ký lưới** và danh sách **cột mẫu**.
- **Chữ ký lưới** (`chu_ky_luoi jsonb`) được dịch vụ nhận dạng tính một cách tất định từ ảnh mẫu đã nắn:
  `{ "version": 1, "columnWidths": [tỉ lệ bề rộng từng cột dữ liệu / bề rộng bảng], "headerTexts": [chữ tiêu đề đã bỏ dấu hoặc ""], "headerRows": n, "rowHeightMm": x, "tableWidthMm": y }`.
- Mỗi **cột mẫu** có `chi_so_cot` (0..n-1, theo thứ tự trái → phải của cột dữ liệu) và một **vai trò**:
  - `STT`: tối đa một cột.
  - `HO_TEN`: đúng một cột, bắt buộc.
  - `DIEM`: ít nhất một cột. Kèm `loai_he_so` (TX/GK/CK) và `thu_tu_trong_nhom` (≥ 1). Cặp (`loai_he_so`, `thu_tu_trong_nhom`) không trùng trong một mẫu.
  - `DIEM_CHU`: kèm `cot_diem_di_kem` = `chi_so_cot` của một cột `DIEM`. Mỗi cột `DIEM` có tối đa một cột chữ.
  - `BO_QUA`: các cột còn lại (mã HS, ngày sinh, lớp, ký tên, ghi chú...).
- **Kiểu đọc** được suy ra, không lưu riêng: cột `DIEM` có cột `DIEM_CHU` đi kèm thì đọc hai kênh, không có thì đọc một kênh.
- Mẫu **không gắn với môn**. Khi dùng cho một bảng điểm, `(TX, 2)` được ánh xạ tới thành phần có `loai_he_so='TX'` đứng thứ 2 theo `thu_tu_hien_thi, ma_thanh_phan` của môn đó. Giáo viên xác nhận lại ánh xạ trước khi gửi.
- **Trạng thái mẫu**: `NHAP` → `DANG_DUNG` → `NGUNG`.
  - Mẫu chưa được phiếu nào dùng thì sửa tại chỗ được.
  - Mẫu đã được dùng thì không sửa. "Sửa" lúc này tạo **phiên bản mới**: dòng mới có `ma_mau_goc` trỏ về bản gốc, `phien_ban + 1`. Bản cũ chuyển `NGUNG`.
  - Không xóa cứng mẫu.
- Chỉ QTV tạo, sửa, ngừng mẫu. Giáo viên chỉ đọc các mẫu `DANG_DUNG`.

### 2. Dịch vụ nhận dạng: contract v2 (v1 giữ nguyên)

`/v1/recognize` **không đổi** để luồng cũ và test cũ chạy tiếp. Thêm:

- `POST /v2/layout/analyze` (multipart `image`). Trả về:
  `{ signature, columns: [{ index, x0, x1 (tỉ lệ 0–1 theo bề rộng bảng), widthMm, headerText, suggestedRole, suggestedGroup, suggestedOrder }], previewPngBase64 }`.
  - `previewPngBase64` là trang đã nắn, vẽ lưới và số thứ tự cột, chiều rộng tối đa 1400 px.
  - Vai trò gợi ý lấy từ `dinh_danh_cot` có bật đọc tiêu đề: dùng mô hình họ tên (VietOCR gốc) làm `ocr_ham`.
  - Không đọc được tiêu đề thì `suggestedRole=null`.
- `POST /v2/recognize` (multipart `image`, `layout` là chuỗi JSON). Trong đó:
  `layout = { "signature": {...}, "columns": [{ "index": i, "role": "STT|HO_TEN|DIEM|DIEM_CHU", "key": "TX1", "writtenIndex": j|null }] }`.
  - Chỉ gửi các cột cần đọc. `key` là định danh ổn định của cột điểm, ví dụ `"TX1"`, `"GK1"`, `"CK1"`.
  - Phản hồi:
    `{ modelVersion, pageStartStt, templateMatch: { score, columnMap: {templateIndex: imageIndex} }, rows: [{ rowIndex, struck, stt, name, nameCropBase64, sttRead, sttFromPosition, grades: [{ key, numeric, written|null, numericCropBase64, writtenCropBase64|null, comparison, reviewLevel, suggestedSource }] }] }`.
- **Khớp mẫu** (`pipeline/template_match.py`):
  - Căn dãy `columnWidths` của ảnh với dãy của mẫu bằng quy hoạch động. Chi phí gồm: sai lệch tỉ lệ bề rộng; phạt gộp hai cột (một vạch dọc bị mất); phạt tách một cột (vạch giả).
  - Nếu đọc được tiêu đề thì cộng thêm độ giống chữ tiêu đề.
  - `score` nằm trong 0–1. Nếu `score < TEMPLATE_MIN_SCORE` (mặc định 0,80, cấu hình bằng env `RECOGNITION_TEMPLATE_MIN_SCORE`) hoặc một cột cần đọc không ánh xạ được, trả lỗi `TEMPLATE_MISMATCH`.
  - **Không bao giờ tự đoán** sang cột khác.
- **Đọc nhiều cột**: mỗi dòng đọc STT/Họ tên một lần, rồi đọc từng cột điểm được yêu cầu. Mỗi `grade` được phân loại bằng `classification.py` hiện có:
  - Cột một kênh: `written=null`. Thực chất là nhánh "chỉ kênh số đủ tin cậy" → tối đa Vàng, `suggestedSource=SO`, `comparison=MOT_KENH`. Kênh số yếu hoặc không hợp lệ → Đỏ, không gợi ý.
  - Không cần sửa bất biến 4. Chỉ ghi rõ trong tài liệu rằng bảng một kênh không bao giờ đạt Xanh.
- Dịch vụ vẫn **không nhận danh sách học sinh**.

### 3. Lô nhận dạng: nhiều trang, nhiều thành phần

- Bảng mới `lo_nhan_dien` (lô): `ma_lo`, `ma_bang_diem`, `ma_mau`, `nguoi_tai`, `so_trang`, `trang_thai` (`DANG_XU_LY|XONG|LOI|DA_HUY`), `ma_loi`, `ngay_tao`.
- Bảng mới `trang_lo_nhan_dien`: `ma_lo`, `so_trang` (1..n), `ma_bam_tep`, `duong_dan_anh`. Tối đa **4 trang** mỗi lô.
- Một lô tạo **một phiếu cho mỗi thành phần được chọn** (bảng `phieu_nhan_dien` hiện có). Phiếu thêm các cột: `ma_lo` (nullable), `ma_mau` (nullable), `chi_so_cot_mau` (nullable).
  - `duong_dan_anh_goc` của phiếu là ảnh trang 1.
  - `ma_bam_tep` của phiếu thuộc lô là hash của (checksum các trang theo thứ tự + mã thành phần), để không vi phạm UNIQUE một phần hiện có.
  - Danh sách lớp chốt (`danh_sach_phieu`) được ghi cho từng phiếu, giống nhau trong một lô.
- `ket_qua_dong` thêm `so_trang` (nullable; phiếu cũ là null).
- Ràng buộc chờ giữ nguyên: thành phần nào đang có phiếu `DANG_XU_LY|CHO_DOI_CHIEU` thì không đưa vào lô mới (`RECOGNITION_ALREADY_PENDING`).
- **Worker xử lý theo lô**:
  1. Gọi `/v2/recognize` cho từng trang với cùng một `layout`.
  2. Gom dòng của mọi trang.
  3. Chạy **một lần** bộ ghép học sinh (`row-matching.ts`, Hungarian) trên toàn bộ dòng của lô. Mô hình STT vẫn tính theo từng trang (BE-24c).
  4. Tách kết quả theo `key` để ghi `ket_qua_dong` cho từng phiếu bằng hàm SQL `luu_ket_qua_nhan_dien` (mở rộng có tham số trang) trong cùng một giao dịch cho cả lô.
  - Một trang lỗi (`TEMPLATE_MISMATCH`, `GRID_NOT_FOUND`, `IMAGE_QUALITY_LOW`...) → **cả lô** `LOI`, mọi phiếu trong lô `LOI` cùng mã lỗi kèm số trang. Không ghi kết quả dòng.
  - Hai dòng ở hai trang cùng ghép vào một học sinh → `ROW_MATCH_FAILED`.
- Duyệt vẫn **theo từng phiếu** bằng `duyet_phieu_nhan_dien` hiện có (bất biến 6 không đổi). Hủy lô = hủy mềm mọi phiếu chưa duyệt trong lô.
- Endpoint cũ `POST /gradebooks/:id/recognition-tickets` giữ nguyên.

### 4. API (module `recognition` + module mới `form-templates`)

Đường dẫn danh mục theo quy ước hiện có `catalog/...` (quyền ghi chỉ QTV như các danh mục khác). Module mới phải đăng ký trong `apps/api/src/modules/index.ts` và qua `scripts/check-boundaries.mjs`.

| Method | Đường dẫn                                                    | Quyền             | Ghi chú                                                                                                                                                                         |
| ------ | ------------------------------------------------------------ | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| POST   | `/api/v1/catalog/form-templates/analyze`                     | QTV               | multipart `image`; proxy `/v2/layout/analyze`; không lưu gì                                                                                                                     |
| POST   | `/api/v1/catalog/form-templates`                             | QTV               | multipart `image` + `definition` (JSON: tên, mô tả, cột). Server phân tích lại ảnh, kiểm số cột khớp, tính chữ ký, lưu `NHAP`                                                   |
| GET    | `/api/v1/catalog/form-templates`                             | QTV, GV           | GV chỉ thấy `DANG_DUNG`; cursor pagination                                                                                                                                      |
| GET    | `/api/v1/catalog/form-templates/:id`                         | QTV, GV           | gồm cột và URL ảnh mẫu ký ngắn hạn                                                                                                                                              |
| PUT    | `/api/v1/catalog/form-templates/:id`                         | QTV               | chưa được dùng → sửa tại chỗ; đã dùng → `TEMPLATE_IN_USE` kèm gợi ý tạo phiên bản                                                                                               |
| POST   | `/api/v1/catalog/form-templates/:id/versions`                | QTV               | tạo phiên bản mới, bản cũ `NGUNG`                                                                                                                                               |
| POST   | `/api/v1/catalog/form-templates/:id/activate` \| `/retire`   | QTV               | đổi trạng thái, có `expectedVersion`                                                                                                                                            |
| POST   | `/api/v1/catalog/form-templates/:id/try`                     | QTV               | multipart `image`; gọi `/v2/recognize` đồng bộ (timeout 90 s); trả kết quả đọc, **không** ghép học sinh, **không** lưu                                                          |
| GET    | `/api/v1/gradebooks/:id/form-templates/:templateId/mapping`  | GV được phân công | gợi ý ánh xạ cột → thành phần, đánh dấu thành phần đang khóa/đang chờ                                                                                                           |
| POST   | `/api/v1/gradebooks/:id/recognition-batches`                 | GV được phân công | multipart `images[]` (1–4) + `templateId` + `components` (JSON `[{templateColumnIndex, componentId}]`), idempotency key; trả `{batchId, tickets:[{ticketId, componentId}]}` 202 |
| GET    | `/api/v1/gradebooks/:id/recognition-batches/:batchId`        | GV được phân công | trạng thái lô và các phiếu                                                                                                                                                      |
| POST   | `/api/v1/gradebooks/:id/recognition-batches/:batchId/cancel` | GV được phân công | hủy mềm mọi phiếu chưa duyệt                                                                                                                                                    |

**Mã lỗi mới**: `TEMPLATE_MISMATCH`, `TEMPLATE_NOT_FOUND`, `TEMPLATE_INACTIVE`, `TEMPLATE_IN_USE`, `INVALID_TEMPLATE_DEFINITION`, `TEMPLATE_COLUMN_COUNT_MISMATCH`, `COMPONENT_NOT_MAPPABLE`, `TOO_MANY_PAGES`.

### 5. Giao diện

- **QTV** — route Flutter `/admin/form-templates`:
  - Danh sách mẫu (tên, phiên bản, trạng thái, số cột điểm).
  - Tạo mẫu từ ảnh: preview có số cột; bảng cột gồm tiêu đề đọc được, vai trò, nhóm, thứ tự, cột đi kèm.
  - Kiểm hợp lệ ngay trên form theo các luật ở mục 1.
  - Nút "Thử nhận dạng" hiện kết quả từng dòng (không có họ tên học sinh hệ thống).
  - Kích hoạt, ngừng, tạo phiên bản.
- **Giáo viên** — trong panel nhận dạng của bảng điểm:
  1. Chọn mẫu: mặc định là mẫu dùng lần trước cho bảng này; lưu cục bộ trong phiên, không thêm package.
  2. Chọn hoặc chụp 1–4 ảnh trang, sắp xếp lại được thứ tự trang.
  3. Màn xác nhận ánh xạ cột → thành phần: tick chọn; thành phần khóa hoặc đang chờ thì không chọn được; hiện "số + chữ" hoặc "chỉ số".
  4. Gửi, rồi theo dõi lô.
  5. Khi xong: danh sách phiếu của lô dạng tab theo thành phần, mỗi tab mở màn đối chiếu hiện có (không viết lại màn đối chiếu).
  - Luồng cũ (một ảnh, không chọn mẫu) vẫn còn, nhãn "Không dùng mẫu (mẫu E0330113 cũ)".

### 6. Ngoài phạm vi ADR này

- Nhận dạng cột Đạt/Không đạt (bất biến 15).
- Bảng không kẻ ô.
- Vẽ tay lưới hoặc gộp/tách cột trên giao diện.
- Mô hình học bố cục.
- Khung căn trên camera.
- Kiểm chất lượng ảnh trên thiết bị.
- Tự nhận biết mẫu (chọn mẫu tự động trong số nhiều mẫu): **QUYẾT ĐỊNH MỞ D-03**, mặc định chưa làm.

## Đánh đổi

- QTV phải khai báo mẫu một lần cho mỗi loại tờ. Đổi lại, hệ thống không phải đoán cột và lỗi đọc nhầm cột bị chặn bằng `TEMPLATE_MISMATCH`.
- Lô làm worker phức tạp hơn. Bù lại, duyệt và hủy vẫn theo phiếu nên các bất biến 1, 6, 11, 13 không phải viết lại.
- Bảng một kênh luôn cần người xem mọi dòng có gợi ý (Vàng). Cho phép Xanh một kênh là **QUYẾT ĐỊNH MỞ D-01**, mặc định không.

## Tiêu chí nghiệm thu tổng

- Mẫu E0330113 khai báo bằng tính năng mới cho kết quả trên DEV **không kém** đường hình học cũ: gán sai học sinh 0, Xanh sai 0, độ đúng hai kênh không giảm quá 0,5 điểm phần trăm.
- Một mẫu thứ hai (ảnh trong `data/05_BANG_DIEM_GOC/Data_thayHa` hoặc `Data_coMai`) và một mẫu THPT mô phỏng (sinh bằng `scripts/recognition/make_thpt_form.py`) tạo được mẫu, thử nhận dạng và nhận dạng theo lô.
- Ảnh của mẫu khác với mẫu đã chọn → `TEMPLATE_MISMATCH`, không ghi kết quả dòng.
- Lô hai trang ghép đủ học sinh của cả hai trang; một học sinh xuất hiện ở hai trang → `ROW_MATCH_FAILED`.
- Toàn bộ test hiện có vẫn pass; luồng `/v1` và endpoint phiếu cũ không đổi hành vi.

## Ghi chú hiện thực P1

Phạm vi: `apps/recognition-service`. `/v1/recognize` không đổi (v1 vẫn gọi `analyze_page(image, None)`); chỉ luồng v2 truyền `ocr_ham` (VietOCR gốc, cùng `name_reader`).

- **Chữ ký và khớp mẫu** (`pipeline/template_match.py`): `columnWidths` là tỉ lệ bề rộng cột dữ liệu trên bề rộng bảng, làm tròn 4 chữ số. `score = 1 − (tổng |lệch tỉ lệ bề rộng| + phạt)` sau khi chuẩn hóa hai dãy về tổng 1; phạt gộp cột và phạt tách cột đều 0,04. Khi cả hai bên có chữ tiêu đề (≥ 2 cặp cột 1–1) thì `score = 0,75 · điểm bề rộng + 0,25 · độ giống chữ tiêu đề`. Ngưỡng đọc từ `RECOGNITION_TEMPLATE_MIN_SCORE` (mặc định 0,80); giá trị sai thì dịch vụ trả 503 `MODEL_UNAVAILABLE` như các ngưỡng khác.
- **`columnMap` chỉ chứa cột căn 1–1.** Cột mẫu bị gộp (mất một vạch dọc) hoặc bị tách (vạch giả) không có trong ánh xạ. Nếu cột đó nằm trong `layout` cần đọc thì trả `TEMPLATE_MISMATCH`, không đoán. Lỗi này là HTTP 422 với `detail = {code, message, details: {score, minScore, unmappedColumns, imageColumns, templateColumns}}`; các mã lỗi v1 không có `details`.
- **`/v2/layout/analyze`** không kiểm "có phải bảng điểm" (`NOT_A_GRADEBOOK`) và không chọn cột điểm, nên tờ ít hơn 4 cột vẫn khai báo được thành mẫu. `suggestedRole` gồm `STT | HO_TEN | DIEM | DIEM_CHU | BO_QUA`, `null` khi không đọc được tiêu đề. Tiêu đề chỉ gồm ký hiệu nhóm (`TX1`, `GK`, `CK`, `ĐĐGck`...) cũng được gợi ý là `DIEM`. `suggestedOrder` là thứ tự trái → phải trong nhóm. Số trên `previewPngBase64` bằng `index` (bắt đầu từ 0).
- **Schema `layout`** (`domain/layout.py`): `key` và `writtenIndex` chỉ xuất hiện ở cột `DIEM`; `writtenIndex` phải trỏ tới `index` của một cột `DIEM_CHU` có trong layout, và mỗi cột chữ chỉ đi kèm một cột `DIEM`. `key` khớp `[A-Za-z0-9_-]{1,32}`. `signature.columnWidths` có 2–64 số dương; mọi `index` nằm trong `[0, số cột chữ ký)`. P2 phải gửi đúng dạng này. Sai thì 422 `INVALID_LAYOUT`, kiểm trước khi gọi mô hình.
- **`/v2/recognize`**: `grades` theo thứ tự khai báo trong `layout` và chỉ gồm các `key` được yêu cầu. Cột một kênh có `written = null`, `writtenCropBase64 = null`; phân loại bằng `classification.py` với kênh chữ trống nên tối đa Vàng (D-01). `pageStartStt` là STT dòng đầu suy được khi bật `RECOGNITION_STT_CHECK` và mẫu có cột STT (v1 trả `null`), còn lại `null`. Dòng gạch bỏ: ô họ tên có nét gạch dài và ít nhất một ô điểm hoặc ô chữ cũng có.
- **Fake v2** (chỉ development/test): nắn trang, dò lưới, khớp mẫu và cắt ô là thật; chỉ phần đọc là giả. Cấu hình bằng `FAKE_START_STT` và `FAKE_DETECTED_ROWS` (tùy chọn). Không có OCR tiêu đề nên `suggestedRole` đều `null`. Production không có trọng số thì 503 `MODEL_UNAVAILABLE` kể cả khi đặt chế độ fake.
- **Bảo mật và riêng tư:** dịch vụ không nhận danh sách lớp; không thêm log nào chứa họ tên đọc được; không thêm dependency; `torch.load` vẫn chỉ `weights_only=True`.

## Ghi chú hiện thực P3

Phạm vi: migration `202610200001_recognition_batches`, module `recognition` (lô) và `form-templates` (`/mapping`). `/v1`, endpoint phiếu cũ và hàm `duyet_phieu_nhan_dien` không đổi.

- **Giao dịch tạo lô:** `tao_lo_nhan_dien` (SERIALIZABLE, khóa bảng điểm) tạo lô, 1–4 trang, MỘT phiếu cho mỗi thành phần, danh sách lớp chốt cho từng phiếu (giống nhau trong lô), audit, khóa idempotency `RECOGNITION_BATCH_UPLOAD` và MỘT sự kiện outbox `RECOGNITION_BATCH_REQUESTED` (`recognition_outbox.ma_lo`, `ma_phieu` NULL). Lỗi ở bất kỳ thành phần nào → rollback toàn bộ; API dọn ảnh đã tải lên trước giao dịch. Kiểm lại ở SQL (không tin UI): cột mẫu phải là `DIEM`, thành phần thuộc môn và khớp ánh xạ (nhóm, thứ tự) theo `thu_tu_hien_thi, ma_thanh_phan`, cột chưa chốt và đang trong thời gian nhập (`kiem_thoi_gian_nhap`), thành phần không có phiếu chờ, mẫu `DANG_DUNG`.
- **`ma_bam_tep` của phiếu thuộc lô** = SHA-256(`checksum các trang theo thứ tự, nối bằng ","` + `:` + mã thành phần); chỉ mục duy nhất một phần hiện có (`WHERE trang_thai <> 'DA_HUY'`) vẫn phát hiện tải trùng, và hủy xong tải lại đúng ảnh được. Hai trang cùng một ảnh trong một lô → `DUPLICATE_FILE`.
- **Số trang và thứ tự dòng:** `ket_qua_dong.so_trang` (NULL với phiếu cũ, trigger `kiem_dong_theo_lo` ép nhất quán nên phiếu thuộc lô không ghi được qua `luu_ket_qua_nhan_dien`). `thu_tu_dong = (trang − 1) × 1000 + vị trí dòng trên trang` để duy nhất trong phiếu; vị trí > 999 bị worker từ chối (`MALFORMED_RESPONSE`).
- **Worker lô** (`batch-worker.ts`): dựng `layout` chỉ gồm STT, HO_TEN, các DIEM được chọn và DIEM_CHU đi kèm; gọi `/v2/recognize` từng trang với cùng `layout`; phản hồi phải có đúng các `key` đã yêu cầu; ghép học sinh MỘT lần cho cả lô (`matchBatchRows`, mô hình STT theo từng trang, BE-24c); ghi mọi phiếu bằng `luu_ket_qua_lo` trong một giao dịch. Mã lỗi xác định (`TEMPLATE_MISMATCH`, `GRID_NOT_FOUND`, `IMAGE_QUALITY_LOW`, `INVALID_LAYOUT`...) → `danh_dau_lo_nhan_dien_loi` đặt cả lô và mọi phiếu `LOI` cùng mã, kèm `trang_loi`; lỗi hạ tầng ném lại để BullMQ thử lại, hết lượt thì cả lô `LOI`. `ROW_MATCH_FAILED` (kể cả một học sinh ở hai trang) có `trang_loi = NULL`.
- **Ràng buộc ở SQL (bất biến 4, D-01):** cột một kênh (không có `DIEM_CHU` đi kèm) không được `XANH`, không `KHOP`/`LECH`, không ảnh ô chữ, không gợi ý `CHU`; `KHONG_DOC_DUOC` luôn `DO` không gợi ý; dòng mức cuối `DO` không lưu `kenh_goi_y`.
- **Hủy lô:** `huy_lo_nhan_dien` hủy mềm mọi phiếu chưa duyệt (`DANG_XU_LY`, `CHO_DOI_CHIEU`, `LOI`), giữ phiếu `DA_DUYET`; mọi phiếu đã duyệt → `TICKET_ALREADY_APPROVED` (API: `BATCH_ALREADY_APPROVED`). Hủy từng phiếu của lô bằng endpoint cũ chỉ xóa ảnh các trang khi phiếu cuối của lô đã hủy. `luu_ket_qua_lo` bỏ qua lô đã hủy (hủy giữa lúc worker chạy) và worker dọn ảnh ô mồ côi.
- **API:** thẻ OpenAPI `recognition-batches` (client Dart `RecognitionBatchesApi`) và `form-templates` cho `/mapping`. Mã lỗi thêm: `TOO_MANY_PAGES`, `COMPONENT_NOT_MAPPABLE` (400), `BATCH_NOT_FOUND` (404), `BATCH_ALREADY_APPROVED`, `COLUMN_LOCKED`, `GRADE_ENTRY_WINDOW_CLOSED`, `GRADEBOOK_NOT_EDITABLE`, `IDEMPOTENCY_MISMATCH` (409). `/mapping` và các endpoint lô chỉ cho giáo viên được phân công (QTV và học sinh 403).
- **Client sinh:** generator `dart-dio` bỏ trống thân multipart; `scripts/repair-generated-client.mjs` chỉ vá `recognition_api.dart`. Các hàm `recognitionBatchUpload` (và `formTemplates*` ở P2) sinh ra có thân rỗng cho tới khi script vá được mở rộng (ngoài phạm vi P3); P5 phải xử lý khi làm giao diện.

## Ghi chú hiện thực P7

Phạm vi: `pipeline/{template_match,layout,khoi_phuc_vach,page}.py`, test, công cụ đo. Contract `/v1`, `/v2`, API, DB và Flutter không đổi; lỗi `TEMPLATE_MISMATCH` giữ nguyên hình dạng `details`.

- **Chẩn đoán 4 trang DEV bị từ chối (từ chữ ký đã lưu, không cần ảnh):** không phải "mất vạch giữa bảng" như giả định ban đầu. Hai trang (P05 S02 p1, R03 T03 p1) có 8 cột ảnh đúng bằng cột 0–7 của mẫu: cột cuối (Ghi chú, không cần đọc) nằm ngoài lưới; phép căn cũ lại gộp nhầm cột 6+7 nên Điểm chữ (cột 6) không ánh xạ được. Hai trang còn lại mất cột trái: T03 S06 p2 mất STT (8 cột = cột 1–8), T03 S08 p1 mất hai cột trái (7 cột = cột 2–8). Sai lệch bề rộng của các phép căn cắt mép đúng là 0,0009–0,0046; cách cắt tốt thứ hai ≥ 0,13.
- **Khớp mẫu chịu cắt mép (`khop_mau_chi_tiet`):** thêm phép căn chỉ với một đoạn liên tiếp của mẫu (bỏ tối đa 3 cột đầu/cuối, phạt 0,05 mỗi cột). Chỉ được chọn khi (1) các cột nhìn thấy khớp đoạn mẫu gần như chính xác (sai lệch bề rộng ≤ 0,03), (2) rẻ hơn phép căn toàn bộ ≥ 0,03, (3) hơn mọi cách cắt khác ≥ 0,02. Không thỏa thì giữ phép căn toàn bộ như P6, nên với ảnh đủ cột `column_map` giữ nguyên (đã kiểm trên 75 chữ ký đã lưu: chỉ đúng 4 trang trên đổi ánh xạ). Cột nằm ngoài lưới KHÔNG có trong `column_map`.
- **Khôi phục vạch có bằng chứng (`khoi_phuc_vach_thieu` + `khoi_phuc_vach.tim_vach_doc`):** cột cần đọc chưa ánh xạ nhưng điểm khớp ≥ ngưỡng thì tìm vạch dọc thật tại vị trí mẫu kỳ vọng: (a) một cột ảnh bằng hai cột mẫu kề (mất vạch giữa) → tách tại vạch tìm được; (b) cột ngoài mép → thêm từng vạch từ mép lưới ra ngoài, mỗi vạch dựa trên vạch tìm được trước đó (không nội suy). Bằng chứng: trong khoảng ±30% bề rộng cột nhỏ hơn (10–40 px) quanh vị trí kỳ vọng, ≥ 60% số dòng dữ liệu có nét tối phủ ≥ 90% chiều cao dòng (sau khi lấp khe ≤ 11 px) trên CÙNG một đường gần đứng (độ dốc ≤ 0,03), các dòng đó trải ≥ 50% chiều cao bảng, đường mảnh (≤ 14 px) và là ứng viên DUY NHẤT (hai ứng viên tách biệt → mơ hồ, từ chối). Chữ số/chữ in cao chưa hết dòng nên không đạt 90%; bóng đổ quá rộng bị loại; sát mép trang (1,5%) bị bỏ. Sau khôi phục, chữ ký được dựng lại và khớp lại: điểm vẫn phải ≥ ngưỡng và mọi cột cần đọc phải ánh xạ được, nếu không vẫn `TEMPLATE_MISMATCH` với `details` của kết quả ban đầu.
- **Không đổi:** cột bị tách bởi vạch giả không được khôi phục; ảnh có điểm khớp < ngưỡng không được thử khôi phục; ngưỡng D-04 giữ 0,80. `templateMatch.columnMap` là chỉ số cột của danh sách cột SAU khôi phục (khác `layout/analyze` của cùng ảnh khi có vạch được thêm).
- **Nắn lại với quad giấy nới (vòng 3):** nếu sau cắt mép và khôi phục vạch mà cột cần đọc vẫn chưa ánh xạ (trang nắn bị cắt mất cột ở mép do dò cạnh giấy sai, trong khi ảnh gốc còn đủ bảng), `layout.nan_lai_mo_rong` nắn lại ảnh gốc với quad giấy nới ra phía bị cắt (`page.mo_rong_quad`; mức nới = phần bảng mẫu bị mất × {1,0; 1,5}), dò lưới lại bằng vạch thật và khớp lại với mẫu. Nhận chỉ khi điểm ≥ ngưỡng và mọi cột cần đọc ánh xạ được; không thì `TEMPLATE_MISMATCH` như cũ. Tham số `mo_rong` mặc định không nới nên mọi đường khác không đổi.
- **Kiểm chứng:** `apps/recognition-service/tests/test_template_recovery.py` (34 test, gồm `PaperEdgeCutTest` cho nhánh nới quad; vạch giữa/vạch mép tìm lại được; không mực → vẫn từ chối; mẫu khác kể cả khi có vạch đứt → từ chối; chữ số, bóng đổ, hai ứng viên, mép trang không bị nhận là vạch). Công cụ chẩn đoán: `evaluate_pages.py diagnose --split dev --layout …` (`--recover` chạy thêm trên ảnh thật).

## Kết quả đánh giá (P7)

Báo cáo: `docs/reports/recognition/Danh_gia_P7_2026-10-19.md`. Mô hình `crnn-dot5+vietocr-tang4+name-vgg:1f230266bd93`, layout `e0330113.json`, ngưỡng 0,80.

- **AC-1 trên DEV: ĐẠT** (`compare --split dev --v2-tag _v2p7` in "AC-1 (DEV): ĐẠT"): 0/60 trang `TEMPLATE_MISMATCH` (P6: 4/60); trên 1.170 dòng có nhãn Đ.số 99,06% (v1 99,15%; P6 89,74%), Điểm chữ 98,80% (v1 98,80%; P6 89,32%); gán sai học sinh 0/760; Xanh sai 0. `regression_checks` không đổi. 56/56 trang DEV đã đọc được ở P6 cho kết quả y hệt.
- **Nguyên nhân gốc hai trang mất STT:** ảnh điện thoại còn đủ cột STT nhưng dò cạnh giấy chọn sai cạnh trái nên trang nắn bị cắt; sửa bằng nắn lại với quad giấy nới ra (`nan_lai_mo_rong`) rồi dò lưới lại, chỉ nhận khi lưới đủ vạch thật và khớp mẫu ≥ 0,80 với mọi cột cần đọc ánh xạ được. Hai trang mép phải được cứu bằng phép căn cắt mép. Ảnh có bảng thật sự nằm ngoài khung vẫn `TEMPLATE_MISMATCH`.
- **Mẫu khác (AC-2):** 9/9 ảnh `TEMPLATE_MISMATCH` trên toàn bộ pipeline (điểm 0,5136–0,6638).
- **TEST (chạy đúng một lần, 2026-10-19 18:56:26 → 19:03:56 +07, sau khi khóa cấu hình):** 0/100 trang bị từ chối (P6: 5/100); độ đúng trên mọi dòng có nhãn Đ.số 90,56% (v1 90,61%), Điểm chữ 90,66% (v1 90,66%). **Gán sai 2/1139 và Xanh sai 3 (v1: 0 và 2) — hai điều kiện này không đạt nguyên văn trên TEST.** Chẩn đoán (không sửa gì sau khi xem TEST): cả hai thuộc một trang P08 S02 p2 (điện thoại, tờ 3 dòng) mà đường v2 trả 2 dòng thay vì 3, nên phép đo theo vị trí dòng chấm lệch một chỗ; kết quả y hệt ở P6, vì vậy không do P7, và chẩn đoán "trang 1 bị từ chối" của P6 cho hai dòng này chưa đúng. Xanh sai còn lại (2) có ở cả v1. Việc v2 mất dòng đầu của trang ngắn điện thoại cần xử lý ở phase sau.
- **Chưa chứng minh:** độ tổng quát của hai mức nới quad (chỉ 2 trang DEV cần nhánh này); đọc chữ viết tay cấp 3 thật.

## Kết quả đánh giá (P6, 2026-10-19)

Báo cáo đầy đủ: `docs/reports/recognition/Danh_gia_mau_bang_diem_2026-10-19.md`. Mô hình `crnn-dot5+vietocr-tang4+name-vgg:1f230266bd93`, layout `scripts/recognition/layouts/e0330113.json`, ngưỡng khớp mẫu 0,80.

- **Không kém đường cũ trên DEV (KHÔNG ĐẠT):** trên cùng 1.170 dòng có nhãn, Đ.số đúng 89,74% (v1 99,15%, −9,40 điểm %), Điểm chữ đúng 89,32% (v1 98,80%, −9,49 điểm %); Xanh sai 0, gán sai học sinh 0 (hai điều kiện này đạt). Trên riêng dòng đọc được, v2 ngang v1 (99,2% / 98,7%), nhưng chỉ số đó không chứng minh tiêu chí vì v2 loại 111 dòng. Nguyên nhân: v2 từ chối 4/60 trang (4/30 ảnh điện thoại, mất/dính vạch dọc) bằng `TEMPLATE_MISMATCH` mà v1 vẫn đọc được; máy quét giống hệt v1. Từ chối thay vì đoán cột là đúng thiết kế của ADR này, nhưng tiêu chí nghiệm thu chưa đạt; muốn đạt cần cải thiện căn cột khi mất vạch (ngoài phạm vi P6). AC-1 chuyển sang P7 theo quyết định chủ dự án 2026-10-19.
- **Ngưỡng D-04:** dò chỉ trên DEV; ảnh đúng mẫu đã ánh xạ đủ cột có điểm 0,9574–0,9981, ảnh mẫu khác 0,5885–0,7026. Giữ mặc định 0,80 (không đổi mã).
- **TEST (chạy một lần, 2026-10-19 13:35–13:47):** 1.960 dòng; Đ.số 92,9% và Điểm chữ 91,6% trên dòng đọc được (v1 90,6% / 90,7%); 5/100 trang bị từ chối. Xanh sai 2 ở cả v1 và v2 (sẵn có của mô hình). Gán sai v2 = 2 dòng, đều do bộ đo ghép trang 2 khi trang 1 của tờ đó bị từ chối; ở luồng thật cả lô sẽ `LOI`, không ghi dòng nào. Không chỉnh cấu hình sau khi xem TEST.
- **Mẫu thứ hai** (Data_thayHa, 14 cột) đọc được trên 4 ảnh (định tính); ảnh của mẫu khác với layout → `TEMPLATE_MISMATCH` ở mọi cặp thử. **Mẫu THPT mô phỏng** sinh bằng `make_thpt_form.py` khớp chính ảnh của nó với điểm 1,0 và đọc đủ 40 dòng.
- **Chưa chứng minh:** đọc chữ viết tay cấp 3 thật (chưa có dữ liệu); chấp nhận ảnh điện thoại mất vạch dọc (hiện từ chối: 4/30 = 13,3% trang điện thoại DEV, 4/60 = 6,7% mọi trang DEV; 5/50 = 10% trang điện thoại TEST).
