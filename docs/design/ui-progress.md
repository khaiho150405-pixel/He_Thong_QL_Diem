# Tiến độ thiết kế lại UI

Mỗi dòng: bước, file đã đổi, kết quả `flutter analyze` / `flutter test`, và assertion test đã đổi (nếu có).

| Bước | Nội dung | File đã đổi | Kết quả | Assertion test đã đổi |
|---|---|---|---|---|
| 0 | Baseline | không | analyze sạch, 105 test pass | không |
| 1 | Theme, token, font, dark mode | `lib/app/design_tokens.dart`, `lib/app/theme.dart`, `lib/app/app.dart`, `pubspec.yaml`, `assets/fonts/*`, `test/theme_test.dart`, bỏ `fontFamily: 'serif'` ở 4 file | analyze sạch, 113 test pass | không |
| 2 | Widget dùng chung mới (chưa gắn vào màn nào) | `lib/app/widgets/app_badge.dart`, `app_progress.dart`, `app_avatar.dart`, `app_tabs.dart`, `app_pager.dart`, `app_dialog.dart`, `app_charts.dart`, `grade_cell.dart`, `test/app_widgets_test.dart` (tất cả là file mới, 0 file cũ) | analyze sạch, 156 test pass (113 cũ + 43 mới) | không |
| 3 | Đăng nhập (web + mobile) | `lib/features/authentication/login_screen.dart`, `test/login_theme_test.dart` (file mới) | analyze sạch, 164 test pass (156 cũ + 8 mới) | không |
| 4 | Kết quả HS, chính sách xếp loại, kết nối | `lib/features/final_results/student_results_screen.dart`, `lib/features/final_results/classification_policy_screen.dart`, `lib/features/connection/connection.dart`, `test/results_policy_dark_test.dart` (file mới) | analyze sạch, 177 test pass (164 cũ + 13 mới) | không |
| 4b | Khôi phục ĐTB chung và xếp loại chung ở client | `lib/features/final_results/student_results_screen.dart`, `test/results_policy_dark_test.dart` | analyze sạch, 182 test pass (177 cũ + 5 mới) | không |
| 5 | Khung điều hướng (sidebar navy, topbar, nav đáy, trang chủ) | `lib/app/widgets/app_sidebar.dart`, `lib/app/widgets/app_scaffold.dart`, `lib/app/widgets/app_shell.dart` (file mới: `AppSidebarFrame`, `AppTopBar`, `AppBottomNav`), `lib/features/authentication/presentation/web/home_web_view.dart`, `lib/features/authentication/presentation/mobile/home_mobile_view.dart`, `test/shell_theme_test.dart` (file mới) | analyze sạch, 197 test pass (182 cũ + 15 mới) | không |
| 6 | Dashboard (3 vai) | `lib/app/widgets/stat_card.dart` (thêm `StatTone`, `StatCardGrid`, đổi bố cục theo `.kpi`, API cũ giữ nguyên), `lib/app/widgets/app_progress.dart` (thêm tông `bad`), `lib/features/authentication/presentation/widgets/home_dashboard_content.dart`, `lib/features/authentication/admin_charts.dart`, `test/dashboard_theme_test.dart` (file mới) | analyze sạch, 210 test pass (197 cũ + 13 mới) | không |
| 7 | Tổng kết và báo cáo (hộp thoại "Tổng kết", tab "Báo cáo & Tiện ích") | `lib/features/final_results/final_results_panel.dart`, `lib/features/reports/reports_panel.dart`, `test/final_reports_theme_test.dart` (file mới); không sửa `gradebook_screen.dart` | analyze sạch, 226 test pass (210 cũ + 16 mới) | không |
| 8 | Thời khóa biểu (lưới tuần, theo ngày, hộp thoại xếp tiết, bộ lọc) | `lib/features/timetable/timetable_screen.dart`, `lib/features/timetable/timetable_edit_dialog.dart`, `lib/features/timetable/timetable_filter.dart`, `test/timetable_theme_test.dart` (file mới) | analyze sạch, 242 test pass (226 cũ + 16 mới) | không |
