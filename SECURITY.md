# Báo cáo bảo mật

Không đăng mật khẩu, token, ảnh hoặc hồ sơ học sinh trong issue công khai. Khi repository được thiết lập, maintainer phải công bố kênh báo riêng hoặc bật GitHub private vulnerability reporting trước khi nhận dữ liệu thật. Hiện chưa có kênh liên hệ được xác nhận.

Giai đoạn 0 chỉ có health endpoints, chưa triển khai xác thực hoặc nghiệp vụ điểm. Không dùng làm production. API không dùng tài khoản DB quản trị. Với secret đã lộ: thu hồi/đổi secret trước, sau đó xử lý lịch sử Git cùng maintainer; xóa file ở commit mới không thu hồi được secret cũ.
