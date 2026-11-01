---
name: gradebook-ui-ux
description: UI/UX design principles, production-grade patterns, and reference implementations for the School Gradebook System (Sổ điểm điện tử, Đối chiếu OCR 3 màu, Thời khóa biểu, Adaptive Material 3).
license: MIT
metadata:
  author: AI Agent & Dev Team
  version: "1.0.0"
---

# Gradebook UI/UX Design & Implementation Guide

Cẩm nang quy chuẩn UI/UX thực chiến và các mẫu tham chiếu tốt nhất cho Hệ thống Quản lý Điểm & Nhận dạng bảng điểm viết tay trên Flutter (Web, Android, iOS).

---

## 1. Local Cloned Reference Repositories

Hệ thống đã tích hợp 5 repository mã nguồn mở chất lượng cao nhất trên GitHub tại thư mục cục bộ `.local/references/` (đã được cấu hình gitignore, không commit lên git remote) để làm kim chỉ nam tái cấu trúc UI/UX:

1. **`bosskmk/pluto_grid`** (`.local/references/pluto_grid`):
   * **Mục đích**: DataGrid cấp doanh nghiệp cho Sổ điểm điện tử trên Web & Tablet.
   * **Tính năng thực tế**: Ghim cột (Frozen Columns: STT, Mã số, Họ và tên), phím tắt bàn phím (Tab, Enter, Arrow keys) để nhập điểm siêu tốc không cần chuột, validation trực tiếp (0.0 - 10.0), render ảo hóa (virtual scrolling) không giật lag ở bảng điểm 50+ học sinh và hàng chục cột điểm.
2. **`htsuruo/flutter-admin-dashboard-template`** (`.local/references/flutter-admin-dashboard-template`):
   * **Mục đích**: Kiến trúc Web Admin Dashboard chuẩn Material 3.
   * **Tính năng thực tế**: Hệ thống điều hướng thích ứng (Sidebar cố định trên màn hình rộng > 1024px, NavigationRail trên màn hình trung bình 768-1024px, Drawer trượt trên màn hình nhỏ/mobile), phân tách rạch ròi giữa Header cố định và Content cuộn độc lập.
3. **`MyGradesApp/grades-flutter`** (`.local/references/grades-flutter`):
   * **Mục đích**: Cổng thông tin tra cứu điểm số và học tập dành riêng cho học sinh trên thiết bị di động.
   * **Tính năng thực tế**: Giao diện Mobile-First dạng thẻ điểm (Grade Cards), huy hiệu trạng thái môn học (Đạt / Không đạt / Miễn), tóm tắt GPA và biểu đồ xu hướng học tập tối ưu cho màn hình cảm ứng.
4. **`gskinnerTeam/flutter-adaptive-demo`** (`.local/references/flutter-adaptive-demo`):
   * **Mục đích**: Chuẩn mực kiến trúc Adaptive đa nền tảng chính thức do Google Flutter Team và gskinner phát triển.
   * **Tính năng thực tế**: Giải quyết triệt để sự cố co giãn cửa sổ và phóng to/thu nhỏ trình duyệt (Browser Zoom In/Out `Ctrl +/-`). Tự động điều chỉnh form layout, lưới card và thanh công cụ khi không gian hiển thị thay đổi.
5. **`Codelessly/ResponsiveFramework`** (`.local/references/responsive-framework`):
   * **Mục đích**: Bộ công cụ điều phối Responsive & Auto-Scaling chuyên nghiệp cho Flutter Web & Desktop.
   * **Tính năng thực tế**: Quản lý Breakpoints linh hoạt (`Compact: 0-599`, `Medium: 600-1023`, `Expanded: 1024+`), chống tràn pixel (`RenderFlex overflowed`) khi người dùng thay đổi kích thước cửa sổ trình duyệt hoặc zoom lớn tới 150% - 200%.

---

## 2. Quy chuẩn Thiết kế & Bất biến Giao diện

### 2.1. Bảng màu & Design Tokens (`lib/app/design_tokens.dart`)
* **Chủ đạo**: Navy thanh bên (`--navy: #0F2B5B`, `--navy2: #1A3D7C`), Nền sáng (`--bg: #F3F6FB`, `--surface: #FFFFFF`).
* **Hành động chính (Primary)**: Xanh dương trường học (`--pri: #1F5FD1`, `--prih: #1A4FB0`).
* **Trạng thái 3 màu OCR & Xếp loại**:
  * 🟢 **Xanh (OK)**: `--ok: #12805C`, `--oksoft: #E3F6EE`, `--okline: #A7DEC8`.
  * 🟡 **Vàng (Warn)**: `--warn: #8A5600`, `--warnsoft: #FFF3D1`, `--warnline: #F3D58A`.
  * 🔴 **Đỏ (Bad)**: `--bad: #C23B3B`, `--badsoft: #FDE8E8`, `--badline: #F1B4B4`.

### 2.2. Kích thước Control & Trợ năng (`docs/ux/ui-control-standard.md`)
* Chiều cao control, button, dropdown: **48 px**.
* Bo góc chuẩn: **10 px** (`AppRadius.sm` / `AppRadius.md`).
* Điểm chạm tối thiểu trên màn hình cảm ứng: **44 × 48 px**.
* Mọi bộ lọc nhiều thành phần phải dùng `Wrap` (không dùng `Row` cố định gây tràn viền trên màn hình hẹp).
* Hỗ trợ co giãn màn hình từ **320 px** đến **1440 px+**, bao gồm cả cỡ chữ trợ năng **150%**.

---

## 3. Các Pattern UI/UX Trọng tâm Theo Màn hình

### 3.1. Sổ điểm điện tử (Gradebook Table View)
1. **Phân biệt rạch ròi giữa `NULL` và `0.0`**:
   * Ô chưa có điểm: hiển thị trống hoặc placeholder `—` (xám nhạt).
   * Ô điểm 0 thật: hiển thị số `0.0` (màu mực chuẩn).
2. **Cột đã khóa (Read-only)**:
   * Khi cột điểm hết hạn theo lịch của nhà trường (ADR-0014), chuyển nền ô sang xám nhạt (`subtle`), hiển thị badge "Đã khóa", không cho phép sửa.
3. **Audit Trail Drawer**:
   * Khi cần xem lịch sử sửa điểm của một ô, mở panel chi tiết hiển thị danh sách append-only: ai sửa, thời điểm, giá trị cũ $\rightarrow$ mới, lý do sửa.

### 3.2. Màn hình Đối chiếu Nhận dạng 3 màu (OCR Review Flow)
1. **Bố cục Split-View**:
   * Cột trái: Ảnh phóng to ô điểm cắt từ tờ giấy thi/phiếu điểm.
   * Cột phải: 2 kênh dự đoán máy (Điểm số & Điểm chữ), độ tin cậy và ô duyệt giá trị.
2. **Quy tắc 3 màu trực quan**:
   * **Dòng Xanh**: Hai kênh khớp nhau $\rightarrow$ cho phép giáo viên bấm "Duyệt tất cả dòng Xanh" chỉ với 1 chạm.
   * **Dòng Vàng**: Một kênh tin cậy $\rightarrow$ hiển thị rõ gợi ý "Lấy theo điểm số/chữ", giáo viên bấm xác nhận hoặc sửa.
   * **Dòng Đỏ**: Mâu thuẫn 2 kênh hoặc không đọc được $\rightarrow$ con trỏ tự động focus vào ô nhập để gõ nhanh điểm số.

### 3.3. Thời khóa biểu (Timetable Matrix)
* Lưới 10 tiết $\times$ 7 ngày (Thứ 2 đến Chủ nhật).
* Phân chia rõ ràng "BUỔI SÁNG" (Tiết 1–5) và "BUỔI CHIỀU" (Tiết 6–10).
* Bộ lọc 3 chiều: Theo Lớp, Theo Giáo viên, Theo Phòng học (chỉ QTV xem được phòng học).
* Khi trạng thái tải lỗi hoặc rỗng, luôn bọc trong vùng cuộn (`SingleChildScrollView`) để tránh lỗi tràn pixel (`RenderFlex overflow`) trên thiết bị nhỏ.

### 3.4. Tránh che khuất nội dung bởi Thanh điều hướng đáy (Bottom Navigation Safe Margin)
* Trên Mobile (khi có `bottomNavigationBar`), vùng cuộn chính phải có khoảng trống đáy tối thiểu **80–88 px** để item cuối cùng không bị thanh nav che khuất khi cuộn xuống hết cỡ.

---

## 4. Chiến lược Web Responsive & Ổn định khi Zoom In / Zoom Out

### 4.1. Cơ chế Browser Zoom trên Flutter Web
* Khi người dùng nhấn `Ctrl +` (phóng to tới 125%, 150%, 175%, 200%) hoặc `Ctrl -` (thu nhỏ 80%, 67%, 50%), trình duyệt thay đổi `window.devicePixelRatio`.
* Trong Flutter Web, việc này làm thay đổi trực tiếp kích thước không gian logic khả dụng: `MediaQuery.sizeOf(context).width` bị giảm mạnh khi zoom in và tăng mạnh khi zoom out.
* **Nguyên tắc chống vỡ giao diện (Anti-Overflow)**:
  1. **Không dùng `Row` cố định cho các dãy điều khiển / nút bấm / filter**: Luôn dùng `Wrap(spacing: 8, runSpacing: 8, children: [...])`. Khi người dùng zoom in 200%, các nút bấm sẽ tự động rơi xuống dòng tiếp theo thay vì gây văng lỗi sọc vàng đen `A RenderFlex overflowed by ... pixels`.
  2. **Tự động chuyển đổi dạng hiển thị theo Breakpoint**:
     * Khi chiều rộng logic $< 768px$ (do thu nhỏ cửa sổ hoặc do zoom in lớn): Tự động chuyển bảng dạng lưới thành danh sách thẻ (Card view), ẩn Sidebar cố định và chuyển sang Menu trượt (Drawer).
     * Khi chiều rộng logic $> 1024px$ (màn hình rộng hoặc zoom out): Hiển thị thanh bên cố định, bảng mở rộng toàn màn hình.
  3. **Khống chế độ rộng tối đa trên màn hình cực rộng (Max-Width Container)**:
     * Khi zoom out (`Ctrl -`) hoặc trên màn hình 2K/4K, bọc nội dung chính trong `Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 1400), child: ...))` để nội dung không bị dạt ra hai mép viền ngoài cùng gây mỏi cổ người dùng khi đọc dữ liệu.
  4. **Bảng dữ liệu lớn (Sổ điểm & Thời khóa biểu)**:
     * Luôn bọc trong thanh cuộn ngang `SingleChildScrollView(scrollDirection: Axis.horizontal)` hoặc tích hợp `PlutoGrid`. Các cột STT và Tên học sinh luôn được ghim cố định (`freeze: PlutoColumnFrozen.start`) để khi zoom in hay cuộn ngang, thông tin định danh học sinh luôn hiển thị rõ ràng.

---

## 5. Chiến lược Mobile Viewport Cố Định & Hỗ Trợ Xoay Ngang / Dọc

### 5.1. Viewport di động cố định (No Browser Zoom)
* Khác với Web, trên ứng dụng di động Native (Android/iOS), viewport được quản lý cố định bởi hệ điều hành theo kích thước vật lý của màn hình (thường là 360–430dp chiều ngang ở chế độ dọc).
* Không cho phép thao tác thu phóng toàn màn hình (pinch-to-zoom) trên các màn hình nghiệp vụ (chỉ hỗ trợ pinch-to-zoom trong chế độ soi ảnh phiếu điểm OCR để kiểm tra nét bút viết tay).
* Bọc toàn bộ Scaffold trong `SafeArea` để không bị đè bởi tai thỏ (Notch), Dynamic Island hoặc thanh cử chỉ Home Indicator.

### 5.2. Chuyển đổi linh hoạt Xoay Ngang / Dọc (Orientation Awareness)
Giáo viên và học sinh thường xuyên xoay ngang điện thoại để có không gian quan sát rộng hơn. Hệ thống đáp ứng chuẩn xác 2 trạng thái:

1. **Chế độ Dọc (Portrait - Mặc định)**:
   * **Bố cục**: Cột đơn cuộn dọc (`ListView` / `CustomScrollView`).
   * **Điều hướng**: `NavigationBar` Material 3 ở đáy màn hình, dễ dàng thao tác bằng ngón tay cái.
   * **Hiển thị điểm**: Dạng danh sách thẻ học sinh (`AppGradeCard`), mỗi thẻ thể hiện tóm tắt điểm và trạng thái.
2. **Chế độ Ngang (Landscape - Xoay điện thoại)**:
   * **Không gian khả dụng**: Chiều rộng tăng lên 700–920dp, nhưng chiều cao giảm xuống còn 360–420dp.
   * **Tự động chuyển đổi Điều hướng**: Ẩn `NavigationBar` ở đáy (để không chiếm dụng chiều cao quý giá), chuyển sang **`NavigationRail` hẹp** (72px) bên cạnh trái.
   * **Hiển thị điểm**: Tự động chuyển đổi từ danh sách thẻ sang **Bảng điểm ma trận ngang đầy đủ** (Full Matrix Grade Table), cho phép giáo viên nhìn thấy đồng thời cột Miệng, 15 phút, 1 tiết, Thi học kỳ mà không cần phải cuộn ngang quá nhiều.
   * **Triển khai kỹ thuật**:
     ```dart
     OrientationBuilder(
       builder: (context, orientation) {
         final isLandscape = orientation == Orientation.landscape;
         if (isLandscape) {
           return Row(
             children: [
               AppNavigationRail(...),
               Expanded(child: FullGradeTableView(...)),
             ],
           );
         }
         return Scaffold(
           body: GradeCardListView(...),
           bottomNavigationBar: AppBottomNav(...),
         );
       },
     )
     ```

---

## 6. Checklist Kiểm Định UI/UX Thực Tế (Production-Grade)

Khi phát triển hoặc review giao diện màn hình mới, bắt buộc đối chiếu 8 tiêu chí:
* [x] **Zoom Test (Web)**: Đã test phóng to trình duyệt lên 150% và 200%, không bị văng lỗi `A RenderFlex overflowed`.
* [x] **Resize Test (Web)**: Co hẹp cửa sổ trình duyệt xuống 50% màn hình, thanh công cụ tự động xếp dòng (`Wrap`) mượt mà.
* [x] **Orientation Test (Mobile)**: Xoay ngang điện thoại, thanh nav đáy tự động ẩn/chuyển thành rail hẹp, bảng dữ liệu mở rộng tối đa.
* [x] **Touch Target (Mobile)**: Tất cả nút bấm, icon bấm được có diện tích tối thiểu $44 \times 48\text{ dp}$.
* [x] **Text Scaling Test**: Thiết lập cỡ chữ hệ thống $1.3\times$ đến $1.5\times$, nhãn và văn bản không bị cắt cụt (`TextOverflow.ellipsis` hoặc nhiều dòng).
* [x] **Bottom Inset Safety**: Bàn phím ảo xuất hiện không đè lên ô nhập liệu (`resizeToAvoidBottomInset: true`).
* [x] **Data Integrity**: Phân biệt chuẩn xác giữa `NULL` (chưa nhập/trống) và `0.0` (điểm liệt/điểm không thật).
* [x] **Color Consistency**: Sử dụng chính xác token màu chuẩn (`AppColors`), không tự ý hardcode mã màu lạ.
