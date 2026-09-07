# Trạng thái thực thi Giai đoạn 0

Ngày kiểm tra: 2026-09-07. Đây là nền móng, chưa hoàn tất toàn bộ Definition of Done.

| Phần               | Kết quả thực tế                                                                                                                            |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Workspace/ADR/Git  | Có NestJS, Flutter ba target, Melos, docs, templates; Git local có main tài liệu và nhánh feat/phase-0-foundation                          |
| Dependencies       | pnpm install thành công với Node 24 đúng PATH; Dart bootstrap thành công                                                                   |
| Backend            | Format/lint/typecheck (gồm seed/tests)/HTTP unit/build pass; HTTP kiểm 200/400/404/500/503 và không lộ lỗi nội bộ                          |
| PostgreSQL         | Hai migration áp dụng thành công trên cụm riêng localhost:55432; seed chạy hai lần; test constraints/quyền runtime/NULL/0/append-only pass |
| OpenAPI/Dart       | Generator 7.17.0 + serializers chạy được; contracts:check pass                                                                             |
| Flutter            | Analyze và web build pass; 4 tests widget/serialization pass, gồm lỗi/retry và kích thước 390px/1280px                                     |
| Web thực tế        | Mở localhost:8080 thấy kết nối thành công tới API local                                                                                    |
| Android            | Có target/flavors; build bị chặn bởi Java/Gradle lỗi Unable to establish loopback connection, thử IPv4 vẫn lỗi; chưa có emulator đang chạy |
| iOS                | Có target, cấu hình Dart ba môi trường; Windows không có Xcode/simulator. Workflow macOS được chuẩn bị, chưa có kết quả chạy               |
| Docker integration | Máy chưa có Docker CLI; chưa kiểm chứng đầy đủ Redis/MinIO/Compose. PostgreSQL test riêng không thay thế gate này                          |
| GitHub             | Đã push main chứa tài liệu gốc; bản nền móng ở nhánh review riêng. CI/branch protection/CODEOWNERS chưa nghiệm thu                         |

UC01–18 chưa triển khai. Chưa có bảo vệ phân công ở use case hoặc UI nhập/duyệt điểm; runtime chưa được cấp quyền ghi điểm. Không sử dụng phase 0 với dữ liệu thật hoặc coi là bản production.

Các phần cần tiếp tục: chạy workflow trên GitHub và sửa lỗi thực tế; kiểm Android/iOS runtime; chốt reviewer để thiết lập review policy; kiểm onboarding bằng máy đồng nghiệp. Chưa đánh dấu các gate chưa kiểm chứng trong plan.
