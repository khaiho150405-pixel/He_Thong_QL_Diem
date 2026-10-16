# Tiến độ thiết kế lại UI

Mỗi dòng: bước, file đã đổi, kết quả `flutter analyze` / `flutter test`, và assertion test đã đổi (nếu có).

| Bước | Nội dung | File đã đổi | Kết quả | Assertion test đã đổi |
|---|---|---|---|---|
| 0 | Baseline | không | analyze sạch, 105 test pass | không |
| 1 | Theme, token, font, dark mode | `lib/app/design_tokens.dart`, `lib/app/theme.dart`, `lib/app/app.dart`, `pubspec.yaml`, `assets/fonts/*`, `test/theme_test.dart`, bỏ `fontFamily: 'serif'` ở 4 file | analyze sạch, 113 test pass | không |
| 2 | Widget dùng chung mới (chưa gắn vào màn nào) | `lib/app/widgets/app_badge.dart`, `app_progress.dart`, `app_avatar.dart`, `app_tabs.dart`, `app_pager.dart`, `app_dialog.dart`, `app_charts.dart`, `grade_cell.dart`, `test/app_widgets_test.dart` (tất cả là file mới, 0 file cũ) | analyze sạch, 156 test pass (113 cũ + 43 mới) | không |
| 3 | Đăng nhập (web + mobile) | `lib/features/authentication/login_screen.dart`, `test/login_theme_test.dart` (file mới) | analyze sạch, 164 test pass (156 cũ + 8 mới) | không |
| 4 | Kết quả HS, chính sách xếp loại, kết nối | `lib/features/final_results/student_results_screen.dart`, `lib/features/final_results/classification_policy_screen.dart`, `lib/features/connection/connection.dart`, `test/results_policy_dark_test.dart` (file mới) | analyze sạch, 177 test pass (164 cũ + 13 mới) | không |
