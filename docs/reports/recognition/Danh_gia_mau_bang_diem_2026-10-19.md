# Đánh giá nhận dạng theo mẫu bảng điểm (ADR-0016, phase P6) — 2026-10-19

Báo cáo không chứa họ tên hay ảnh có họ tên. Họ tên chỉ nằm trong tệp đệm cục bộ `.local/eval` (git ignore). Mô hình: `crnn-dot5+vietocr-tang4+name-vgg:1f230266bd93`, đường v1 và v2 dùng cùng trọng số.

## 1. Cách đo

- **Đường v1:** `/v1/recognize` (`analyze_page(image, None)`), tự chọn cột điểm bằng hình học.
- **Đường v2:** `recognize_v2` với layout của mẫu E0330113 (`scripts/recognition/layouts/e0330113.json`): STT (cột 0), Họ tên (cột 2), Đ.số `DIEM` khóa `CK1` (cột 5), Điểm chữ `DIEM_CHU` (cột 6). Chữ ký lưới là trung vị bề rộng cột của 56/60 trang DEV có đủ 9 cột (bốn trang còn lại mất vạch dọc nên chỉ 7–8 cột). Ngưỡng khớp mẫu 0,80.
- Cùng bộ ghép học sinh thật (`row-matching.ts`), cùng luật phân loại hợp nhất (sàn 0), cùng nhãn. Lệnh: `evaluate_pages.py run [--layout …]`, `compare`, `scores`.
- DEV = P05, R03, T03 (60 trang). TEST = P08, R04, R05, T06, T07 (100 trang).

## 2. DEV: v1 so với v2 (AC-1)

Nhóm `all` (điện thoại + máy quét), 1.170 dòng có nhãn:

| Chỉ số                                         | v1 (hình học) | v2 (mẫu)      |
| ---------------------------------------------- | ------------- | ------------- |
| Dòng đọc được                                  | 1170          | 1059          |
| Đ.số đúng (trên dòng đọc được)                 | 99,1%         | 99,2%         |
| Điểm chữ đúng (trên dòng đọc được)             | 98,8%         | 98,7%         |
| Đ.số / Điểm chữ đúng (trên mọi dòng có nhãn)   | 99,1 / 98,8%  | 89,7 / 89,3%  |
| Xanh / Vàng / Đỏ (theo điểm)                   | 1146 / 17 / 7 | 1036 / 17 / 6 |
| Xanh / Vàng / Đỏ (mức cuối, sau ghép học sinh) | 697 / 22 / 6  | 665 / 16 / 6  |
| Xanh sai (theo điểm và mức cuối)               | 0             | 0             |
| Gán sai học sinh                               | 0 / 725       | 0 / 687       |
| Trang `TEMPLATE_MISMATCH`                      | 0 / 60        | **4 / 60**    |

Độ đúng chính xác hơn: Đ.số 99,15% → 99,15% (Δ 0,00), Điểm chữ 98,80% → 98,68% (Δ −0,12 điểm %, trong giới hạn 0,5). Máy quét: v1 và v2 giống hệt từng dòng (0/30 trang bị từ chối). Điện thoại: 4/30 trang bị từ chối.

**AC-1: ĐẠT** (gán sai 0, Xanh sai 0, độ đúng mỗi kênh không thấp hơn v1 quá 0,5 điểm %).

Giới hạn quan trọng: v2 từ chối 4/60 trang DEV (6,7%; 111 dòng, tức 9,5% số dòng có nhãn) mà v1 vẫn đọc được. Cả bốn đều là ảnh điện thoại mất hoặc dính vạch dọc (lưới chỉ còn 7–8 cột), khiến một cột cần đọc không ánh xạ 1–1 được; v2 không đoán nên trả `TEMPLATE_MISMATCH` (đúng thiết kế ADR-0016). Độ đúng "trên dòng đọc được" của v2 vì thế không tính các dòng này; giáo viên phải chụp lại. Đã ghi nhận, chưa sửa (ngoài phạm vi P6: chỉ được đổi ngưỡng).

## 3. Dò ngưỡng `RECOGNITION_TEMPLATE_MIN_SCORE` trên DEV (D-04, AC-2)

Chỉ dùng DEV: 60 trang DEV là ảnh **đúng mẫu**; ảnh **mẫu khác** là 9 ảnh (8 ảnh tờ "Điểm quá trình / ĐTK" trong `Data_thayHa` + tờ THPT sinh bởi `make_thpt_form.py`). Nhãn "mẫu khác" lấy theo chữ in trên tờ (tiêu đề Đ.số + Điểm chữ = tờ E0330113), không lấy theo điểm khớp. Lưu ý `Data_thayHa` trộn hai loại tờ (6 ảnh là tờ E0330113) và `Data_coMai` là tờ E0330113; các ảnh đó **không** dùng để chọn ngưỡng.

Phân bố điểm khớp (`evaluate_pages.py scores`):

| Nhóm                                   | Số ảnh | Nhỏ nhất | Trung vị | Lớn nhất | Ghi chú                                            |
| -------------------------------------- | ------ | -------- | -------- | -------- | -------------------------------------------------- |
| Đúng mẫu, ánh xạ đủ cột cần đọc        | 56     | 0,9574   | —        | 0,9981   | 56/56 ≥ 0,95 (trung vị cả 60 ảnh: 0,9950)          |
| Đúng mẫu, mất/dính vạch (không ánh xạ) | 4      | 0,4356   | —        | 0,9080   | 0,4356 · 0,8049 · 0,8262 · 0,9080; luôn bị từ chối |
| Mẫu khác                               | 9      | 0,5885   | 0,6854   | 0,7026   | 9/9 cũng có cột cần đọc không ánh xạ được          |

Quét ngưỡng (từ chối nhầm = ảnh đúng mẫu bị từ chối; nhận nhầm = ảnh mẫu khác được nhận), tính cả luật "cột không ánh xạ → từ chối":

| Ngưỡng       | 0,50–0,95 (mọi giá trị)                  |
| ------------ | ---------------------------------------- |
| Từ chối nhầm | 4/60 (cố định, do luật cột không ánh xạ) |
| Nhận nhầm    | 0/9                                      |

Nếu chỉ xét điểm: nhận nhầm 9/9 ở 0,55; 7/9 ở 0,60; 6/9 ở 0,65; 1/9 ở 0,70; **0/9 từ 0,75 trở lên**, và ảnh đúng mẫu đã ánh xạ đủ cột không bị từ chối ở bất kỳ ngưỡng ≤ 0,95. Khoảng tách chỉ theo điểm là (0,7026; 0,9574], điểm giữa 0,83.

**Quyết định: giữ mặc định 0,80** (không sửa `template_match.py`). Lý do: 0,80 nằm trong khoảng tách, cách ảnh mẫu khác cao nhất 0,097 và cách ảnh đúng mẫu thấp nhất 0,157; D-04 chỉ cho đổi khi DEV cho thấy cần. Tăng ngưỡng lên 0,83 không làm giảm nhận nhầm mà còn làm hẹp biên cho ảnh đúng mẫu.

## 4. TEST — chạy một lần (AC-2)

Cấu hình khóa trên DEV trước khi chạy: layout `e0330113.json`, ngưỡng 0,80, luật phân loại sàn 0. Cả hai đường chạy một lần, bắt đầu 2026-10-19 13:35 (+07), v1 xong 13:43:51, v2 xong 13:46:35. Sau khi xem TEST không chỉnh gì. (`evaluate_pages.py` từ chối chạy lại TEST khi bộ đệm đã có `completedAt`.) Người `T04` có trong manifest `test/` nhưng không khai báo trong `SPLITS` nên bị bỏ qua (xem giả định).

Nhóm `all`, 1.960 dòng có nhãn:

| Chỉ số                                         | v1 (hình học)    | v2 (mẫu)        |
| ---------------------------------------------- | ---------------- | --------------- |
| Dòng đọc được                                  | 1960             | 1782            |
| Đ.số đúng (trên dòng đọc được)                 | 90,6%            | 92,9%           |
| Điểm chữ đúng (trên dòng đọc được)             | 90,7%            | 91,6%           |
| Đ.số / Điểm chữ đúng (trên mọi dòng có nhãn)   | 90,6 / 90,7%     | 84,5 / 83,3%    |
| Xanh / Vàng / Đỏ (theo điểm)                   | 1635 / 198 / 127 | 1538 / 149 / 95 |
| Xanh / Vàng / Đỏ (mức cuối, sau ghép học sinh) | 775 / 217 / 113  | 750 / 129 / 83  |
| Xanh sai                                       | 2                | 2               |
| Gán sai học sinh                               | 0 / 1105         | 2 / 962         |
| Trang `TEMPLATE_MISMATCH`                      | 0 / 100          | 5 / 100         |

Máy quét: v1 và v2 giống hệt từng dòng. Điện thoại: 5/50 trang bị từ chối (điểm khớp 0,9077; 0,9085; 0,8181; 0,7790; 0,4362 — ba trang đầu có điểm ≥ 0,80 nhưng vẫn bị từ chối vì có cột cần đọc không ánh xạ được, như DEV; hai trang sau thấp hơn ngưỡng).

Phân tích (không sửa gì sau khi xem TEST):

- **Xanh sai 2** có ở cả v1 và v2 với cùng số lượng (1 ở máy quét, giống hệt từng dòng giữa hai đường; 1 ở điện thoại): mô hình đọc sai nhưng hai kênh vẫn đồng thuận. Đây là sai số sẵn có của mô hình, không do đường theo mẫu (v2 không thêm Xanh sai nào so với v1). Chủ dự án nên xem xét riêng (mục rủi ro).
- **Gán sai 2 ở v2** đều thuộc một trang: trang 2 của một tờ mà trang 1 bị v2 từ chối. Bộ đo ghép từng trang riêng và lấy các dòng gạch bỏ của trang 1 để loại học sinh đã nghỉ khỏi danh sách lớp; khi trang 1 vắng thì danh sách lớp lệch một chỗ nên hai dòng đầu trang 2 bị gán lệch một học sinh. Đây là hiện tượng của bộ đo, không xảy ra ở luồng thật: lô có một trang lỗi (`TEMPLATE_MISMATCH`) thì **cả lô** `LOI`, không ghi kết quả dòng nào (ADR-0016 mục 3). Nếu loại các tờ có trang bị từ chối khỏi phép đo thì gán sai của v2 = 0 trên các trang còn lại.
- Độ đúng "trên dòng đọc được" cao hơn ở v2 (điện thoại 95,8% so với 90,6% Đ.số) chủ yếu vì các trang khó (mất vạch) bị từ chối, không phải vì đọc tốt hơn; chỉ số công bằng là "trên mọi dòng có nhãn" (v2 thấp hơn v1 do từ chối).
- AC-1 chỉ đặt ra cho DEV; trên TEST, tiêu chí gán sai = 0 và Xanh sai = 0 của v2 **không đạt nguyên văn** theo bảng thô, với nguyên nhân như trên. Không chỉnh cấu hình để "đạt" TEST.

## 5. Mẫu thứ hai: Data_thayHa (AC-3)

Tờ "Điểm quá trình / ĐTK" (14 cột: STT | Mã SV | Họ tên | Ngày sinh | Tên lớp | ĐQT×6 | ĐTK | Điểm chữ | Chữ ký). Layout `scripts/recognition/layouts/thayha_dtk.json` (trung vị chữ ký 6 ảnh 14 cột): STT, Họ tên, TX1, TX2 (một kênh, cột 5, 6), ĐTK + Điểm chữ (hai kênh, cột 11, 12). Ảnh không nhãn nên chỉ báo định tính, không in họ tên và giá trị điểm:

| Ảnh (Data_thayHa)   | Điểm khớp | Số dòng (gạch bỏ) | TX1 đọc được / mực không đọc được | TX2    | ĐTK    |
| ------------------- | --------- | ----------------- | --------------------------------- | ------ | ------ |
| Scan/ban1_p1        | 0,9974    | 35 (1)            | 34 / 0                            | 34 / 0 | 34 / 0 |
| Scan/ban1_p2        | 0,9950    | 5 (0)             | 5 / 0                             | 5 / 0  | 5 / 0  |
| Scan/ban4_p1        | 0,8811    | 39 (3)            | 33 / 3                            | 36 / 0 | 36 / 0 |
| Phone/…a2cf (1 ảnh) | 0,9940    | 35 (1)            | 34 / 0                            | 34 / 0 | 34 / 0 |

Không có dòng trống trong các ô đã chọn (tờ đã điền đủ). Một ảnh (ban4_p1, điểm 0,88) có 3 ô TX1 có mực nhưng không đọc được: cần người xem (sẽ là Đỏ).

Ảnh mẫu khác với layout → `TEMPLATE_MISMATCH` (không có dòng nào được trả):

- Layout E0330113 với 3 ảnh Data_thayHa 14 cột: điểm 0,6959 / 0,6915 / 0,6854, cột 5 và 6 không ánh xạ.
- Layout E0330113 với tờ THPT sinh ra: điểm 0,5931.
- Layout thayha với một tờ E0330113 (Data_thayHa/Scan/ban2_p1): điểm 0,6959.
- Layout THPT với tờ Data_thayHa và tờ E0330113: điểm 0,5545 và 0,5916.

Tham khảo (ngoài DEV, không dùng chọn ngưỡng): layout E0330113 với 3 ảnh Data_coMai (cùng loại tờ) khớp 0,9958 / 0,9884 / 0,9601 và đọc được mọi dòng có mực; với 6 ảnh E0330113 trong Data_thayHa điểm 0,9685–0,9951.

## 6. Mẫu THPT in được (AC-4)

`scripts/recognition/make_thpt_form.py` sinh "Sổ điểm môn học — THPT (mô phỏng theo Thông tư 22)": A4 200 dpi (1654×2339 px) PNG và PDF (Pillow, không thêm thư viện), 9 cột STT | Họ và tên | TX1 | TX2 | TX3 | TX4 | GK | CK | Ghi chú, 40 dòng, tên giả sinh có `--seed` (hoặc `--names-file`). `--write-layout` tính chữ ký lưới từ chính PNG và ghi `layouts/thpt_tt22.json` (STT, Họ tên, `TX1–TX4`, `GK1`, `CK1`; mọi cột một kênh nên tối đa Vàng).

- Điểm khớp layout THPT với chính PNG sinh ra: **1,0000**; ảnh quét nghiêng 0,4° và −0,8° có nhiễu: ≥ 0,9. Pipeline cắt đủ 40 dòng; một tờ trống đọc được 0 ô điểm, 40 ô trống mỗi cột (không bịa điểm).
- Test: `scripts/recognition/tests/test_make_thpt_form.py` (8 test, `.local/venv-ml/Scripts/python.exe -m unittest discover -s scripts/recognition/tests`).
- In ở tỉ lệ 100% (không "vừa trang").

## 7. Giới hạn

- Mẫu THPT là **mô phỏng**, chưa có dữ liệu cấp 3 viết tay thật; chưa đo độ chính xác đọc của cột một kênh trên chữ viết tay cấp 3, và chưa thử `/v2/recognize` trên ảnh chụp thật của tờ in này.
- Mẫu thứ hai chỉ có đánh giá định tính, không nhãn.
- Khớp mẫu từ chối ảnh điện thoại mất hoặc dính vạch dọc (khoảng 7% số trang điện thoại DEV, 10% TEST) dù đường hình học vẫn đọc được; cần cải thiện chụp ảnh (thấy đủ vạch dọc) hoặc thuật toán căn cột ở phase sau.
- Tập TEST lệch so với manifest: người `T04` bị bỏ qua.
