# Giai đoạn 1 — Tài khoản và danh mục

Nhánh thực hiện từ main `02ec66d` (PR #1 đã merge). Nguồn: AGENTS.md và HTML §3–4, UC01–08. Trạng thái: đang triển khai, chưa nghiệm thu.

## Acceptance criteria

1. UC01–02: xác thực Argon2id, lỗi đăng nhập không tiết lộ tài khoản; khóa 15 phút sau 5 lần sai; phiên hết hạn sau 30 phút không hoạt động và tối đa 8 giờ; đăng xuất thu hồi ngay.
2. UC03–04: QTV tạo/cập nhật/khóa/mở/đặt lại mật khẩu và vai trò; người dùng tự đổi mật khẩu. Thay đổi bảo mật thu hồi mọi phiên; không khóa/hạ quyền QTV cuối cùng. Audit trong cùng transaction.
3. UC05–08: CRUD danh mục qua API có DTO, cursor, validation và lỗi ổn định; QTV ghi, GV chỉ đọc trong phạm vi; HS chỉ hồ sơ của mình. Không xóa dữ liệu có tham chiếu.
4. Năm học/học kỳ/lớp/phân công nhất quán; tài khoản HS/GV đúng vai trò; không chuyển lớp học sinh đã có điểm hay đổi cấu trúc đã dùng làm sai dữ liệu cũ.
5. Flutter có đăng nhập/đăng xuất, điều hướng theo vai trò, danh sách và form danh mục qua client sinh từ OpenAPI; loading/empty/error/retry.
6. Kiểm thử PostgreSQL thật cho phiên, quyền âm tính, CSRF, thu hồi, ràng buộc và rollback. Contract generation, backend checks, Flutter analyze/test/build; ghi riêng giới hạn native CI.

## Thứ tự và giới hạn

Migration kỹ thuật → identity/authorization → danh mục → OpenAPI/client → Flutter → integration/UI checks. Giữ nguyên migration Phase 0. Không triển khai ghi điểm/OCR/tổng kết trong giai đoạn này. Các checklist chỉ được đánh dấu bằng kết quả thực chạy.

## Kiểm chứng và hướng dẫn

Web thực tế: đăng nhập bằng tài khoản giả trên DB test riêng, tạo năm học qua cookie/CSRF và hiển thị lại danh sách. Bố cục danh sách được kiểm ở 390 px và desktop. Test dữ liệu bổ sung kiểm hồ sơ cá nhân chống thay lớp, tìm kiếm không vượt scope và rollback cả dữ liệu/audit sau lỗi chủ động.

[Onboarding và kịch bản review](phase-1-onboarding.md). Migration đã chạy nâng cấp trên DB test có Phase 0 và chạy từ rỗng trên DB test riêng. PostgreSQL integration đã kiểm chứng đăng nhập, CSRF, khóa/mở, phân quyền dữ liệu, thu hồi và hết phiên. API connection bắt buộc timezone UTC; test idle expiry phát hiện lỗi timezone trên PostgreSQL Windows và đã được sửa.

Đã chạy thành công: `pnpm check`, `pnpm contracts:check`, `pnpm test:db`, test API `identity-catalog.test.ts`, Flutter analyze, 7 unit/widget tests và `flutter build web`. Test giao diện kiểm tra hai kích thước 390/1280 px, lỗi đăng nhập/thử lại, tạo năm học, logout và menu học sinh. CI native được bổ sung cùng luồng UI qua HTTP adapter test; kiểm tra kết nối native vẫn dùng API thật. Chưa coi CI Phase 1 hoặc nghiệm thu Android/iOS là hoàn tất dựa vào CI Phase 0.
