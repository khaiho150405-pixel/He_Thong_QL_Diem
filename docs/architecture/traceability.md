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

## Ghép dòng nhận dạng (ADR-0015)

UC11–UC13 (nút 3.2, 4.1–4.9, 5.1–5.8; sơ đồ phân cấp chức năng không đổi): một hàm STT chung ở API (`common/student-order.ts`); phiếu nhận dạng chốt danh sách lớp STT → học sinh vào `danh_sach_phieu` (append-only); bỏ số dòng khai báo; ghép dòng theo STT + họ tên đọc trên giấy (`recognition/domain/row-matching.ts`); mức dòng là mức thấp hơn giữa mức điểm và mức ghép; ghép thất bại → phiếu `LOI` (`ROW_MATCH_FAILED`); màn hình kiểm tra riêng. Bất biến 5 trong AGENTS.md được diễn giải lại. Trạng thái triển khai theo `docs/development/phase-7-prompts.md`; test tương ứng được liệt kê khi từng bước BE/FE hoàn tất.

## Mẫu bảng điểm (ADR-0016, P2)

UC11–UC12 (chuẩn bị nhận dạng nhiều cột, chưa đổi luồng tải ảnh của giáo viên): QTV khai báo mẫu qua `catalog/form-templates*` (module `form-templates`: `domain/definition.ts` luật hợp lệ và ánh xạ (nhóm, thứ tự) → thành phần; `application/service.ts`; `infrastructure/prisma-store.ts` gọi `luu_mau_bang_diem` / `doi_trang_thai_mau_bang_diem`). Server phân tích lại ảnh qua `/v2/layout/analyze` (client `HttpRecognitionV2Client`, `recognition/public.ts`), không tin chữ ký/số cột của client (`TEMPLATE_COLUMN_COUNT_MISMATCH`). Mẫu đã có phiếu tham chiếu không sửa tại chỗ (`TEMPLATE_IN_USE`), "sửa" là `versions`; khóa lạc quan `expectedVersion` (`VERSION_CONFLICT`). `try` gọi `/v2/recognize` đồng bộ, không ghép học sinh, không tạo phiếu/kết quả dòng, chỉ audit `FORM_TEMPLATE_TRIED` (bất biến 1 và 2 không bị đụng: không ghi vào `diem_thanh_phan`). Giáo viên chỉ đọc mẫu `DANG_DUNG`, học sinh 403 (bất biến 9, 10).

Kiểm thử: `apps/api/test/form-template-definition.test.ts` (luật hợp lệ, ánh xạ), `apps/api/test/form-templates.test.ts` (service với fake store/model/storage, phân quyền âm tính, mã lỗi `try`, dịch lỗi SQL, client v2 với fetch giả), `database/tests/form-templates.test.ts` (CHECK/UNIQUE/FK, quyền runtime, hàm SQL, trigger, hạn mức).

## Lô nhận dạng nhiều trang, nhiều thành phần (ADR-0016, P3)

UC11–UC13: giáo viên được phân công tải 1–4 ảnh trang cùng một mẫu `DANG_DUNG` và chọn nhiều cột điểm; `POST gradebooks/:id/recognition-batches` tạo MỘT lô (`lo_nhan_dien`, `trang_lo_nhan_dien`) và MỘT phiếu cho mỗi thành phần trong MỘT giao dịch SERIALIZABLE (`tao_lo_nhan_dien`: khóa bảng điểm, kiểm phân công, thành phần thuộc môn và khớp ánh xạ (nhóm, thứ tự), cột chưa chốt/đang trong thời gian nhập, không có phiếu chờ, danh sách lớp chốt cho từng phiếu, audit, idempotency, MỘT sự kiện outbox cho cả lô). `GET .../form-templates/:templateId/mapping` chỉ gợi ý (cờ `locked`, `pending`, `channels`); backend kiểm lại ở SQL (bất biến 9). Worker (`recognition/application/batch-worker.ts`) gọi `/v2/recognize` cho từng trang với cùng một `layout`, kiểm phản hồi chặt theo `key` đã yêu cầu, gom dòng mọi trang, ghép học sinh MỘT lần cho cả lô (`matchBatchRows`, bất biến 5; học sinh ở hai trang → `ROW_MATCH_FAILED`), tách theo `key` và ghi mọi phiếu bằng `luu_ket_qua_lo` trong một giao dịch. Mức cuối của dòng là mức thấp hơn giữa mức điểm và mức ghép (bất biến 4); cột một kênh không bao giờ Xanh (D-01) và dòng Đỏ không lưu gợi ý, đều bị ràng buộc ở SQL. Một trang lỗi → cả lô và mọi phiếu `LOI` cùng mã kèm số trang, không có `ket_qua_dong`. Máy chỉ đề xuất (bất biến 1): không đường nào ghi `diem_thanh_phan`. Duyệt vẫn từng phiếu bằng `duyet_phieu_nhan_dien` không đổi (bất biến 6, 11); hủy lô (`huy_lo_nhan_dien`) hủy mềm mọi phiếu chưa duyệt. Phiếu một ảnh cũ không đổi.

Kiểm thử: `apps/api/test/recognition-batch-matching.test.ts` (ghép nhiều trang), `apps/api/test/recognition-batch-worker.test.ts` (worker với store/mô hình giả: đúng cột, một kênh, lỗi trang, hủy giữa chừng), `apps/api/test/recognition-batch-service.test.ts` (kiểm ảnh, tối đa 4 trang, dọn object, replay), `apps/api/test/form-template-mapping.test.ts` (`/mapping`), `database/tests/recognition-batches.test.ts` (hàm SQL, rollback, ràng buộc, quyền, duyệt từng phiếu, hủy), `apps/api/test/integration/recognition-batches.test.ts` (HTTP + worker thật + PostgreSQL: AC-2..AC-8).

Cấu hình: thời gian chờ `try` đặt bằng biến môi trường `FORM_TEMPLATE_TRY_TIMEOUT_MS` (mặc định 90000, 1000–600000, đọc trong `app.ts`); `analyze`/tạo mẫu dùng `RECOGNITION_TIMEOUT_MS` hiện có; hạn mức `analyze`/`try` dùng chung `UPLOAD_RATE_LIMIT_PER_MINUTE`.

## Ghép dòng nhận dạng (ADR-0015) — luật phân loại

Luật phân loại hai kênh (BE-21/22, bất biến 4): hai kênh độc lập đồng thuận → Xanh; chỉ một kênh ≥ τ → Vàng kèm gợi ý và nguồn (`suggestedSource`); mâu thuẫn/cùng yếu/không hợp lệ → Đỏ không gợi ý. Mã: `apps/recognition-service/src/domain/classification.py`; kiểm thử: `tests/test_classification.py`, `apps/api/test/recognition-worker.test.ts`; đo: `scripts/recognition/evaluate_pages.py` (số liệu trong ADR-0015).
