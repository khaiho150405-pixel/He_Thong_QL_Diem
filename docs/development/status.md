# Trạng thái thực thi Giai đoạn 0

Cập nhật: 2026-09-08. Đây là nền móng, chưa hoàn tất toàn bộ Definition of Done.

| Phần             | Kết quả thực tế                                                                                                                              |
| ---------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Workspace        | NestJS, Flutter ba target, Melos, ADR, tài liệu và templates đã commit                                                                       |
| Backend          | Format/lint/typecheck/build pass; HTTP kiểm 200/400/404/500/503, CORS và lỗi nội bộ được che                                                 |
| PostgreSQL local | Hai migration áp dụng trên cụm test riêng; seed chạy hai lần; constraint, NULL/0, append-only và quyền runtime pass. Cụm test đã dừng        |
| Quyền migration  | CI phát hiện thiếu CREATE trên database. Đã sửa bootstrap Docker và test độc lập; test xác nhận runtime không có CREATE schema/database pass |
| OpenAPI/Dart     | Generator 7.17.0, serializers và contracts:check pass                                                                                        |
| Flutter/Web      | Analyze, 4 tests và web build pass; kiểm 390px/1280px, lỗi/retry; đã mở Web và kết nối API thật                                              |
| iOS              | Job macOS trong lượt CI đầu đã build simulator và chạy integration test kết nối thành công                                                   |
| Docker           | Lượt CI đầu đã pull/start PostgreSQL/Redis/MinIO healthy và tạo bucket private; các bước integration sau migration chưa được xác nhận lại    |
| Android          | Build local lỗi Java loopback. Đã bổ sung CI build APK và chạy integration test trên emulator API 35, Pixel 7 Pro; chờ kết quả               |
| GitHub           | Đã push nhánh feat/phase-0-foundation. Tạo draft PR qua connector bị 403; chưa xác minh branch protection và chưa có handles CODEOWNERS      |

## Bằng chứng CI và commit

- [Lượt đầu](https://github.com/khaiho150405-pixel/He_Thong_QL_Diem/actions/runs/34145742431): iOS success; foundation fail ở migration vì thiếu quyền database.
- Commit `4fde0f4`: cấp quyền CREATE database riêng cho migration, đồng bộ bootstrap test và bổ sung test âm tính cho runtime. Kiểm thử PostgreSQL thật sau sửa pass.
- Commit `47c56d3`: thêm Android emulator integration theo [hướng dẫn action](https://github.com/ReactiveCircus/android-emulator-runner).
- [Lượt CI mới](https://github.com/khaiho150405-pixel/He_Thong_QL_Diem/actions/runs/34177968115): lần đọc cuối còn đang chạy. Sau đó kết nối GitHub/API/web lỗi; chưa có kết luận trên commit mới nhất.
- [Mở pull request](https://github.com/khaiho150405-pixel/He_Thong_QL_Diem/compare/main...feat/phase-0-foundation?expand=1). Chưa có PR được tạo tự động.

## Việc cần tiếp tục

1. Đọc lượt CI mới nhất khi kết nối trở lại; sửa lỗi thực tế và kiểm lại các bước bị chặn, không bỏ gate.
2. Hoàn tất smoke lỗi/retry trên các nền tảng; hiện lỗi/retry được kiểm bằng widget test, integration native mới kiểm kết nối thành công.
3. Chốt reviewer thật, mở draft PR, xác minh branch protection/review policy và onboarding trên máy đồng nghiệp.

UC01–18 chưa triển khai. Chưa có use case phân công hoặc UI nhập/duyệt điểm; runtime chưa được cấp quyền ghi điểm. Đây chưa phải bản production.
