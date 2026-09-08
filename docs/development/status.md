# Trạng thái thực thi Giai đoạn 0

Cập nhật: 2026-09-08. Bản mã `4db57d6` đã có [CI xanh toàn bộ](https://github.com/khaiho150405-pixel/He_Thong_QL_Diem/actions/runs/34179438066). Giai đoạn 0 vẫn còn điều kiện cộng tác chưa hoàn tất.

| Phần                  | Kết quả thực tế                                                                                                                                 |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| Workspace             | NestJS, Flutter ba target, Melos, ADR, tài liệu và templates đã commit                                                                          |
| Backend               | Format/lint/typecheck/build và HTTP tests 200/400/404/500/503, CORS pass                                                                        |
| PostgreSQL            | Migration từ database rỗng, seed, constraints, NULL/0, append-only, quyền runtime pass trên PostgreSQL thật local và CI                         |
| Docker integration    | PostgreSQL/Redis/MinIO healthy; private bucket và dependency failure tests pass trên CI                                                         |
| OpenAPI/Dart          | Regeneration không drift, serializers và generated client analyze pass                                                                          |
| Flutter Web           | Build và 4 widget/serialization tests pass; 390px/1280px không overflow. Đã kiểm Web thật lỗi → bấm Thử lại → kết nối API thật qua proxy test   |
| Android               | CI build APK development và integration kết nối API pass trên emulator API 35/Pixel 7 Pro. Local vẫn có lỗi Java loopback                       |
| iOS                   | CI build và integration kết nối API pass trên iPhone simulator; một lượt trước timeout debug connection, workflow đã tách bước và timeout riêng |
| Smoke phục hồi native | Đã bổ sung proxy test-only và assertion lỗi/Thử lại/thành công; chờ lượt CI cho phần bổ sung này                                                |
| GitHub                | Nhánh feat/phase-0-foundation đã push; main được xác minh protected=false. Connector tạo PR và rerun trả 403; chưa có reviewer CODEOWNERS       |

## Các sửa lỗi đã kiểm chứng

- `4fde0f4`: cấp quyền CREATE database riêng cho migration; runtime vẫn không được tạo schema/bảng. Kiểm thử PostgreSQL thật pass.
- `47c56d3`: bổ sung Android emulator integration.
- `8d2e92e`: cleanup Docker chỉ chạy sau khi tạo env.
- `4db57d6`: tách bước iOS resolve/build/boot/test và giới hạn timeout. Cả foundation, ios và required-checks đều success ở lượt CI liên kết trên.

Proxy `scripts/testing/connection-proxy.mjs` chỉ chạy khi bật CONNECTION_SMOKE_TEST=1, chỉ phục vụ health trên loopback và không được gọi bởi luồng ứng dụng/deployment. Xem README để tái lập. Nó trả 503 một lần; lần tiếp theo chuyển tới API thật, không giả kết quả thành công.

## Điều kiện còn thiếu

1. Kiểm kết quả CI cho smoke lỗi/retry native mới bổ sung.
2. Cung cấp reviewer thật, [mở draft PR](https://github.com/khaiho150405-pixel/He_Thong_QL_Diem/compare/main...feat/phase-0-foundation?expand=1), bật bảo vệ main và xác minh review policy.
3. Đồng nghiệp clone/setup trên máy riêng và ghi bằng chứng onboarding; chốt license.

Cụm PostgreSQL test tạm đã dừng, không sửa database cá nhân. UC01–18 chưa triển khai; chưa có luồng nhập/duyệt điểm hoặc phân quyền nghiệp vụ. Đây chưa phải bản production.
