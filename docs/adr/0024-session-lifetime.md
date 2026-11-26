# ADR-0024: Thời hạn phiên web 3 ngày, app 7 ngày

## Trạng thái

Accepted (2026-11-27, chủ dự án chốt). Thay thế mốc 8 giờ / 30 phút không hoạt động của ADR-0005.

## Quyết định

- Phiên web: tối đa 3 ngày (`phien_lam_viec.het_han`, cookie `qld_session` cùng thời hạn).
- Phiên app (đăng nhập hoặc đổi mã ghi nhớ): tối đa 7 ngày. Mã ghi nhớ vẫn 30 ngày, gia hạn mỗi lần dùng.
- Không đăng xuất vì không thao tác trước khi phiên hết hạn. Mốc không hoạt động nâng lên 7 ngày ở API
  (`session-policy.ts`) và ở mọi hàm SQL kiểm phiên (migration `202612010001_session_lifetime`), nên thời hạn tuyệt
  đối mới là giới hạn thực tế.
- Đăng xuất, đổi mật khẩu, khóa tài khoản và đổi vai trò vẫn hủy phiên ngay như trước.

## Hệ quả

- Người dùng chung máy hoặc lấy được cookie có thể dùng tiếp tới hết hạn nếu chủ tài khoản không đăng xuất. Đây là
  đánh đổi chủ dự án chấp nhận để đỡ phải đăng nhập lại; yêu cầu "access token ngắn hạn" ở AGENTS.md mục 9 được nới
  theo quyết định này.
- Rollback: đặt lại hằng số trong `session-policy.ts` và chạy migration mới đổi `7 days` về `30 minutes`.
