# ADR-0004 — Duyệt nguyên tử và job bền vững

Thiết kế cho Giai đoạn 3–4. Phase 4 triển khai một port thuộc module review; adapter Prisma gọi duy nhất hàm PostgreSQL `duyet_phieu_nhan_dien` trong transaction `SERIALIZABLE`. Hàm là ranh giới UnitOfWork cho authorization, gradebooks, audit và recognition; application không import repository nội bộ của module khác và không lồng transaction độc lập.

Trong callback: kiểm actor/phân công, version phiếu, khóa bảng → cập nhật điểm qua gradebooks → audit append → đóng dấu dòng/phiếu qua recognition. Bất kỳ lỗi nào rollback. Version và trạng thái kiểm trong câu lệnh cập nhật/khóa DB để tránh race giữa kiểm và ghi. Test duyệt/chốt đồng thời và lỗi tại từng bước bắt buộc trước đóng UC13.

Upload commit phiếu và outbox trong PostgreSQL; dispatcher enqueue job idempotent, retry hữu hạn. Worker chỉ ghi nhận dạng, không ghi điểm. Idempotency record chứa actor/operation/key/request hash/result; cùng key khác payload reject. Không dùng Redis làm nguồn chuẩn. Bảng kỹ thuật outbox/idempotency chỉ thêm bằng migration khi triển khai consumer.
