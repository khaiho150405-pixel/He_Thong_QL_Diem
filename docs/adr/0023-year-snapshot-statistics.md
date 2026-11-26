# ADR-0023: Bản chốt cuối năm và thống kê theo năm học

## Trạng thái

Accepted (2026-11-26, chủ dự án chọn làm đợt 2 của lộ trình lưu trữ năm học). Bổ sung ADR-0020 và ADR-0022.

## Bối cảnh

Sau khi đóng năm, danh mục dùng chung (họ tên, tên môn, giáo viên, tên trường) vẫn đổi được và mức học tập vẫn
tính lúc xem, nên số liệu năm cũ có thể hiển thị khác đi. Báo cáo chỉ theo từng bảng điểm.

## Quyết định

1. Đóng năm lập một bản chốt trong cùng giao dịch: `ban_chot_nam` (phiên bản, tên năm, tên trường),
   `ban_chot_hoc_sinh` (theo học kỳ: họ tên, ngày sinh, lớp, khối, GVCN, trạng thái ghi danh, mức học tập) và
   `ban_chot_mon` (tên môn, giáo viên, điểm tổng kết, kết quả, điểm thành phần kèm hệ số). Chỉ gồm học kỳ đã công
   bố và học sinh được tính ở cuối học kỳ.
2. Bản chốt chỉ ghi thêm. Mở lại rồi đóng lại tạo phiên bản mới; phiên bản cũ giữ nguyên. Năm đã đóng trước
   migration này được lập phiên bản đầu khi chạy migration.
3. Ngoại lệ duy nhất: xóa thông tin học sinh (ADR-0020) ẩn họ tên và ngày sinh trong mọi phiên bản; điểm giữ
   nguyên.
4. Một nguồn số liệu (`nguon_hoc_sinh_nam`, `nguon_mon_nam`): năm đã đóng đọc phiên bản mới nhất, năm còn mở đọc
   dữ liệu hiện tại của học kỳ đã công bố. `xep_muc_hoc_tap` trả mức đã chốt cho năm đã đóng.
5. Thống kê theo **từng học kỳ** (không gộp hai kỳ, giữ ADR-0013): toàn trường, khối, lớp, môn, và so sánh các
   năm. Điểm trung bình là trung bình các điểm tổng kết môn tính điểm; môn nhận xét đếm Đạt/Chưa đạt.
6. Excel tổng hợp được dựng từ nguồn trên mỗi lần tải, **không lưu tệp**, để việc ẩn thông tin học sinh luôn có
   hiệu lực. Mỗi lần xuất ghi `YEAR_RECORD_EXPORTED`, tối đa 5 lần mỗi phút.
7. API chỉ QTV: `GET /reports/admin/years/{id}/statistics?term=`, `/export.xlsx?term=`,
   `/reports/admin/years/comparison?term=`. Giao diện: màn "Thống kê năm học".

## Hệ quả và giới hạn

- Màn điểm của học sinh và bảng điểm vẫn hiển thị tên hiện tại; chỉ mức học tập, thống kê và Excel tổng hợp đọc
  bản chốt.
- Excel không phải học bạ số theo Thông tư 70/2026 (chưa có chữ ký số, chuẩn dữ liệu của Bộ).
- Chưa đo hiệu năng với quy mô nhiều nghìn học sinh; năm còn mở tính mức học tập khi xem thống kê.
- Sao lưu định kỳ và thử khôi phục vẫn là việc vận hành.
- Rollback: khôi phục hàm cũ và bỏ ba bảng `ban_chot_*` của migration `202611300001_year_snapshot`.
