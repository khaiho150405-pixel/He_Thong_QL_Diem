# ADR-0014 — Nhà trường đặt lịch, hệ thống tự khóa điểm

## Quyết định ngày 2026-10-04

Theo yêu cầu mới nhất, giáo viên không chốt cột/bảng thủ công. QTV đặt thời điểm mở và hạn nhập cho từng `(bảng điểm, thành phần)`, vì mỗi cột thường xuyên có thể có thời hạn riêng. Biểu mẫu hiển thị giờ thiết bị và gửi UTC. Hệ số chỉ dùng cấu hình chung TX/GK/CK của học kỳ; bỏ hệ số thành phần cũ khỏi giao diện, giữ trường/contract deprecated để truy vết và tương thích.

API/DB chỉ cho nhập hoặc duyệt OCR khi `mở ≤ giờ hiện tại < đóng`; chặn upload ngoài lịch. QTV không thay điểm tùy ý bằng API lịch. Chỉ nhận hạn tương lai, phiên QTV hợp lệ, thành phần đúng môn/bảng, optimistic version lịch. Không sửa lịch đã hết hạn hoặc cột/bảng đã khóa; không tự đặt thời hạn cho dữ liệu cũ. Chưa có lịch thì giữ cổng nhập hiện có; phải đặt lịch cho mọi cột để tự khóa toàn bảng.

Đến hạn, giao dịch đồng bộ ô còn thiếu cho học sinh đang học, giữ điểm `DA_DUYET` khác NULL, ghi 0 cho NULL/chưa duyệt kèm lý do lịch nhà trường, đóng phiếu OCR đang xử lý/chờ duyệt thành `LOI` và khóa cột. Không dùng đề xuất OCR chưa được con người duyệt. Điểm 0 của môn Đạt/Không đạt tương ứng Không đạt. Bằng chứng cột và lịch sử append-only; nhật ký thay đổi gắn QTV đặt lịch và lý do tự động, audit thao tác khóa có tác nhân hệ thống. Chốt mọi cột thì bảng `DA_CHOT`, tăng version, vẫn chưa công bố xếp loại.

Tác vụ chạy khi API khởi động và mỗi 30 giây; điều kiện hạn do DB kiểm ngay cả trước tick. Khóa advisory transaction và khóa bảng bảo vệ chạy lặp/cạnh tranh; retry SERIALIZABLE có giới hạn. Không nhận thời gian giả từ client. API chết qua thời hạn thì khi khởi động lại xử lý các lịch quá hạn. Lỗi audit rollback toàn transaction và retry ở tick sau, không log dữ liệu điểm. Runtime chỉ SELECT lịch, thực thi hàm chuyên biệt; thu hồi quyền chốt thủ công cũ. Migration `202610040003_grade_deadlines` tiến tiếp, không sửa migration đã chạy. Rollback bằng migration thu hồi/tạm ngưng executor có review, không xóa điểm 0/lịch sử đã dùng.

## UI admin và kiểm chứng

Bổ sung yêu cầu ngày 2026-10-04: bỏ chọn/ẩn/sắp xếp môn và nút quản lý môn khỏi bảng điểm toàn trường. Tải đủ trang trước khi áp dụng bộ lọc admin. Lịch nhập điểm hiển thị một hàng thẻ cuộn ngang, giữ đầy đủ tên cột, thời gian mở/hạn và thao tác QTV. Thanh cuộn chính vẫn ở mép màn; lịch có thanh cuộn ngang riêng.

Acceptance: PostgreSQL thật kiểm chặn trước/sau hạn, phân quyền QTV/GV, version lịch, không mở lại, bảo toàn 0/điểm duyệt, thêm sĩ số còn thiếu, rollback audit, hai executor không nhân đôi lịch sử. DB constraints kiểm quyền runtime. Flutter kiểm biểu mẫu gửi UTC ở 320/390/1280, role GV không thấy nút chỉnh/chốt và lịch nằm cùng hàng có thể cuộn ngang; widget profile không thay thiết bị Android/iOS thật.

Vận hành: giữ API chạy và giám sát `grade_deadline_failed`; khi lỗi, DB vẫn từ chối ghi sau hạn. Sửa lỗi DB/audit rồi tick sau xử lý. Không dùng seed/reset để khắc phục. Nếu áp dụng thời hạn nhầm, dùng quy trình điều chỉnh có review/migration audit, không bypass khóa qua UI hay role migration của API.
