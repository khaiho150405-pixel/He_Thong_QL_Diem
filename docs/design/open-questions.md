# Điểm chưa rõ và hạng mục backend chưa hỗ trợ

Quy ước: mỗi mục ghi bước phát sinh, điều gì chưa rõ, và phương án đã chọn (mặc định là giữ nguyên hành vi hiện tại).

## Backend chưa hỗ trợ (không làm giả trong giao diện)

Danh sách đầy đủ ở `docs/design/ui-migration-plan.md` mục 2. Tóm tắt: thông báo; chốt bảng điểm thủ công (backend luôn 403, ADR-0014); điểm TB toàn trường và đường điểm theo tháng; xuất báo cáo toàn trường; cảnh báo bảng điểm sắp quá hạn; tiến độ/sĩ số/hạn trên danh sách bảng điểm; giới tính học sinh; "đăng nhập gần nhất"; phân quyền chi tiết; xem trước xếp loại và lịch sử phiên bản chính sách; tên giáo viên và GVCN trong "Điểm của tôi"; tải bảng điểm cho học sinh; điểm TB nhóm TX/GK/CK trong tổng kết; giờ bắt đầu từng tiết; tìm kiếm toàn cục; OCR nhiều trang trong một phiếu.

## Quyết định đã áp dụng

- Bước điểm 0,25 của prototype: bỏ qua, giữ validate hiện có (bước 0,1 theo AGENTS.md).
- Không có nút đổi sáng/tối và không lưu lựa chọn: giao diện theo hệ điều hành (`ThemeMode.system`).
- Chữ viết tay (Caveat) không đóng gói: dùng Be Vietnam Pro nghiêng.

## Phát sinh trong lúc làm

(Các bước ghi thêm bên dưới.)

### Bước 2 - widget dùng chung

- Chấm "nhập từ ảnh" của `AppGradeCell`: prototype (`.gc.src`) vẽ chấm màu `pri`, yêu cầu bước này ghi chấm màu `ok`. Đã làm theo yêu cầu (`ok`); nếu muốn đúng prototype thì đổi một dòng trong `grade_cell.dart`.
- Màu "warn" của `AppProgress` và vạch giữa của `AppConfidenceBar`: prototype dùng `#D99A00`, không có token tương ứng. Đã dùng `tokens.acc` (amber `#F2A900`) để không có màu cứng; hơi sáng hơn prototype.
- Avatar lấy chữ cái đầu của từ đầu và từ cuối của họ tên ("Nguyễn Thị Lan" thành "NL"), đúng hàm `initials` của prototype. Chữ avatar không co theo cỡ chữ hệ thống để vừa khung tròn cố định.
- `AppLineChart`: chữ trục và tooltip không co theo cỡ chữ hệ thống (giống SVG của prototype); tooltip hiện khi rê chuột hoặc chạm/kéo, thả tay thì ẩn. Màu từng cột của `AppHBars` do màn gọi truyền vào (prototype dùng mã hex cứng cho Giỏi/Khá/Đạt); khi gắn vào màn cần chọn token tương ứng.
- `AppPager` hiện nút Trước/Sau (mũi tên) và rút gọn bằng "…" khi quá 7 nút; prototype chỉ có nút số. Thêm vì danh sách thực có thể nhiều trang.
- `AppDialog`: nút Hủy/X mặc định đóng với kết quả `false`, nút chính đóng với `true` khi không truyền callback; nút chính vẫn là `FilledButton` cao 48 theo theme (prototype cao 40).
- `AppGradeCell` không tự validate: màn gắn vào phải truyền `isInvalid` từ quy tắc validate hiện có và `isChanged` từ trạng thái sửa chưa lưu.


### Bước 3 - đăng nhập

- Chữ "EduScore" chỉ xuất hiện đúng một lần (test ghim `findsOneWidget`): màn rộng đặt ở đầu nửa trái navy, màn hẹp đặt ở đầu form. Prototype dùng tên trường làm tiêu đề; ở đây dòng phụ là "Trường THPT Bà Điểm · Quản lý điểm".
- "Xem thử với vai trò": prototype dùng 3 chip chọn vai trò; giữ popup "Gợi ý tài khoản demo" hiện có (nhãn tooltip và 3 mục giữ nguyên) và vẽ lại như một chip bo tròn. Tài khoản demo vẫn là tài khoản đã có sẵn trong mã.
- Chuỗi đổi so với bản cũ: tiêu đề "Đăng nhập tài khoản" thành "Đăng nhập" kèm "Dùng tài khoản do nhà trường cấp." (theo prototype, chỉ ở màn rộng); dòng trợ giúp thành "Quên mật khẩu? Liên hệ quản trị viên của trường." (chỉ là chữ); bỏ dòng chân trang "THPT Bà Điểm · ... EduScore · Đa nền tảng". Không test nào ghim các chuỗi này.
- Giữ nút "Kiểm tra kết nối hệ thống" (prototype không có) vì là chức năng hiện có.
- Tờ giấy trang trí dùng tên và điểm mẫu cố định của prototype (chỉ minh họa, ẩn khỏi trợ năng); chữ viết tay là Be Vietnam Pro nghiêng, nên nét chữ khác Caveat của prototype.
- Mobile: prototype dùng 2 chip vai trò (Giáo viên, Học sinh); bản này dùng chung popup 3 vai trò với web.

### Bước 4 - kết quả HS, chính sách xếp loại, kết nối

- "Điểm của tôi": bỏ (backend không có dữ liệu) tên giáo viên từng môn, GVCN, mã học sinh (test vẫn cấm "Mã học sinh"), nút "Tải bảng điểm", đường điểm qua các kỳ, khối "Môn mạnh nhất" và hộp chọn học kỳ (API nhận một `termId` mỗi lần). Hero chỉ có dữ liệu thật: lớp (`summary.className`), ĐTB (`summary.averageScore`), xếp hạng/sĩ số (`classRank`/`classSize`), môn đã có điểm (`publishedSubjects`/`totalSubjects`).
- Họ tên học sinh không có trong `StudentResultsDto` hay `SessionDto` (chỉ có `username`, có thể là số điện thoại). Avatar hiển thị "HS" (chữ cái của "Học sinh") và tiêu đề "Bảng điểm cá nhân", giữ như bản cũ thay vì hiện username.
- Màn cũ tự tính ĐTB chung ở client (trung bình các `finalScore`) và tự xếp loại chung theo ngưỡng 8.0/6.5, vi phạm AGENTS.md. Đã bỏ cả hai: ĐTB lấy từ `summary.averageScore` do backend tính; ô "Xếp loại" của hàng ĐTB chung hiện "—" vì `summary` chưa có xếp loại chung. Nếu cần hiển thị, backend phải trả thêm trường này.
- Xếp loại ánh xạ theo MÃ: `GIOI` ok, `KHA` info, `DAT`/`TRUNG_BINH` neutral, `CHUA_DAT`/`KHONG_DAT` bad ("Chưa đạt"), `YEU` bad ("Yếu"), `KEM` bad ("Kém"); mã khác neutral với đúng chuỗi mã. DTO học sinh không có cờ `passing`, nên mã tùy cấu hình ngoài danh sách này luôn hiện neutral dù chính sách có thể coi là "chưa đạt".
- Khung thẻ theo môn vẫn hiện "điểm · mã" (ví dụ "6.5 · KHA") vì test ghim chuỗi này; bảng tổng hợp hiện nhãn tiếng Việt ("Khá"). Chuyển 'Thẻ theo môn' / 'Bảng tổng hợp' đổi từ SegmentedButton sang `AppTabs` (chuỗi giữ nguyên).
- Chính sách xếp loại: giữ form `criteria` tùy cấu hình (không thay bằng 3 ô ngưỡng cố định). Thêm badge "Phiên bản X · đang áp dụng" từ `version`/`active`. Không làm "Xem trước kết quả" (sẽ phải tính xếp loại trong widget) và lịch sử phiên bản (backend chỉ có `active`/`activate`). Form giới hạn rộng tối đa 880 px và canh giữa.
- Kết nối: chỉ đổi sang token; thẻ bỏ `elevation`, dùng viền `line` và `t.shadow`.
