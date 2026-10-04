# ADR-0013 — Chốt cột, công bố và đánh giá theo học kỳ

> Quyền chốt thủ công được thay thế bởi [ADR-0014](0014-grade-entry-deadlines.md). Các quyết định về công bố, hệ số chung, tài khoản và môn Đạt/Không đạt vẫn áp dụng.

## Quyết định của chủ dự án ngày 2026-10-04

Hệ số TX/GK/CK dùng chung cho mọi môn theo học kỳ thuộc năm học, mặc định 1/2/3. Cấu hình mới trong `he_so_hoc_ky_chung` thay thế phạm vi theo thành phần của ADR-0012. Giữ bảng cũ và snapshot để giải thích kết quả trước đây. Khóa thay đổi khi có bất kỳ cột hoặc bảng chốt trong kỳ.

Giáo viên chốt từng cột trong phạm vi phân công; các cột còn lại vẫn nhập được. `chot_cot_diem` lưu bằng chứng append-only. Chốt hết cột thì bảng tự chuyển `DA_CHOT`. Chốt kiểm đủ điểm bắt buộc, phiếu OCR đang xử lý/chờ duyệt, version, idempotency và audit. API chốt cả bảng cũ trả 403 hướng dẫn dùng cột. OCR không chạy trên cột chốt hoặc môn định tính.

QTV công bố qua `hoc_ky.da_cong_bo`. Trước công bố, API/UI/Excel ẩn xếp loại; không công bố khi bảng chưa chốt hoặc thiếu tổng kết học sinh đang học. Công bố ngăn tạo bảng mới/tính lại; có thể thu hồi công bố bằng QTV trước khi xử lý tiếp. Điểm cá nhân của cột đã chốt được đọc trong đúng phạm vi học sinh.

Môn đánh giá Đạt/Không đạt dùng hai giá trị nội bộ 10/0, UI/Excel hiển thị chữ; không chấp nhận giá trị trung gian. Thiếu điểm bắt buộc thì chưa tổng kết. Với các cột đã có điểm, Đạt khi tổng hệ số cột Đạt chiếm ít nhất 50% tổng hệ số; đúng 50% vẫn Đạt. NULL không đồng nghĩa Không đạt. Môn này không góp ĐTB, xếp hạng hay thống kê điểm số. Snapshot lưu kiểu đánh giá và hệ số.

Tài khoản giáo viên/học sinh mới dùng username điện thoại 10 chữ số đầu 0; Excel lưu dạng text. Không đổi tài khoản cũ. Không cho hai vai trò tự đổi tên; học sinh không đổi mật khẩu. UI danh mục chỉ QTV, route guard cùng backend kiểm quyền. Giáo viên có một mục Bảng điểm, OCR nằm trong bảng. Lịch học sinh ẩn phòng; QTV chọn nhóm lớp/phòng.

## Migration và acceptance

Hai migration tiến tiếp `202610040001_school_workflow`, `202610040002_workflow_guards`: thêm schema/hàm/trigger; backfill chốt cột của bảng đã chốt, nhận biết thành phần GK/CK cũ và giữ lịch sử. Không reset/seed DB đang dùng. Không rollback bằng xóa cấu hình/bằng chứng đã dùng; sửa bằng migration tiến tiếp có review. Không sửa migration đã áp dụng.

- PostgreSQL thật: từ chối quyền ngoài phân công, chốt thiếu điểm, sửa cột khóa, đổi hệ số sau chốt, công bố thiếu kết quả; replay không trùng audit.
- Tổng kết: cùng hệ số trên nhiều môn, Đạt với TX không đạt nhưng GK/CK đạt, đúng ngưỡng 50%, ẩn trước/hiện sau công bố, loại môn định tính khỏi ĐTB.
- Identity: từ chối đổi tên/mật khẩu học sinh, username mới sai định dạng và báo cáo quản trị ngoài vai trò.
- Flutter: route trực tiếp bị chặn; hồ sơ read-only, nút chốt cột, form hệ số và màn hiện hữu qua generated client. Thanh cuộn chính nằm ngoài nội dung có giới hạn chiều rộng; cuộn con độc lập.

Kiểm chứng chính: `school-workflow.test.ts`, `semester-weights.test.ts`, toàn bộ integration/DB constraints, `school_permissions_test.dart` và suite Flutter. Widget profile không thay thế kiểm thử Android/iOS trên thiết bị hoặc simulator thật.
