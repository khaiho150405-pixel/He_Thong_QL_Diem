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
- (Đã sửa ở Bước 4b, xem bên dưới) Bản đầu của bước 4 đã bỏ ĐTB chung và xếp loại chung tính ở client; việc đó đổi hành vi nên đã được khôi phục.
- Xếp loại ánh xạ theo MÃ: `GIOI` ok, `KHA` info, `DAT`/`TRUNG_BINH` neutral, `CHUA_DAT`/`KHONG_DAT` bad ("Chưa đạt"), `YEU` bad ("Yếu"), `KEM` bad ("Kém"); mã khác neutral với đúng chuỗi mã. DTO học sinh không có cờ `passing`, nên mã tùy cấu hình ngoài danh sách này luôn hiện neutral dù chính sách có thể coi là "chưa đạt".
- Khung thẻ theo môn vẫn hiện "điểm · mã" (ví dụ "6.5 · KHA") vì test ghim chuỗi này; bảng tổng hợp hiện nhãn tiếng Việt ("Khá"). Chuyển 'Thẻ theo môn' / 'Bảng tổng hợp' đổi từ SegmentedButton sang `AppTabs` (chuỗi giữ nguyên).
- Chính sách xếp loại: giữ form `criteria` tùy cấu hình (không thay bằng 3 ô ngưỡng cố định). Thêm badge "Phiên bản X · đang áp dụng" từ `version`/`active`. Không làm "Xem trước kết quả" (sẽ phải tính xếp loại trong widget) và lịch sử phiên bản (backend chỉ có `active`/`activate`). Form giới hạn rộng tối đa 880 px và canh giữa.
- Kết nối: chỉ đổi sang token; thẻ bỏ `elevation`, dùng viền `line` và `t.shadow`.


### Bước 4b - khôi phục ĐTB chung và xếp loại chung ở client

- Hàng "ĐIỂM TRUNG BÌNH CHUNG" của bảng tổng hợp lại tính ở client y như màn cũ: `allLocked` khi mọi môn có `classification`; ĐTB là trung bình cộng `finalScore` các môn không phải Đạt/Không đạt; xếp loại chung theo ngưỡng >= 8.0 Giỏi, >= 6.5 Khá, còn lại Đạt; chưa đủ điều kiện thì hiện "Chờ công bố" ở cả hai ô. Nằm trong hai hàm thuần `semesterOverviewOf` và `overallClassificationCodeOf` (`student_results_screen.dart`).
- AGENTS.md cấm đặt quy tắc tính điểm/xếp loại ở widget, nhưng bản cũ đã có sẵn việc này. Đã GIỮ NGUYÊN hành vi theo quy tắc "không đổi công thức". Đề xuất ở lần sau: backend trả ĐTB chung và xếp loại chung trong `summary`, client chỉ hiển thị.
- Hero vẫn dùng `summary.averageScore` do backend tính (dữ liệu API), còn hàng tổng kết dùng trung bình cộng ở client. Hai số có thể khác nhau (backend có thể tính theo hệ số/làm tròn khác). Bản cũ cũng có hai nguồn: ô "ĐTB HỌC KỲ" của banner và hàng tổng kết đều tính ở client, còn thanh bên dùng số của backend. Cần quyết định sau nguồn nào là chuẩn.
- Chip trạng thái ở hero ("Đã công bố ĐTB" / "Đang cập nhật (x/y)") dùng `publishedSubjects`/`totalSubjects` của `summary`; bản cũ đếm số môn có `classification` ở client. Giữ hero theo dữ liệu API như yêu cầu.


### Bước 5 - khung điều hướng

- Đã bỏ badge cứng `'08'` ở mục "Bảng điểm" và chuỗi cứng "Học kỳ I · 2024–2025" (cùng khối "HỌC KỲ HIỆN TẠI / HẠN NỘP ĐIỂM / TIẾN ĐỘ HỌC KỲ" ở đáy sidebar, vì khối chỉ chứa chuỗi cứng; không có dữ liệu học kỳ hiện hành để thay). Trường `countBadge` của mục sidebar vẫn còn, hiện đang `null` ở mọi mục; muốn có badge đếm (ví dụ số phiếu chờ đối chiếu) cần backend/provider có số thật.
- Không thêm vào topbar: ô tìm kiếm toàn cục, chip học kỳ, chuông thông báo (backend chưa hỗ trợ, mục 2 của kế hoạch).
- Sidebar: khối thẻ hồ sơ ở đầu sidebar (bản cũ) chuyển xuống cuối theo prototype (`.s-user`): avatar chữ cái đầu `username`, tên (`username`; DTO phiên không có họ tên), vai trò. Giáo viên giữ dòng "Giáo viên bộ môn"; quản trị hiện "Quản trị viên" (trước không có); học sinh giữ "Lớp X · học kỳ" từ `studentResultsList` và dải ĐTB / Xếp hạng / Sĩ số (dữ liệu thật, trước gọi API hai lần mỗi lần build, nay gọi một lần).
- Nút "Đăng xuất" trên màn rộng chuyển từ topbar xuống chân sidebar (giữ tooltip 'Đăng xuất' và hộp thoại xác nhận khi vào từ `AppScaffold`; trang chủ vẫn đăng xuất ngay như trước). Trên màn hẹp, AppBar vẫn có nút đăng xuất như cũ; Drawer có thêm nút ở chân.
- Topbar màn rộng đổi từ `AppBar` sang `AppTopBar` (không phải `PreferredSizeWidget`, cao tối thiểu 68, tự giãn khi tiêu đề nhiều dòng). Dòng nhỏ vai trò viết hoa ("GIÁO VIÊN"). Tiêu đề trang chủ web đổi từ "EduScore · THPT Bà Điểm" thành "Tổng quan" (theo prototype; thương hiệu nằm ở đầu sidebar). AppBar mobile của trang chủ vẫn giữ "EduScore · THPT Bà Điểm".
- Nav đáy: tab đang chọn dùng `priLink` (bằng `pri` ở chế độ sáng, sáng hơn ở chế độ tối để đủ tương phản), bỏ nền "viên thuốc" của Material 3, nhãn 12px. Mục giữa nổi (`.tabbar .mid`) của prototype không làm.
- Mục con trong nhóm gập cao 40 (mục cấp một cao 44) để phân biệt cấp; prototype không có nhóm gập.


### Bước 6 - dashboard

- Không làm (backend chưa hỗ trợ hoặc cần nguồn dữ liệu mới, mục 2 của kế hoạch): đường điểm TB toàn trường theo tháng; ô "Điểm TB toàn trường"; nút "Xuất báo cáo"; alert "bảng điểm sắp quá hạn nhập"; khối "Việc cần làm" và "Lịch dạy hôm nay" của giáo viên; chuông thông báo. `AppLineChart` đã có từ bước 2 nhưng chưa gắn vào dashboard vì chưa có dữ liệu thật.
- KPI giữ đúng nguồn cũ: QTV 4 ô (Bảng điểm, Tỷ lệ hoàn thành, Đối chiếu OCR, Học sinh) từ `adminOverviewProvider`; GV 3 ô (Phụ trách, Tiến độ nhập, OCR chờ duyệt) từ `teacherOverviewProvider`; HS 3 ô (ĐTB học kỳ, Môn đã chốt, Xếp hạng lớp) từ `studentResultsList`. Prototype của GV có 4 ô (Bảng điểm phụ trách, Đã chốt, Chờ đối chiếu, Tiến độ) và của QTV là Học sinh/Giáo viên/Bảng điểm đã chốt/Điểm TB; không đổi bộ ô theo prototype vì sẽ phải đổi nguồn dữ liệu.
- Dưới 720 px, QTV vẫn dùng nhãn rút gọn như bản cũ ("Tỷ lệ", "OCR", "Đã chốt sổ", "Chờ GV duyệt"); từ 720 px trở lên dùng nhãn đầy đủ. Bố cục dưới 720 px đổi từ dải cuộn ngang sang lưới 2 cột (`StatCardGrid`); ô lẻ cuối (GV, HS có 3 ô) chiếm nửa hàng.
- Vẫn còn chuỗi cứng "HỌC KỲ I, 2024–2025 · THPT BÀ ĐIỂM · ..." ở dòng nhỏ đầu trang chủ (bước 5 đã bỏ chuỗi này ở sidebar vì không có dữ liệu học kỳ hiện hành). Giữ nguyên ở bước này theo quy tắc "giữ chuỗi"; nên thay bằng tên học kỳ thật khi có nguồn.
- Biểu đồ phân bố học lực: màu cột lấy từ token theo mã (`GIOI` = pri, `KHA` = xanh nhạt hơn pri ở chế độ sáng và `priLink` ở chế độ tối, `DAT` = neu, `CHUA_DAT`/`YEU` = bad); trường `color` (mã hex) backend trả về không còn được dùng để vẽ. Chuyển từ cột đứng sang `AppHBars` (cột ngang); mỗi dòng hiện "N HS · P%".
- Tiến độ theo khối: màu thanh vẫn phân 3 mức như bản cũ (>= 80% `ok`, >= 40% `pri`, còn lại `acc`), nhưng prototype dùng một màu `pri` cho cả ba.
- Độ chính xác OCR: bỏ thanh xếp chồng vẽ tay; thay bằng ba dòng (AppBadge Xanh/Vàng/Đỏ + mô tả + phần trăm + `AppProgress`). Bản cũ khi chưa có ô nào (`totalCells == 0`) vẫn vẽ thanh với tỷ lệ cố định 75/18/7, đó là số giả; bản mới để thanh rỗng và hiện số đếm. Thêm tông `bad` vào `AppProgressTone` (chỉ thêm giá trị enum, không đổi tông cũ).
- Hoạt động gần đây: trạng thái "Đã chốt" dùng AppBadge ok, "Đang nhập" dùng AppBadge info (bản cũ dùng vàng) cho khớp prototype; chuỗi lấy nguyên từ API.
- Chuỗi bỏ đi trong bước này: không có. Thẻ biểu đồ không còn nhãn nhỏ "X HS" dưới mỗi cột và nhãn "%" trên cột (gộp vào giá trị bên phải của mỗi dòng).
