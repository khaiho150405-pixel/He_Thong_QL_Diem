# ADR-0005 — Phiên và quyền danh mục

Chọn phiên opaque do PostgreSQL quản lý (phương án tương đương session bảo mật trong AGENTS.md). Token ngẫu nhiên 256 bit, DB chỉ giữ SHA-256, 30 phút idle/8 giờ tuyệt đối. Web dùng cookie HttpOnly, SameSite=Strict, Secure ngoài development; mọi mutation dùng Origin allowlist và X-CSRF-Token gắn phiên. Login dùng Origin allowlist và header riêng chống form CSRF. Native dùng bearer token trong bộ nhớ, không lưu bền nên mở lại ứng dụng phải đăng nhập lại; không có secret trong localStorage hoặc preferences.

Khóa 15 phút sau 5 lần sai theo HTML; throttling IP bền vững trong DB giới hạn brute force tên không tồn tại. Argon2id có cấu hình được kiểm tra, tối thiểu 64 MiB/3 lượt/1 luồng. Thay đổi mật khẩu/vai trò/khóa thu hồi phiên ngay, bắt đăng nhập lại. Audit kỹ thuật append-only độc lập lịch sử điểm.

Danh mục do QTV quản lý; GV xem lớp chủ nhiệm/lớp được phân công, học sinh trong lớp được dạy, hồ sơ và phân công của mình. HS chỉ endpoint hồ sơ của mình. Không dùng quyền chủ nhiệm thay quyền nhập điểm. Mutation dùng transaction serializable có retry hữu hạn và kiểm tra tham chiếu trước thay đổi. Không chốt công thức tổng kết trong Phase 1.

Rollback bằng forward migration; không xóa bảng audit. Không thay stack hoặc thêm dịch vụ. Session bộ nhớ native giảm tiện lợi nhưng tránh thêm dependency lưu bí mật trước khi có nhu cầu lưu đăng nhập lâu dài.
