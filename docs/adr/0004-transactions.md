# ADR-0004 — Duyệt nguyên tử và job bền vững

Thiết kế cho Giai đoạn 3–4, chưa triển khai nghiệp vụ. Review application nhận UnitOfWork và public ports của authorization, gradebooks, audit, recognition. UnitOfWork callback cung cấp các ports đã bind cùng Prisma transaction; domain/application không nhận PrismaClient. Không gọi repository riêng của module khác, không lồng transaction độc lập.

Trong callback: kiểm actor/phân công, version phiếu, khóa bảng → cập nhật điểm qua gradebooks → audit append → đóng dấu dòng/phiếu qua recognition. Bất kỳ lỗi nào rollback. Version và trạng thái kiểm trong câu lệnh cập nhật/khóa DB để tránh race giữa kiểm và ghi. Test duyệt/chốt đồng thời và lỗi tại từng bước bắt buộc trước đóng UC13.

Upload commit phiếu và outbox trong PostgreSQL; dispatcher enqueue job idempotent, retry hữu hạn. Worker chỉ ghi nhận dạng, không ghi điểm. Idempotency record chứa actor/operation/key/request hash/result; cùng key khác payload reject. Không dùng Redis làm nguồn chuẩn. Bảng kỹ thuật outbox/idempotency chỉ thêm bằng migration khi triển khai consumer.
