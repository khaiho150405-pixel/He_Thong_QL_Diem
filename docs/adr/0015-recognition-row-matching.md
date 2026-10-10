# ADR-0015 — Ghép dòng nhận dạng với học sinh theo danh sách lớp đã chốt

## Vấn đề (2026-10-06)

- Hàm SQL `luu_ket_qua_nhan_dien` (migration `202609120001_recognition_results`) gán dòng thứ n trên ảnh cho học sinh bằng `ORDER BY ma_hoc_sinh OFFSET n-1`, trong khi giấy ghi theo STT (thứ tự tên). Mô phỏng trên dữ liệu seed: lớp 10A1 sai 37/41 dòng, 10A2 sai 29/41, 10A3 sai 37/41. Fake adapter trả cùng một giá trị cho mọi dòng nên lỗi không lộ.
- Có bốn cách sắp học sinh khác nhau: SQL (`ma_hoc_sinh`), `apps/api/src/common/catalog.ts` (`compareStudentRows`), `reports/application/service.ts` (`compareVietnameseNames`, không xét mã) và Flutter (`vietnamese_sort.dart`, `gradebook_screen.dart`).
- Ứng dụng tự gửi `declaredRows` bằng sĩ số và `tao_phieu_nhan_dien` bắt số dòng bằng sĩ số, nên không nhận được lớp nhiều trang hoặc bảng có dòng bị gạch.
- Trường cấp 3 không in mã học sinh trên giấy; chỉ có STT và họ tên.

## Quyết định

1. **Một hàm STT chung ở API** (`apps/api/src/common/student-order.ts`): tên (từ cuối) → họ tên đầy đủ → `ma_hoc_sinh`, chỉ học sinh đang theo học, STT bắt đầu từ 1 theo lớp. Mọi nơi (lưới điểm, báo cáo, Excel, nhận dạng) dùng hàm này; client không tự sắp.
2. **Chốt danh sách lớp khi tạo phiếu**: API tính danh sách `(stt, studentId, fullName)` và truyền vào `tao_phieu_nhan_dien`; hàm SQL kiểm tra rồi ghi vào bảng kỹ thuật append-only `danh_sach_phieu`. Học sinh thêm/nghỉ sau thời điểm đó không đổi ánh xạ của phiếu.
3. **Bỏ số dòng khai báo**. `phieu_nhan_dien.so_dong_khai_bao` giữ lại để tương thích nhưng nghĩa là sĩ số snapshot. Giáo viên không còn nhập số dòng.
4. **Ghép dòng theo STT và họ tên đọc trên giấy**, bằng ghép một-một tối ưu toàn cục (Hungarian; BE-20c thay cho căn chỉnh giữ thứ tự) giữa dòng trên ảnh và danh sách đã chốt (miền thuần ở API): họ tên là chính, thứ tự dòng chỉ là điểm thưởng nhỏ phân xử khi tên yếu/trùng. Dịch vụ nhận dạng Python không nhận danh sách học sinh để không gửi dữ liệu cá nhân sang dịch vụ ML.
5. **Mức của dòng = mức thấp hơn giữa mức điểm (hai kênh) và mức ghép** (`ĐỎ < VÀNG < XANH`). Dòng gạch và dòng không có mực ở cả ô điểm lẫn ô tên bị bỏ qua.
6. **Ghép thất bại → phiếu `LOI` với mã `ROW_MATCH_FAILED`**, không ghi kết quả dòng, yêu cầu ảnh khác. Thất bại khi: dòng có mực ở ô điểm nhưng không ghép được; hai dòng cùng một học sinh; tỷ lệ dòng Đỏ do ghép vượt ngưỡng.
7. **Màn hình kiểm tra riêng** tự mở khi phiếu chuyển `CHO_DOI_CHIEU`, hiển thị STT, tên hệ thống gán, ảnh ô họ tên trên giấy, hai kênh và ghi chú ghép.
8. **Không sửa sơ đồ phân cấp chức năng**: mọi thay đổi nằm trong các nút 3.2, 4.1–4.9, 5.1–5.8.
9. Bất biến 5 trong AGENTS.md được diễn giải lại: số dòng không do giáo viên khai báo; mọi dòng có điểm phát hiện được phải ghép được với danh sách lớp đã chốt của phiếu; ghép thất bại thì dừng, yêu cầu ảnh khác, không đoán.

Các bất biến khác giữ nguyên: máy chỉ đề xuất, duyệt nguyên tử, NULL khác 0.0, Đỏ không gợi ý giá trị, `torch.load` chỉ với `weights_only=True`, không tải mô hình từ Internet lúc chạy.

## Đánh đổi

- Ghép bằng họ tên OCR có thể sai khi chữ viết tay khó đọc hoặc họ tên trùng; bù lại bằng mức ghép tham gia mức dòng (Vàng/Đỏ buộc giáo viên xem) và bằng việc hiển thị ảnh ô họ tên ở màn hình kiểm tra.
- Thêm một bảng kỹ thuật (`danh_sach_phieu`) và 5 cột trong `ket_qua_dong`; đổi lại ánh xạ ổn định, giải thích lại được.
- Danh sách chốt tại thời điểm tải ảnh: nếu lớp đổi ngay sau đó, giáo viên phải tải lại ảnh để dùng danh sách mới.
- Thời gian xử lý mỗi phiếu tăng (đọc thêm cột STT/Họ tên); `RECOGNITION_TIMEOUT_MS` cấu hình được.
- Ngưỡng ghép (`NAME_STRONG`, `NAME_WEAK`, `MAX_RED_RATIO`) và ngưỡng hai kênh (số 0.95, chữ 0.90) là giá trị khởi điểm, chờ dò trên dữ liệu cấp 3 thật (BE-21–BE-22). Kết quả dò sẽ ghi vào mục "Kết quả dò ngưỡng" bên dưới.

## Kế hoạch migration

- Migration mới `recognition_roster_snapshot`: bảng `danh_sach_phieu` (append-only, runtime chỉ SELECT), 5 cột mới của `ket_qua_dong`, sửa CHECK `phieu_luoi`. Rollback ghi trong file migration.
- Migration mới thay `tao_phieu_nhan_dien` (nhận `p_roster jsonb`, bỏ `p_declared_rows`) và `luu_ket_qua_nhan_dien` (tra học sinh theo `danh_sach_phieu`, bỏ `ORDER BY ma_hoc_sinh OFFSET`).
- Không sửa migration đã chạy; kiểm từ DB rỗng và nâng cấp từ DB `*_test` gần nhất. Không reset hay seed lại DB development.
- Phiếu đã tồn tại trước migration không có snapshot; chúng giữ nguyên dữ liệu đã lưu và không dùng hàm mới.

## Dò lưới cho bảng ngắn (BE-16, thay đổi so với thuật toán gốc)

Thuật toán dò lưới gốc (`luoi_tong_quat.trich_luoi`) cần ít nhất 4 vạch ngang suốt bề ngang cùng một cụm. Trang cuối của lớp chỉ có tiêu đề cộng vài dòng (ví dụ 3), vạch ngang còn ít và thường đứt, nên đo thử trên 80 ảnh mẫu cho 40/40 đúng ở trang đầy đủ nhưng chỉ 16/40 ở trang 2 (nhiều ca `GRID_NOT_FOUND`). Chủ dự án chốt thay đổi: dựng bảng từ các vạch dọc cột (≥ 4 vạch dọc cùng khoảng y) rồi nhận vạch ngang theo độ phủ cộng dồn của các đoạn nằm trong khoảng đó, chỉ cần ≥ 3 vạch ngang; không dựng được thì dùng thuật toán gốc. Vạch giả do nét chữ hoặc nét gạch bỏ dòng cắt dòng thật thành hai dòng thấp được gỡ ở `rows.chuan_hoa_hang_y`. Tiêu chí đo: số dòng CÓ ĐIỂM so với tham chiếu (dòng trống thừa được chấp nhận vì bước ghép bỏ `UNMATCHED_BLANK`), không ảnh nào thiếu dòng có điểm.

## Phụ thuộc cho mô hình thật (BE-13 → BE-19)

Dịch vụ nhận dạng thêm: `numpy` và `opencv-python-headless` (nắn trang, dò lưới, cắt ô); `torch`, `torchvision` (CRNN, VietOCR); `einops`, `pyyaml`, `pillow` (VietOCR); `vietocr==0.3.13` ghim trong extra `vietocr` nhưng cài bằng `--no-deps` vì các phụ thuộc của nó (opencv-python, albumentations, imgaug, lmdb, gdown...) không cần cho suy luận và xung đột với bản headless. Mô hình chỉ nạp bằng `weights_only=True` sau khi kiểm SHA-256, không tải gì từ Internet lúc chạy; `Predictor` của vietocr bị thay bằng dựng mô hình + nạp state dict an toàn vì nó nạp trọng số bằng `torch.load` mặc định và có đường tải URL. Nhánh "trọng tài" của `hop_nhat` (chọn một giá trị khi hai kênh bất đồng hoặc cùng yếu) không được mang sang, và nắn từ điển điểm chữ bị chặn khi chuỗi đọc ra cách từ điển quá 2 ký tự sửa, để Đỏ không gợi ý giá trị.

## Mô hình đọc họ tên (BE-20b)

Thử BE-20 cho thấy cả 4 ảnh mẫu bị `ROW_MATCH_FAILED` vì độ giống họ tên đọc được chỉ khoảng 0,3–0,7. Đo trên cùng ô cắt (82 ô, tờ mẫu train, phone + scan, độ giống như thuật toán ghép): hai nguyên nhân.

1. Ô họ tên gồm hai cột con (họ đệm | tên) cách nhau khe trắng rộng; mô hình dừng ở khe nên bỏ phần tên (với mô hình gốc, 32/38 chuỗi đọc ra là phần đầu đúng của họ tên, không có ký tự thay sai). Sửa ở `rows.compact_name_cell`.
2. `vietocr_best_tang4.pth` được tinh chỉnh cho điểm chữ viết tay nên đọc tên in kém hơn bản gốc. Họ tên dùng VietOCR gốc `vgg_seq2seq` qua cấu hình riêng `RECOGNITION_NAME_WEIGHTS` / `RECOGNITION_NAME_SHA256` (bắt buộc; thiếu → `MODEL_UNAVAILABLE`, không dùng thay bằng tang4); điểm chữ vẫn dùng tang4. Tải MỘT LẦN, kiểm SHA-256, nạp `weights_only=True`.

Ngưỡng ghép (`NAME_STRONG`, `NAME_WEAK`, `MAX_RED_RATIO`) KHÔNG đổi; việc dò lại thuộc BE-22.

## Ghép một-một theo họ tên và dòng không ghi điểm (BE-20c)

- Căn chỉnh giữ thứ tự gán nhầm học sinh khi thứ tự trên giấy khác thứ tự hệ thống (P03_S03: STT 5↔6 và 15↔16). `row-matching.ts` nay giải bài toán phân công chi phí nhỏ nhất (Hungarian) trên điểm = độ giống họ tên (lập phương, để khớp tốt không bị đánh đổi lấy cải thiện nhỏ ở dòng đọc kém) cộng STT nếu có và một điểm thưởng thứ tự nhỏ (`ORDER_BONUS` = 0,1, giảm dần theo độ lệch so với vị trí dự kiến ước lượng từ các dòng khớp tên mạnh). Học sinh không có trên trang được bỏ trống; dòng có điểm bắt buộc phải ghép.
- Họ tên khớp mạnh nhưng thứ tự trên giấy khác hệ thống: giữ mức theo tên (không hạ Đỏ) và ghi chú "Thứ tự trên giấy khác hệ thống." (dòng nằm ngoài dãy tăng dài nhất; hai dòng kề đổi chỗ đều được ghi chú). Các lỗi `ROW_MATCH_FAILED` và các ngưỡng `NAME_STRONG`, `NAME_WEAK`, `MAX_RED_RATIO` không đổi; hằng `GAP_PENALTY` không còn dùng nên bị bỏ.
- Duyệt phiếu: giá trị cuối `null` nghĩa là KHÔNG ghi điểm cho học sinh đó (ví dụ vắng). Hàm `duyet_phieu_nhan_dien` không động tới `diem_thanh_phan` của học sinh đó (NULL khác 0.0, điểm cũ giữ nguyên) nhưng vẫn lưu người duyệt, thời điểm và lý do bắt buộc (≤ 500 ký tự) ở cột mới `ket_qua_dong.ly_do_duyet`; ràng buộc `dong_duyet_day_du` có ba trạng thái hợp lệ (chưa duyệt / đã ghi điểm / đã duyệt không ghi điểm kèm lý do). Dòng không ghi điểm tính vào `reviewedRows` và `humanCorrectedRows`, không tính là máy đúng. Trước đó `null` vừa xóa ô điểm vừa vi phạm ràng buộc nên không duyệt được (409).

## Luật phân loại hai kênh và đánh giá (BE-21/BE-22)

**Luật.** Phân loại ba màu lấy từ `ket_hop/hop_nhat.py::hop_nhat_mot_o` của nghiên cứu (ngưỡng `ket_qua/tang4/cau_hinh_hop_nhat_dev_co_mai.json`: τ số 0,95, τ chữ 0,90), bỏ nhánh trọng tài hiệu chuẩn nhiệt độ:

| Tình huống                                                                  | Màu                       | Gợi ý giá trị    |
| --------------------------------------------------------------------------- | ------------------------- | ---------------- |
| Hai kênh cùng một giá trị hợp lệ (đồng thuận; kèm sàn mỗi kênh, mặc định 0) | Xanh                      | giá trị chung    |
| Chỉ kênh số ≥ τ số (kênh chữ yếu, không hợp lệ hoặc khác giá trị)           | Vàng, "Lấy theo điểm số"  | giá trị kênh số  |
| Chỉ kênh chữ ≥ τ chữ (kênh số yếu, không hợp lệ hoặc khác giá trị)          | Vàng, "Lấy theo điểm chữ" | giá trị kênh chữ |
| Cả hai mạnh nhưng mâu thuẫn, cả hai yếu, hoặc không kênh nào hợp lệ         | Đỏ                        | không gợi ý      |

"Đủ tin cậy" của dòng Xanh nghĩa là hai kênh ĐỘC LẬP (CRNN cho Đ.số, VietOCR cho Điểm chữ) đồng thuận về cùng một giá trị, không cần độ tin cậy từng kênh vượt ngưỡng; sàn (`RECOGNITION_NUMERIC_FLOOR`/`RECOGNITION_WRITTEN_FLOOR`, mặc định 0) chỉ hạ một đồng thuận xuống Vàng khi cấu hình. Dịch vụ vẫn trả hai kênh thô, giá trị chuẩn hóa và độ tin cậy; kênh gợi ý đi qua trường mới `suggestedSource` (`SO`/`CHU`/`null`; cột `ket_qua_dong.kenh_goi_y`, migration `202610070002`), `comparison` vẫn là KHOP/LECH/MOT_KENH/KHONG_DOC_DUOC. Mức cuối của dòng vẫn là mức thấp hơn giữa mức điểm và mức ghép học sinh, và dòng Đỏ cuối cùng không gợi ý giá trị. Bất biến 4 trong AGENTS.md đã sửa câu chữ cho khớp.

**Cách đo.** `scripts/recognition/evaluate_pages.py` (cục bộ) chạy pipeline và ba trọng số thật trên ảnh trang, ghép nhãn theo (người, tờ, trang, stt) từ `06_ANH_O_CAT/<valid|test>/manifest_*_{num,txt}.csv`, rồi chạy bộ ghép dòng THẬT của API (`evaluate_matching.ts`) với danh sách lớp trong `BANG_DIEM_CHEP_TAY_Sheet_01_10.xlsx`. DEV = P05, R03, T03 (60 ảnh trang, 1170 ô có nhãn); TEST = P08, R04, R05, T06, T07 (100 ảnh trang, 1960 ô). Không dùng người viết tập TRAIN; đo TEST đúng một lần sau khi khóa cấu hình.

**Cấu hình đã khóa (dò chỉ trên DEV).** τ số 0,95 và τ chữ 0,90 (giá trị của nghiên cứu, không dò lại); sàn đồng thuận 0,00 vì nhánh đồng thuận không có dòng Xanh sai nào trên DEV nên không cần sàn; `NAME_STRONG` 0,85 và `NAME_WEAK` 0,60 giữ nguyên; `MAX_RED_RATIO` 0,30 → 0,34 vì trên DEV 5 trang (trang 2 chỉ 3 dòng) bị từ chối chỉ do đúng một dòng Đỏ (33%) trong khi dòng gán sai vẫn 0 ở mọi giá trị thử (0,30; 0,34; 0,40; 0,50).

**Số liệu (luật nghiên cứu so với luật cũ trước BE-22: Xanh = hai kênh khớp và cả hai ≥ τ; lệch hoặc một kênh = Vàng).**

|      | Tập    | Nguồn  | Đ.số đúng | Điểm chữ đúng | Xanh / Vàng / Đỏ (luật cũ) | Xanh / Vàng / Đỏ (luật mới) | Giá trị cuối đúng, cũ → mới | Xanh sai, cũ → mới |
| ---- | ------ | ------ | --------- | ------------- | -------------------------- | --------------------------- | --------------------------- | ------------------ |
| DEV  | 1170 ô | phone  | 99,3%     | 99,0%         | 52,5 / 47,5 / 0,0%         | 98,3 / 1,2 / 0,5%           | 98,3% → 99,5%               | 0 → 0              |
| DEV  |        | scan   | 99,0%     | 98,6%         | 49,6 / 50,4 / 0,0%         | 97,6 / 1,7 / 0,7%           | 97,6% → 99,0%               | 0 → 0              |
| DEV  |        | tất cả | 99,1%     | 98,8%         | 51,0 / 49,0 / 0,0%         | 97,9 / 1,5 / 0,6%           | 97,9% → 99,2%               | 0 → 0              |
| TEST | 1960 ô | phone  | 90,6%     | 90,7%         | 32,2 / 67,8 / 0,0%         | 83,5 / 11,0 / 5,5%          | 83,5% → 91,0%               | 0 → 1              |
| TEST |        | scan   | 90,6%     | 90,6%         | 31,6 / 68,4 / 0,0%         | 83,4 / 9,2 / 7,4%           | 83,5% → 89,0%               | 0 → 1              |
| TEST |        | tất cả | 90,6%     | 90,7%         | 31,9 / 68,1 / 0,0%         | 83,4 / 10,1 / 6,5%          | 83,5% → 90,0%               | 0 → 2              |

"Giá trị cuối đúng" tính trên mọi ô có nhãn (dòng Đỏ hoặc không gợi ý tính là chưa đúng); trên các dòng có gợi ý, độ chính xác của luật mới là 99,8% (DEV) và 96,2% (TEST), của luật cũ là 100% và 99,8%. Số dòng Vàng có gợi ý sai: DEV 2, TEST 67 (luật cũ: 0 và 4), tức người duyệt phải xem các dòng Vàng. Hai dòng Xanh sai trên TEST (một phone, một scan) là lỗi im lặng còn tồn tại của nhánh đồng thuận: hai mô hình đọc sai giống nhau; DEV không có dòng nào nên không có căn cứ đặt sàn, và không chỉnh sau khi đã xem TEST.

**Ghép học sinh (bộ ghép thật, chỉ các trang có danh sách lớp Sheet_xx; số liệu sau BE-23).** DEV: 725 dòng, gán sai 0; mức cuối (hợp điểm và ghép) Xanh/Vàng/Đỏ 705 / 14 / 6, Xanh cuối sai 0. TEST: 1105 dòng, gán sai 0; mức cuối 816 / 176 / 113, Xanh cuối sai 2 (đúng hai lỗi im lặng của nhánh đồng thuận ở trên; trước BE-23 một trong hai bị mức ghép hạ xuống Vàng nên chỉ thấy 1). Mỗi tập có một trang bị từ chối `TOO_MANY_LOW_CONFIDENCE` (35 dòng; trang này chọn nhầm cột "Lớp" làm cột họ tên). Các trang dùng bộ danh sách khác (T01–T05) không có danh sách lớp trong bộ dữ liệu nên chưa đo phần ghép học sinh. Thời gian: DEV trung vị 1,5 s, lớn nhất 2,9 s mỗi ảnh trang; TEST 1,8 s và 6,1 s (CPU).

## Gom khe ô họ tên bền với ảnh chụp điện thoại (BE-23)

Trên ảnh chụp điện thoại, `compact_name_cell` bỏ sót khe ở 12–13% ô họ tên (DEV: phone 86,8%, scan 89,1% ô được thu khe) vì (a) đường kẻ ngang lọt vào ô khiến mọi cột "có mực", (b) bóng/nền xám làm Otsu toàn cục coi nền là mực, nên VietOCR đọc thiếu phần tên và dòng bị hạ xuống Vàng. Mặt nạ mực nay: bù nền (chia cho nền ước lượng bằng lọc trung vị rồi Otsu), bỏ hàng có mực > 50% chiều rộng, bỏ dải 3 điểm ảnh sát bốn mép ô (tàn dư đường kẻ), và chỉ tính cột có ≥ 2 điểm mực; ô không có điểm nào tối hơn nền đáng kể được coi là trống. Các hằng `NGUONG_KHE_TEN`, `KHE_TEN_SAU_KHI_GOM`, `LE_TEN_SAU_KHI_GOM` và mọi ngưỡng ghép không đổi; ảnh đầu ra vẫn chỉ ghép từ các mảnh của ảnh gốc. Dòng bị gạch không được đọc nên không gom.

| Tập                             | Ô họ tên được thu khe, trước → sau | Gán sai học sinh | Xanh/Vàng/Đỏ cuối, trước → sau    |
| ------------------------------- | ---------------------------------- | ---------------- | --------------------------------- |
| DEV phone                       | 86,8% → 94,0%                      | 0 → 0            | (gộp)                             |
| DEV scan                        | 89,1% → 100%                       | 0 → 0            | (gộp)                             |
| DEV tất cả                      | 87,9% → 97,0%                      | 0 → 0            | 534 / 157 / 32 → 705 / 14 / 6     |
| TEST (đo một lần, sau khi chốt) | 98,2% (phone 96,4%, scan 100%)     | 0                | 495 / 421 / 184 → 816 / 176 / 113 |

Phần ô chưa thu khe (DEV: 35 ô phone) đều thuộc một trang mà cột được chọn làm họ tên thực ra là cột "Lớp"; đó là lỗi chọn cột chứ không phải lỗi gom khe và chưa được xử lý ở bước này.

**Giới hạn đánh giá.** Mọi số liệu đo trên mẫu E0330113 của trường đại học (chữ viết tay chép lại có chủ đích, 41 học sinh, hai trang), không phải bảng điểm cấp 3 thật; chưa có ảnh bảng điểm cấp 3 thật. Độ chính xác TEST thấp hơn DEV rõ rệt (90,6% so với 99,1%) nên không suy ra cho người viết/mẫu khác. Phiếu dùng với hệ thống PHẢI có cột Đ.số và cột Điểm chữ (luật dựa trên hai kênh độc lập). Bố cục cấp 3 mô phỏng chỉ được kiểm bằng ảnh tổng hợp ở mức cấu trúc, không dùng để dò ngưỡng.

## Ràng buộc STT + họ tên (BE-24, BE-24b)

**Quyết định của chủ dự án (BE-24b): mọi dòng phải thỏa cả họ tên lẫn STT; Xanh chỉ khi tên khớp mạnh VÀ STT khớp.** `RECOGNITION_STT_CHECK` mặc định BẬT (đặt 0 để tắt; cùng giá trị cho dịch vụ nhận dạng và worker). STT thay thế quyết định tắt đọc STT của BE-19b nhưng KHÔNG thay họ tên trong việc gán học sinh.

- **Dịch vụ nhận dạng:** với mỗi dòng không bị gạch, đọc ô STT in bằng VietOCR gốc (cùng mô hình với cột họ tên, KHÔNG dùng CRNN) → `sttRead` kèm độ tin cậy; `sttFromPosition` suy theo vị trí dòng bằng bỏ phiếu (`suy_stt_bat_dau`, chịu được vài ô đọc sai và ảnh mất dòng đầu). `stt.value` (STT trên giấy, lưu ở `ket_qua_dong.stt_giay`) = giá trị khi hai nguồn trùng nhau, khác nhau thì null. Hai trường tùy chọn mới ở phản hồi; API bỏ qua chúng nên contract với API không đổi.
- **Gán học sinh vẫn theo họ tên** (ghép một-một tối ưu toàn cục). STT chỉ quyết định gán trong nhóm TRÙNG họ tên: dòng có STT dự kiến khớp đúng một thành viên chưa bị dòng khác nhận thì gán cho thành viên đó.
- **Mô hình độ lệch STT theo trang (BE-24c, thay luật "luôn trừ dòng gạch" của BE-24b).** STT in trên giấy lệch STT trong danh sách lớp đã chốt vì học sinh đã nghỉ (ở dòng bị gạch hoặc ở trang trước), vì giấy sắp theo chữ không dấu, hoặc học sinh bị gạch vẫn còn học. Với mỗi trang, trên các dòng tên khớp mạnh (không trùng họ tên) có `sttOnPaper`, tính delta = `sttOnPaper` − STT theo quy ước, và chọn mô hình khớp nhiều dòng nhất trong {quy ước A, B} × {không cộng, cộng 1 sau mỗi dòng gạch đứng trước}, với k = delta phổ biến nhất của mô hình đó. Hòa → không cộng, rồi A, rồi |k| nhỏ. (A) `Intl.Collator("vi")` như `student-order.ts`; (B) bỏ dấu (NFD, bỏ dấu, đ → d) trước, chỉ khi bằng nhau mới so dấu. Cần ≥ 3 dòng ủng hộ (≥ 2 với trang ≤ 5 dòng, như `suy_stt_bat_dau`); dưới mức đó trang không có mô hình và mọi dòng là "Không xác nhận được STT.". `student-order.ts` và STT hiển thị của hệ thống KHÔNG đổi. Mô hình đã chọn được ghi log có cấu trúc `recognition_stt_model` (phiếu, quy ước, k, cộng dòng gạch, số dòng ủng hộ; không chứa họ tên).
- **Luật mức** (mức cuối = thấp hơn giữa mức điểm và mức ghép; các luật Vàng/Đỏ theo tên giữ nguyên): tên mạnh + STT khớp mô hình → Xanh "Khớp họ tên và STT."; tên mạnh + STT lệch mô hình → Vàng "STT trên giấy N khác STT dự kiến M."; tên yếu + STT lệch mô hình → Đỏ; tên mạnh + không xác nhận được STT → Vàng "Không xác nhận được STT."; trùng họ tên phân biệt được bằng STT (theo mô hình) → Vàng "Trùng họ tên — phân biệt bằng STT N."; không phân biệt được → Đỏ. STT không bao giờ nâng mức của dòng tên yếu hoặc không đọc được.
- **Đánh giá DEV** (60 ảnh trang; hai chế độ danh sách lớp mô phỏng, đều bỏ học sinh ở dòng bị gạch của MỌI trang cùng bộ ảnh khỏi danh sách nếu "đã nghỉ", hoặc giữ nguyên nếu "còn học"): `sttOnPaper` có giá trị ở 96,2% dòng và đúng 96,2% (sai 0; phone 92,6%, scan 99,7%). Gán sai 0 ở cả hai chế độ. Mức cuối Xanh/Vàng/Đỏ (725 dòng đã ghép) = 697 / 22 / 6 ở CẢ HAI chế độ (BE-24b: 697 / 22 / 6; BE-23, không ràng buộc STT: 705 / 14 / 6): 8 dòng Vàng "không xác nhận được STT", 0 dòng Vàng vì STT lệch. Mô hình đã chọn — đã nghỉ: B+gạch k=0 ở 19 trang đầu, A k=2–3 ở 17 trang 2 (độ lệch do học sinh nghỉ ở trang 1), A+gạch k=2 ở 2 trang, không mô hình 1; còn học: B k=0 ở 19 trang đầu, A k=0 ở 19 trang 2, không mô hình 1.
- **Đo TEST một lần** (đây là lần đo SAU KHI sửa logic BE-24c; không chỉnh ngưỡng hay luật theo TEST): `sttOnPaper` có giá trị 94,3% dòng và đúng 94,3% (sai 0). Gán sai 0 trên 1105 dòng ở cả hai chế độ. Mức cuối Xanh/Vàng/Đỏ = 775 / 217 / 113 ở cả hai chế độ (bằng BE-24b; BE-23: 816 / 176 / 113): 73 dòng Vàng "không xác nhận được STT" (2 trang không đủ dòng ủng hộ), 0 vì STT lệch, 0 vì trùng họ tên. Xanh cuối sai 2 (không đổi, là hai lỗi im lặng của nhánh đồng thuận). Mô hình — đã nghỉ: B+gạch k=0 27 trang, A k=3 25, A k=2 3, A+gạch k=2 2, không mô hình 2; còn học: B k=0 27, A k=0 30, không mô hình 2.
- **Đã xử lý ở BE-24c:** luật BE-24b chỉ trừ dòng gạch trên chính trang nên trang 2 bị Vàng khi học sinh nghỉ ở trang 1 (phát hiện ở lớp thử); mô hình k theo trang hấp thụ độ lệch cố định đó, và học sinh bị gạch nhưng còn học không còn bị coi là lệch.
- **Giới hạn:** chỉ đo trên mẫu E0330113 (thứ tự giấy theo chữ không dấu); danh sách lớp thật của trường có thể theo quy ước khác, khi đó trang hòa về A. Các trang dùng bộ danh sách T01–T05 chưa đo ghép học sinh. STT suy theo vị trí cần ít nhất 3 phiếu đồng ý (2 với trang ≤ 5 dòng), dưới mức này mọi dòng thành Vàng "Không xác nhận được STT".

## Tiêu chí nghiệm thu

- Thứ tự mã ≠ thứ tự tên: kết quả gán đúng học sinh theo STT.
- Thêm học sinh mới hoặc cho nghỉ học sau khi tạo phiếu: ánh xạ không đổi.
- Roster sai lớp, học sinh nghỉ, STT không liên tục hoặc trùng bị từ chối (`INVALID_ROSTER_SNAPSHOT`); STT ngoài snapshot hoặc trùng trong kết quả bị từ chối (`MALFORMED_RECOGNITION_RESULT`).
- Runtime không UPDATE/DELETE được `danh_sach_phieu`.
- Duyệt phiếu ghi điểm đúng học sinh trong snapshot; `diem_thanh_phan` không bị ghi trước khi duyệt.
- Upload không cần `declaredRows`; replay idempotent không tạo bản ghi lặp.
- Test thuật toán ghép (dữ liệu giả): đúng thứ tự, trang 2 bắt đầu STT 39, dòng gạch, giấy lệch một dòng, OCR sai 1–2 ký tự, trùng họ tên, không đọc được STT, sai lớp → `ROW_MATCH_FAILED`, hai dòng cùng học sinh → lỗi.
- Không có lỗi im lặng: dòng Xanh sai học sinh hoặc sai điểm được ưu tiên giảm hơn số dòng Vàng (đo ở BE-22).

## Kết quả dò ngưỡng

Chưa có. Sẽ cập nhật ở BE-22 sau khi có ảnh bảng điểm cấp 3 có nhãn.
