# Kế hoạch di chuyển UI: Flutter client theo prototype

Nguồn thiết kế: `Hệ thống quản lý điểm.html` (`docs/design/Hệ thống quản lý điểm.html`; trước đây ở thư mục gốc dự án). Phạm vi: chỉ lớp hiển thị (widget, theme, layout). Không đổi provider, repository, model, API, route path, quyền, công thức điểm (theo `CLAUDE.md`).

Ghi chú về độ chắc chắn: các cột "API/provider" dựa trên `docs/api/openapi.json`, `apps/api/src` và code Flutter.

## 0. Quyết định đã chốt (cập nhật 2026-10-16)

Các quyết định của chủ dự án cho mục 6 bản trước, cộng quyết định bổ sung về nút chốt. Chi tiết tác động nằm ở các mục 1–4.

| # | Quyết định | Cách áp dụng |
|---|---|---|
| 1 | **Font**: đóng gói **Be Vietnam Pro** thành asset trong `assets/fonts/`, khai báo trong `pubspec.yaml`, không tải font khi ứng dụng chạy | Xem 3.2. File font đã có sẵn trong `assets/fonts/`. Không dùng `google_fonts`. Caveat **không** đóng gói, trang đăng nhập dùng kiểu chữ thay thế (đã chấp nhận) |
| 2 | **Dark mode** theo `ThemeMode.system`; **không lưu** lựa chọn; **không** thêm `shared_preferences` hay package nào | Xem 3.1 và bước 1. Không có nút đổi sáng/tối (prototype có, ở đây bỏ vì không lưu được); giao diện theo hệ điều hành. **Thay đổi ngày 2026-10-16 theo yêu cầu của chủ dự án: mặc định SÁNG (không còn theo hệ điều hành), có nút đổi sáng/tối (`themeModeProvider`, `ThemeModeButton`); vẫn không lưu lựa chọn, không thêm package.** |
| 3 | **Route**: thêm route mới cho các màn gộp và trang Tổng kết riêng; **giữ nguyên toàn bộ route cũ**; guard phân quyền giống màn tương ứng | Xem 4.1 |
| 4 | **Điểm 0,25**: bỏ qua, giữ validate hiện có | Không động vào validate trong lưới điểm |
| 5 | **KHÔNG thêm nút "Chốt bảng điểm"**. Thay bằng **nhãn trạng thái bảng điểm** (Đang nhập liệu / Đã khóa, kèm hạn khóa nếu có dữ liệu). Giao diện **không gọi** `lock()` hay `lockColumn()` (quyết định bổ sung, thay cho phiên bản trước yêu cầu giữ nút) | Xem 0.1 |
| 6 | **Camera mobile**: làm giao diện tối, giữ nguyên plugin camera và logic upload, chỉ đổi lớp phủ giao diện | Xem 4.2. Có giới hạn kỹ thuật của `image_picker` |

### 0.1. Nhãn trạng thái bảng điểm thay cho nút "Chốt" (đã chốt)

**Cơ sở** (đã kiểm tra code):
- Giao diện Flutter hiện không có nút chốt. `GradebooksRepository.lock()` và `lockColumn()` tồn tại trong `repository.dart` nhưng không widget nào gọi.
- Backend luôn từ chối (403) cả hai thao tác (`service.ts`); ADR-0014 quy định nhà trường đặt hạn nhập và hệ thống tự khóa. Vì vậy một nút chốt sẽ không bao giờ thành công.

**Quy tắc áp dụng**:
1. Không thêm nút, modal hay luồng "Chốt bảng điểm" ở bất kỳ màn nào (kể cả mobile). Bỏ phần này của prototype (`gv-grid` modal "Chốt bảng điểm", nút "Chốt bảng").
2. Không có lời gọi `lock()` / `lockColumn()` từ giao diện. Không sửa, không xóa hai phương thức này trong repository (ngoài phạm vi, và để repository nguyên trạng).
3. Hiển thị **nhãn trạng thái** dùng `AppBadge` (bước 2), dữ liệu có sẵn:

| Trạng thái | Điều kiện (dữ liệu hiện có) | Nhãn | Màu |
|---|---|---|---|
| Đang nhập liệu | `GradebookDto.status == DANG_NHAP_LIEU` | "Đang nhập liệu" | info |
| Đã khóa | `GradebookDto.status == DA_CHOT` | "Đã khóa" | ok |

4. **Hạn khóa** chỉ hiện khi có dữ liệu thật, và chỉ ở màn chi tiết bảng điểm:
   - Nguồn: `GradeCellDto.closesAt` của từng cột điểm (đã có trong phản hồi `gradebooksCells`, cùng nguồn với `GradeDeadlinesPanel`).
   - Quy tắc hiển thị: nếu **mọi cột nhập được đều có** `closesAt`, hiện "Khóa lúc <giờ muộn nhất>" cạnh nhãn (cùng hàm `deadlineLabel` đang dùng). Nếu còn cột chưa đặt lịch hoặc chưa có dữ liệu thì **không hiện hạn**, không đoán. Lý do: ADR-0014 nói muốn tự khóa toàn bảng thì phải đặt lịch cho mọi cột.
   - Đây chỉ là cách hiển thị giá trị đã có, không tính toán nghiệp vụ mới.
   - Màn danh sách bảng điểm: **chỉ nhãn trạng thái, không có hạn**, vì `GradebookDto` không chứa hạn và không được gọi thêm API cho từng bảng (tránh N+1 và tránh đổi repository).
5. Trạng thái "Đã khóa" vẫn giữ nguyên hành vi hiện có: lưới điểm chỉ đọc, ẩn nút lưu. Thông báo chỉ-đọc theo prototype ("Chỉ xem, không sửa được…") dùng chữ phù hợp backend: điểm tự khóa theo hạn do nhà trường đặt; không hướng dẫn người dùng tìm cách "chốt".

**Tác động tới chuỗi chữ và test** (cần lưu ý ở bước 10):
- Chữ hiện tại: "Đã chốt" (`gradebook_screen.dart:402`), "Đã chốt sổ" (`gradebooks_screen.dart:187` trong bộ lọc, `:584` trên thẻ). Đổi sang "Đã khóa" đồng nhất ở hai màn này.
- `phase2_gradebooks_test.dart` đang tìm chuỗi 'Đã chốt' nên phải cập nhật assertion tương ứng. Đây là thay đổi test bắt buộc, sẽ báo bạn khi làm.
- Không đổi các chữ "chốt" thuộc nghĩa khác: điểm tổng kết ("Chờ chốt ĐTB", "Đã chốt & tính ĐTB" trong `student_results_screen.dart`) và thống kê dashboard ("bảng đã chốt", "Tỷ lệ chốt sổ"). Nếu muốn thống nhất thuật ngữ ở cả những chỗ này, cần bạn quyết riêng, vì test `phase5_final_results` và dữ liệu `AdminKpiDto.lockedGradebooks` dùng từ "chốt".


## 1. Bảng so sánh màn hình

Ký hiệu: ✅ đủ, 🟡 một phần, ❌ chưa có.

| # | Màn trong thiết kế | File Flutter hiện tại | API / provider | Khoảng cách chính |
|---|---|---|---|---|
| 1 | Đăng nhập | `features/authentication/login_screen.dart` (545 dòng, `Scaffold` riêng) | ✅ `identityLogin` qua `sessionProvider` | Thiếu nửa trái navy (tiêu đề, 3 tính năng, tờ giấy Caveat). Phần "Xem thử với vai trò" tương ứng popup gợi ý tài khoản demo hiện có |
| 2 | GV · Tổng quan | `authentication/presentation/widgets/home_dashboard_content.dart` + `web/home_web_view.dart` + `mobile/home_mobile_view.dart` | 🟡 `teacherOverviewProvider` (ghép `gradebooksList` + `recognitionList`) | Có 3 KPI, thiết kế có 4. "Việc cần làm", "Lịch dạy hôm nay" (có `GET /timetable`), alert hạn nhập phải ghép từ nhiều nguồn. Không có endpoint tổng quan GV |
| 3 | GV · Bảng điểm | `features/gradebooks/gradebooks_screen.dart` (892) | ✅ `gradebooksRepositoryProvider.list` | Hiện là thẻ (grid 2 cột), thiết kế là bảng. `GradebookDto` **không có** tiến độ, sĩ số, hạn nhập, ngày cập nhật |
| 4 | GV · Nhập điểm | `gradebooks/gradebook_screen.dart` (1542) tab "Nhập điểm", `excel_import_dialog.dart`, `grade_deadlines_panel.dart` | ✅ `gradebooksCells`, `gradebooksBatchUpdate`, `gradebooksHistory`, `syncRoster` | Hiện là `DataTable` + lưu có hộp lý do. Thiết kế: ô điểm 64×36 trạng thái (đã sửa / từ ảnh / lỗi), phím Enter/Tab/Esc, TB môn, hàng trung bình lớp. **Không có nút "Chốt bảng"** (backend luôn 403); thay bằng nhãn trạng thái + hạn khóa nếu có dữ liệu, xem 0.1 |
| 5 | GV · Nhận dạng từ ảnh | `features/recognition/recognition_panel.dart` (1129), `image_picker.dart`, `image_preview.dart`, `cancel_ticket_dialog.dart` | ✅ `recognitionRepositoryProvider` (list, upload, cancel, detail) | Đang là tab trong bảng điểm. Thiết kế là trang riêng có stepper 4 bước, chip chọn cột điểm, dropzone, "Phiếu gần đây" 4 trạng thái. Backend xử lý bất đồng bộ (202), đã có |
| 6 | GV · Đối chiếu & duyệt | `recognition/review_screen.dart` (1032) + `review/*` (10 file) | ✅ `recognitionDetail`, `reviewApprove` | Logic Xanh/Vàng/Đỏ đã đủ. Thiết kế đổi bố cục: 3 KPI, tab Cần xem/Vàng/Đỏ/Tất cả, thanh dính đáy, nhóm Xanh gập. Màn **nhạy test nhất** |
| 7 | GV · Tổng kết | `final_results/final_results_panel.dart` (297, nằm trong dialog của bảng điểm) + `reports/reports_panel.dart` (319) | ✅ `finalResultsList/Calculate`, `reportsSummary`, `reportsExport` | Thiết kế là trang riêng chọn lớp + học kỳ, có cột TX/GK/CK, KPI, biểu đồ phân bố. `FinalResultDto` chỉ có `finalScore` + `classification`, **không có điểm TB từng nhóm TX/GK/CK**. Trang riêng dùng **route mới** (4.1) |
| 8 | GV · Thời khóa biểu | `features/timetable/timetable_screen.dart` (1304) + 3 file phụ | ✅ `timetableRepositoryProvider` (gọi Dio trực tiếp) | Hiện giàu hơn thiết kế (lọc, sửa, chuyển). Thiết kế: lưới tiết 1–6 × Thứ 2–7 kèm giờ. Backend chỉ có số tiết, **không có giờ bắt đầu từng tiết** |
| 9 | QT · Tổng quan | `home_dashboard_content.dart` + `authentication/admin_charts.dart` (924) | ✅ `adminOverviewProvider` (`/reports/admin/overview`, tự làm mới 10s) | KPI học sinh/GV/tiến độ có sẵn. Thiếu: **điểm TB toàn trường**, đường điểm TB theo tháng, nút "Xuất báo cáo", alert "bảng điểm sắp quá hạn" |
| 10 | QT · Học sinh | `academic_catalog/catalog_screen.dart` (1765, dùng chung 10 tài nguyên) + `edit_dialog.dart` + `catalog_import_dialog.dart` | ✅ `catalogRepositoryProvider` (`students` CRUD + import) | Hiện là thẻ. Thiết kế là bảng + phân trang 10 dòng. **Không có trường giới tính** (`StudentsDto` chỉ có họ tên, ngày sinh, lớp). Cột "Tài khoản" phải suy ra từ `ma_nguoi_dung` |
| 11 | QT · Giáo viên & phân công | `catalog_screen` với `teachers` và `assignments` (hai màn riêng) | ✅ hai tài nguyên + `classes` | Thiết kế gộp 1 bảng (GV, môn, chip lớp, chủ nhiệm). Phải ghép client-side 3 danh sách → là màn mới, không phải sửa giao diện. **Đã duyệt route mới** (4.1) |
| 12 | QT · Môn học & hệ số | `catalog_screen` với `subjects`, `components`, `semester-weights` (ba màn riêng) | ✅ ba tài nguyên | Thiết kế gộp 1 bảng chip "TX ×1 · 4 cột". Cùng vấn đề ghép như mục 11, **route mới** (4.1). Công thức minh họa "chia 9" của prototype sai cho môn 3 cột TX (tổng 8) → không sao chép |
| 13 | QT · Chính sách xếp loại | `final_results/classification_policy_screen.dart` (305) | ✅ `classificationPoliciesActive/Activate` (gọi thẳng `apiProvider`) | Thiết kế: 3 ô ngưỡng cố định + "Xem trước kết quả" + badge phiên bản. Backend dùng danh sách `criteria` tùy cấu hình. Không có API xem phiên bản cũ. Xem trước = tính xếp loại trong widget, vi phạm `AGENTS.md` |
| 14 | QT · Tài khoản & phân quyền | `catalog_screen` với `accounts` | 🟡 `identityAccounts`, create, update (đổi vai trò, khóa, đặt lại mật khẩu), import | Tab theo vai trò làm client-side được. **Không có "Đăng nhập gần nhất"** (`AccountDto`: id, username, role, active). Không có phân quyền chi tiết, chỉ 3 vai trò cố định |
| 15 | HS · Điểm của tôi | `final_results/student_results_screen.dart` (845) | ✅ `studentResultsList` (gọi thẳng `apiProvider`) | Có điểm theo môn, TB, xếp hạng, sĩ số, tên lớp. **Thiếu**: tên GV từng môn, GVCN, mã HS trên hero (test hiện cấm hiện "Mã học sinh"), nút "Tải bảng điểm", đường điểm qua nhiều kỳ (phải gọi nhiều `termId`) |
| 16 | HS · Thời khóa biểu | `timetable_screen.dart` (cùng file mục 8) | ✅ | Backend ép theo lớp của HS và HS không thấy phòng học (theo `AGENTS.md`) |
| 17 | Mobile · Đăng nhập | `login_screen.dart` | ✅ | Ô cao 48, chip chọn vai trò |
| 18 | Mobile · Trang chủ | `home_mobile_view.dart` (213) | 🟡 như mục 2 | Hero navy, nút lớn "Chụp bảng điểm", thẻ nhiệm vụ |
| 19 | Mobile · Bảng điểm | `gradebooks_screen.dart` (nhánh hẹp) | ✅ | Chip lọc, thẻ kèm progress (progress thiếu dữ liệu như mục 3) |
| 20 | Mobile · Nhập điểm | `gradebook_screen.dart` (`_mobileGrid`) | ✅ | Chip chọn thành phần dính trên, ô 80×48, thanh Lưu dính đáy |
| 21 | Mobile · Chụp ảnh | `recognition_panel.dart` + `image_picker.dart` (camera qua `image_picker`) | ✅ | Giao diện camera tối 4 góc vàng là **màn tự dựng**; `image_picker` mở camera hệ thống, không cho chèn overlay. Nên coi là tùy chọn |
| 22 | Mobile · Duyệt kết quả | `review/review_mobile_pager.dart` (449) | ✅ | Chấm tiến độ từng dòng, thanh Trước/Xác nhận/Sau |
| 23 | Mobile · Điểm của tôi (HS) | `student_results_screen.dart` | ✅ | Hero navy, accordion theo môn |
| 24 | Mobile · Tài khoản | `authentication/profile_dialog.dart` (228) + `NavigationBar` "Cá nhân" | 🟡 `identityProfile`/`Password` | Hồ sơ: GV sửa email/điện thoại, HS chỉ xem, **QTV không có hồ sơ (403)**. Đổi mật khẩu: **HS bị 403**. "Thông báo": không có (mục 2) |

Ghi chú điều hướng: prototype không có mục Năm học, Học kỳ, Lớp, Thành phần điểm, Hệ số học kỳ, Trạng thái kết nối. App đã có và QTV cần các màn này → **giữ nguyên trong sidebar**, chỉ đổi kiểu hiển thị.

## 2. Màn / chức năng trong thiết kế mà backend CHƯA hỗ trợ

Theo `CLAUDE.md`: không làm giả, chỉ liệt kê.

| # | Hạng mục trong thiết kế | Tình trạng backend | Bằng chứng |
|---|---|---|---|
| 1 | Thông báo (chuông, chấm vàng, mục "Thông báo" trên mobile) | Không có | Không có model, endpoint hay module |
| 2 | Chốt bảng điểm thủ công (nút + modal) | Cấm có chủ đích: tự khóa theo hạn (ADR-0014). **Quyết định: không làm nút**, thay bằng nhãn trạng thái (0.1) | `POST /gradebooks/{id}/lock` và `.../components/{cid}/lock` luôn 403 (`service.ts`) |
| 3 | Điểm TB toàn trường và đường điểm TB theo tháng (QT · Tổng quan) | Không có | `AdminKpiDto` không có trường này; `gradeDistribution` chỉ là phân bố |
| 4 | "Xuất báo cáo" toàn trường | Không có | Chỉ có `export.xlsx` theo từng bảng điểm. Không có PDF |
| 5 | Alert "N bảng điểm sắp quá hạn nhập" | Không có tổng hợp | Hạn nằm ở từng cột của từng bảng điểm (`lich_nhap_diem`), không có endpoint tổng hợp |
| 6 | Tiến độ, sĩ số, hạn, ngày cập nhật trên danh sách bảng điểm | Thiếu trường | `GradebookDto`: id, classId, subjectId, termId, tên lớp/môn/kỳ, status, version |
| 7 | Dashboard GV (4 KPI, việc cần làm, lịch dạy hôm nay) | Một phần | Không có endpoint riêng. Ghép được từ bảng điểm, phiếu nhận dạng và `GET /timetable` |
| 8 | Giới tính học sinh | Không có | `StudentsDto`/`StudentsInput`: không có trường giới tính; Prisma không có cột |
| 9 | "Đăng nhập gần nhất" của tài khoản | Không có | `AccountDto`: id, username, role, active |
| 10 | Phân quyền chi tiết (ma trận quyền) | Không có | Chỉ enum 3 vai trò, không có bảng quyền |
| 11 | Xem trước xếp loại / lịch sử phiên bản chính sách | Không có | Chỉ `active` và `activate`. Backend không có API xem trước |
| 12 | HS: tên GV từng môn, GVCN, mã HS | Không có trong DTO | `StudentSubjectResultDto` không có tên GV; HS chỉ đọc được bảng `hoc_sinh` của mình, không đọc `lop` để lấy GVCN |
| 13 | HS: "Tải bảng điểm", đường điểm qua các kỳ/năm | Không có / một phần | Không có export cho HS. `/students/me/results` nhận một `termId` mỗi lần |
| 14 | Tổng kết: cột TB nhóm TX/GK/CK | Không có | `FinalResultDto`: finalScore, classification, weightVersion, policyVersion, calculatedAt |
| 15 | Giờ bắt đầu từng tiết trên thời khóa biểu | Không có | `TimetableItemDto` chỉ có `thu`, `tiet`, `phong_hoc` |
| 16 | Tìm kiếm toàn cục trên topbar | Không có | Chỉ có `q` theo từng danh mục |
| 17 | Đổi mật khẩu cho HS; hồ sơ cho QTV | Cấm | HS bị 403 ở `/identity/password`; QTV bị 403 ở `/identity/profile` |
| 18 | OCR nhiều trang "Trang 1/2" trong một phiếu | Không có | Mỗi phiếu là một ảnh; nhiều trang = nhiều phiếu |
| 19 | Bước điểm 0,25 (prototype) | Khác quy tắc nghiệp vụ | **Đã quyết: bỏ qua**, giữ validate hiện có |
| 20 | Xóa tài khoản | Không có | Chỉ khóa/mở, đặt lại mật khẩu |
| 21 | Avatar ảnh | Không có | Dùng chữ cái đầu như prototype nên không ảnh hưởng |

## 3. Theme, font, component dùng chung hiện có

### 3.1 Token

`lib/app/theme.dart` (318 dòng): chỉ có `AppTheme.light()`, Material 3, seed `1A56DB`. Không có dark theme.

| Token | Prototype | Flutter hiện tại | Mức tái dùng |
|---|---|---|---|
| Primary | `#1F5FD1` | `#1A56DB` | Gần. Đổi giá trị hằng |
| Nền trang | `#F3F6FB` | `#F8FAFC` (`warmIvoryBg`) | Đổi giá trị |
| Surface / viền | `#FFF` / `#DDE4EE` | `#FFF` / `#E2E8F0` | Gần |
| Chữ | `#14213D` / `#44546F` / `#62728F` | `#0F172A` / `#475569` / `#64748B` | Đổi giá trị |
| **Sidebar** | navy `#0F2B5B`, mục active kèm vạch vàng 3px | **trắng** (`sidebarBg`) | **Đổi hoàn toàn** |
| Accent vàng | `#F2A900` | `goldAccent` = `#2563EB` (tên "gold" nhưng là xanh) | Cần hằng mới, tránh dùng tên gây nhầm |
| Ok / Warn / Bad (+soft, +line) | `#12805C` / `#8A5600` / `#C23B3B` | có cặp nền/chữ badge, không có `line` | Mở rộng |
| Bo góc | button/input 8, card 12, modal 14 | input 12, card 14, dialog 16, control chuẩn 10 | Chưa có token tập trung; cần tạo |
| Chiều cao control | 40 (lg 48, sm 32) | **48** (chuẩn `ui-control-standard.md`) | **Xung đột**: giữ 48 vì test ghim 300×48 và 164×48 |
| Dark mode | có (theo hệ điều hành + nút đổi tay) | không có | **Mới, theo `ThemeMode.system`**: thêm `AppTheme.dark()` và `darkTheme:` + `themeMode: ThemeMode.system` trong `app.dart` (hiện `app.dart:119` chỉ có `theme: AppTheme.light()`). Không nút đổi, không lưu |
| Màu cứng ngoài theme (**chặn dark mode**: màu cứng không đổi theo chế độ tối) | – | `admin_charts` 26, `catalog_screen` 18, `timetable_screen` 16, `student_results_screen` 11, `login_screen` 4, `home_dashboard_content` 4, cộng `Colors.xxx` rải ở recognition/gradebooks | Phải gom về token khi làm từng màn |

### 3.2 Font (đã chốt: Be Vietnam Pro, đóng gói asset)

- Prototype dùng **Be Vietnam Pro** (400/500/600/700) và **Caveat** (chữ viết tay mô phỏng giấy).
- Quyết định: chỉ đóng gói **Be Vietnam Pro**. Không dùng `google_fonts`, không tải font khi ứng dụng chạy; font là file asset nằm trong dự án.
- **Đã có file font** (tải một lần từ kho `google/fonts`, thư mục `ofl/bevietnampro`, về ổ F, 2026-10-16): `apps/client_flutter/assets/fonts/BeVietnamPro-Regular.ttf`, `-Medium.ttf`, `-SemiBold.ttf`, `-Bold.ttf` và `OFL.txt` (giấy phép SIL OFL). Đã kiểm: 4 file là TrueType hợp lệ, đủ 134 ký tự có dấu tiếng Việt (chữ thường và hoa). **Chưa** khai báo trong `pubspec.yaml` (việc của bước 1).
- Hiện trạng Flutter: `pubspec.yaml` chưa có `fonts:` / `assets:`; text theme dùng `fontFamilyFallback: [Roboto, Arial, Noto Sans]`; có 10 chỗ gán `fontFamily: 'serif'` (logo, login, số trên thẻ KPI, `admin_charts`, `connection`, `app_sidebar`).
- Việc cần làm ở bước 1: khai báo family `BeVietnamPro` trong `pubspec.yaml` (4 weight: 400, 500, 600, 700, trỏ tới 4 file ở trên), đặt `fontFamily` trong `ThemeData`/`TextTheme`, thay 10 chỗ `'serif'`.
- **Caveat không đóng gói (đã chấp nhận)**: phần "chữ viết tay" ở **trang đăng nhập** (tờ giấy nghiêng bên trái) dùng kiểu chữ thay thế, ví dụ Be Vietnam Pro nghiêng. Các ô crop viết tay trong màn đối chiếu của prototype chỉ là mô phỏng; app thật hiển thị ảnh cắt từ server nên không bị ảnh hưởng.
- Kiểm tra: Be Vietnam Pro hỗ trợ đủ dấu tiếng Việt; test độ rộng chữ (320 px, scale 150%) cần chạy lại vì metric font đổi.

### 3.3 Component dùng chung (`lib/app/widgets/`)

| Widget | Số file `lib/` dùng | Dùng lại cho thiết kế mới |
|---|---|---|
| `AppScaffold` (434 dòng) | 8 màn (catalog, connection, policy, student_results, gradebooks, gradebook, review, timetable). Login và Trang chủ **không** dùng | Cao. Giữ API, đổi topbar/nav đáy |
| `AppSidebar` (1012) | 3 nơi (`app_scaffold`, hai home view) | Giữ cấu trúc nhóm gập, **đổi kiểu sang navy** + vạch vàng + avatar/đăng xuất ở cuối. Chuỗi cứng "Học kỳ I · 2024–2025", badge `'08'` cần bỏ |
| `AppEdgeScrollbar` | 4 | Giữ nguyên (test ghim `app-edge-scrollbar`) |
| `AppControlMetrics`, `AppFilterDropdown`, `AppActionButton` | `AppFilterDropdown` 3 màn, `AppActionButton` 2 màn, `AppControlMetrics` 5 chỗ | Giữ kích thước; đổi bo góc/màu. Mở rộng áp dụng sang các màn còn dùng Material thô |
| `EmptyState` | 3 | Dùng lại, đổi kiểu |
| `ShimmerLoading` | 4 (hiện là khung tĩnh) | Dùng lại |
| `RoleBadge` | 5 | Dùng lại; map màu: QTV đỏ, GV xanh dương, HS xám theo prototype |
| `StatCard` (96 dòng) | **0** (dashboard tự dựng `_buildStatCard`) | Dùng làm nền cho KPI card mới và thay phần tự dựng |

Widget Material thô còn rất nhiều, mỗi cái cần được chuẩn hóa qua theme chứ không thay từng chỗ: `Card` 99 lần/23 file, `FilledButton` 48/25, `TextButton` 45/19, `OutlinedButton` 41/16, `SnackBar` 36/14, `showDialog` 24/14, `DataTable` 6/5.

**Cần tạo mới** (chưa có): `AppBadge` (Xanh/Vàng/Đỏ/info/neutral có chấm), `AppProgress` (+ thanh độ tin cậy), `AppAvatar`, `AppTabs` (gạch dưới + chip đếm), `AppPager`, khung `AppDialog` (header/footer), toast kiểu navy (qua `SnackBarThemeData`), `LineChart`/`HBars` dùng chung (hiện private trong `admin_charts`), `GradeCell` (ô điểm có trạng thái).

**Tài sản test cần giữ** (ghim trong 18 file test): chuỗi tiếng Việt, `ValueKey` (vd. `review-approve`, `grade-<id>`, `add-slot-…`, `activate-policy`, `app-edge-scrollbar`), loại widget (`FilledButton`, `TextFormField`, `DataTable`, `PageView`, `PopupMenuButton`), kích thước 300×48 và 164×48, breakpoint 600/960/1024, hiện/ẩn mục theo vai, và việc không có overflow ở 320 px với chữ 150%.

## 4. Thứ tự thực hiện (ít rủi ro → nhiều rủi ro)

Số file tính cả file `lib/` sửa mới và file test dự kiến phải sửa. Sau mỗi bước chạy `flutter analyze` và `flutter test`, báo kết quả. Nguyên tắc: **giữ chuỗi, key, loại widget** để không phải sửa test; nếu bắt buộc đổi thì hỏi bạn trước.

| Bước | Nội dung | Số file ảnh hưởng | Rủi ro |
|---|---|---|---|
| 0 | Chạy `flutter analyze` + `flutter test` để ghi nhận baseline. Chốt các quyết định ở mục 6. **Đã chạy 2026-10-16: `flutter analyze` "No issues found!" (90,7 s); `flutter test` "All tests passed!", 105 test. Không file nào của client bị thay đổi.** | 0 | Không |
| 1 | **Token + theme + font + dark**: cập nhật giá trị màu, bo góc, text theme; thêm `SnackBarTheme`, `TabBarTheme`, `TextButtonTheme`; `AppTheme.dark()` và `ThemeExtension` cho màu ok/warn/bad/navy; khai báo Be Vietnam Pro (file đã có trong `assets/fonts/`); `app.dart` thêm `darkTheme` + `themeMode: ThemeMode.system` | 3 file sửa (`theme.dart`, `pubspec.yaml`, `app.dart`), không cần thêm file font | Thấp–trung bình. Đổi diện rộng; metric font mới có thể làm tràn chữ ở 320 px; test chạy ở chế độ sáng nên ít bị ảnh hưởng bởi dark. **Đã làm 2026-10-16** (thêm `lib/app/design_tokens.dart`, `test/theme_test.dart`, gỡ 8 chỗ `fontFamily: 'serif'` ở 4 file). `flutter analyze` sạch, `flutter test` 113/113. **Phát hiện khi mở app trên máy đang ở chế độ tối**: màn đăng nhập bị lẫn màu (ô nhập tối trên thẻ trắng, vài dòng chữ gần như mất) vì màn còn dùng hằng `AppTheme.*` và màu cứng; sẽ hết khi từng màn được chuyển sang token ở các bước sau |
| 2 | **Widget dùng chung mới**, thêm vào mà chưa gắn vào màn nào | 7–9 file mới, 0 file cũ | Gần như không |
| 3 | **Đăng nhập** (+ phiên bản mobile) | 1 (`login_screen.dart`), test 1–2 (`phase1`, `responsive_ui`) | Thấp. Giữ 'EduScore', nhãn 'Tên đăng nhập', nút 'Đăng nhập' |
| 4 | **Màn đọc, ít logic**: `student_results_screen`, `classification_policy_screen`, `connection` | 3, test 2 (`phase5_final_results`, `widget_test`) | Thấp. Chỉ thêm phần tử có dữ liệu; bỏ các phần mục 2 liệt kê |
| 5 | **Khung điều hướng**: `app_sidebar` (navy), `app_scaffold` (topbar, nav đáy), `home_web_view`, `home_mobile_view` | 4, test 4 (`phase1`, `school_permissions`, `responsive_ui`, `widget_test`) | Trung bình. Sidebar 1012 dòng, ảnh hưởng mọi màn; test ghim hiện/ẩn mục theo vai |
| 6 | **Dashboard**: `home_dashboard_content`, `admin_charts` (dùng `StatCard`, chart chung) | 2–3, test 0–1 | Trung bình thấp. Giữ nguyên nguồn dữ liệu, bỏ mục không có API |
| 7 | **Tổng kết + báo cáo**: `final_results_panel`, `reports_panel` (giữ trong dialog/tab hiện có) | 2, test 1 (`phase5`) | Trung bình thấp. Trang riêng cần route mới → để mục 6 |
| 8 | **Thời khóa biểu**: `timetable_screen`, `timetable_edit_dialog`, `timetable_filter` | 3–4, test 3 (`timetable_admin_ux`, `timetable_layout`, `timetable_filter`) | Trung bình. Test dày và ghim key ô lưới; giờ tiết phải để hằng cố định chỉ để hiển thị hoặc bỏ |
| 9 | **Danh mục (QTV)**: `catalog_screen` thêm kiểu bảng cho students/teachers/accounts, `edit_dialog`, `catalog_import_dialog`, `fields.dart` (chỉ nhãn) | 3–4, test 4 (`phase1`, `semester_weights`, `school_permissions`, `ui_control_standard`) | Trung bình cao. Một file 1765 dòng phục vụ 10 tài nguyên; test ghim chữ 'Thêm mới', key `catalog-add-…` |
| 10 | **Bảng điểm + lưới nhập điểm**: `gradebooks_screen`, `gradebook_screen`, `grade_deadlines_panel`, `excel_import_dialog`; **nhãn trạng thái "Đang nhập liệu / Đã khóa" + hạn khóa nếu có dữ liệu** (xem 0.1); **không** thêm nút chốt, không gọi `lock()`/`lockColumn()` | 4, test 2 (`phase2_gradebooks` cập nhật chuỗi "Đã chốt" → "Đã khóa", `grade_deadline_ui`) + 1 test mới cho nhãn trạng thái và hạn khóa (có đủ lịch / thiếu lịch) | Cao. Lưới điểm là nơi dễ lệch hành vi lưu, phiên bản, xung đột; ô `grade-<id>` được test ghim. Phần nhãn thì rủi ro thấp, chỉ hiển thị |
| 11 | **Nhận dạng ảnh**: `recognition_panel`, `image_preview`, `cancel_ticket_dialog` (stepper, "Phiếu gần đây") | 3–4, test 3 (`phase3_recognition`, `recognition_upload_ux`, `recognition_cancel_and_navigation`) | Cao. Có upload bất đồng bộ, hủy phiếu, dialog/bottom sheet theo kích thước |
| 12 | **Đối chiếu & duyệt**: `review_screen` + 10 file `review/*` | 11, test 2 (`recognition_review_screen` 1430 dòng, `recognition_cancel_and_navigation`) | **Cao nhất**. Màn quan trọng nhất cho demo, test ghim rất nhiều key và chuỗi, có chặn rời trang, conflict version, pager mobile |
| 13 | **Route + màn mới (đã duyệt)**: "Giáo viên & phân công", "Môn học & hệ số", trang "Tổng kết" riêng (xem 4.1). Thêm route vào `app.dart` (giữ nguyên route cũ), mục sidebar tương ứng | 4–6 file mới (3 màn, 1–3 widget bảng ghép), sửa `app.dart` + `app_sidebar.dart`, test mới 3–4 (guard theo vai, render, dark) | Cao. Ghép dữ liệu client-side từ nhiều danh sách, guard phân quyền phải khớp màn cũ |
| 14 | **Camera mobile giao diện tối (đã duyệt)**: màn tối bọc luồng chọn/chụp ảnh, giữ nguyên `RecognitionImagePicker` và upload (xem 4.2) | 2–3 file (1 màn mới, `recognition_panel.dart`, có thể `image_picker.dart` chỉ để gắn nút), test 1–2 (`recognition_upload_ux`, `phase3_recognition`) | Trung bình cao. Hạn chế của `image_picker`, xem 4.2 |

Tổng ước lượng: khoảng 45–55 file `lib/` sửa (trên tổng ≈ 56 file Dart) cộng 8–10 file mới (widget dùng chung, 3 màn mới, màn camera) và 14–18 file test sửa hoặc thêm. Bước 12 một mình chiếm 11 file.

**Dark mode không phải một bước riêng.** Hạ tầng nằm ở bước 1, nhưng mỗi màn chỉ đúng ở chế độ tối sau khi bỏ hết màu cứng (`Color(0x…)`, `Colors.xxx`) và dùng token/`ThemeExtension`. Vì vậy mỗi bước 3–14 phải: gom màu cứng của file đó về token, rồi kiểm tra bằng một smoke test render ở `Brightness.dark` (không overflow, chữ đọc được). Công này đã nằm trong ước lượng rủi ro từng bước; `admin_charts` (26 màu cứng) và `catalog_screen` (18) là hai nơi tốn nhất.

Lý do đặt khung điều hướng (bước 5) sau đăng nhập và các màn đọc: thay đổi này ảnh hưởng mọi màn nên cần hạ tầng token/widget (bước 1–2) và một vài màn đơn giản đã ổn định trước.

### 4.1. Route mới (đã duyệt)

Giữ nguyên toàn bộ route hiện có (`/`, `/login`, `/connection`, `/my-results`, `/timetable`, `/classification-policy`, `/catalog/:resource`, `/gradebooks`, `/gradebooks/:id`, `/gradebooks/:id/recognition/:ticketId`). Chỉ **thêm** các route sau (tên là đề xuất, chốt khi làm bước 13):

| Route mới (đề xuất) | Màn | Guard (sao chép từ màn tương ứng) | Dữ liệu (repository có sẵn) |
|---|---|---|---|
| `/admin/teaching-assignments` | QT · Giáo viên & phân công | Chỉ `QUAN_TRI_VIEN`, khác thì về `/`, giống `/catalog/:resource` | `catalogRepositoryProvider.list` cho `teachers`, `assignments`, `classes`; ghép ở client |
| `/admin/subjects-weights` | QT · Môn học & hệ số | Chỉ `QUAN_TRI_VIEN`, giống `/catalog/:resource` | `catalogRepositoryProvider.list` cho `subjects`, `components`, `semester-weights` |
| `/final-results` | GV · Tổng kết (trang riêng) | `HOC_SINH` bị đẩy về `/`, giống nhánh `/gradebooks`; GV và QTV được vào | `gradebooksRepositoryProvider.list` chọn bảng điểm, rồi `finalResultsRepositoryProvider.list/calculate` và `reportsRepositoryProvider` (thống kê, xuất Excel) |

Lưu ý khi làm:
- Guard hiện áp theo tiền tố `/gradebooks`; route `/final-results` nằm ngoài tiền tố nên phải thêm điều kiện tương ứng vào `redirect` trong `app.dart`. Đây là thay đổi cộng thêm, không sửa điều kiện cũ.
- Phân quyền dữ liệu vẫn do backend quyết định (GV chỉ thấy bảng điểm được phân công). Guard ở client chỉ để điều hướng.
- "Chọn lớp + học kỳ" của prototype không đủ định danh một bảng điểm vì một bảng điểm là lớp + **môn** + học kỳ. Trang Tổng kết sẽ có thêm bộ chọn môn (lấy từ `gradebooksList`).
- Cột TB nhóm TX/GK/CK của prototype **không có dữ liệu** (mục 2, hạng mục 14), nên trang Tổng kết chỉ hiện `finalScore`, `classification`, `weightVersion`, `policyVersion`, `calculatedAt`.
- Các màn gộp chỉ đọc và điều hướng sang màn danh mục hiện có (`/catalog/...`) để thêm/sửa/xóa, không viết lại logic CRUD.
- Trang `/final-results` không thay thế dialog Tổng kết trong bảng điểm; cả hai cùng tồn tại để không phá `phase5_final_results_test`.

### 4.2. Camera mobile giao diện tối (đã duyệt, có giới hạn)

- Plugin hiện dùng: `image_picker` 1.2.0, qua `DeviceRecognitionImagePicker` (`lib/features/recognition/image_picker.dart`). Giữ nguyên plugin và logic upload (`recognitionRepositoryProvider.upload`, kiểm MIME, giới hạn kích thước).
- **Giới hạn kỹ thuật**: `image_picker` mở **ứng dụng camera của hệ điều hành** khi chụp; Flutter không thể vẽ lớp phủ (4 góc vàng, khung căn tờ giấy) lên trên khung ngắm đó. Vì vậy "lớp phủ giao diện" ở đây là **màn Flutter tối đặt trước bước chụp**, không phải overlay trên camera thật.
- Phạm vi dự kiến: màn nền tối với khung 4 góc vàng minh họa cách căn, pill "10A1 · Toán · Giữa kỳ" (lấy từ dữ liệu bảng điểm và cột điểm đang chọn), mẹo chụp, nút chụp và nút thư viện gọi `RecognitionImagePicker` như hiện nay. Sau khi có ảnh, quay lại luồng xem trước và tải lên hiện tại.
- Không làm: nhãn "Trang 1/2" (mỗi phiếu một ảnh, mục 2 hạng mục 18), flash (không có trong `image_picker`), đổi sang plugin `camera`.
- Trên web, nút chụp mở hộp chọn tệp của trình duyệt; màn tối vẫn dùng được nhưng khung hướng dẫn chỉ mang tính minh họa.
- Muốn overlay thật trên khung ngắm thì phải thêm plugin `camera`, trái quyết định 6 và quy tắc "không thêm package", nên không nằm trong kế hoạch.

## 5. Điều kiện kiểm chứng cho mỗi bước

- `flutter analyze` sạch, `flutter test` xanh (so với baseline bước 0).
- Kiểm tra responsive ở 320 / 390 / 768 / 1440, chữ 150%, không overflow (các test hiện có đã kiểm `takeException() == null`).
- Không có thay đổi trong `packages/api_client_dart`, repository, provider. Route chỉ được **thêm** (bước 13), không sửa route cũ.
- Màn đã làm xong phải render đúng ở `Brightness.dark` (không overflow, không còn màu cứng của file đó).
- Không thêm package nào; `pubspec.yaml` chỉ thêm khai báo `fonts:`.
- Giao diện không có lời gọi `lock()` / `lockColumn()` (kiểm bằng grep trong `lib/` sau bước 10).
- Mỗi màn: đối chiếu với mục 2, bỏ phần không có API và liệt kê lại cho bạn thay vì làm giả.

## 6. Việc còn lại cần từ bạn

Các quyết định ở mục 0 đã chốt, kể cả việc không làm nút chốt. Còn lại:

Đã xong (2026-10-16):
- File font Be Vietnam Pro đã tải về `assets/fonts/` (mục 3.2).
- Chấp nhận kiểu chữ thay thế Caveat ở trang đăng nhập (mục 3.2).
- `CLAUDE.md`: dòng tham chiếu thiết kế trỏ tới `docs/design/Hệ thống quản lý điểm.html`; dòng route đã đổi thành "không đổi hoặc xóa route cũ, được thêm route mới theo mục 4.1 của tài liệu này".

Còn lại một câu hỏi nhỏ, không chặn việc khác:
1. **Thuật ngữ "chốt" / "khóa"** (mục 0.1): mặc định chỉ đổi ở nhãn trạng thái bảng điểm ("Đã khóa"), giữ nguyên các chữ "chốt" của điểm tổng kết và dashboard. Nếu bạn muốn thống nhất cả những chỗ đó thì cho biết trước khi làm bước 10.

Chưa sửa code Flutter (chỉ thêm file font vào `assets/fonts/`, chưa đụng `pubspec.yaml` hay file Dart nào). Việc đầu tiên khi bắt đầu là bước 0: chạy `flutter analyze` + `flutter test` lấy baseline.
