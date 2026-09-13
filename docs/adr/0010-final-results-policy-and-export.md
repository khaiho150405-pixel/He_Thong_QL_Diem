# ADR-0010 — Tổng kết có phiên bản và xuất Excel

## Bối cảnh

UC14–UC18 cần tính tổng kết, xếp loại, thống kê, xuất Excel và cho học sinh xem điểm của chính mình. Tài liệu phân tích chưa chốt công thức làm tròn, ngưỡng xếp loại, xử lý thiếu điểm và mẫu Excel production. Hệ thống vẫn phải phát triển tiếp mà không đóng cứng các quyết định đó trong controller, widget hoặc mã ứng dụng.

## Quyết định

Hệ thống chỉ tính một bảng điểm đã `DA_CHOT`. Hàm `tinh_ket_qua_bang_diem` chạy ở mức cô lập `SERIALIZABLE`, khóa bảng, xác minh phiên giáo viên cùng phân công và dùng duy nhất ô có trạng thái `DA_DUYET`. Thành phần bắt buộc thiếu hoặc chưa duyệt làm học sinh đó bị bỏ qua và được trả trong danh sách thiếu; không đổi `NULL` thành `0.0`. Điểm tổng kết là trung bình có trọng số của các thành phần đã duyệt, làm tròn theo policy đang hoạt động.

Mỗi policy xếp loại có version bất biến, số chữ số làm tròn và các mức gồm mã, điểm tối thiểu, thứ tự, cờ đạt/chưa đạt. QTV tạo một version mới rồi kích hoạt nguyên tử; không sửa version đã được dùng. Migration seed `DEV-2026-01` chỉ là mặc định development để chạy và demo, không phải quy định cuối của nhà trường.

Mỗi kết quả lưu snapshot đầy đủ của bộ hệ số và policy, kèm hash version hệ số. Lần tính đầu và mọi lần tính lại đều thêm `lich_su_tong_ket`; trigger cấm update/delete/truncate. Kết quả, lịch sử, audit và idempotency cùng transaction. Bảng `lich_su_tong_ket` là bảng kỹ thuật bổ sung, còn `chinh_sach_xep_loai` và `tieu_chi_xep_loai` là dữ liệu cấu hình nghiệp vụ; 16 bảng nghiệp vụ baseline vẫn được giữ nguyên.

Thống kê UC16 là truy vấn chỉ đọc từ kết quả đã tính. Trạng thái đạt lấy theo đúng version policy gắn với từng kết quả. UC17 dùng ExcelJS vì runtime Node không có API chuẩn để tạo workbook `.xlsx`; file gồm sheet bảng điểm và sheet thông tin, ô điểm là số, tên người dùng được vô hiệu hóa tiền tố công thức. Mỗi lần xuất thành công được audit và giới hạn năm lần mỗi phút cho từng tài khoản. Mẫu này là mẫu development chung; cột Vietschool chính thức cần quyết định riêng trước production.

UC18 không nhận student ID từ client. API ánh xạ `ma_nguoi_dung` của phiên sang đúng `hoc_sinh`, chỉ trả ô `DA_DUYET` và kết quả tổng kết tương ứng. Bản development dùng lớp hiện tại vì lịch sử chuyển lớp chưa được sản phẩm quyết định.

## Hệ quả và rollback

Thay ngưỡng tạo version mới; kết quả cũ vẫn giải thích được. Thay hệ số rồi tính lại tạo history thay vì mất bằng chứng cũ. Runtime không được DML trực tiếp vào policy hoặc lịch sử.

Rollback ở môi trường dùng chung dùng migration tiến tiếp để thu hồi quyền execute hoặc kích hoạt policy thay thế. Không xóa kết quả, snapshot, lịch sử hoặc audit đã sinh.
