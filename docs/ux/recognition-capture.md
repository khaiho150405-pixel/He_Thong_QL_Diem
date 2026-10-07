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
