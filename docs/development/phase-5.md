# Giai đoạn 5 — Tổng kết, báo cáo và tra cứu cá nhân

## UC14–UC15: tổng kết và xếp loại

- `POST /api/v1/gradebooks/{id}/final-results/calculate` yêu cầu giáo viên đúng phân công, bảng `DA_CHOT`, `expectedVersion`, lý do và `x-idempotency-key`.
- PostgreSQL chỉ dùng điểm `DA_DUYET`, giữ `NULL` khác `0.0`, tính trung bình có trọng số, làm tròn và xếp loại theo policy đang hoạt động.
- Response nêu số học sinh đã tính và danh sách học sinh bị bỏ qua vì thiếu thành phần bắt buộc. Kết quả lưu snapshot hệ số/policy; tính lại thêm lịch sử append-only.
- QTV xem và tạo version mới tại màn hình **Chính sách xếp loại**. Mặc định `DEV-2026-01` cần nhà trường thay bằng policy đã phê duyệt trước production.

## UC16–UC17: thống kê và Excel

- `GET /api/v1/reports/gradebooks/{id}/summary` trả trung bình, cao nhất, thấp nhất, đạt/chưa đạt và phân bố xếp loại trong đúng phạm vi phân công.
- `GET /api/v1/reports/gradebooks/{id}/export.xlsx` tạo workbook thật với điểm dạng số, sheet thông tin, chống công thức từ dữ liệu text, audit người/phạm vi xuất và rate limit 5 lần/phút.
- Màn hình bảng đã chốt hiển thị thống kê, kết quả, version hệ số/policy, lịch sử và nút lưu Excel trên web/Android/iOS qua `file_picker`.
- Mẫu workbook hiện tại là mẫu development chung. Mẫu Vietschool/cột chính thức vẫn là quyết định production trong AGENTS.md §14.

## UC18: học sinh xem điểm của mình

- `GET /api/v1/students/me/results` không nhận mã học sinh tùy ý. Backend lấy học sinh từ tài khoản phiên hiện tại và chỉ trả điểm thành phần `DA_DUYET`.
- Màn hình **Điểm của tôi** hiển thị theo học kỳ/môn, điểm thành phần, tổng kết và xếp loại; giáo viên/QTV bị chặn khỏi route và role học sinh không được gọi API toàn bảng.
- Hiện dùng lớp hiện tại của học sinh. Lịch sử chuyển lớp nhiều năm cần chốt mô hình dữ liệu trước production.

## Kiểm chứng

- Hai migration Phase 5 cài thành công từ database rỗng và nâng cấp database Phase 4.
- Integration PostgreSQL xác nhận phép tính trọng số/làm tròn, `NULL`/`0.0`, snapshot, history, idempotency, policy version, thống kê, workbook ZIP/XLSX, audit export, IDOR và lọc điểm chờ đối chiếu khỏi học sinh.
- Unit test xác nhận request/policy chặt chẽ. Widget test ở 1280 px và 390 px xác nhận luồng giáo viên, QTV và học sinh.

Xem [ADR-0010](../adr/0010-final-results-policy-and-export.md). Phase 5 chỉ đủ điều kiện mở PR sau khi `pnpm check`, contract drift, PostgreSQL suites, Flutter workspace, Python và GitHub CI đều xanh.
