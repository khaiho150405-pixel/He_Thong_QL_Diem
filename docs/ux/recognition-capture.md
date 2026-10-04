# Chụp và tải ảnh bảng điểm

## Phạm vi UC11–UC13

Giáo viên chọn thành phần điểm và số dòng trên bảng đang nhập liệu. Điện thoại có nút **Chụp ảnh**; web/desktop có nút chọn tệp PNG/JPEG. Ảnh được xem trước, phóng to, bỏ chọn hoặc thay ảnh trước khi gửi. Hủy hộp chọn không làm mất ảnh đang chọn. Upload chỉ bật khi có ảnh hợp lệ, hiển thị tiến độ và giữ ảnh khi gửi lỗi để thử lại.

Client kiểm nội dung PNG/JPEG, giới hạn 10 MiB, chiều tối đa 10.000 pixel và tổng tối đa 40 triệu pixel, rồi thử giải mã ảnh trước khi hiển thị. Backend vẫn kiểm độc lập và giữ quyền phân công, idempotency, checksum, lưu private. HEIC cần chuyển sang JPEG/PNG. Khi chụp, lấy đủ khung bảng, đặt máy thẳng, đủ sáng và tránh bóng/ánh phản chiếu.

Biểu mẫu tự xuống dòng trên màn nhỏ, tên thành phần được xuống dòng; ảnh gốc/ảnh ô có chế độ phóng to. Màn đối chiếu hiển thị riêng hai kênh và confidence, kiểm tất cả dòng kể cả dòng bị lọc trước khi duyệt. Dòng đỏ không tự đề xuất điểm. Fake model có cảnh báo; lỗi model/queue không hướng dẫn người dùng đổi ảnh sai nguyên nhân.

## Tích hợp nền tảng

Thêm `image_picker` 1.2.0 vì file picker hiện có không cung cấp camera native. Khóa dependency trong pubspec.lock. iOS khai báo quyền camera/thư viện ảnh ở Runner/Info.plist. Android khôi phục ảnh qua retrieveLostData khi activity bị hệ điều hành hủy; người dùng vẫn kiểm tra đúng bảng/thành phần trước khi gửi. Desktop không hiển thị camera khi chưa có camera delegate.

Mô hình thật chưa được bật: checkpoint đã có nhưng còn thiếu mã/config inference, preprocessing, charset/decoder và tách lưới. `MODEL_UNAVAILABLE` phải hiển thị rõ; không đổi sang fake để tạo kết quả thật. Điểm chỉ được ghi qua giao dịch duyệt của người có quyền.

## Kiểm chứng và kiểm tra thủ công

- `flutter analyze`, `flutter test`; test `recognition_upload_ux_test.dart` kiểm ảnh sai, quá dung lượng, MIME theo nội dung, camera/file, hủy chọn, preview, phóng to, upload và đối chiếu trên profile Android 320, iOS 390 với chữ 1,3×, desktop 1280.
- `phase3_recognition_test.dart` kiểm luồng upload, evidence, nhập/sửa và duyệt với adapter HTTP test; không dùng mô hình giả trong production.
- Trên thiết bị thật: cấp/từ chối quyền camera; chụp ngang/dọc; hủy camera; Android activity bị hủy; chọn ảnh JPEG/PNG lớn; mạng chậm/mất mạng và thử lại; cuộn/phóng ảnh và duyệt khi lọc. iOS cần macOS/Xcode.
- Widget profile không thay thế kiểm camera hoặc simulator thật. Build Android trên máy Windows hiện bị lỗi Gradle loopback (`Unable to establish loopback connection`); cần xử lý môi trường và build lại trước khi nghiệm thu Android.
