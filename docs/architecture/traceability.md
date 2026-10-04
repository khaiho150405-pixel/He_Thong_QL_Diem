# Truy vết

| Phạm vi | Module/bảng                                       | Hiện trạng / kiểm chứng                                                                                                                      |
| ------- | ------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| P0-01   | Workspace, ADR, module ownership                  | Có mã/config; checks ghi trong status.md                                                                                                     |
| P0-02   | PostgreSQL/Redis/MinIO/env                        | Compose có sẵn; Docker local chưa có                                                                                                         |
| P0-03   | 16 bảng, migrations, audit                        | Migration/seed/test trên PostgreSQL riêng; chưa có use case ghi                                                                              |
| P0-04   | API common health/error/config                    | HTTP tests tự động                                                                                                                           |
| P0-05   | OpenAPI → Dart                                    | Generator/template/serializer, drift check                                                                                                   |
| P0-06   | Flutter ba target                                 | Widget và build cần xem status theo platform                                                                                                 |
| P0-07   | GitHub CI/onboarding/review                       | Templates/workflow; GitHub settings cần xác minh riêng                                                                                       |
| UC01–02 | identity / phien_lam_viec                         | Login/logout, khóa tạm, idle/absolute expiry; integration/identity-catalog.test.ts                                                           |
| UC03–04 | identity / nguoi_dung, nhat_ky_bao_mat            | CRUD tài khoản, thu hồi phiên, hồ sơ/mật khẩu; test PostgreSQL và Flutter phase1_test.dart                                                   |
| UC05–08 | students/classes/subjects/teachers/academic-years | API + generated client + form Flutter, phân trang/tìm kiếm; kiểm scope/quan hệ trên PostgreSQL thật                                          |
| UC09    | gradebooks/bang_diem, diem_thanh_phan             | API tạo/lưới/nhập/chốt/sync có version/idempotency/quyền và rollback; Flutter responsive dùng generated client, xử lý conflict               |
| UC10    | audit/lich_su_sua_diem                            | Lịch sử cùng transaction, API cursor đúng scope, append-only; Flutter hiển thị NULL/0.0 và người/lý do/thời điểm sửa                         |
| UC11–12 | recognition/files                                 | Upload/outbox + worker BullMQ + FastAPI contract; chặn lệch lưới, lưu hai kênh/ảnh ô riêng và chuyển `CHO_DOI_CHIEU`; model thật chờ weights |
| UC13    | review                                            | API/UI đối chiếu, migration duyệt nguyên tử, version/idempotency, audit và rollback test; full-stack E2E còn lại                             |
| UC14–15 | final-results/ket_qua_tong_ket                    | Tính/xếp loại có policy và snapshot hệ số phiên bản; history append-only, transaction, idempotency và UI bảng đã chốt                        |
| UC16–17 | reports                                           | Thống kê chỉ đọc, phân bố đạt/chưa đạt, xuất workbook `.xlsx`, chống formula injection, rate limit và audit                                  |
| UC18    | final-results/students                            | API `students/me` không nhận student ID, chỉ trả điểm `DA_DUYET`; màn hình học sinh responsive                                               |

HTML §09 là truy vết thiết kế; không coi là kết quả nghiệm thu phần mềm. Tests phase 0 không chứng minh authorization nghiệp vụ chưa được viết.

## Bổ sung hệ số học kỳ (2026-10-03)

UC07 và UC14–UC18: ADR-0012; migration `202610030001_semester_weights`; danh mục `semester-weights`; hàm `he_so_ap_dung`; integration `apps/api/test/integration/semester-weights.test.ts` kiểm phân quyền, độc lập học kỳ, fallback, khóa và snapshot trên PostgreSQL thật. Widget `semester_weights_test.dart` kiểm sửa qua generated client trên ba profile. Nhận dạng thật vẫn chờ mã/config huấn luyện theo `docs/development/recognition-checkpoints.md`.

## Chụp/upload và đối chiếu (2026-10-03)

UC11–UC13: `docs/ux/recognition-capture.md`; camera mobile, kiểm ảnh theo nội dung, xem trước/phóng to, tiến độ và retry; biểu mẫu responsive, cảnh báo model unavailable/fake, không đề xuất dòng đỏ, kiểm dòng bị lọc trước khi duyệt. `recognition_upload_ux_test.dart` và `phase3_recognition_test.dart` kiểm luồng/profile; chưa kiểm camera thiết bị thật hoặc build iOS. Không đổi schema/API hoặc luồng ghi điểm chính thức.

## Quy trình nhà trường (2026-10-04)

- UC01–08: username điện thoại cho tài khoản mới, hồ sơ hạn chế, chặn quản trị theo vai trò; `identity-catalog.test.ts`, `school-workflow.test.ts`, `school_permissions_test.dart`.
- UC09–13: chốt từng cột, khóa sửa/import/OCR, version/idempotency/audit; `gradebook-write.test.ts`, `recognition-upload.test.ts`, `school-workflow.test.ts`, `phase2_gradebooks_test.dart`.
- UC14–18: hệ số chung theo học kỳ/năm, Đạt theo tỷ lệ ≥50%, không tính ĐTB môn định tính, công bố xếp loại riêng; integration PostgreSQL thật và Flutter generated client.
- Mở rộng lịch: nút đổi chế độ thống nhất, QTV nhóm lớp/phòng, học sinh ẩn phòng. Màn chính dùng AppEdgeScrollbar ngoài giới hạn chiều rộng nội dung.
- Hai migration thêm bảng cấu hình/chốt cột ngoài 16 bảng baseline; DB constraints kiểm quyền thực, append-only và migration mới/nâng cấp. Quyết định và acceptance ở ADR-0013.

## Lịch nhập điểm nhà trường (ADR-0014)

UC07: bỏ hệ số thành phần cũ khỏi form/badge, chỉ nhóm TX/GK/CK với hệ số chung học kỳ. Giữ field DB/contract deprecated cho lịch sử/tương thích.

UC09–13: QTV đặt lịch từng bảng/cột, giáo viên không chốt. DB chặn nhập/duyệt/upload ngoài lịch; tiến trình nền có khóa phối hợp, retry transaction, audit đầy đủ và idempotency khi fill 0/khóa. UC14–18 vẫn tổng kết theo phân công và chỉ công bố sau đủ kết quả. `grade-deadlines.test.ts` kiểm PostgreSQL thật: trước/sau hạn, quyền, version lịch, NULL/0/điểm đã duyệt, sĩ số mới, rollback audit, chạy đồng thời/replay; DB constraints kiểm quyền runtime không DML lịch/chốt thủ công.

`grade_deadline_ui_test.dart` kiểm lịch nằm ngang/cuộn và biểu mẫu UTC trên 320/390/1280, giáo viên chỉ xem lịch. Theo yêu cầu mới đã bỏ chọn/sắp xếp môn và nút quản lý môn khỏi bảng điểm toàn trường. Các test legacy tạo fixture chốt bằng role migration trong DB test để giữ kiểm tra dữ liệu lịch sử, không dùng API/role runtime chốt thủ công.

Mở rộng thời khóa biểu: `timetable_admin_ux_test.dart` kiểm thao tác từ ô trống/ô có môn, preset ngày/tiết, gửi tạo Chủ nhật/buổi chiều và chuyển ngày giữ nguyên môn/GV; profile 320/390/1440 với chữ 130%. `timetable_layout_test.dart` tiếp tục kiểm chia bảng toàn trường và GV/HS cuộn lịch chỉ đọc. Không đổi quy tắc backend, quyền hay schema trong phần UI này.
