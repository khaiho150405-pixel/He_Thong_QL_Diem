# Chụp và tải ảnh bảng điểm

## Phạm vi UC11–UC13

Giáo viên chọn thành phần điểm trên bảng đang nhập liệu (không còn chọn số dòng khai báo; backend tự chốt danh sách học sinh theo STT và tự ghép theo họ tên theo ADR-0015). Điện thoại có nút **Chụp ảnh**; web/desktop có nút chọn tệp PNG/JPEG. Hướng dẫn chụp: _"Chụp thẳng toàn bộ bảng, đủ sáng, rõ các cột Họ tên, Điểm số, Điểm chữ. PNG hoặc JPEG, tối đa 10 MB. Hệ thống tự xác định học sinh theo họ tên."_ Ảnh được xem trước, phóng to, bỏ chọn hoặc thay ảnh trước khi gửi. Hủy hộp chọn không làm mất ảnh đang chọn. Upload chỉ bật khi có ảnh hợp lệ, hiển thị tiến độ và giữ ảnh khi gửi lỗi để thử lại.

Client kiểm nội dung PNG/JPEG, giới hạn 10 MiB, chiều tối đa 10.000 pixel và tổng tối đa 40 triệu pixel, rồi thử giải mã ảnh trước khi hiển thị. Backend vẫn kiểm độc lập và giữ quyền phân công, idempotency, checksum, lưu private. HEIC cần chuyển sang JPEG/PNG. Khi chụp, lấy đủ khung bảng, đặt máy thẳng, đủ sáng và tránh bóng/ánh phản chiếu.

Sau khi tải ảnh lên, polling 3 giây theo dõi trạng thái phiếu. Khi phiếu chuyển sang `CHO_DOI_CHIEU`, ứng dụng tự động điều hướng sang **Màn hình kiểm tra riêng** (`/gradebooks/:id/recognition/:ticketId`). Nếu phiếu chuyển sang `LOI`, hệ thống hiển thị thông báo lỗi thân thiện theo `errorCode` (ví dụ: `ROW_MATCH_FAILED`, `IMAGE_UNREADABLE`, `GRID_NOT_FOUND`,...) kèm nút "Chụp lại" hoặc "Chọn ảnh khác".

Màn hình kiểm tra hiển thị danh sách dòng đã được ghép theo STT hệ thống:

- Ảnh cắt ô họ tên trên giấy (`nameCropUrl`, hỗ trợ chạm phóng to), STT hệ thống, tên học sinh trong danh sách đã chốt.
- Họ tên máy đọc (`nameRead`), độ tin cậy ghép (`matchConfidence`) và ghi chú ghép (`matchNote`).
- Ảnh cắt ô Điểm số (`numericCropUrl`) và Điểm chữ (`writtenCropUrl`), giá trị hai kênh kèm độ tin cậy.
- **Yêu cầu phiếu:** bảng điểm chụp phải có cột Đ.số (điểm số) và cột Điểm chữ vì phân loại dựa trên hai kênh độc lập. Xanh = hai kênh cùng giá trị; Vàng = chỉ một kênh đủ tin cậy, ô được điền sẵn giá trị kênh đó kèm ghi chú "Lấy theo điểm số" hoặc "Lấy theo điểm chữ"; Đỏ = mâu thuẫn hoặc cùng yếu, không điền sẵn (ADR-0015).
- Phân loại màu Xanh / Vàng / Đỏ (gộp từ mức điểm và mức ghép) với bộ lọc 3 màu và sắp xếp ưu tiên dòng Vàng/Đỏ cần chú ý trước.
- **Bất biến:** Dòng Đỏ tuyệt đối không tự điền giá trị đề xuất (ô nhập để trống); giáo viên bắt buộc phải xem/xác nhận tất cả các dòng trước khi bấm Duyệt. Khi duyệt thành công, giao dịch nguyên tử ghi điểm chính thức và quay lại màn hình bảng điểm để tự động tải lại dữ liệu mới nhất.

## Tích hợp nền tảng

Thêm `image_picker` 1.2.0 vì file picker hiện có không cung cấp camera native. Khóa dependency trong pubspec.lock. iOS khai báo quyền camera/thư viện ảnh ở Runner/Info.plist. Android khôi phục ảnh qua retrieveLostData khi activity bị hệ điều hành hủy; người dùng vẫn kiểm tra đúng bảng/thành phần trước khi gửi. Desktop không hiển thị camera khi chưa có camera delegate.

Mô hình thật chưa được bật: checkpoint đã có nhưng còn thiếu mã/config inference, preprocessing, charset/decoder và tách lưới. `MODEL_UNAVAILABLE` phải hiển thị rõ; không đổi sang fake để tạo kết quả thật. Điểm chỉ được ghi qua giao dịch duyệt của người có quyền.

## Kiểm chứng và kiểm tra thủ công

- `flutter analyze`, `flutter test`; test `recognition_upload_ux_test.dart` kiểm ảnh sai, quá dung lượng, MIME theo nội dung, camera/file, hủy chọn, preview, phóng to, upload và đối chiếu trên profile Android 320, iOS 390 với chữ 1,3×, desktop 1280.
- `phase3_recognition_test.dart` kiểm luồng upload, evidence, nhập/sửa và duyệt với adapter HTTP test; không dùng mô hình giả trong production.
- Trên thiết bị thật: cấp/từ chối quyền camera; chụp ngang/dọc; hủy camera; Android activity bị hủy; chọn ảnh JPEG/PNG lớn; mạng chậm/mất mạng và thử lại; cuộn/phóng ảnh và duyệt khi lọc. iOS cần macOS/Xcode.
- Widget profile không thay thế kiểm camera hoặc simulator thật. Build Android trên máy Windows hiện bị lỗi Gradle loopback (`Unable to establish loopback connection`); cần xử lý môi trường và build lại trước khi nghiệm thu Android.

## Nhận dạng theo mẫu: nhiều trang, nhiều cột (ADR-0016 mục 5)

Đầu panel nhận dạng có ô **Mẫu bảng điểm** (các mẫu `DANG_DUNG` cộng "Không dùng mẫu (mẫu E0330113 cũ)"). Lựa chọn được nhớ cho bảng điểm này trong phiên chạy, không lưu ra đĩa. Không chọn mẫu, hoặc chưa có mẫu nào đang dùng, thì panel hoạt động y hệt luồng một ảnh ở trên.

Khi chọn mẫu:

1. **Ảnh các trang:** thêm 1–4 ảnh theo đúng thứ tự trang của tờ. Mỗi ảnh có thẻ "Trang n", xóa được, đổi thứ tự bằng nút lên/xuống. Quá 4 ảnh thì hiện thông báo và không thêm. Ảnh qua cùng bước kiểm nội dung/dung lượng như luồng một ảnh.
2. **Xác nhận cột:** danh sách từ `/mapping`, mỗi dòng "Cột TX1 → Kiểm tra thường xuyên 1 · số + chữ" (hoặc "chỉ số") với checkbox. Cột bị khóa, đang có phiếu chờ hoặc không có thành phần tương ứng thì không chọn được và ghi lý do. Nút **Tải ảnh & Nhận dạng** chỉ bật khi có ≥ 1 ảnh và ≥ 1 cột. Bảng một kênh (chỉ số) tối đa Vàng (D-01).
3. **Gửi và theo dõi:** gửi lô với idempotency key, có tiến độ tải lên và nút hủy tải lên; sau đó polling 3 giây. Lỗi lô hiện thông báo theo `errorCode` kèm số trang (ví dụ `TEMPLATE_MISMATCH`: "Trang 2: Ảnh không khớp lưới của mẫu đã chọn…"). Có nút **Hủy lô** (hủy mềm mọi phiếu chưa duyệt, bắt buộc lý do).
4. **Kết quả lô:** màn `/gradebooks/:id/recognition-batches/:batchId` có tab theo thành phần, mỗi tab hiện số Xanh/Vàng/Đỏ. Bấm tab mở **màn đối chiếu hiện có** của đúng phiếu đó; duyệt vẫn theo từng phiếu (bất biến 1 và 6). Dòng của phiếu thuộc lô hiện nhãn "Trang n".
5. **Thẻ phiếu gần đây:** phiếu thuộc lô hiện "N ảnh · tên mẫu".

Kiểm chứng: `test/recognition_batch_test.dart` (repository giả: luồng đầy đủ, cột khóa, quá 4 ảnh, `TEMPLATE_MISMATCH` và các lỗi gửi lô, hủy lô, "Không dùng mẫu", responsive 320/390/1280 với chữ 1,3×). Các test nhận dạng cũ giữ nguyên assertion.

## Chụp ảnh theo mẫu và tờ THPT in được (P6)

- **Chụp để khớp mẫu:** hệ thống so lưới ảnh với lưới của mẫu đã chọn. Chụp thẳng, thấy trọn bảng và **đủ mọi vạch dọc** (không để bóng, nếp gấp hay chữ đè làm mất vạch). Ảnh lệch lưới hoặc không đúng mẫu bị từ chối bằng `TEMPLATE_MISMATCH` và không có dòng nào được ghi; hãy chụp lại hoặc chọn đúng mẫu, không cố gửi lại ảnh cũ. Trên bộ DEV, khoảng 7% ảnh điện thoại bị từ chối vì mất vạch (báo cáo `docs/reports/recognition/Danh_gia_mau_bang_diem_2026-10-19.md`).
- **Bảng một kênh** (chỉ cột điểm số, như tờ THPT TX1–TX4, GK, CK): mọi dòng tối đa Vàng, giáo viên xem và xác nhận từng dòng (D-01); không bao giờ Xanh.
- **Tờ THPT in được:** `python scripts/recognition/make_thpt_form.py --out-dir .local/forms [--seed N] [--names-file ten_gia.txt] [--write-layout scripts/recognition/layouts/thpt_tt22.json]` sinh `so_diem_thpt_tt22.pdf` và `.png` (A4, 200 dpi, 40 dòng; tên in sẵn là dữ liệu giả). In ở tỉ lệ 100%, không chọn "vừa trang"; nếu không đọc được PDF thì in từ PNG ở 200 dpi. Khai báo mẫu từ ảnh của tờ này, hoặc dùng layout có sẵn `thpt_tt22.json` khi thử bằng `evaluate_pages.py`. Đây là mẫu **mô phỏng**, chưa đo trên chữ viết tay cấp 3 thật.
