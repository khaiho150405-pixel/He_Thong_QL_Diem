*## Quy tắc thiết kế lại UI*

*- Tham chiếu thiết kế: "F:\HK1_Nam04\KLCN\He_Thong_QL_Diem\docs\design\Hệ thống quản lý điểm.html" (mở file để xem token, bố cục, component).*

*- CHỈ sửa lớp hiển thị (widget, theme, layout). KHÔNG đổi provider, repository, model, API, quyền truy cập, công thức tính điểm. KHÔNG đổi hoặc xóa route cũ; được THÊM route mới theo `docs/design/ui-migration-plan.md` (mục 4.1), guard phân quyền phải giống màn tương ứng đang có.*

*- Mỗi lần sửa xong phải chạy `flutter analyze` và `flutter test`, báo kết quả.*

*- Không cài gì lên ổ C. Cần thêm package thì hỏi trước.*

*- Màn nào trong thiết kế chưa có API ở backend thì KHÔNG làm giả chức năng, chỉ liệt kê lại cho tôi.*

