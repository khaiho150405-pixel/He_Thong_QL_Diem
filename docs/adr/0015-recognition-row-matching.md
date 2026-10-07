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
4. **Ghép dòng theo STT và họ tên đọc trên giấy**, bằng căn chỉnh quy hoạch động giữ thứ tự giữa dòng trên ảnh và danh sách đã chốt (miền thuần ở API). Dịch vụ nhận dạng Python không nhận danh sách học sinh để không gửi dữ liệu cá nhân sang dịch vụ ML.
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
