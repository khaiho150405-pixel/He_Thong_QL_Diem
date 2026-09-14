# Checklist sẵn sàng phát hành

Tài liệu này là cổng kiểm soát trước staging, Google Play internal testing, TestFlight và production. Mỗi mục chỉ được đánh dấu đạt khi có đường dẫn bằng chứng hoặc mã run; không ghi secret, mật khẩu, token hay PII vào tệp này.

## Baseline đã xác minh

| Hạng mục                                                                    | Trạng thái  | Bằng chứng                                                                                   |
| --------------------------------------------------------------------------- | ----------- | -------------------------------------------------------------------------------------------- |
| Security headers, TLS config, backup/restore, load smoke                    | Đạt trên CI | Run `34764178335`                                                                            |
| Rate limit upload dùng chung, quyền runtime tối thiểu                       | Đạt trên CI | Commit `93e32ec`, run `34764178335`                                                          |
| Flutter Web SPA fallback, cache, dotfile và security header trên Nginx thật | Đạt trên CI | Commit `46fd73d`, run `34765154536`                                                          |
| Flutter Web development, Android debug/emulator, iOS simulator              | Đạt trên CI | Run `34765154536`                                                                            |
| Model nhận dạng production                                                  | Hoãn        | Chưa có weights; production phải trả `MODEL_UNAVAILABLE`, máy không được ghi điểm chính thức |

## Thông tin chủ dự án phải chốt

- [ ] Tên ứng dụng hiển thị chính thức trên Web, Android và iOS.
- [ ] Android application ID chính thức. Giá trị tạm hiện tại: `vn.edu.quanlydiem.client_flutter`.
- [ ] iOS bundle ID chính thức. Giá trị tạm hiện tại: `vn.edu.quanlydiem.clientFlutter`.
- [ ] Version phát hành đầu và build number. Giá trị hiện tại: `0.1.0+1`.
- [ ] HTTPS origin của API staging và production; HTTPS origin của Web; DNS/TLS owner.
- [ ] Google Play Console account, keystore/upload key owner và nơi lưu secret CI.
- [ ] Apple Developer team, App Store Connect access, certificate/profile owner và nơi lưu secret CI.
- [ ] Người chịu trách nhiệm deploy, rollback, backup/restore và xử lý sự cố.

## Quyết định nghiệp vụ và dữ liệu trước production

- [ ] Công thức làm tròn, ngưỡng/xếp loại và cách xử lý thiếu điểm.
- [ ] Ngưỡng confidence Xanh/Vàng/Đỏ cho phiên bản model thật.
- [ ] Mẫu Excel/Vietschool chính thức.
- [ ] Thời gian lưu ảnh, audit, session, rate-limit counter và dữ liệu học sinh.
- [ ] Duyệt một cấp hay nhiều cấp; quyền tổ trưởng/BGH nếu có.
- [ ] Lịch sử chuyển lớp của học sinh.
- [ ] Tải dự kiến, SLA, RPO/RTO, khu vực lưu dữ liệu và yêu cầu pháp lý.

## Staging

- [ ] Cấp PostgreSQL, Redis TLS, S3 private và recognition endpoint qua secret manager.
- [ ] Chạy migration bằng `app_migration`; API chạy bằng `app_runtime`.
- [ ] Chạy restore rehearsal database và object storage trong RTO mục tiêu.
- [ ] Chạy load profile bằng tài khoản giả và lưu JSON đã loại token/PII.
- [ ] Đặt `WEB_API_BASE_URL=https://<api-staging>` và chạy `pnpm release:web:build`.
- [ ] Deploy artifact Web; kiểm direct-route fallback, TLS, cache/security headers và đăng nhập.
- [ ] Smoke test phân quyền âm tính, bảng điểm, upload/đối chiếu, tổng kết, Excel và học sinh xem chính mình.

## Android internal testing

- [ ] Thay tên/icon/metadata placeholder và chốt application ID/version.
- [ ] Cấu hình production signing từ secret CI; không dùng debug key, không commit keystore.
- [ ] Build Android App Bundle production trỏ HTTPS API đã chốt.
- [ ] Upload internal testing, cài từ Play Store và smoke test trên ít nhất một thiết bị thật.
- [ ] Ghi release ID, commit, tester và kết quả; thu hồi tài khoản test sau nghiệm thu.

## iOS TestFlight

- [ ] Thay tên/icon/metadata placeholder và chốt bundle ID/version.
- [ ] Cấu hình Apple team, certificate và provisioning profile từ secret CI.
- [ ] Archive production trỏ HTTPS API đã chốt và upload App Store Connect.
- [ ] Cài từ TestFlight và smoke test trên ít nhất một iPhone thật.
- [ ] Ghi build ID, commit, tester và kết quả; thu hồi tài khoản test sau nghiệm thu.

## Cho phép production

- [ ] `foundation`, `ios`, `required-checks` xanh trên đúng commit phát hành.
- [ ] Không còn placeholder/TODO bắt buộc trong metadata và config artifact.
- [ ] Backup database và object storage cùng mốc đã có checksum, mã hóa và restore rehearsal đạt.
- [ ] Monitoring/alert và người trực vận hành đã được xác nhận.
- [ ] Chủ dữ liệu chấp thuận chính sách dữ liệu và các quyết định nghiệp vụ ở trên.
- [ ] Chủ dự án phê duyệt deploy từ artifact đã kiểm; ghi commit, thời điểm UTC và người thực hiện.
