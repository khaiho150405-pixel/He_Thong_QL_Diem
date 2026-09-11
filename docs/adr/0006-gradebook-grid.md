# ADR-0006 — Khởi tạo lưới điểm qua quyền DB giới hạn

Phạm vi Phase 2 phần 1 theo UC09: application service tạo bảng lớp–môn–học kỳ và ô trống; đọc danh sách/lưới theo phạm vi. Phần này chưa công bố endpoint, chưa có thao tác sửa/chốt điểm hoặc UI. Không thay stack, không thêm dependency hoặc bảng nghiệp vụ.

Runtime chỉ được EXECUTE `public.tao_luoi_diem_trong(text, integer, integer, integer)`. Hàm SECURITY DEFINER dùng search_path cố định `pg_catalog`, tên bảng có schema đầy đủ, không dynamic SQL; PUBLIC bị thu hồi EXECUTE trong cùng migration transaction. Runtime vẫn không có INSERT/UPDATE/DELETE trực tiếp bảng điểm/ô điểm, nên không thể bypass validator bước 0.1 của ADR-0002. Chủ sở hữu migration là tài khoản quản trị tin cậy, không dùng để chạy API.

Application kiểm lại phiên/vai trò/phân công trong cùng transaction. Hàm DB cũng xác minh phiên chưa hết hạn, tài khoản giáo viên hoạt động, đúng lớp–môn–học kỳ, cùng năm học và có học sinh đang học/thành phần điểm. Chỉ cho chạy ở isolation serializable; adapter retry lỗi serialization/deadlock hữu hạn. QTV được đọc, không tự có quyền tạo/sửa điểm; chủ nhiệm không thay phân công. Học sinh chưa được đọc toàn bảng (tra cứu chính mình ở UC18).

Khóa duy nhất lớp–môn–học kỳ là định danh tự nhiên: gọi tạo lại trả bảng cũ, không sửa trạng thái/giá trị hoặc thêm audit. Gọi đồng thời hội tụ về một bảng; khi hết retry hoặc đụng unique, caller nhận conflict và có thể đọc/gọi lại. Endpoint tương lai phải bổ sung contract idempotency phù hợp cho batch sửa/chốt, không suy rộng tính idempotent này sang sửa điểm.

Tạo mới là một transaction: bảng → tích Descartes học sinh đang học × thành phần → audit `GRADEBOOK_CREATED`. Ô mới là NULL/CHUA_CO/NHAP_TAY. Không ghi lịch sử sửa điểm khi mới tạo NULL vì chưa thay đổi giá trị; mọi lần nhập/sửa sau đó phải có lịch sử cùng transaction. Lỗi ở bất kỳ bước nào rollback cả ba.

Danh sách bảng và ô có cursor tăng theo PK, 50 phần tử/trang. ID bigint và điểm/hệ số ra application dưới dạng chuỗi; NULL giữ nguyên. Hàng đã ngừng học vẫn được đọc với `active=false`. Gọi tạo lại không đồng bộ sĩ số: A3 của UC09 (thêm học sinh mới, giữ dòng cũ) còn thuộc phần 2, phải thiết kế thao tác riêng có version/lock; GET không tạo dữ liệu. Phase 1 đang chặn chuyển lớp khi đã có ô điểm, kể cả NULL; muốn nới phải bổ sung test và quyết định rõ.

Rollback môi trường dùng chung: migration tiến tiếp thu hồi EXECUTE của hàm nếu cần dừng tạo bảng; giữ dữ liệu và audit. Không sửa/xóa migration đã chạy, không DROP database hoặc gỡ trigger append-only. Phase 1 không gọi hàm nên có thể quay lại ứng dụng Phase 1 mà giữ schema mới.
