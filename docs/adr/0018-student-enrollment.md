# ADR-0018: Ghi danh học sinh theo lớp và năm học

- Trạng thái: chấp nhận, đợt A (2026-10-23); đợt B (chức năng lên lớp / đổi lớp / lưu ban / thôi học) làm sau
- Liên quan: bất biến 5, 7, 8 trong `AGENTS.md`; ADR-0014; ADR-0017

## Vấn đề

`hoc_sinh` chỉ có một `ma_lop` (lớp gắn năm học) và cờ `dang_theo_hoc` chung. Muốn lên lớp năm sau phải tạo hồ sơ và tài khoản mới; nếu đổi `ma_lop` thì bảng điểm, tổng kết, báo cáo năm cũ mất học sinh vì mọi truy vấn lấy danh sách bằng `hs.ma_lop = b.ma_lop AND hs.dang_theo_hoc`.

## Quyết định

- Bảng `hoc_sinh_lop` (ghi danh): `ma_hoc_sinh`, `ma_lop`, `ma_nam_hoc` (sao từ lớp, trigger kiểm khớp), `tu_ngay`, `den_ngay`, `trang_thai` (`DANG_HOC`, `LEN_LOP`, `LUU_BAN`, `DA_CHUYEN_LOP`, `NGHI_HOC`, `TOT_NGHIEP`), `ly_do`, `nguoi_thuc_hien`. Duy nhất `(ma_hoc_sinh, ma_lop)`; tối đa một `DANG_HOC` cho mỗi `(ma_hoc_sinh, ma_nam_hoc)`; `DANG_HOC` ⇔ `den_ngay IS NULL`. Không xóa; runtime chỉ đọc.
- Dữ liệu cũ chuyển thành đúng một ghi danh mỗi học sinh. `hoc_sinh.ma_lop` và `hoc_sinh.dang_theo_hoc` giữ làm cột "lớp hiện tại" (DEPRECATED) do trigger đồng bộ từ ghi danh; sửa trực tiếp hai cột này → `STUDENT_CLASS_VIA_ENROLLMENT` (kể cả từ danh mục học sinh). INSERT `hoc_sinh` có `ma_lop` vẫn chạy được: trigger tạo ghi danh đầu tiên.
- Hàm dùng chung `hoc_sinh_cua_lop(lop, học_kỳ)` trả học sinh có ghi danh chồng lấn học kỳ, kèm `con_hoc`: `DANG_HOC`/`LEN_LOP`/`LUU_BAN`/`TOT_NGHIEP`, hoặc rời lớp sau khi học kỳ kết thúc. Học sinh đã lên lớp vẫn còn trong bảng điểm và tổng kết năm cũ; chuyển lớp/nghỉ giữa học kỳ thì giữ điểm nhưng không còn tính (không bị ghi 0, không bị đòi kết quả). Mọi hàm SQL và truy vấn API về "học sinh của bảng điểm" dùng hàm này.
- Học sinh xem điểm qua mọi ghi danh của em (`GET /students/me/results?yearId=`); danh mục học sinh có `currentClassId`, `currentClassName`, `currentYearId`.

## Còn dùng cột cũ (có chủ đích)

STT toàn trường/lớp trong danh mục học sinh, thời khóa biểu của học sinh và số học sinh trên tổng quan quản trị dùng "lớp hiện tại" (`ma_lop`, `dang_theo_hoc`), đúng nghĩa của chúng sau khi đồng bộ.
