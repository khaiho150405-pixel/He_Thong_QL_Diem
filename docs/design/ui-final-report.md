# Báo cáo rà soát cuối (bước 15)

Phạm vi: toàn bộ thiết kế lại UI Flutter (`apps/client_flutter`), các bước 1 đến 14. Chi tiết từng bước ở `docs/design/ui-progress.md`; điểm chưa rõ ở `docs/design/open-questions.md`.

## 1. Kết quả lệnh (chạy trong `apps/client_flutter`)

| Lệnh                                                                                                                             | Kết quả                                                                                    |
| -------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| `dart format --output=none --set-exit-if-changed lib test`                                                                       | Sạch lúc đầu (109 file, 0 thay đổi). Sau khi sửa `profile_dialog.dart` cũng 0 thay đổi     |
| `flutter analyze`                                                                                                                | No issues found                                                                            |
| `flutter test`                                                                                                                   | 379 test pass, 0 lỗi (105 baseline + 274 test mới của các bước)                            |
| `flutter build web --dart-define-from-file=config/development.json` (xuất ra thư mục tạm, không vào `apps/client_flutter/build`) | Thành công (`Built ...webbuild_final`). Có cảnh báo "Wasm dry run" chỉ mang tính thông tin |

## 2. Các commit bước (git log ba2cbf1..HEAD)

15 commit bước sau `ba2cbf1`: bước 2, 3, 4, 4b, 5, 6, 7, 8, 9, 10, 11, 12, 12b, 13, 14 (`f0d07b2` đến `a059a01`), cộng commit bước 15 này. Bước 1 là `a65c941`, nằm trước `ba2cbf1`.

## 3. Điểm còn lệch so với prototype, theo màn

| Màn                                              | Còn lệch / không làm (lý do)                                                                                                                                                                                                                                |
| ------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Đăng nhập                                        | Popup "Xem thử với vai trò" thay cho 3 chip; mobile dùng chung 3 vai trò; chữ viết tay là Be Vietnam Pro nghiêng thay Caveat; còn nút "Kiểm tra kết nối hệ thống" (chức năng có sẵn)                                                                        |
| Khung điều hướng                                 | Không có ô tìm kiếm toàn cục, chip học kỳ, chuông thông báo; không có badge đếm ở sidebar (`countBadge` đều null); không có khối "học kỳ hiện tại / hạn nộp / tiến độ" ở đáy sidebar; mục giữa nổi của nav đáy không làm; nav đáy không thêm mục mới        |
| Dashboard                                        | Không có đường điểm TB toàn trường, ô "Điểm TB toàn trường", nút "Xuất báo cáo", alert sắp quá hạn, "Việc cần làm", "Lịch dạy hôm nay"; bộ KPI giữ nguồn cũ, khác bộ ô của prototype; còn chuỗi cứng "HỌC KỲ I, 2024–2025 · THPT BÀ ĐIỂM · ..." (xem mục 7) |
| Điểm của tôi (HS)                                | Không có tên giáo viên, GVCN, mã HS, tải bảng điểm, đường điểm qua kỳ, môn mạnh nhất, chọn học kỳ; avatar hiện "HS" vì DTO không có họ tên                                                                                                                  |
| Chính sách xếp loại                              | Giữ form tiêu chí tùy cấu hình; không có "Xem trước kết quả" và lịch sử phiên bản                                                                                                                                                                           |
| Tổng kết và báo cáo                              | Không có TB nhóm TX/GK/CK, công thức "(TX + 2 GK + 3 CK) / tổng hệ số"; mã xếp loại tùy cấu hình hiện trung tính vì không có cờ `passing`; panel tổng kết ở `/final-results` còn tiêu đề phụ "Hiển thị dưới bảng điểm"                                      |
| Thời khóa biểu                                   | Dải 10 tiết và 7 ngày (prototype 6 tiết, 6 ngày); không giờ bắt đầu từng tiết (backend không có); bỏ màu theo môn; không xuất lịch; `TimetableFilter` chưa được màn nào dùng                                                                                |
| Danh mục quản trị                                | Bảng chỉ cho học sinh, giáo viên, tài khoản (>= 768 px); thiếu Giới tính, Mã HS, "Đăng nhập gần nhất", họ tên tài khoản, tab theo vai trò; cột Tài khoản chỉ "Đã liên kết / Chưa liên kết"; phân trang giữ nút Trước/Sau cũ                                 |
| Giáo viên & phân công, Môn học & hệ số (màn mới) | Chỉ đọc, sửa ở `/catalog/...`; không có "Thêm giáo viên", "Nhập Excel"; không có "Tổng hệ số", công thức chia 9; hệ số hiện theo một học kỳ được chọn                                                                                                       |
| Danh sách bảng điểm                              | Thiếu cột Sĩ số, Tiến độ, Hạn nhập, Cập nhật; không hiện hạn khóa ở danh sách                                                                                                                                                                               |
| Chi tiết bảng điểm / lưới điểm                   | Không dùng `AppGradeCell` (test đọc `TextFormField`); ô vẫn cao hơn 64x36; không cột "TB môn", hàng "TB lớp", ô tìm học sinh, "Sĩ số", "Hạn nhập" ở tiêu đề, lịch sử cuối trang, phím tắt kiểu bảng tính; không breadcrumb; còn chữ "Cột đã chốt"           |
| Nhận dạng ảnh                                    | Không OCR nhiều trang; không chọn bảng điểm trong màn; không kéo-thả; không thanh % cho phiếu đang xử lý; không nút "Thử lại" trên thẻ phiếu lỗi; hộp hủy phiếu chưa dùng `AppDialog`                                                                       |
| Đối chiếu & duyệt                                | Không hiện độ tin cậy (xem mục 5); không tô sáng dòng trên ảnh gốc; không "Xác nhận tất cả gợi ý Vàng"; nhãn mức là "Xanh/Vàng/Đỏ"; bộ lọc vẫn là `FilterChip` (key test ghim); không tab "Cần xem"; không chấm bấm nhảy dòng                               |
| Màn chuẩn bị chụp                                | Khung 4 góc chỉ là minh họa, không phải overlay trên camera hệ điều hành (`image_picker`); không flash, không "Trang 1/2"; gắn bằng nút phụ "Hướng dẫn chụp", không chèn bước trung gian                                                                    |
| Chung                                            | Bước điểm 0,25 bỏ qua (giữ 0,1); không nút đổi sáng/tối (theo hệ điều hành); không đóng gói Caveat                                                                                                                                                          |

## 4. Hạng mục backend chưa hỗ trợ (không làm giả)

Thông báo; chốt bảng điểm thủ công (ADR-0014, backend trả 403); điểm TB toàn trường và đường điểm theo tháng; xuất báo cáo toàn trường; cảnh báo bảng điểm sắp quá hạn; sĩ số, tiến độ, hạn nhập trên danh sách bảng điểm; giới tính học sinh; "đăng nhập gần nhất" và họ tên tài khoản; phân quyền chi tiết; xem trước xếp loại và lịch sử phiên bản chính sách; tên giáo viên, GVCN, họ tên học sinh trong "Điểm của tôi"; tải bảng điểm cho học sinh; TB nhóm TX/GK/CK trong tổng kết; cờ `passing` trong DTO kết quả; giờ bắt đầu từng tiết; tìm kiếm toàn cục; OCR nhiều trang trong một phiếu; tọa độ dòng trên ảnh gốc; tiến độ phần trăm của phiếu đang xử lý; trạng thái hoạt động/khóa của tài khoản liên kết với học sinh; tên học kỳ hiện hành (để thay chuỗi cứng ở đầu trang chủ).

## 5. Mâu thuẫn cần chủ dự án quyết định

1. **Bất biến 3 (AGENTS.md mục 7) và `docs/ux/recognition-capture.md`** yêu cầu màn đối chiếu hiện độ tin cậy hai kênh, nhưng `test/recognition_review_screen_test.dart` ghim "KHÔNG hiển thị: Độ tin cậy, Ký tự thô, ...". Đã giữ hành vi test (bước 12b). Cần chọn một bên; nếu muốn hiện thì phải đổi các assertion đó (`AppConfidenceBar` đã sẵn).
2. **ĐTB chung và xếp loại chung tính ở client** (`semesterOverviewOf`, `overallClassificationCodeOf`) trái nguyên tắc "không đặt quy tắc tính điểm ở widget". Đã giữ nguyên hành vi cũ. Đề xuất backend trả sẵn trong `summary`.
3. **Hai nguồn ĐTB** ở "Điểm của tôi": hero dùng `summary.averageScore` (backend), hàng tổng hợp dùng trung bình cộng ở client; hai số có thể khác nhau.
4. **Ngưỡng "Chưa đạt"**: mã hiện tại không có nhánh này; mọi ĐTB dưới 6.5 (kể cả dưới 5.0) ra "Đạt", trái mô tả Giỏi >= 8.0, Khá >= 6.5, Đạt >= 5.0, còn lại Chưa đạt. Chưa sửa.
5. **Nút "Chốt bảng điểm"**: prototype có, nhưng ADR-0014 bỏ quyền chốt thủ công. UI không có nút và không gọi `lock()`/`lockColumn()` (có test quét `lib/`). Còn chữ "Cột đã chốt" ở lưới điểm, nên thống nhất thành "Cột đã khóa".
6. **Chuỗi cứng học kỳ ở đầu trang chủ** (xem mục 7).
7. Bản đồ màu `GIOI/KHA/...` và mã xếp loại tùy cấu hình hiển thị theo MÃ, không theo cờ `passing`; mã ngoài danh sách luôn trung tính.
8. Test backend thiếu: cột Cuối kỳ hệ số 3, quy tắc tối đa 4 cột TX, biên xếp loại 7.99/8.0, 6.49/6.5, 4.99/5.0 (ghi ở open-questions bước 10).
9. Khung giờ tiết cố định ở client (`timeSlotLabel`, `_timeOf`) cần xác nhận nguồn thật.

## 6. Kết quả grep `apps/client_flutter/lib`

- **`Color(0x`**: `lib/app/design_tokens.dart` 81 lần (định nghĩa token, đúng chỗ); `lib/app/theme.dart` 25 lần (hằng cũ `AppTheme.*` ở dòng 13-40 và một màu `0xFFE2E8F0` ở dòng 77). Không file màn hình nào còn `Color(0x`.
- **`Colors.xxx` (trừ `transparent`)**: `lib/app/theme.dart` 3 lần (`Colors.white` ở `onError` và chữ snackbar, `Colors.black/white` ở track thanh cuộn; đều là tông nền theme, không phải màn); `lib/features/authentication/profile_dialog.dart` 1 lần (vòng xoay trên nút) đã chuyển sang `context.tokens.onPri` ở bước này. Các khớp khác của "Colors." trong `catalog_screen.dart` là tên biến `sttColors`, không phải màu cứng.
- **Hằng `AppTheme.(primarySeed|primaryDark|...|blueBadge)`**: 0 chỗ dùng ngoài định nghĩa. Các hằng cũ (kể cả `greenBadgeBg`, `yellowBadgeText`, ...) vẫn còn khai báo trong `theme.dart` nhưng không có nơi gọi; có thể xóa ở lần dọn sau.
- **`.lock(` / `lockColumn(`**: chỉ có định nghĩa `lockColumn(` ở `lib/features/gradebooks/repository.dart:107`; không lời gọi nào từ giao diện.
- **`fontFamily: 'serif'`**: 0.
- **Chuỗi cứng học kỳ**: còn 3 chỗ ở `lib/features/authentication/presentation/widgets/home_dashboard_content.dart` (dòng 118, 122, 126): "HỌC KỲ I, 2024–2025 · THPT BÀ ĐIỂM · ...". "Học kỳ I · 2024–2025" ở sidebar và badge cứng '08' đã bỏ từ bước 5. Còn chuỗi "THPT Bà Điểm · Học kỳ I" ở một test của `results_policy_dark_test.dart` thuộc màn khác (dữ liệu giả của test).

## 7. Việc đã thử sửa ở bước này nhưng phải giữ nguyên

Đã thử bỏ phần "HỌC KỲ I, 2024–2025 · " khỏi dòng nhỏ đầu trang chủ (không test nào ghim chuỗi này). Kết quả: `test/phase1_test.dart` ("login retry, create year and logout at width 390.0") thất bại. Nguyên nhân gián tiếp: dòng nhỏ ngắn lại làm trang chủ thấp hơn, `scrollUntilVisible(find.text('Năm học'), 100)` dừng khi mục "Năm học" ở y = 855 (cửa sổ test cao 900) và bị thanh nav đáy che, nên `tap` trượt. Đã HOÀN TÁC thay đổi để giữ 379 test pass và không đổi test. Cách xử lý đề xuất khi chủ dự án đồng ý: bỏ chuỗi học kỳ cứng và thêm `ensureVisible`/kéo thêm trong bước đăng nhập của `phase1_test.dart` (đổi thao tác cuộn, không đổi assertion), hoặc thay bằng tên học kỳ thật khi backend có nguồn.

Thay đổi duy nhất của bước này ở mã: `lib/features/authentication/profile_dialog.dart` (vòng xoay nút "Lưu thay đổi" dùng `context.tokens.onPri` thay `Colors.white`, bỏ `const` ở `SizedBox` tương ứng, thêm import `design_tokens.dart`; không đổi kích thước, key, chuỗi).

## 8. Kiểm tra diff (`git diff ba2cbf1..HEAD`, và từ `a65c941^` cho bước 1)

- **(i) `packages/`**: không có file nào bị đổi (kể cả `packages/api_client_dart`).
- **(ii) repository / model / provider / session**: không file `*repository*.dart`, provider hay session nào bị đổi. Chỉ `lib/features/recognition/review/review_models.dart` bị sửa: thêm import, lớp `ReviewLevelColors`, hàm `reviewLevelColors`, `reviewOnOk`, `reviewLevelLabel`, và viết lại `buildReviewLevelBadge` thành `AppBadge`. Các hàm logic (lý do ngắn, `isYellowRowHandled`, ...) không đổi. Chỉ hiển thị.
- **(iii) `lib/app/app.dart`**: chỉ thêm 3 import, 3 `GoRoute` mới (`/admin/teaching-assignments`, `/admin/subjects-weights`, `/final-results`) và 2 khối điều kiện guard mới trong `redirect`. Mọi route cũ (`/`, `/login`, `/connection`, `/my-results`, `/timetable`, `/classification-policy`, `/catalog/:resource`, `/gradebooks`, `/gradebooks/:id`, `/gradebooks/:id/recognition/:ticketId`) và guard cũ còn nguyên, không dòng nào bị xóa.
- **(iv) Test cũ bị sửa**: chỉ một file test có từ trước bị sửa là `test/phase2_gradebooks_test.dart` (khoảng dòng 340): `expect(find.text('Đã chốt'), findsWidgets);` thành `expect(find.text('Đã khóa'), findsWidgets);`. Khớp với dòng bước 10 trong `ui-progress.md` (nhãn trạng thái bảng điểm theo mục 0.1 của kế hoạch). Mọi file test khác trong diff đều là file mới.
- **(v) `pubspec.yaml`**: chỉ thêm khối `flutter: fonts:` (Be Vietnam Pro, 4 file) ở bước 1; không thêm hay đổi dependency nào. `assets/fonts/*` là file mới của bước 1.

## 9. Chưa kiểm được

- Thiết bị Android/iOS thật (và simulator): chưa chạy; mọi kiểm tra là widget test và build web.
- Camera thật: `image_picker` mở ứng dụng camera hệ điều hành; màn chuẩn bị chụp, hành vi quay về sau khi chụp, `recoverImage` khi Android hủy activity chưa thử trên máy.
- Dark mode trên máy thật (`ThemeMode.system`): chỉ kiểm bằng widget test `Brightness.dark`; chưa xem bằng mắt toàn bộ màn, chưa so ảnh chụp với prototype, chưa golden test.
- Trình duyệt thật: build web thành công nhưng chưa mở xem; hành vi chọn tệp/ảnh trên trình duyệt di động chưa kiểm.
- Font Be Vietnam Pro hiển thị đủ dấu tiếng Việt trên mọi nền tảng; tương phản màu theo chuẩn trợ năng chưa đo.
- Test tích hợp backend (cần PostgreSQL) không chạy ở đợt rà soát này.
