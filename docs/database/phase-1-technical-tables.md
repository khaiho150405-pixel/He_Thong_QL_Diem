# Các bảng kỹ thuật Phase 1

Migration `202609100001_identity_catalog` thêm ba bảng, không thay 16 bảng nghiệp vụ.

| Bảng               | Cột và ràng buộc                                                                                                                          | Quyền runtime                                                          |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| phien_lam_viec     | ma_bam char(64) PK SHA-256; ma_nguoi_dung integer FK RESTRICT và index; csrf char(64); het_han và hoat_dong_cuoi timestamptz NOT NULL     | SELECT/INSERT/UPDATE/DELETE để tạo, chạm và thu hồi phiên              |
| nhat_ky_bao_mat    | ma_su_kien bigserial PK; ma_tac_nhan integer nullable; hanh_dong varchar(64); doi_tuong varchar(100); thoi_diem timestamptz default now() | SELECT/INSERT; UPDATE/DELETE/TRUNCATE bị từ chối bằng quyền và trigger |
| gioi_han_dang_nhap | ma_bam char(64) PK của IP socket đã băm; so_lan integer >=0; het_han timestamptz                                                          | SELECT/INSERT/UPDATE/DELETE cho cửa sổ rate-limit                      |

Không lưu raw token, IP hoặc mật khẩu trong ba bảng. Audit giữ actor ID không FK để không ràng buộc việc lưu sự kiện với vòng đời tài khoản. Session giữ FK RESTRICT. Dữ liệu catalog chỉ QTV được ghi qua application service; runtime vẫn không có DML điểm. Prisma connection đặt timezone UTC, không phụ thuộc timezone của máy PostgreSQL.

Account/catalog writes và audit dùng cùng Unit of Work serializable, retry tối đa ba lần khi xung đột. Application gọi port Store/Unit; adapter duy nhất ánh xạ sang Prisma, HTTP không nhận table/where tùy ý. Port này là hạ tầng truy vấn/giao dịch; các rule nằm ở application module và authorization public policy.

Trước production cần retention/cleanup định kỳ cho phiên và rate-limit; việc này không được xóa audit trái chính sách. Rollback bằng forward migration, giữ audit; xem ADR-0005.
