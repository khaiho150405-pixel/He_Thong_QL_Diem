# ADR-0007 — Nhập/chốt điểm nguyên tử

Phase 2 phần 2 theo UC09–10: API tạo/đọc bảng, nhập điểm hàng loạt, chốt bảng, đồng bộ sĩ số và đọc lịch sử. Không thay stack/dependency. Migration 202609100003 được hoàn thiện trước lần triển khai đầu tiên; không sửa các migration đã commit/chạy trước đó.

## Giao dịch và quyền

Runtime vẫn không có DML trực tiếp trên bang_diem/diem_thanh_phan. Ba hàm SECURITY DEFINER cap_nhat_diem, chot_bang_diem, dong_bo_si_so có search_path cố định pg_catalog, tên schema đầy đủ và PUBLIC không có EXECUTE. Helper kiem_quyen_ghi_bang chỉ dành chủ hàm, không cấp runtime. Cả service và DB kiểm phiên hoạt động, đúng giáo viên/phân công; không cấp quyền ghi điểm cho QTV hoặc quyền chủ nhiệm. GET/history cho QTV và giáo viên đúng phân công; học sinh không đọc toàn bảng.

Mọi mutation yêu cầu expectedVersion từ client, transaction serializable và khóa hàng bảng điểm FOR UPDATE. Mỗi batch/chốt/sync thành công tăng version một lần, kể cả batch không thay giá trị. Retry serialization có giới hạn; version cũ trả 409 và yêu cầu tải lại. Service không tự lấy version mới thay version người dùng đã đọc. Ô và lịch sử phải khớp bookId trong URL; không được dùng quyền một bảng để đọc/ghi bảng khác.

## Nhập tay

Một batch từ 1–100 ô, cấm trùng cellId/field lạ. ID bigint là chuỗi; value bắt buộc là NULL hoặc chuỗi chuẩn một chữ số thập phân 0.0–10.0 (không nhận exponent, hex, chuỗi trắng hoặc float). DB kiểm dạng đầu vào và gọi validator trước numeric coercion. Lý do bắt buộc, tối đa 500 ký tự. Ô ngừng theo dõi, sai lớp/môn hoặc đang chờ đối chiếu bị chặn.

Điểm giáo viên nhập có giá trị chuyển DA_DUYET/NHAP_TAY; đặt NULL chuyển CHUA_CO/NHAP_TAY. Mỗi thay đổi giá trị (kể cả lần NULL → số hoặc số → NULL) thêm lịch sử cũ/mới/người/lý do/thời điểm trong cùng transaction. Không đổi giá trị thì không tạo lịch sử giả hoặc đổi nguồn nhập; request vẫn được audit và tăng version. Ghi điểm, lịch sử, security audit, version và idempotency cùng commit; mọi lỗi rollback toàn bộ. Response trả giá trị chuỗi từ PostgreSQL, giữ chính xác NULL và 0.0.

Khi có phiếu nhận dạng DANG_XU_LY/CHO_DOI_CHIEU cho thành phần hoặc ô CHO_DOI_CHIEU, tạm từ chối nhập tay bằng 409. Quy trình lựa chọn ghi đè/tiếp tục đối chiếu ở UC09 A4 cần nối với Phase 3–4; hiện không có bypass âm thầm.

## Chốt và sĩ số

Mặc định bảo thủ cho development: chặn chốt khi thiếu ô lưới hoặc điểm thành phần bắt buộc của học sinh đang học chưa DA_DUYET; điểm thành phần không bắt buộc có thể NULL. Chặn mọi ô/phiếu còn chờ đối chiếu. Đây là mặc định kỹ thuật để phát triển, chưa thay quyết định production về thiếu điểm/xếp loại tại AGENTS.md §14. Không tự coi thiếu điểm là 0 hoặc loại bỏ học sinh. Chốt thành công chuyển DA_CHOT và ghi GRADEBOOK_LOCKED; không có API mở lại.

POST sync-roster thêm ô NULL cho học sinh mới, không xóa dòng cũ, có quyền/version/idempotency/audit tương tự ghi điểm. GET không thay sĩ số. Dòng đã ngừng học được giữ và trả active=false; không được ghi qua luồng thông thường. Quy tắc Phase 1 vẫn chặn chuyển lớp khi đã có ô điểm; lịch sử chuyển lớp nhiều năm cần quyết định riêng.

## Idempotency và quan sát

x-idempotency-key gồm 1–64 ký tự chữ/số/gạch ngang/gạch dưới. Khóa DB là (người dùng, thao tác, key); hash SHA-256 từ payload đã chuẩn hóa gồm bookId, expectedVersion, thay đổi. Luôn kiểm phiên/quyền trước đọc replay. Cùng key/hash trả nguyên kết quả; khác hash trả 409. Gửi đồng thời chỉ một transaction ghi; caller có thể retry khi nhận conflict serialization/unique. Replay sau khi bảng chốt vẫn được trả nếu quyền còn hợp lệ.

het_han đánh dấu mốc 24 giờ đủ điều kiện cho chính sách retention tương lai; hiện giữ record và tiếp tục replay sau mốc này, không tự tái sử dụng key hay DELETE để tránh ghi lặp. Runtime chỉ SELECT/INSERT. Không có cleanup job giả hoặc cam kết record tự hết hạn. Bảng kỹ thuật khoa_idempotency không thuộc 16 bảng nghiệp vụ.

Lỗi HTTP giữ envelope/requestId; query/log không chứa điểm/token. Truy cập bị từ chối do quyền ghi GRADEBOOK_ACCESS_DENIED trong transaction riêng sau rollback; không lưu giá trị điểm. Lịch sử dùng cursor 50, bigint/decimal là chuỗi và timestamp UTC. OpenAPI và Dart client cập nhật cùng mã.

Rollback môi trường dùng chung qua migration tiến tiếp thu hồi EXECUTE, giữ điểm/lịch sử/audit/idempotency. Không sửa migration đã chạy hoặc DROP dữ liệu.
