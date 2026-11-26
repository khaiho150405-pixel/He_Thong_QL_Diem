# ADR-0020: Quản trị viên xóa thông tin học sinh

## Trạng thái

Accepted (2026-11-27, chủ dự án chốt).

## Quyết định

Quản trị viên xóa thông tin một học sinh qua `DELETE /api/v1/catalog/students/{id}`, thực hiện bằng hàm
`xoa_hoc_sinh` (migration `202611270001_student_removal`):

- Học sinh chưa có dữ liệu (không có giá trị điểm, miễn điểm, lịch sử, tổng kết, phiếu nhận dạng): xóa hẳn hồ
  sơ, ghi danh và các ô điểm trống.
- Học sinh đã có dữ liệu: ẩn danh. Họ tên thành "Học sinh đã xóa #<mã>", ngày sinh thành 1900-01-01, gỡ liên kết
  và khóa tài khoản, xóa phiên đăng nhập, đóng ghi danh đang học, ẩn tên trong danh sách chốt của phiếu và tên máy
  đọc được; điểm và lịch sử giữ nguyên. Hồ sơ đã ẩn danh không sửa được và không hiện trong danh mục.
- Mỗi lần xóa ghi một dòng `nhat_ky_bao_mat` (`STUDENT_DELETED` hoặc `STUDENT_ANONYMIZED`).

Bất biến "không hard-delete điểm, lịch sử, phiếu" của AGENTS.md vẫn giữ.

## Hạn chế

Ảnh gốc và ảnh ô cắt trong kho đối tượng vẫn chứa họ tên viết trên tờ điểm. Lý do ghi trong nhật ký sửa điểm không
được rà lại. Bản sao lưu cũ vẫn chứa dữ liệu trước khi xóa.

## Thao tác một lần (2026-11-27)

Theo yêu cầu và xác nhận của chủ dự án, database dùng cho deploy được cắt còn mỗi khối một lớp (10A1, 11A1, 12A1):
xóa hẳn 12 lớp, 492 học sinh, 10 bảng điểm (492 giá trị điểm của 10A2), 10 phân công, 28 tiết thời khóa biểu và
6 phiếu nhận dạng. Đây là dọn dữ liệu thử, không phải luồng của ứng dụng. Bản sao lưu trước khi xóa nằm trong
`.local/backups`.
