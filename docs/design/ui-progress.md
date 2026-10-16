# Tiến độ thiết kế lại UI

Mỗi dòng: bước, file đã đổi, kết quả `flutter analyze` / `flutter test`, và assertion test đã đổi (nếu có).

| Bước | Nội dung | File đã đổi | Kết quả | Assertion test đã đổi |
|---|---|---|---|---|
| 0 | Baseline | không | analyze sạch, 105 test pass | không |
| 1 | Theme, token, font, dark mode | `lib/app/design_tokens.dart`, `lib/app/theme.dart`, `lib/app/app.dart`, `pubspec.yaml`, `assets/fonts/*`, `test/theme_test.dart`, bỏ `fontFamily: 'serif'` ở 4 file | analyze sạch, 113 test pass | không |
| 2 | Widget dùng chung mới (chưa gắn vào màn nào) | `lib/app/widgets/app_badge.dart`, `app_progress.dart`, `app_avatar.dart`, `app_tabs.dart`, `app_pager.dart`, `app_dialog.dart`, `app_charts.dart`, `grade_cell.dart`, `test/app_widgets_test.dart` (tất cả là file mới, 0 file cũ) | analyze sạch, 156 test pass (113 cũ + 43 mới) | không |
