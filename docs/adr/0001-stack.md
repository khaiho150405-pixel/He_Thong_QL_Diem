# ADR-0001 — Nền móng modular monolith

Chấp nhận cho development: NestJS 12, Node 24, PostgreSQL 18, Prisma 7 stable, Flutter/Dart, Redis và MinIO theo AGENTS.md. Prisma latest trả release candidate 8 nên chọn stable 7.10.0. Node 24.19.0 hỗ trợ Nest 12 và Prisma 7; scripts cần cùng Node trên PATH, không chỉ launcher pnpm.

API là một deployable. Module ownership theo implementation_plan1.md §4; HTML control ánh xạ application use case, không đặt rule vào HTTP controller. Worker entrypoint cùng backend và FastAPI triển khai ở Giai đoạn 3; không có OCR fake trong đường production.

Flutter 3.35.7/Dart 3.9.2 đang cài được giữ để kiểm chứng nền móng, chưa khẳng định là stable mới nhất. Nâng SDK là PR riêng với web/Android/iOS checks; không tự sửa SDK dùng chung trên máy. Melos 6 dùng các pubspec/lockfile riêng.

Nguồn kiểm tra 2026-09-07: https://docs.nestjs.com/migration-guide, https://www.prisma.io/docs/guides/upgrade-prisma-orm/v7, https://docs.flutter.dev/install/archive và package registry. Versions thực pin trong package.json/pnpm-lock.yaml/pubspec.lock.

Dependency phục vụ: pg/Prisma cho DB; Redis/S3 SDK cho readiness; Swagger/generator cho contract; Argon2 cho seed; Riverpod/GoRouter/Dio theo stack; ESLint/Prettier/tsx cho checks. Không thêm BullMQ khi chưa có job consumer.
