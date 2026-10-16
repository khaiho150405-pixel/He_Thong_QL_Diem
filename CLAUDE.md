@AGENTS.md

# Thiết kế lại UI Flutter

Flutter client nằm ở `apps/client_flutter`. Chạy mọi lệnh `flutter` (analyze, test, build) trong thư mục đó.

Tài liệu cần đọc trước khi làm:
- Thiết kế tham chiếu: `docs/design/Hệ thống quản lý điểm.html` (token, bố cục, component).
- Kế hoạch: `docs/design/ui-migration-plan.md` (mục 0 đến 4.2).
- Token và theme đã có (bước 1): `lib/app/design_tokens.dart`, `lib/app/theme.dart`.
- Nhật ký: `docs/design/ui-progress.md` (bước đã xong), `docs/design/open-questions.md` (điểm chưa rõ, hạng mục backend chưa hỗ trợ).

## Quy tắc

- Chỉ sửa lớp hiển thị (widget, theme, layout). Không đổi provider, repository, model, API, `packages/api_client_dart`, quyền truy cập, công thức tính điểm, validate nhập điểm.
- Không đổi hay xóa route cũ. Chỉ được thêm route mới theo mục 4.1 của kế hoạch, guard phân quyền giống màn tương ứng đang có.
- Giữ nguyên chuỗi tiếng Việt, `ValueKey`, loại widget, chiều cao control 48 và breakpoint 600/960/1024 mà test đang ghim. Nếu bắt buộc đổi assertion của test thì chỉ sửa đúng assertion đó và ghi vào `docs/design/ui-progress.md`.
- Dùng màu, bo góc, khoảng cách từ `context.tokens`, `AppRadius`, `AppSpacing`. Trong file đang sửa, gom hết màu cứng (`Color(0x..)`, `Colors.xxx`) về token để đúng ở chế độ tối. Giao diện mặc định SÁNG, có nút đổi sáng/tối (`themeModeProvider` trong `lib/app/theme_mode.dart`, nút `ThemeModeButton`), không lưu lựa chọn.
- Không thêm package (không `google_fonts`, không `shared_preferences`). `pubspec.yaml` chỉ được thêm khai báo `fonts`. Không cài gì lên ổ C.
- Không thêm nút "Chốt bảng điểm" và không gọi `lock()` / `lockColumn()` từ giao diện. Dùng nhãn "Đang nhập liệu" / "Đã khóa" (mục 0.1 của kế hoạch).
- Hạng mục trong thiết kế mà backend chưa hỗ trợ (mục 2 của kế hoạch): không làm giả, không tạo dữ liệu giả; ghi vào `docs/design/open-questions.md`.
- Cần quyết định mà tài liệu chưa nêu: chọn phương án giữ nguyên hành vi hiện tại và ghi vào `docs/design/open-questions.md`.

## Quy trình mỗi bước

1. Làm đúng bước được giao, trong `apps/client_flutter`: `dart format`, `flutter analyze`, `flutter test`.
2. Lỗi thì sửa tối đa 3 lần; không nới lỏng test ngoài mức cho phép, không đổi logic nghiệp vụ để qua test.
3. Qua thì thêm một dòng vào `docs/design/ui-progress.md` (bước, file đã đổi, kết quả), rồi `git add -A` và `git commit -m "ui: buoc N - <tên ngắn>"`.
4. Không `git push`, không `git reset`, không xóa nhánh. Không commit mã hỏng.
