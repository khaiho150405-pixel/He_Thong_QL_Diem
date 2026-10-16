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


### Bước 7 - tổng kết và báo cáo

- Không làm cột TB nhóm TX/GK/CK, cột Giữa kỳ/Cuối kỳ và dòng công thức "(tổng TX + 2 × GK + 3 × CK) / tổng hệ số" của prototype (backend không có, hạng mục 14 mục 2 của kế hoạch). Bảng chỉ có STT, Học sinh, Điểm tổng kết, Xếp loại, Chi tiết.
- Bảng tổng kết: dưới tên học sinh thêm hai dòng nhỏ lấy từ `FinalResultDto` (`weightVersion`, `policyVersion`, `calculatedAt`); trước đây các trường này chỉ có trong DTO, không hiện ở bảng. Cột "Xếp loại" đổi từ `Chip` hiện mã thô ("YEU") sang `AppBadge` hiện nhãn tiếng Việt ("Yếu") theo `classificationBadgeOf` (ánh xạ theo MÃ, không so ngưỡng). Mã ngoài danh sách (mã tùy cấu hình chính sách) hiện nguyên mã, tông trung tính, nên mã "chưa đạt" tùy cấu hình không được tô đỏ. Cần cờ `passing` trong `FinalResultDto` để tô đúng.
- Lịch sử tổng kết: chuỗi tiêu đề và nội dung giữ nguyên; thời điểm tính hiện `dd/MM/yyyy HH:mm` (trước là chuỗi `DateTime.toLocal()` thô). Nút "Đóng" đặt cuối nội dung (hộp thoại không có footer).
- Panel "Kết quả tổng kết và xếp loại": bỏ `ExpansionTile` (luôn mở trong hộp thoại), bỏ `Card` bên trong `Dialog` (tránh viền đôi); thêm nút X "Đóng" ở header khi panel nằm trong hộp thoại (`PopupRoute`). Vùng bảng cao 320 và cuộn dọc + ngang (bản cũ chỉ cuộn ngang nên danh sách dài bị cắt). Trên 390 px nút "Lịch sử tính" nằm ngoài khung nhìn, phải cuộn ngang.
- Hộp thoại "Tính kết quả tổng kết" đổi từ `AlertDialog` sang `AppDialog`: giữ nguyên chuỗi, luồng và `ValueKey`; nút Hủy là `OutlinedButton` (trước là `TextButton`), thêm nút X; bỏ `SizedBox(width: 500)` cố định để vừa màn hẹp.
- Báo cáo: sáu số liệu sang `StatCard` (3 cột từ 720 px, 2 cột dưới đó). "Đạt yêu cầu"/"Chưa đạt" vẫn luôn hiện như bản cũ: client không có cờ nào để biết khi nào backend ẩn số liệu này. Phân bố xếp loại đổi từ các chip "MÃ: N HS" sang `AppHBars` với nhãn tiếng Việt theo mã và giá trị "N HS" (màu cột theo mã, cùng quy ước dashboard); tiêu đề "Phân bố xếp loại:" giữ nguyên.
- Chưa làm trang "Tổng kết" riêng (route mới, mục 4.1 của kế hoạch): thuộc bước sau.


### Bước 8 - thời khóa biểu

- Giữ nguyên dải tiết 1-10 và Thứ Hai đến Chủ nhật (prototype chỉ có tiết 1-6 và Thứ 2-7); chỉ đổi cách trình bày. Hàng phân cách "BUỔI SÁNG" / "BUỔI CHIỀU" thêm trước tiết 1 và tiết 6.
- Giờ bắt đầu từng tiết: backend không có; KHÔNG thêm giờ vào lưới tuần (prototype có "bắt đầu 07:00"). Lưu ý: khung giờ cố định ở client đã có sẵn từ trước (`TimetableItem.timeSlotLabel` trong chế độ "Theo ngày" và `_timeOf` trong hộp thoại xếp tiết) vẫn được giữ nguyên; đó là hằng số trong mã, không phải dữ liệu từ backend, cần xác nhận nguồn thật.
- Màu theo môn (Toán xanh dương, Văn hồng, ...) bị bỏ vì là màu cứng; chip tiết dùng một tông: giáo viên/quản trị nền `priSoft`, học sinh nền `hover` (như `.tc` và `.tc.sub`). Các môn khác nhau chỉ phân biệt bằng tên.
- Tiêu đề cột đổi sang chữ hoa 12 ("THỨ HAI", "TIẾT"); nhãn cột "Sáng/Chiều" dưới số tiết trong lưới được thay bằng hàng phân cách buổi (chế độ "Theo ngày" vẫn hiện Sáng/Chiều).
- Nút chuyển "Lưới tuần" / "Theo ngày" đổi từ `SegmentedButton` sang `AppTabs` (chuỗi giữ nguyên, mất icon nhỏ). Thanh lọc trên màn rộng xuống dòng (`Wrap`) thay vì cuộn ngang; trên màn hẹp vẫn cuộn ngang.
- Hàng dữ liệu của lưới giờ co theo nội dung (trước cố định tối đa 104/120 px), nên bảng gọn hơn.
- Hộp thoại xóa tiết và hộp thoại xếp/chuyển tiết đổi sang `AppDialog` (giữ chuỗi, `DropdownButtonFormField<num>/<int>`, luồng). Khác: không còn icon đầu hộp thoại; khi đang lưu nút chính hiện chữ "Đang lưu…" thay vì vòng xoay, nút Hủy/X không đóng hộp thoại; nút Hủy là `OutlinedButton`.
- Không làm: chuông thông báo, chú giải theo môn, xuất lịch (backend chưa hỗ trợ). `TimetableFilter` (sheet có tìm kiếm) vẫn chưa được màn hình dùng, chỉ đổi token.


### Bước 9 - danh mục quản trị

- Dạng bảng chỉ cho `students`, `teachers`, `accounts` và chỉ khi vùng nội dung >= 768 px (đúng điều kiện cũ của lưới 2 cột; có thanh bên thì cửa sổ cần khoảng >= 1070 px). Dưới đó và với các tài nguyên khác (`years`, `semesters`, `classes`, `subjects`, `components`, `semester-weights`, `assignments`) vẫn là thẻ, chỉ đổi token và `AppBadge`.
- Cột chỉ lấy từ dữ liệu có thật. Học sinh: STT (như logic cũ: chỉ khi `_showsStudentStt` hoặc học sinh xem hồ sơ mình), Học sinh (AppAvatar + họ tên), Lớp, Ngày sinh (nguyên chuỗi API, `YYYY-MM-DD`), Tình trạng, Tài khoản. Cột Tài khoản chỉ là "Đã liên kết" / "Chưa liên kết" suy ra từ `ma_nguoi_dung` có hay không; client không tải danh sách tài khoản nên KHÔNG biết tài khoản đó đang hoạt động hay đã khóa (prototype hiện "Đang hoạt động" / "Chưa kích hoạt"). Giáo viên: Giáo viên, Tổ chuyên môn, Email, Điện thoại (thiếu thì hiện "—"). Tài khoản: Tài khoản, Vai trò, Trạng thái.
- Không làm (backend chưa có hoặc cần nguồn dữ liệu mới): cột Giới tính (học sinh không có trường này), cột "Họ và tên" và "Đăng nhập gần nhất" của bảng tài khoản (`AccountDto` chỉ có id, username, role, active), cột "Mã HS" (`ma_hoc_sinh` là khóa nội bộ, không phải mã học sinh của trường), và tab theo vai trò của "Tài khoản & phân quyền". Danh sách chỉ nạp theo trang (cursor) nên tab đếm theo vai trò sẽ đếm sai; bộ lọc "Vai trò" hiện có giữ nguyên, lọc đúng như cũ.
- "Giáo viên & phân công" của prototype gộp một bảng (môn, chip lớp phân công, số lớp, chủ nhiệm) cần ghép `teachers` + `assignments` + `classes` ở client. Bước này chỉ làm bảng giáo viên với dữ liệu có trong `TeachersDto`; việc gộp (mục 1 dòng 11 của kế hoạch, route mới) để bước sau.
- Phân trang: giữ nguyên nút 'Trang trước' / 'Trang sau' và chuỗi 'Trang N / M (K mục)' (client 50 mục) hoặc 'Trang N (K mục)' (cursor); không dùng `AppPager` vì cursor không biết tổng số trang và `AppPager` đổi chuỗi/nút số. Với bảng, thanh phân trang nằm ở chân thẻ bảng.
- Hộp thoại sửa/tạo (`EditDialog`), nhập file (`CatalogImportDialog`), xác nhận xóa và "Tạo tài khoản giáo viên" đều chuyển sang `AppDialog`; giữ nguyên chuỗi, luồng và `ValueKey`. Khác so với `AlertDialog`: không còn icon đầu tiêu đề; có nút X; nút Đóng/Hủy là `OutlinedButton` ở chân; nút 'Tải lại' chuyển vào khung báo lỗi; dòng tên bản ghi (`rowLabel`) chuyển từ phụ đề tiêu đề xuống đầu nội dung; khi chỉ xem (không phải quản trị) không có chân, nút 'Đóng' nằm cuối nội dung; hộp nhập file mất icon trên nút "Nhập N dòng". Ô vai trò trong form tài khoản trước hiện huy hiệu và nhãn lặp hai lần, nay chỉ một `AppBadge`.
- Các màu cứng (18 chỗ `Color(0x..)`, `Colors.green/red/grey`) trong `catalog_screen.dart` đã về token. Huy hiệu vai trò dùng `AppBadge` theo quy ước prototype (quản trị = đỏ, giáo viên = xanh, học sinh = trung tính), thay `RoleBadge` ở màn này. Huy hiệu "Đang khóa nhập" của thành phần điểm dùng tông cảnh báo (trước là đỏ nhạt) và mất icon khóa nhỏ.
- Hộp STT 44x44 ở thẻ học sinh tràn 1 px khi dùng font Be Vietnam Pro; đổi thành 48x48 và `height: 1.2` cho chữ.
- Chuỗi chip STT dạng "STT toàn trường: #N" / "STT lớp: #N" vẫn dùng ở thẻ; ở bảng thay bằng cột 'STT' với '#N TRƯỜNG' / '#N LỚP'. Trong bảng, STT lớp của học sinh xem hồ sơ mình không lặp khi đã là phạm vi lớp.
- Chưa đổi (ngoài phạm vi bước, dùng chung): `EmptyState`, `ShimmerLoading` và `AppControlMetrics.decoration`/`AppFilterDropdown` vẫn lấy màu từ `colorScheme` (vẫn đúng chế độ tối vì theme sinh từ token).


### Bước 10 - bảng điểm và lưới nhập điểm

- **Kiểm tra vị trí công thức (đọc, không sửa)**:
  - Điểm TB môn (TX x1, Giữa kỳ x2, Cuối kỳ x3 theo `he_so_ap_dung`) và xếp loại theo ngưỡng chính sách nằm ở backend, trong hàm SQL `public.tinh_ket_qua_bang_diem` (`database/migrations/202609130001_final_results` và bản mới nhất ở `202610030001_semester_weights`): `sum(gia_tri * he_so) / sum(he_so)`, làm tròn theo `so_chu_so_lam_tron`, xếp loại là hàng `tieu_chi_xep_loai` có `diem_toi_thieu` lớn nhất mà điểm vẫn đạt. Chính sách mặc định DEV: Giỏi 8.0, Khá 6.5, Trung bình 5.0, Yếu 0.0 (4 mức, không có nhãn "Chưa đạt"; cấu hình được).
  - `gradebook_screen.dart` KHÔNG tính ĐTB môn. Chỉ hiển thị `coefficient`, `finalScore`, `classification` do backend trả về. Không viết công thức mới ở client.
  - Test backend liên quan: `apps/api/test/integration/final-results.test.ts` (cần PostgreSQL, không chạy ở bước này) kiểm ĐTB `8.7` (TX 8.0 hệ số 1, GK 9.0 hệ số 2) và `4.0` (0.0 và 6.0), lưu snapshot hệ số/chính sách và lịch sử; `apps/api/test/integration/semester-weights.test.ts` kiểm hệ số theo học kỳ; `apps/api/test/final-results.test.ts` kiểm đầu vào tính và chính sách phải liền mạch, có cờ đạt/không đạt; `apps/api/test/component-rules.test.ts` kiểm quy tắc sửa thành phần; `apps/api/test/gradebook-policy.test.ts` kiểm quyền. `apps/api/test/grade-level.test.ts` là phân loại Xanh/Vàng/Đỏ của OCR, KHÔNG phải xếp loại học lực.
  - Khoảng trống phát hiện được (chưa sửa, ngoài phạm vi UI): (1) test tích hợp chỉ dùng TX và một cột hệ số 2 (đặt `loai_he_so='GK'`), chưa có test cột Cuối kỳ hệ số 3; (2) không tìm thấy quy tắc "tối đa 4 cột TX" trong migration, `apps/api/src/modules` hay test; (3) không có test biên xếp loại 7.99/8.0, 6.49/6.5, 4.99/5.0 ở backend (xếp loại hiện là `CHUA_CONG_BO` đến khi công bố). Đề nghị thêm các test này ở backend.
- **Client có công thức duy nhất** là hàng "ĐIỂM TRUNG BÌNH CHUNG" ở `student_results_screen.dart` (đã ghi ở bước 4b). Bước này chỉ bổ sung test cho đúng hành vi hiện tại (`test/results_policy_dark_test.dart`): biên 10.0, 8.0, 7.99, 6.5, 6.49, 5.0, 4.99, 0.0 và `semesterOverviewOf` (chỉ tính khi mọi môn có xếp loại, trung bình cộng, bỏ môn Đạt/Không đạt). **Mã hiện tại không có nhánh "Chưa đạt"** cho ĐTB chung: mọi ĐTB dưới 6.5, kể cả dưới 5.0, đều ra `DAT` ("Đạt"), khác mô tả Giỏi >= 8.0, Khá >= 6.5, Đạt >= 5.0, còn lại Chưa đạt. Không sửa mã; cần chủ dự án quyết hoặc chuyển phép tính này sang backend.
- **Danh sách bảng điểm** (`gradebooks_screen.dart`): chỉ làm cột có trong `GradebookDto`: Lớp, Môn học, Học kỳ, Phiên bản, Trạng thái, nút mở. Không có cột Sĩ số, Tiến độ, Hạn nhập, Cập nhật của prototype (DTO không có). Bảng từ 768 px (đúng ngưỡng cũ của lưới 2 cột), dưới đó là thẻ một cột. Danh sách KHÔNG hiện hạn khóa (DTO không có; tránh gọi API từng bảng).
- Chuỗi bỏ/đổi ở danh sách: "Đã chốt sổ" (bộ lọc và thẻ) thành "Đã khóa" (giá trị lọc `DA_CHOT` giữ nguyên); bỏ dòng "Sĩ số học sinh" (chỉ là nhãn, không có số) và nhãn "Hoàn tất"/"Đang xử lý" (suy ra từ trạng thái, trùng với huy hiệu). Giữ "v<N>" (phiên bản) nhưng chuyển thành cột "Phiên bản" ở bảng. Nút ở mỗi dòng là "Nhập điểm" (giáo viên, bảng chưa khóa) hoặc "Xem" (còn lại), cùng mở `/gradebooks/<id>` như bấm vào dòng. Thanh tìm kiếm vẫn là `SearchBar` cao mặc định 56 (không phải ô 48).
- **Chi tiết bảng điểm** (`gradebook_screen.dart`): huy hiệu trạng thái chuyển từ tiêu đề xuống một dải riêng dưới thanh tab, hiện trên cả ba tab (`AppBadge` "Đang nhập liệu" info / "Đã khóa" ok), kèm "Khóa lúc <giờ>" khi mọi cột đều có `closesAt` đọc được (hàm `latestColumnClosesAt`, hiển thị bằng `deadlineLabel`). Nếu thiếu lịch một cột, `closesAt` hỏng hoặc không có cột nào thì không hiện hạn. Bảng đã khóa vẫn hiện "Khóa lúc" (giờ này đã qua). Không thêm nút/modal chốt và không gọi `lock()`/`lockColumn()` (test mới quét `lib/`). Không có breadcrumb riêng: vẫn dùng nút quay lại và mục "Bảng điểm" sáng trên thanh bên.
- Chữ "Cột đã chốt" (helper dưới ô điểm khi `columnLocked`) và "Cột đang khóa"/"(Đang khóa)" giữ nguyên: mục 0.1 chỉ yêu cầu đổi nhãn trạng thái bảng. Có thể đổi "Cột đã chốt" thành "Cột đã khóa" nếu muốn thống nhất thuật ngữ.
- Thông báo chỉ-đọc khi bảng `DA_CHOT` (mới, theo `.alert.ok`): "Bảng điểm đã khóa. Chỉ xem, không sửa được. Điểm tự khóa khi đến hạn nhập do nhà trường đặt." Prototype nói "Cần mở lại thì liên hệ quản trị viên"; không dùng vì backend không có luồng mở lại.
- **Ô điểm**: KHÔNG dùng `AppGradeCell`. Ô điểm hiện tại là `TextFormField` với `ValueKey('grade-<cellId>')` và test đọc `TextFormField` (và `DropdownButtonFormField` cho `grade-pf-<cellId>`), nên kiểu `.gc` (nền accSoft khi đã sửa, nền badSoft/viền bad khi sai định dạng, chấm ngoài khi nhập từ ảnh dùng nhãn "● AI") được dựng ngay tại chỗ bằng token trong `_gradeDecoration`. "Không hợp lệ" lấy từ `validateGrade` hiện có, "đã sửa" so với giá trị đã lưu như `changedCells`; validate, lưu và xung đột không đổi. Ô vẫn rộng 170 (lưới rộng) và vẫn kèm `helperText` ("Chưa có điểm", "Chờ đối chiếu"...) nên cao hơn ô 64x36 của prototype; bước 0,25 bỏ qua như đã quyết.
- Không làm (backend/DTO chưa hỗ trợ hoặc phải tính ở client): cột "TB môn" và hàng "Trung bình lớp" (sẽ phải tính điểm ở client), cột "Mã HS" (`studentId` là khóa nội bộ), ô "Tìm học sinh theo tên hoặc mã", dòng "Sĩ số" và "Hạn nhập" ở tiêu đề (không có trong DTO), khối "Lịch sử cập nhật điểm" cuối trang (lịch sử vẫn mở từ menu ⋮ như cũ), phím tắt Enter/Tab/Esc kiểu bảng tính (hành vi mới, không thuộc lớp hiển thị). Cột "Xếp loại" khi bảng khóa đổi từ `Chip` sang `AppBadge`: chữ giữ nguyên bản cũ (`classificationLabel`: "Chưa công bố", "Đạt", "Không đạt", mã khác giữ nguyên mã), màu theo mã qua `classificationBadgeOf`.
- Hộp thoại đổi sang `AppDialog` (giữ chuỗi, luồng, `ValueKey`): "Lưu N ô điểm" (Lý do thay đổi, Hủy, Xác nhận lưu), "Lịch sử cập nhật điểm", "Mã tham chiếu bảng điểm", "Tạo bảng điểm", "Nhập điểm từ file Excel", "Lịch nhập · <cột>". Khác `AlertDialog`: có nút X, nút Hủy/Đóng là `OutlinedButton`, không còn icon đầu tiêu đề ở hộp nhập Excel; hộp lịch sử và mã tham chiếu không có chân, nút "Đóng" nằm cuối nội dung; nút "Áp dụng N điểm" của hộp Excel luôn hiện, tắt khi chưa có điểm hợp lệ (trước đó ẩn hẳn). Hộp "Tạo bảng điểm" truyền `onCancel` riêng vì kết quả đóng là `GradebookDto?`.
- Cột đã khóa trong "Lịch nhập điểm của nhà trường" đổi chữ trơn "Đã khóa" thành `AppBadge` ok (cùng chuỗi). Panel vẫn là `Card` + `ExpansionTile`.
- Hộp "Tổng kết" (`FinalResultsPanel`) vẫn bọc trong `Dialog` thường như bước 7 (không đổi ở bước này).
