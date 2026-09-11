# ADR-0008 — Upload ảnh và outbox nhận dạng

Phase 3 phần 2 theo UC11 dùng endpoint multipart của module `recognition`, object storage private của module `files` và một outbox PostgreSQL. API chỉ nhận PNG/JPEG tối đa 10 MiB, kiểm chữ ký nội dung, MIME khai báo, kích thước từng chiều tối đa 10.000 pixel và tổng tối đa 40 triệu pixel. Tên tệp từ client không được dùng làm object key; server tạo UUID. PostgreSQL chỉ lưu SHA-256 và object key, không lưu binary hoặc signed URL.

Giáo viên phải có phiên còn hiệu lực và đúng phân công lớp–môn–học kỳ. Bảng điểm phải đang nhập liệu, thành phần phải thuộc môn và số dòng khai báo phải bằng sĩ số đang học. Application kiểm quyền trước khi tải object; hàm DB `tao_phieu_nhan_dien` kiểm lại trong transaction `SERIALIZABLE` và khóa bảng điểm để không chạy đua với thao tác chốt.

Phiếu, audit, idempotency record và `recognition_outbox` được commit nguyên tử. Upload object xảy ra trước transaction vì PostgreSQL không thể giao dịch hai pha với S3; nếu transaction thất bại, API xóa object UUID vừa tạo. Nếu xóa thất bại, object không có ticket tham chiếu và được xử lý bằng tác vụ dọn orphan vận hành sau này. Không dùng checksum làm object key để hai upload đồng thời không xóa nhầm object đã được phiếu khác tham chiếu.

Idempotency hash gồm bảng điểm, thành phần, số dòng và checksum. Cùng actor/key/hash trả receipt cũ và xóa object tạm của lượt replay; cùng key khác payload hoặc checksum đã tồn tại trả conflict. Response chỉ có `ticketId`, `jobId`, trạng thái; object key không rời backend.

Dispatcher claim outbox bằng `FOR UPDATE SKIP LOCKED`, lease 30 giây và tối đa năm lần gửi. BullMQ dùng `jobId=recognition-<ticketId>` nên gửi lại sau crash không tạo job thứ hai; job có ba lần xử lý với exponential backoff. Sau năm lần không enqueue được, phiếu chuyển `LOI/QUEUE_UNAVAILABLE`. Redis không phải nguồn chuẩn. Worker của phần sau chỉ được ghi kết quả nhận dạng, không ghi điểm chính thức.

BullMQ được thêm vì AGENTS.md đã chốt Redis + BullMQ cho queue và dependency hiện có chưa cung cấp hàng đợi bền vững. Multer được khai báo trực tiếp để multipart hoạt động dưới pnpm strict dependency isolation.

Rollback môi trường dùng chung thực hiện bằng migration tiến tiếp thu hồi endpoint/quyền hàm và dừng dispatcher; giữ phiếu, audit và outbox đã có. Không sửa migration đã triển khai hoặc xóa ảnh/ticket đã được dùng.
