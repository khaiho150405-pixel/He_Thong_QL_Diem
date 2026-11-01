# Checklist máy mới

1. Clone repository; đọc AGENTS/README/CONTRIBUTING. Windows bật Git và Flutter trong PATH; macOS cần Xcode cho iOS, Android cần SDK/license được chấp nhận.
2. Cài toolchain được pin, Docker Compose v2. Kiểm Node thực mà pnpm scripts gọi, Java 17+, flutter doctor.
3. Làm theo README từ root; không nhận .env của đồng nghiệp, không chia sẻ database cá nhân.
4. Migrate SQL đã commit, seed hai giáo viên/học sinh giả. Seed lặp giữ dữ liệu hiện hữu.
5. Kiểm API live/ready, bucket private và web kết nối/lỗi/retry. Android emulator dùng config riêng.
6. Chạy check và ghi platform/profile, lệnh, kết quả vào PR. iOS chưa có máy phải ghi blocked.

## PostgreSQL test độc lập khi chưa có Docker

Có thể dùng initdb/pg_ctl từ PostgreSQL đã cài, nhưng phải tạo cụm riêng trong .local/pg-test và cổng 55432, bind 127.0.0.1. Cụm kiểm thử tạm có auth trust chỉ dành môi trường cô lập, phải dừng sau khi test; không dùng để lưu dữ liệu thật. Không chạy các lệnh này trên data directory PostgreSQL cá nhân.

Trên Windows dùng đường dẫn đầy đủ tới initdb.exe và pg_ctl.exe. Sau khi cụm riêng chạy, đặt TEST_ADMIN_URL tới postgres trên cụm đó, chạy `node scripts/prepare-test-db.mjs`. Script chỉ tạo quan_ly_diem_test và hai role trên cụm bạn chỉ định, không drop database. Đặt MIGRATION_DATABASE_URL tới app_migration/quan_ly_diem_test rồi migrate/seed (APP_ENV=test, SEED_PASSWORD do bạn đặt). Đặt TEST_MIGRATION_URL và TEST_RUNTIME_URL trước pnpm test:db.

Đây chỉ kiểm PostgreSQL; không thay kiểm integration Redis/MinIO. README dùng Docker là quy trình tái lập chung của nhóm.

## Khi đổi cấu trúc

Tạo migration mới qua db:migrate:create, review SQL rồi áp dụng trên DB development riêng. Nếu cần shadow database cho migrate dev, cấp URL shadow riêng theo tài liệu Prisma; không nâng quyền runtime. Không chạy migrate dev bằng URL production. CI luôn dùng migrate deploy.

Generated code cập nhật qua api:export/client:generate. Commit cả lockfiles và serializers; không commit pubspec_overrides.yaml của Melos hoặc .env. Không đặt password thật trong issue/PR/log.
