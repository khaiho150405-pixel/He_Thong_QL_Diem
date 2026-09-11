# Truy vết

| Phạm vi | Module/bảng                                       | Hiện trạng / kiểm chứng                                                                                                        |
| ------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| P0-01   | Workspace, ADR, module ownership                  | Có mã/config; checks ghi trong status.md                                                                                       |
| P0-02   | PostgreSQL/Redis/MinIO/env                        | Compose có sẵn; Docker local chưa có                                                                                           |
| P0-03   | 16 bảng, migrations, audit                        | Migration/seed/test trên PostgreSQL riêng; chưa có use case ghi                                                                |
| P0-04   | API common health/error/config                    | HTTP tests tự động                                                                                                             |
| P0-05   | OpenAPI → Dart                                    | Generator/template/serializer, drift check                                                                                     |
| P0-06   | Flutter ba target                                 | Widget và build cần xem status theo platform                                                                                   |
| P0-07   | GitHub CI/onboarding/review                       | Templates/workflow; GitHub settings cần xác minh riêng                                                                         |
| UC01–02 | identity / phien_lam_viec                         | Login/logout, khóa tạm, idle/absolute expiry; integration/identity-catalog.test.ts                                             |
| UC03–04 | identity / nguoi_dung, nhat_ky_bao_mat            | CRUD tài khoản, thu hồi phiên, hồ sơ/mật khẩu; test PostgreSQL và Flutter phase1_test.dart                                     |
| UC05–08 | students/classes/subjects/teachers/academic-years | API + generated client + form Flutter, phân trang/tìm kiếm; kiểm scope/quan hệ trên PostgreSQL thật                            |
| UC09    | gradebooks/bang_diem, diem_thanh_phan             | API tạo/lưới/nhập/chốt/sync có version/idempotency/quyền và rollback; Flutter responsive dùng generated client, xử lý conflict |
| UC10    | audit/lich_su_sua_diem                            | Lịch sử cùng transaction, API cursor đúng scope, append-only; Flutter hiển thị NULL/0.0 và người/lý do/thời điểm sửa           |
| UC11–12 | recognition/files                                 | Schema hai kênh/lưới và policy phân loại thuần đã có; chưa có queue/FastAPI/upload                                             |
| UC13    | review                                            | ADR UnitOfWork; chưa có duyệt hoặc UI ảnh ô                                                                                    |
| UC14–18 | final-results/reports/students                    | Schema snapshot; chưa có tính/xếp loại/export/tra cứu                                                                          |

HTML §09 là truy vết thiết kế; không coi là kết quả nghiệm thu phần mềm. Tests phase 0 không chứng minh authorization nghiệp vụ chưa được viết.
