# Chạy và review Giai đoạn 1

Đồng nghiệp lấy nhánh Phase 1, chạy các lệnh README. Với DB đã có Phase 0: `pnpm db:generate`, `pnpm db:migrate`, `pnpm db:seed`; không chạy `db push`, không sửa hai migration cũ. Nâng cấp chỉ thêm migration `202609100001_identity_catalog`.

Màn hình đầu tiên là đăng nhập. Seed có `demo_admin`, `demo_teacher_a`, `demo_teacher_b`, `demo_student_a`, `demo_student_b`. Mật khẩu là `SEED_PASSWORD` trong `.env` của chính máy đó, không phải mật khẩu PostgreSQL/pgAdmin. Seed không đổi mật khẩu tài khoản đã tồn tại. Quản trị viên có thể đặt lại mật khẩu trong màn hình Tài khoản.

Thứ tự tạo dữ liệu: tài khoản giáo viên → hồ sơ giáo viên; năm học → học kỳ → lớp (gán chủ nhiệm); môn → thành phần; phân công lớp–môn–học kỳ; tài khoản học sinh nếu cần → học sinh và lớp. Hệ số nhập chuỗi hai chữ số thập phân, ví dụ `1.00`; API trả cùng định dạng. Ngày dùng YYYY-MM-DD. Bỏ cờ năm hiện hành cũ trước khi bật năm mới; DB không cho hai năm cùng hiện hành.

QTV quản lý danh mục/tài khoản. GV xem danh mục và danh sách học sinh trong lớp được phân công; lớp chủ nhiệm cho quyền xem lớp, không cấp quyền nhập điểm. HS chỉ hồ sơ liên kết tài khoản của mình. Tên và thông tin liên hệ cá nhân sửa qua nút Hồ sơ; lớp/vai trò không được tự sửa. Chưa có tra cứu điểm UC18.

Web dùng cookie HttpOnly, cần cùng site giữa web/API (localhost cho local), `ALLOWED_ORIGINS` đúng origin web. Native giữ phiên trong bộ nhớ, mở lại app đăng nhập lại. Đổi mật khẩu/vai trò/khóa thu hồi tất cả phiên. Không log hay chia sẻ cookie/bearer. Với reverse proxy, phase này dùng IP socket để rate-limit (không tin X-Forwarded-For); cần cấu hình proxy tin cậy trước production.

Reviewer kiểm: không đăng nhập bị 401; GV/HS ghi danh mục bị 403; teacher B không thấy học sinh teacher A; HS không thấy HS khác; cookie mutation thiếu CSRF bị 403; khóa/đổi mật khẩu thu hồi phiên; năm học/học kỳ lệch bị từ chối; audit không sửa/xóa được. Chạy `pnpm check`, `pnpm test:db`, `pnpm test:integration`, `pnpm contracts:check`, `dart run melos run check`; integration cần TEST_MIGRATION_URL và TEST_RUNTIME_URL trỏ DB `_test` có seed giả.

Rollback: không gỡ audit hoặc sửa migration đã chạy. Nếu lỗi, quay lại phiên bản ứng dụng đã duyệt và xử lý bằng migration tiến tiếp; dữ liệu danh mục và audit được giữ. API Phase 0 không sử dụng ba bảng kỹ thuật mới. Không dùng role migration để chạy API.
