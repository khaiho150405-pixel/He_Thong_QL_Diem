# ADR-0022: Đóng năm học và thống kê theo năm

## Trạng thái

Accepted (2026-11-26, chủ dự án chọn làm đợt 1 của lộ trình lưu trữ năm học).

## Bối cảnh

Dữ liệu mọi năm nằm chung database, tách theo `nam_hoc`. Chuyển năm hiện hành không khóa năm cũ; học kỳ đã công
bố vẫn bỏ công bố được rồi tính lại theo quy tắc mới; tổng quan quản trị cộng gộp mọi năm.

## Quyết định

1. `nam_hoc.da_dong_luc` đánh dấu năm đã đóng. Một năm không thể vừa hiện hành vừa đã đóng.
2. Chỉ hàm `doi_trang_thai_nam_hoc` (QTV, giao dịch SERIALIZABLE, bắt buộc lý do 1–500 ký tự) đóng hoặc mở lại;
   `app_runtime` mất quyền sửa cột trạng thái. Mỗi lần ghi một dòng `lich_su_dong_nam` (chỉ ghi thêm) và nhật ký
   `ACADEMIC_YEAR_CLOSED` / `ACADEMIC_YEAR_REOPENED`.
3. Chỉ đóng được khi (`kiem_san_sang_dong_nam`): không phải năm hiện hành; mọi học kỳ có phân công hoặc bảng điểm
   đã công bố; không còn bảng chưa khóa, phiếu nhận dạng hoặc đơn điều chỉnh đang chờ; không còn học sinh ghi danh
   `DANG_HOC` (đã lên lớp, lưu ban, tốt nghiệp hoặc nghỉ học). Chưa đến ngày kết thúc năm chỉ là cảnh báo.
4. Thứ tự cuối năm vì vậy là: công bố → tạo lớp năm mới → xếp lên lớp → chuyển năm hiện hành → đóng năm cũ. Đề
   xuất ban đầu đặt "đóng" trước "xếp lớp"; đổi lại vì xếp lớp phải ghi vào ghi danh của năm cũ.
5. Với năm đã đóng, trigger `a_year_closed_guard` trả `YEAR_CLOSED` khi ghi vào học kỳ, lớp, ghi danh, phân công,
   thời khóa biểu, hệ số, lịch nhập, bảng điểm, ô điểm, chốt cột, tổng kết, phiếu mới và đơn điều chỉnh mới; thông
   tin năm cũng không sửa, không xóa được. Bỏ công bố học kỳ của năm đã đóng bị chặn theo cùng đường này.
6. API: `GET /catalog/years/{id}/closing`, `POST .../close`, `POST .../reopen`; danh sách năm trả `da_dong_luc`.
   `GET /reports/admin/overview?yearId=` thống kê riêng một năm (học sinh tính theo ghi danh còn đến cuối năm).
7. Giao diện: nút đóng/mở lại trên danh sách năm học, nhãn "Đã đóng", bộ chọn năm ở tổng quan quản trị (mặc định
   năm đang xem).

## Hệ quả và giới hạn

- Danh mục dùng chung (họ tên học sinh, giáo viên, tên môn, cấu trúc cột, tên trường) không thuộc năm nào nên vẫn
  đổi được; muốn giữ nguyên hiển thị năm cũ cần bản chốt cuối năm (đợt 2).
- Mức kết quả học tập học kỳ vẫn tính khi xem.
- Học kỳ chưa đóng năm vẫn bỏ công bố được như trước.
- Xóa hẳn học sinh chưa có dữ liệu nhưng từng ghi danh ở năm đã đóng sẽ bị chặn; mở lại năm nếu thật sự cần. Ẩn
  danh học sinh đã có dữ liệu vẫn thực hiện được.
- Rollback: gỡ trigger, hàm và bảng của migration `202611290001_year_closing`, bỏ cột `da_dong_luc`, cấp lại quyền
  `UPDATE` trên `nam_hoc`.
