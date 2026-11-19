# Báo cáo lỗi đã kiểm tra

Tổng hợp các lỗi và điểm chưa hợp lý tìm được khi kiểm tra hệ thống (web, điện thoại 375px, 3 vai quản trị, giáo viên, học sinh) và rà mã nguồn. Cập nhật: 20/11/2026.

Ký hiệu trạng thái: **Đã sửa**, **Sửa một phần**, **Chưa sửa**, **Chưa kiểm chứng**.

Tình trạng chung: mọi thay đổi trong báo cáo này (trừ commit `47b95be`) vẫn **chưa commit**. Test lần chạy gần nhất: API 208 test, Flutter 719 test đều đạt.

## 1. Tổng hợp nhanh

| Nhóm                                  | Số mục | Đã sửa | Chưa sửa / một phần |
| ------------------------------------- | -----: | -----: | ------------------: |
| A. Lỗi giao diện và nhập liệu         |     14 |     14 |                   0 |
| B. Chức năng, dữ liệu, nghiệp vụ      |      7 |      6 |                   1 |
| C. Thông tin hiển thị theo vai        |      9 |      9 |                   0 |
| D. Nội dung hiển thị không đồng bộ    |      8 |      7 |                   1 |
| E. Hiệu năng và tải dữ liệu           |      4 |      1 |                   3 |
| F. Widget Android                     |      4 |      1 |                   3 |
| G. Môi trường, hạ tầng, giới hạn kiểm |      7 |      0 |                   7 |

## 2. Chi tiết

### A. Lỗi giao diện và nhập liệu

| #    | Lỗi                                                                                                                  | Vai / nền tảng | Trạng thái | Cách xử lý                                                                              |
| ---- | -------------------------------------------------------------------------------------------------------------------- | -------------- | ---------- | --------------------------------------------------------------------------------------- |
| A-01 | Form báo lỗi đỏ không tự mất sau khi sửa                                                                             | Quản trị, web  | Đã sửa     | Thêm `autovalidateMode` ở các hộp thoại danh mục                                        |
| A-02 | Ô chọn (`AppSelectField`) không đồng bộ giá trị vào form, tạo tài khoản giáo viên xong vẫn không Lưu được            | Quản trị       | Đã sửa     | Đồng bộ giá trị vào `FormField`                                                         |
| A-03 | Ô điểm không nhận `8,5` hoặc `9`, lưu khi có ô sai không báo                                                         | Giáo viên      | Đã sửa     | `normalizeGradeText`, thông báo khi lưu có ô sai                                        |
| A-04 | Ngày hiển thị không đồng nhất, chưa dạng dd/MM/yyyy ở danh sách, hộp thoại chuyển lớp, nghỉ học, học lại             | Quản trị       | Đã sửa     | `formatDateTimeVi`, `AppDateField.formatDisplay`                                        |
| A-05 | Ngày hiệu lực mặc định của chuyển lớp, nghỉ học, học lại nằm ngoài năm học đang xem                                  | Quản trị       | Đã sửa     | `defaultEffectiveDate` kẹp vào năm học                                                  |
| A-06 | Rời bảng điểm khi còn ô đã sửa không cảnh báo, mất dữ liệu                                                           | Giáo viên      | Đã sửa     | `confirmLeave`, `onBeforeLeave`                                                         |
| A-07 | Bảng điểm không tải lại khi đổi `bookId` trên địa chỉ                                                                | Giáo viên      | Đã sửa     | `GradebookScreen` tải lại khi `bookId` đổi                                              |
| A-08 | Hiện `#id` và "Phiên bản" kỹ thuật ở nhiều nơi ("Học sinh #id", "Người tính #id", "Bảng điểm #id", header bảng điểm) | Mọi vai        | Đã sửa     | Thay bằng nhãn có nghĩa                                                                 |
| A-09 | Nhãn "Chưa đạt" ở biểu đồ học lực bị cắt                                                                             | Quản trị       | Đã sửa     | Chỉnh bố cục biểu đồ                                                                    |
| A-10 | Nhập số nguyên (khối, số tiết, thứ tự) sai chỉ báo "Yêu cầu không hợp lệ." chung chung                               | Quản trị       | Đã sửa     | Kiểm tra 1..max ở dialog (`_intFieldMax`)                                               |
| A-11 | Câu lỗi 400/409 chung chung không có gợi ý                                                                           | Mọi vai        | Đã sửa     | `errorMessage` có gợi ý cụ thể                                                          |
| A-12 | Công tắc "Đang theo học" khi bị khóa chỉ hiện viên thuốc xám, không thấy nút gạt                                     | Quản trị       | Đã sửa     | `switchTheme`: nền xanh nhạt, nút gạt trắng, có dấu tích                                |
| A-13 | Thông báo nổi (snackbar) trùng màu navy của thanh bên                                                                | Mọi vai        | Đã sửa     | Thẻ nổi nền sáng có viền, chữ đậm                                                       |
| A-14 | Danh sách danh mục hiện khung chờ và tải lại toàn bộ sau mỗi thêm, sửa, xóa                                          | Quản trị       | Đã sửa     | Xóa bỏ dòng tại chỗ, thêm/sửa làm mới ngầm (`ProgressiveLoader.refresh`, `removeWhere`) |

### B. Chức năng, dữ liệu, nghiệp vụ

| #    | Lỗi                                                                                                                           | Vai / nền tảng | Trạng thái | Cách xử lý                                                                                                                               |
| ---- | ----------------------------------------------------------------------------------------------------------------------------- | -------------- | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| B-01 | Còn chức năng tạo bảng điểm thủ công, trong khi bảng điểm đã tự tạo khi phân công                                             | Quản trị, API  | Đã sửa     | Gỡ route `POST gradebooks`, route khởi tạo theo học kỳ, nút trên giao diện; migration `202611070001` xóa hàm `khoi_tao_bang_diem_hoc_ky` |
| B-02 | Năm học "2024-2025" gán cứng trong seed, tiêu đề hiện năm cũ; học kỳ, ngày vào lớp, năm sinh học sinh mẫu cũ theo             | Mọi vai        | Đã sửa     | Seed tính năm học theo ngày hiện tại; dữ liệu DB `quan_ly_diem_dev`, `qld_phase7_test` dời sang 2026-2027 (có sao lưu)                   |
| B-03 | Gợi ý nhập "Ví dụ: 2026-2027", "SCHOOL-2026-01" gán cứng                                                                      | Quản trị       | Đã sửa     | `schoolYearName()`, năm hiện tại                                                                                                         |
| B-04 | `GET timetable` trả phòng học cho học sinh, trái bất biến "học sinh không thấy phòng học"                                     | Học sinh, API  | Đã sửa     | Trả `phong_hoc = null` cho học sinh, có test                                                                                             |
| B-05 | Xếp loại chung của học sinh gộp mọi điểm dưới 6.5 thành "Đạt", kể cả dưới 5                                                   | Học sinh       | Đã sửa     | Ngưỡng 8.0 / 6.5 / 5.0 theo chính sách mặc định (`overallClassificationCodeOf`)                                                          |
| B-06 | Biểu đồ phổ điểm tổng quan bỏ sót học sinh xếp loại `TRUNG_BINH`                                                              | Quản trị       | Đã sửa     | Gộp đúng `TRUNG_BINH`/`YEU` (và mã cũ `DAT`, `CHUA_DAT`)                                                                                 |
| B-07 | Điểm trung bình chung học kỳ của học sinh tính ở client trong bảng, còn ô "Điểm TB" đầu trang lấy từ API: hai nguồn khác nhau | Học sinh       | Chưa sửa   | Cần chuyển sang một nguồn từ API (trái nguyên tắc không đặt quy tắc tính ở client)                                                       |

### C. Thông tin hiển thị theo vai

Nguyên tắc: học sinh chỉ thấy điểm bằng lời thường, không thấy quy trình chốt, duyệt, công bố; giáo viên không thấy mã nội bộ và phiên bản cấu hình; quản trị thấy đủ.

| #    | Lỗi                                                                                                                         | Vai                 | Trạng thái | Cách xử lý                                                                |
| ---- | --------------------------------------------------------------------------------------------------------------------------- | ------------------- | ---------- | ------------------------------------------------------------------------- |
| C-01 | Học sinh thấy "Đã chốt & tính ĐTB lúc ...", "Điểm đã được giáo viên duyệt"                                                  | Học sinh            | Đã sửa     | Bỏ hai dòng                                                               |
| C-02 | Học sinh thấy "Chờ chốt", "Chờ công bố", "Chưa công bố", "Đang cập nhật (0/1)", "Môn đã chốt", "Chỉ tính bảng điểm đã chốt" | Học sinh            | Đã sửa     | Đổi thành "Chưa có điểm TB", "Chưa xếp loại", "Môn đã có điểm"; bỏ số đếm |
| C-03 | Nhãn xếp loại của học sinh hiện mã thô như `GIOI`                                                                           | Học sinh            | Đã sửa     | Dùng nhãn chung                                                           |
| C-04 | API trả cho học sinh thời điểm tính, mã bảng điểm, mã môn, mã học kỳ, mã thành phần điểm                                    | Học sinh            | Đã sửa     | Bỏ khỏi SQL và DTO, sinh lại OpenAPI và client                            |
| C-05 | Giáo viên thấy "Hệ số W-...", "Chính sách DEV-..." ở bảng tổng kết, hộp xác nhận và thông báo sau khi tính                  | Giáo viên           | Đã sửa     | Chỉ quản trị thấy phiên bản; giáo viên chỉ thấy "Tính lúc ..."            |
| C-06 | Banner phiếu điều chỉnh hiện mã phiếu (chuỗi UUID)                                                                          | Giáo viên           | Đã sửa     | "Có phiếu điều chỉnh đang chờ duyệt"                                      |
| C-07 | Lịch sử sửa điểm hiện "Người sửa #id", chữ "NULL", giờ dạng thô                                                             | Giáo viên           | Đã sửa     | "Bạn sửa" khi là mình, "Chưa có", giờ dd/MM/yyyy HH:mm                    |
| C-08 | Màn kết quả nhận dạng hiện `#id` của lô và mẫu                                                                              | Giáo viên           | Đã sửa     | Nhãn chung ("Lô nhận dạng", "Kết quả nhận dạng")                          |
| C-09 | Lời chào, menu tài khoản, thanh bên của giáo viên và học sinh hiện tên đăng nhập ("Xin chào, hocsinh_a")                    | Giáo viên, học sinh | Đã sửa     | `SessionDto.displayName` (họ tên), `shownName` ở giao diện                |

### D. Nội dung hiển thị không đồng bộ giữa các nơi

| #    | Lỗi                                                                                                                                  | Trạng thái | Cách xử lý                                                                                          |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------ | ---------- | --------------------------------------------------------------------------------------------------- |
| D-01 | Ngày giờ có chỗ "giờ trước ngày", chỗ ngày không đệm số 0 (thông tin trường, panel nhận dạng, màn hủy phiếu)                         | Đã sửa     | Mọi nơi dùng `formatDateTimeVi` (dd/MM/yyyy HH:mm)                                                  |
| D-02 | "Chốt" và "khóa" lẫn lộn cho cùng một ý (giao diện và thông báo lỗi API); trạng thái bảng điểm trên tổng quan là "Đã chốt/Đang nhập" | Đã sửa     | Thống nhất "khóa"; API trả "Đã khóa"/"Đang nhập liệu"                                               |
| D-03 | Điểm trung bình gọi bằng 5 cách ("ĐTB", "Điểm TB", "ĐTB Môn", "ĐIỂM TRUNG BÌNH CHUNG", "ĐTB học kỳ")                                 | Đã sửa     | "Điểm TB học kỳ", "Điểm TB lớp", "Điểm tổng kết"                                                    |
| D-04 | `YEU` hiện "Yếu" ở app nhưng "Chưa đạt" ở API; `TRUNG_BINH` không có nhãn thống nhất                                                 | Đã sửa     | Một bộ nhãn: Giỏi / Khá / Đạt / Chưa đạt (`classificationBadgeOf`, `apps/api/src/common/labels.ts`) |
| D-05 | Cột "Xếp loại" của file Excel xuất ra mã (`GIOI`) trong khi giao diện hiện nhãn                                                      | Đã sửa     | Xuất nhãn                                                                                           |
| D-06 | Nhãn vai trò viết ở 4 chỗ riêng; có chữ "Admin" trong hộp thoại nhập Excel                                                           | Đã sửa     | Một hàm `roleLabelOf`; đổi "Admin" thành "bị khóa hoặc chưa mở nhập"                                |
| D-07 | Hệ số học sinh "(hs 1.00)" khác giáo viên "Hệ số 1.00"                                                                               | Đã sửa     | "(hệ số 1.00)"                                                                                      |
| D-08 | Viết tắt GV/HS không thống nhất ở vài nhãn tổng quan ("Chờ GV duyệt", "HS / lớp", "Mã HS")                                           | Chưa sửa   | Nên thống nhất bằng chữ đầy đủ hoặc bảng thuật ngữ                                                  |

### E. Hiệu năng và tải dữ liệu

| #    | Lỗi                                                                                                      | Nền tảng        | Trạng thái   | Ghi chú                                                                                                                                               |
| ---- | -------------------------------------------------------------------------------------------------------- | --------------- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| E-01 | Màn Giáo viên và phân công tải mọi trang của 5 danh mục (156 request, khung chờ hơn 10 giây trên DB thử) | Web             | Sửa một phần | Chỉ tải lớp, phân công, học kỳ của năm đang xem; CORS `maxAge: 600` giảm preflight. Chưa phân trang lười (lazy)                                       |
| E-02 | Màn nhập điểm trên điện thoại hiện sau 15-20 giây, có lúc đứng hình khi dựng 41 thẻ học sinh             | Web, điện thoại | Chưa sửa     | API chỉ mất 40-60 ms cho một trang 20 KB; chậm nằm ở dựng giao diện trong khung trình duyệt tích hợp. Cần đo trên máy thật, cân nhắc ảo hóa danh sách |
| E-03 | Mỗi request catalog kèm một OPTIONS (preflight) do thiếu `Access-Control-Max-Age`                        | Web             | Đã sửa       | `maxAge: 600` trong `app.ts` (cần khởi động lại API)                                                                                                  |
| E-04 | Thêm học sinh: hộp thoại mất khoảng 4 giây vì danh sách danh mục không có tham số kích thước trang       | Web             | Chưa sửa     | Cần đổi OpenAPI và sinh lại client                                                                                                                    |

Tồn tại thêm ở nhóm danh mục: thêm hoặc sửa vẫn làm mới ngầm bằng cách tải lại đủ các trang ở nền vì API chưa có endpoint lấy một bản ghi.

### F. Widget Android (lịch học, lịch dạy)

| #    | Vấn đề                                                                                                          | Trạng thái      | Ghi chú                                                                                                                                                                          |
| ---- | --------------------------------------------------------------------------------------------------------------- | --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| F-01 | Tiết đã qua nằm đầu danh sách và chỉ bị làm mờ, tiết sắp tới bị đẩy xuống phải cuộn                             | Đã sửa          | Chỉ liệt kê tiết chưa kết thúc, tiết đang học được tô nền "Đang học", làm mới đúng lúc bắt đầu và hết tiết                                                                       |
| F-02 | Dữ liệu widget chỉ làm mới khi mở app; học kỳ kết thúc hoặc chưa bắt đầu để trống                               | Sửa một phần    | Làm mới khi mở màn Thời khóa biểu và khi quay lại app (cách nhau 5 phút); widget báo "Học kỳ đã kết thúc / bắt đầu ngày ..."                                                     |
| F-03 | Chưa cập nhật nền hoàn toàn khi không mở app                                                                    | Chưa sửa        | Token ghi nhớ hiện có dùng một lần và xoay vòng, tiến trình nền có thể làm app bị đăng xuất. Cần credential chỉ đọc thời khóa biểu, thu hồi được (endpoint, bảng, migration mới) |
| F-04 | Chưa biên dịch và chạy thử Kotlin, layout, manifest của widget; chưa làm widget iOS (cần WidgetKit trong Xcode) | Chưa kiểm chứng | Xem mục G-01                                                                                                                                                                     |

### G. Môi trường, hạ tầng, giới hạn kiểm tra

| #    | Vấn đề                                                                                                                                                            | Trạng thái      | Ghi chú                                                                                                                        |
| ---- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| G-01 | `flutter build apk` và `gradlew help` lỗi `java.io.IOException: Unable to establish loopback connection` trên máy này (cả ngoài sandbox)                          | Chưa sửa        | Lỗi Java hoặc Windows (tường lửa, antivirus hoặc Winsock). Chặn build APK release mới, chạy thử widget và kiểm tra app Android |
| G-02 | Chưa kiểm tra app Android và iOS thật, chưa xem chế độ tối trên điện thoại                                                                                        | Chưa kiểm chứng | Chỉ kiểm tra bằng web ở 375px                                                                                                  |
| G-03 | Dịch vụ nhận dạng đang tắt trong môi trường thử; chưa kiểm tra tải ảnh và nhận dạng, tạo mẫu bảng điểm, xuất hoặc nhập Excel                                      | Chưa kiểm chứng | Theo phạm vi bạn đặt ra                                                                                                        |
| G-04 | Một lần chạy toàn bộ Flutter có 1 test hỏng không rõ tên, hai lần chạy lại đều đạt                                                                                | Chưa sửa        | Nghi test chập chờn có từ trước                                                                                                |
| G-05 | Test tích hợp `recognition-infrastructure` và `database/tests/recognition-batches` lỗi khi chạy trên stack đang chạy                                              | Chưa sửa        | Do worker đang chạy khóa job và còn phiếu chờ trong DB thử, không phải lỗi sản phẩm; tắt worker hoặc dùng DB riêng khi chạy    |
| G-06 | Bản đóng gói nộp bài `.local/nop-bai`: `1_MaNguon` là mã cũ, thiếu APK release mới                                                                                | Chưa sửa        | Cần tạo lại sau khi commit và build lại APK                                                                                    |
| G-07 | Chưa xem lại bằng mắt các điểm vừa sửa: màn phân công, thanh công cụ thời khóa biểu web, nút "Thêm mới" dạng biểu tượng, tab "Báo cáo", thẻ lớp, đồng bộ nội dung | Chưa kiểm chứng | Đã có test và `flutter analyze` đạt, chưa kiểm tra trên giao diện thật                                                         |

## 3. Việc không phải lỗi nhưng cần biết

- **Xóa toàn bộ comment trong mã** (commit `47b95be`): giữ `database/migrations/` (Prisma kiểm checksum), mã sinh tự động, `automation/`, chỉ thị công cụ (`// ignore:`, `@ts-expect-error`, `# type:`). Docstring Python và 517 dòng comment `--` trong migration vẫn còn.
- **Nhãn chính sách `TT22-2024`** là mã quy chế gắn vào kết quả tổng kết, không phải năm học nên được giữ nguyên.
- **Hệ số "(hệ số 1.00)"** vẫn hiện cho học sinh vì học sinh vốn biết hệ số.
- **API học sinh:** đã rút gọn các trường nội bộ; `finalScore` vẫn trả khi học kỳ chưa công bố (chỉ xếp loại bị che).

## 4. Ghi chú chi tiết theo ngày

Chi tiết kỹ thuật, tên file và lệnh kiểm tra của từng đợt nằm trong `docs/development/CONTINUE.md` (các mục mới nhất ở đầu file).
