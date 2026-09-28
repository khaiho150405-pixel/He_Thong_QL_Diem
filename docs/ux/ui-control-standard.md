# Chuẩn control và thanh thao tác

Tài liệu này là chuẩn mặc định khi thêm hoặc sửa giao diện Flutter. Các giá trị
thực thi nằm tại `apps/client_flutter/lib/app/widgets/app_controls.dart` và
`apps/client_flutter/lib/app/theme.dart`; không khai báo lại kích thước riêng
trong từng feature.

## Control lọc và tìm kiếm

- Chiều cao: `48 px`.
- Chiều rộng desktop/tablet: `300 px`; trên màn hình nhỏ tự co theo vùng trống.
- Bo góc: `10 px`.
- Khoảng cách ngang: `12 px`; khoảng cách khi xuống dòng: `10–12 px`.
- Icon đầu dòng: `18 px`, vùng chạm tối thiểu `44 × 48 px`.
- Nhãn luôn nổi để nội dung đã chọn không che tên trường.
- Dropdown phải `isExpanded` và co nội dung dài thay vì cắt chữ hoặc tràn.
- Nhóm control dùng `Wrap` để tự xuống dòng; không dùng `Row` cố định cho bộ lọc.

## Nút thao tác

- Chiều cao: `48 px`; nút cùng nhóm có chiều rộng `164 px`.
- Hành động chính như **Thêm mới**, **Lưu**, **Xác nhận** dùng `FilledButton`.
- Hành động phụ như **Nhập từ file**, **Xuất**, **Đặt lại** dùng
  `OutlinedButton` hoặc `TextButton` theo mức độ ưu tiên.
- Nút cùng nhóm dùng cùng bo góc, icon `18 px`, cùng khoảng cách và tự xuống dòng.
- Không xếp hai Floating Action Button khác chiều rộng thành một cột.

## Cuộn và responsive

- Nội dung dài theo trang phải có một vùng cuộn dọc rõ ràng.
- `AppScaffold` đặt `AppEdgeScrollbar` ở mép ngoài vùng nội dung trang, trước padding và giới hạn chiều rộng. Controller riêng cho trang, kế thừa trên mọi nền tảng; chỉ nhận thông báo từ vị trí cuộn do nó quản lý. Không bọc Navigator: menu và dialog phải cuộn độc lập. Không tạo scrollbar dọc tự động trùng trong vùng nội dung.
- Bảng rộng được cuộn ngang bên trong vùng cuộn dọc; hai trục không tranh gesture.
- Thanh công cụ không đủ chiều rộng được cuộn ngang hoặc xuống dòng có kiểm soát;
  không ép `Row` làm mất chữ. Tiêu đề dài dùng `Flexible`/`Expanded`, giới hạn số
  dòng và ellipsis khi cần.
- Màn hình phải dùng được ở rộng `320 px`, tablet và desktop, kể cả text scale
  `150%`.
- Khi thêm control mới, ưu tiên `AppFilterDropdown`, `AppActionButton` và
  `AppControlMetrics.decoration` trước khi tạo style riêng.
