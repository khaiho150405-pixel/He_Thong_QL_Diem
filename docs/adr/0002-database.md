# ADR-0002 — Migration, quyền và điểm

Prisma 7 config cho phép giữ database/migrations/ theo AGENTS.md. Baseline cấu trúc sinh từ schema; migration thứ hai thêm CHECK, partial unique index, permissions và append-only trigger. Mọi FK dùng RESTRICT; PostgreSQL 18 có thể trả SQLSTATE 23001 cho RESTRICT, khác 23503 cho FK thông thường.

API runtime phase 0 được đọc 16 bảng, INSERT lịch sử và gọi validator; không có ghi điểm/danh mục khi chưa có use case kiểm quyền. Migration role có CONNECT/CREATE trên database và USAGE/CREATE trên public để chạy cả CREATE SCHEMA IF NOT EXISTS của Prisma; sở hữu các đối tượng do migration tạo, không cần sở hữu database. Runtime không có DDL. Phân quyền ghi được thêm bằng migration cùng các UC, không cấp toàn bộ DML mặc định.

numeric(3,1) tự ép scale trước CHECK. kiem_tra_gia_tri_diem(numeric) kiểm bước 0.1 trước ép kiểu. Runtime không được ghi trực tiếp điểm để bypass. Giai đoạn 2 phải thêm write port/function gọi validator, kiểm authorization/lock và audit trong transaction; chưa có write API phase 0. Owner là quyền quản trị tin cậy, không là đường ghi ứng dụng.

Giữ tên DB tiếng Việt trong Prisma để không mất mapping. Snapshot bo_he_so (JSON object có version schema do Giai đoạn 5 chốt) bổ sung cho phien_ban_he_so để giải thích kết quả cũ. Xếp loại nullable vì không tự chốt công thức. Năm hiện hành là cờ duy nhất; application chuyển cờ theo lịch, không dùng CHECK phụ thuộc thời gian.

FK đơn kiểm tồn tại. Liên bảng lớp/môn/học kỳ/học sinh được kiểm trong application transaction ở giai đoạn có ghi; runtime chưa được ghi các bảng này. Khi triển khai chuyển lớp lịch sử cần ADR riêng.

Rollback: baseline chưa có dữ liệu thật có thể tạo lại database development riêng sau khi chủ máy đồng ý. Không tự drop DB. Môi trường chung không rollback bằng sửa migration; dùng forward migration và backup/restore đã thử trên DB riêng. Migration 0002 có dữ liệu lịch sử phải giữ append-only; không có down script gỡ bảo vệ âm thầm.
