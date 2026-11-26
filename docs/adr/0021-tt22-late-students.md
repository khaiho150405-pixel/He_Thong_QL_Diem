# ADR-0021: Học sinh vào lớp sau và đánh giá theo Thông tư 22/2021

## Trạng thái

Accepted (2026-11-26, chủ dự án chọn "Đúng TT22" và "Đổi theo TT22"). Thay thế phần xếp loại theo từng môn của
ADR-0010, quy tắc Đạt/Không đạt theo tỷ lệ hệ số của ADR-0013 và bổ sung ADR-0014, ADR-0018.

## Bối cảnh

- Học sinh vào lớp sau khi đã có bảng điểm chỉ bị báo "còn thiếu"; đến hạn hệ thống tự thêm ô rồi ghi 0, kể cả
  khi em mới vào sát hạn hoặc cột đã được chấm trước khi em đến.
- Hệ thống gắn Giỏi/Khá/Trung bình/Yếu cho từng môn. Thông tư 22/2021/TT-BGDĐT (còn hiệu lực; Thông tư
  89/2026/TT-BGDĐT hiệu lực 01/12/2026 không đổi cách tính và xếp mức) chỉ xếp mức kết quả học tập cho cả học
  kỳ, tính trên tất cả các môn.
- Thông tư 15/2026/TT-BGDĐT quy định hồ sơ, thủ tục chuyển trường. Chưa thấy văn bản nào quy định cách chấm cột
  điểm cho học sinh chuyển đến giữa kỳ, nên quy tắc dưới đây là quyết định của dự án.

## Quyết định

### Học sinh vào lớp sau

1. Khi ghi danh đang học được tạo hoặc kích hoạt lại, trigger `enrollment_grid` tạo ngay ô trống ở mọi bảng đang
   nhập liệu của lớp (học kỳ chưa công bố, chưa kết thúc trước ngày vào lớp), tăng phiên bản bảng và ghi
   `GRADEBOOK_STUDENT_AUTO_ADDED`.
2. Đến hạn, **không ghi 0** cho em "vào sau" (hàm `hoc_sinh_vao_sau`), đúng khi gặp một trong ba dấu hiệu:
   ghi danh tạo sau lúc cột mở nhập trong khi lớp đã có học sinh khác từ trước đó; ngày vào lớp sau ngày mở cột;
   hoặc bạn cùng lớp đã có điểm ở cột đó trước khi em được ghi danh. Ô giữ `NULL`/`CHUA_CO`, cột vẫn khóa, ghi
   `GRADE_LATE_STUDENT_PENDING`.
3. Giáo viên bổ sung điểm chuyển đến hoặc điểm kiểm tra bù, hoặc xin miễn: nhập trực tiếp khi cột còn mở, gửi
   đơn điều chỉnh khi cột đã khóa. Chừng nào ô bắt buộc còn trống, em chưa được tổng kết và học kỳ chưa công bố
   được.
4. Bảng đã khóa toàn bộ trước khi em vào lớp giữ luồng cũ (QTV thêm học sinh sau chốt, hoặc đơn điều chỉnh).

### Đánh giá theo Thông tư 22/2021

1. Môn tính điểm chỉ lưu điểm trung bình môn (`xep_loai` là NULL).
2. Môn nhận xét: **Đạt** khi mọi cột đã duyệt đều Đạt (kể cả cột không bắt buộc đã có kết quả); một lần Chưa đạt
   là **Chưa đạt**. Thiếu cột bắt buộc thì chưa tổng kết. Điểm lưu 10.0 hoặc 0.0 như trước.
3. Mức kết quả học tập học kỳ (hàm `xep_muc_hoc_tap`, Điều 9): Tốt, Khá, Đạt, Chưa đạt tính trên mọi môn đã tổng
   kết, kèm quy tắc nâng một mức khi riêng một môn làm mức thấp đi từ hai mức. Cần ít nhất 6 môn tính điểm; ít hơn
   thì hiện "Chưa đủ môn để xếp mức". Chỉ hiển thị sau khi công bố học kỳ.
4. Chính sách xếp loại do QTV khai báo chỉ còn quyết định số chữ số làm tròn (theo Thông tư là 1); các ngưỡng
   không còn dùng để xếp loại môn.
5. Kết quả đã tính trước đó giữ nguyên snapshot; chỉ đổi khi tính lại ở học kỳ chưa công bố. API không còn trả
   xếp loại của môn tính điểm, kể cả với kết quả cũ (riêng lịch sử tính giữ giá trị đã ghi). Snapshot mới ghi `standard: TT22/2021/TT-BGDDT`.
6. Báo cáo theo bảng điểm chia nhóm theo khoảng điểm; tổng quan quản trị thống kê theo mức học tập học kỳ. File
   Excel bỏ cột "Xếp loại" (môn nhận xét hiện Đạt/Không đạt ngay trong cột điểm).

## Hệ quả và giới hạn

- Ngoài Thông tư 22 vẫn còn: điểm trung bình các môn và hạng trong lớp trên trang học sinh (thông tin tham khảo
  có từ trước); chưa tính kết quả cả năm vì dự án không gộp hai học kỳ; QTV vẫn đổi được hệ số (Thông tư quy
  định 1/2/3); số lần đánh giá thường xuyên theo số tiết chưa được kiểm tra.
- Không có thông báo riêng cho giáo viên về ô chờ bổ sung; theo dõi qua danh sách điều kiện công bố và nhật ký.
- Nhập cả danh sách lớp sau khi cột đã mở không bị coi là vào sau, trừ khi bạn đã có điểm trước đó.
- Rollback: khôi phục các hàm trước migration `202611280001_tt22_late_students` và gỡ trigger `enrollment_grid`.
