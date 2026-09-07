# Truy vết

| Phạm vi | Module/bảng                      | Hiện trạng / kiểm chứng                                         |
| ------- | -------------------------------- | --------------------------------------------------------------- |
| P0-01   | Workspace, ADR, module ownership | Có mã/config; checks ghi trong status.md                        |
| P0-02   | PostgreSQL/Redis/MinIO/env       | Compose có sẵn; Docker local chưa có                            |
| P0-03   | 16 bảng, migrations, audit       | Migration/seed/test trên PostgreSQL riêng; chưa có use case ghi |
| P0-04   | API common health/error/config   | HTTP tests tự động                                              |
| P0-05   | OpenAPI → Dart                   | Generator/template/serializer, drift check                      |
| P0-06   | Flutter ba target                | Widget và build cần xem status theo platform                    |
| P0-07   | GitHub CI/onboarding/review      | Templates/workflow; GitHub settings cần xác minh riêng          |
| UC01–08 | identity/authorization/catalog   | Chưa triển khai; bắt buộc IDOR/session/CSRF tests               |
| UC09–10 | gradebooks/audit                 | Schema baseline; chưa có write port/lock/transaction nghiệp vụ  |
| UC11–12 | recognition/files                | Schema hai kênh/lưới; chưa có queue/FastAPI/upload              |
| UC13    | review                           | ADR UnitOfWork; chưa có duyệt hoặc UI ảnh ô                     |
| UC14–18 | final-results/reports/students   | Schema snapshot; chưa có tính/xếp loại/export/tra cứu           |

HTML §09 là truy vết thiết kế; không coi là kết quả nghiệm thu phần mềm. Tests phase 0 không chứng minh authorization nghiệp vụ chưa được viết.
