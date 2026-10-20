# CHƯƠNG 4: PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG

---

## 4.1. TỔNG QUAN VÀ PHƯƠNG PHÁP TIẾP CẬN THIẾT KẾ

### 4.1.1. Mục tiêu và phạm vi thiết kế
Khóa luận xây dựng **"Hệ thống Quản lý Điểm có Nhận dạng Bảng điểm Viết tay"** phục vụ Trường THPT Bà Điểm. Mục tiêu của Chương 4 là chuyển hóa các yêu cầu khảo sát thực tế thành bản thiết kế kiến trúc phần mềm chuẩn mực, ổn định, mở rộng và bảo mật cao.

Phạm vi thiết kế giải quyết triệt để bài toán:
1. **Điểm nghẽn nhập liệu thủ công:** Thay thế việc giáo viên/giáo vụ phải nhìn bảng giấy và gõ tay hàng ngàn ô điểm mỗi học kỳ bằng công nghệ nhận dạng quang học hai kênh độc lập (**Kênh A: Điểm số** qua CRNN và **Kênh B: Điểm chữ** qua VietOCR).
2. **Bảo đảm an toàn pháp lý học đường:** Áp dụng nguyên tắc **Human-in-the-loop** (Máy chỉ đề xuất — Giáo viên có thẩm quyền mới chốt điểm), đối soát ba màu thông minh (🟢 Xanh, 🟡 Vàng, 🔴 Đỏ), khóa sổ tự động theo hạn chót (ADR-0014) và nhật ký kiểm toán bất biến (**Append-only**).
3. **Chuẩn hóa quy chế Bộ GD&ĐT:** Áp dụng bộ hệ số dùng chung học kỳ (ADR-0013: TX hệ số 1, GK hệ số 2, CK hệ số 3), phân nhánh môn tính điểm số và môn Đạt/Chưa đạt (ADR-0015: tỷ lệ đạt $\ge 50\%$).

### 4.1.2. Phương pháp tiếp cận
Chương này kết hợp hài hòa hai phương pháp luận chuẩn trong công nghệ phần mềm:
* **Phương pháp phân tích hướng chức năng và luồng dữ liệu (Structured Analysis):** Sử dụng sơ đồ phân rã chức năng (BFD) và sơ đồ luồng dữ liệu (DFD mức ngữ cảnh và mức 1) để cung cấp góc nhìn toàn cảnh về luân chuyển thông tin.
* **Phương pháp phân tích và thiết kế hướng đối tượng (OOAD):** Sử dụng ngôn ngữ mô hình hóa thống nhất (UML) gồm Use-Case (nghiệp vụ & hệ thống), Sơ đồ hoạt động (Activity), Sơ đồ tuần tự (Sequence), Sơ đồ trạng thái (State) và Sơ đồ quan hệ thực thể (ERD).

### 4.1.3. Kiến trúc hệ thống tổng thể (Modular Monolith + AI Worker)
Hệ thống được thiết kế theo mô hình **Modular Monolith** ở tầng nghiệp vụ Backend kết hợp **Worker bất đồng bộ** và **Dịch vụ AI tách riêng**.

![Hình 4.1: Kiến trúc Hệ thống Tổng thể](hinh/kien_truc_tong_the.png)
*Hình 4.1: Kiến trúc Hệ thống Tổng thể (Modular Monolith + AI Worker)*

* **Client đa nền tảng (Flutter):** Một codebase duy nhất phục vụ Web Browser, Android và iOS. Client không kết nối trực tiếp CSDL hay S3 mà đi qua REST API `/api/v1` sinh từ OpenAPI.
* **API Backend (NestJS + TypeScript):** Kiến trúc module theo miền nghiệp vụ (`identity`, `authorization`, `academic-years`, `students`, `classes`, `subjects`, `teachers`, `gradebooks`, `recognition`, `review`, `final-results`, `reports`, `audit`, `files`).
* **Hàng đợi tác vụ (Redis + BullMQ):** Đảm bảo xử lý nhận dạng ảnh dạng bất đồng bộ, phản hồi nhanh mã `202 Accepted` cho Client, chống nghẽn đường truyền HTTP.
* **Recognition Service (Python FastAPI):** Chuyên trách pipeline thị giác máy tính: nắn ảnh 2 giai đoạn, tách lưới, chạy mô hình CRNN và VietOCR.
* **Hạ tầng dữ liệu:** PostgreSQL 16 lưu trữ 16 bảng nghiệp vụ chuẩn 3NF; MinIO/S3 lưu trữ ảnh gốc và ảnh ô cắt sau khi tách lưới.

---

## 4.2. KHẢO SÁT VÀ PHÂN TÍCH USE-CASE NGHIỆP VỤ (BUSINESS USE-CASE)

### 4.2.1. Bối cảnh nghiệp vụ tại Trường THPT Bà Điểm
Quy trình chấm bài và ghi điểm tại trường phổ thông trải qua nhiều bộ phận: Giáo viên bộ môn (GVBM), Giáo viên chủ nhiệm (GVCN), Giáo vụ (NVGV) và Ban giám hiệu / Tổ trưởng chuyên môn (TTCM). Bảng điểm giấy theo quy chuẩn luôn có hai cột bắt buộc: Điểm số (0.0 đến 10.0) và Điểm chữ (viết bằng chữ tiếng Việt).

### 4.2.2. Sơ đồ Use-Case Nghiệp vụ
Sơ đồ mô tả 6 ca nghiệp vụ đời thực ngoài đời khi chưa có hệ thống tự động:

![Hình 4.2: Sơ đồ Use-Case Nghiệp vụ thực tế](hinh/use_case_nghiep_vu.png)
*Hình 4.2: Sơ đồ Use-Case Nghiệp vụ thực tế tại Trường THPT Bà Điểm*

* **BUC1: Chấm bài và ghi điểm vào bảng điểm giấy:** GVBM chấm bài kiểm tra và ghi song song hai cột Điểm số và Điểm chữ lên tờ giấy A4 in sẵn danh sách học sinh.
* **BUC2: Nộp và tiếp nhận bảng điểm:** GVBM nộp bảng điểm giấy cho bộ phận giáo vụ kiểm tra chữ ký và số lượng bài.
* **BUC3: Nhập điểm vào phần mềm quản lý (⚠️ ĐIỂM NGHẼN NGHIỆP VỤ):** Giáo vụ hoặc GVBM phải nhìn bảng giấy và gõ tay từng con số vào phần mềm. Quá trình này mệt mỏi thị giác, tốn hàng chục giờ và là nguyên nhân chính dẫn đến sai sót nhầm số hoặc lệch dòng.
* **BUC4: Đối chiếu và ký duyệt bảng điểm:** Giáo vụ in bản kiểm dò ra giấy, cùng GVBM và Tổ trưởng chuyên môn dò mắt từng dòng đối chiếu với bảng gốc rồi ký xác nhận.
* **BUC5: Tổng kết học kỳ và xếp loại:** Phần mềm tính điểm trung bình môn, điểm trung bình các môn và phân loại học lực.
* **BUC6: Công bố kết quả cho học sinh và phụ huynh:** GVCN gửi bảng điểm về cho phụ huynh và học sinh theo dõi.

### 4.2.3. So sánh Quy trình Hiện tại vs Quy trình Đề xuất

![Hình 4.3: So sánh Quy trình Hiện tại vs Quy trình Đề xuất](hinh/12_luong_so_sanh_hien_tai_vs_de_xuat.png)
*Hình 4.3: So sánh Quy trình Hiện tại (Thủ công) và Quy trình Đề xuất (Ứng dụng AI & Đối soát 3 màu)*

* **Quy trình Hiện tại:** Ghi điểm giấy $\rightarrow$ Nộp giáo vụ $\rightarrow$ **Gõ tay từng ô (Điểm nghẽn)** $\rightarrow$ In bản kiểm dò đối chiếu mắt $\rightarrow$ Ký duyệt sổ điểm.
* **Quy trình Đề xuất:** Ghi điểm giấy $\rightarrow$ **Chụp ảnh tải lên** $\rightarrow$ **Máy tự động nhận dạng 2 kênh (CRNN + VietOCR) & chấm tin cậy** $\rightarrow$ **Soát ba màu thông minh (GV chỉ cần soi 15% dòng Vàng/Đỏ trong 2 phút)** $\rightarrow$ Duyệt nguyên tử, tự động tổng kết và xuất Excel.

---

## 4.3. SƠ ĐỒ PHÂN RÃ CHỨC NĂNG (BFD — BUSINESS FUNCTION DECOMPOSITION)

Sơ đồ BFD thể hiện cây phân rã phân cấp toàn bộ chức năng của hệ thống gồm **6 phân hệ mức 1** và **46 chức năng con chi tiết mức 2**.

![Hình 4.4: Sơ đồ Phân rã Chức năng BFD](hinh/phan_ra_chuc_nang_bfd.png)
*Hình 4.4: Sơ đồ Phân rã Chức năng BFD (6 phân hệ, 46 chức năng con)*

### Đặc tả chi tiết 6 phân hệ và 46 chức năng con:
1. **Phân hệ 1: Quản lý tài khoản và xác thực (7 chức năng con):**
   * *1.1 Đăng nhập:* Xác thực SĐT (10 số) và mật khẩu băm Argon2id; phát hành Access Token JWT và Refresh Token.
   * *1.2 Đăng xuất:* Thu hồi Token, hủy phiên làm việc.
   * *1.3 Xem/cập nhật hồ sơ:* Xem thông tin cá nhân. Khóa quyền tự đổi họ tên của giáo viên và học sinh.
   * *1.4 Đổi mật khẩu:* Cho phép QTV và GV đổi mật khẩu định kỳ; khóa quyền đổi mật khẩu của học sinh.
   * *1.5 Quản lý tài khoản:* QTV CRUD tài khoản cán bộ giáo viên và học sinh.
   * *1.6 Khóa/mở tài khoản:* QTV vô hiệu hóa tài khoản khi có sự cố.
   * *1.7 Phân quyền người dùng:* Gán vai trò RBAC (`QUAN_TRI_VIEN`, `GIAO_VIEN`, `HOC_SINH`).
2. **Phân hệ 2: Quản lý danh mục học tập & Phân công (8 chức năng con + Thời khóa biểu):**
   * *2.1 Quản lý năm học:* Thiết lập niên khóa (ví dụ: 2026–2027).
   * *2.2 Quản lý học kỳ:* Học kỳ 1 & Học kỳ 2; cờ kích hoạt công bố điểm.
   * *2.3 Quản lý lớp học:* Danh mục lớp theo khối $10, 11, 12$ và sĩ số.
   * *2.4 Quản lý học sinh:* Hồ sơ cá nhân và phân lớp theo năm học.
   * *2.5 Quản lý giáo viên:* Danh mục giáo viên và tổ bộ môn.
   * *2.6 Quản lý môn học:* Danh mục môn học trong trường.
   * *2.7 Quản lý cột điểm & hệ số (ADR-0013):* Bộ hệ số dùng chung toàn trường (TX: 1, GK: 2, CK: 3); khóa sửa khi học kỳ có điểm chốt.
   * *2.8 Phân công giảng dạy:* Gán Giáo viên + Lớp + Môn + Học kỳ (tiền đề kiểm tra ABAC).
   * *(Mở rộng)* *Quản lý Thời khóa biểu:* QTV CRUD lịch dạy/học, kiểm tra xung đột phòng/tiết; GV xem lịch dạy; HS xem lịch học (ẩn thông tin phòng).
3. **Phân hệ 3: Quản lý bảng điểm & Nhập tay (7 chức năng con):**
   * *3.1 Tạo bảng điểm:* Sinh tự động theo bộ ba `(lớp, môn, học kỳ)`.
   * *3.2 Tạo lưới điểm sĩ số:* Sinh ma trận ô điểm cho học sinh; **giá trị ban đầu là `NULL`**.
   * *3.3 Nhập điểm thủ công:* Giáo viên nhập điểm kiểm tra miệng, 15 phút trực tiếp trên web/mobile.
   * *3.4 Sửa điểm:* Điều chỉnh điểm trong thời hạn mở cột.
   * *3.5 Xem lịch sử sửa điểm:* Truy vết nhật ký **Append-only** (cấm xóa/sửa).
   * *3.6 Theo dõi trạng thái bảng:* `DANG_NHAP_LIEU` hoặc `DA_CHOT`.
   * *3.7 Khóa sổ tự động theo hạn chót (ADR-0014):* Hết hạn deadline, tự điền $0.0$ cho ô thiếu của HS đang học, khóa cột, tất cả cột khóa chuyển bảng sang `DA_CHOT`.
4. **Phân hệ 4: Nhận dạng bảng điểm từ ảnh (9 chức năng con):**
   * *4.1 Chọn bảng điểm & cột điểm:* Xác định đích ghi điểm.
   * *4.2 Tải ảnh bảng điểm:* Tải ảnh chụp bảng điểm A4 lên hệ thống.
   * *4.3 Kiểm tra định dạng & SHA-256:* Kiểm tra MIME, dung lượng $\le 10\text{ MB}$, mã băm SHA-256 chống tải trùng.
   * *4.4 Nắn ảnh & Chốt chặn số dòng:* Nắn phối cảnh 2 giai đoạn. **Chốt chặn:** so sánh $N_{detected} == N_{declared}$; nếu lệch lập tức gán `LOI` và dừng xử lý, loại trừ rủi ro lệch dòng học sinh.
   * *4.5 Tách ảnh từng ô điểm:* Cắt ô Điểm số và ô Điểm chữ, lưu vào MinIO.
   * *4.6 Nhận dạng Kênh Điểm số:* CRNN đọc chuỗi số thực và xuất độ tin cậy $Conf_A$.
   * *4.7 Nhận dạng Kênh Điểm chữ:* VietOCR đọc chữ viết tay tiếng Việt; tra từ điển `tu_dien_diem_chu` chuẩn hóa thành số thực $Val_B$ và $Conf_B$.
   * *4.8 So sánh kết quả 2 kênh:* Đối chiếu chéo $Val_A$ và $Val_B$.
   * *4.9 Đánh giá độ tin cậy:* Phân loại 3 mức Xanh (tự động chấp nhận), Vàng (cần rà soát), Đỏ (từ chối nhận dạng/nhập tay).
5. **Phân hệ 5: Đối chiếu và duyệt kết quả (8 chức năng con):**
   * *5.1 Xem ảnh ô điểm:* Hiển thị ảnh ô cắt gốc phóng to cạnh kết quả máy.
   * *5.2 Xem kết quả hai kênh:* Thể hiện đồng thời kết quả Kênh A, Kênh B và độ tin cậy.
   * *5.3 Lọc thông minh 3 màu:* Ưu tiên dòng 🟡 Vàng và 🔴 Đỏ lên đầu trang; thu gọn dòng 🟢 Xanh.
   * *5.4 Sửa giá trị máy đọc:* Giáo viên nhấp chọn kênh đúng hoặc tự gõ điểm.
   * *5.5 Chọn điểm cuối cùng:* Xác nhận điểm chốt từng dòng học sinh.
   * *5.6 Duyệt phiếu nhận dạng:* Kiểm tra $100\%$ dòng đã được quyết định.
   * *5.7 Ghi điểm đã duyệt nguyên tử:* Cập nhật `diem_thanh_phan` `DA_DUYET` trong một **Atomic Transaction** (All-or-Nothing).
   * *5.8 Ghi lịch sử & người duyệt:* Đóng dấu người duyệt, thời điểm duyệt và ghi vết `lich_su_sua_diem`.
6. **Phân hệ 6: Tổng kết kết quả học tập & Báo cáo (7 chức năng con):**
   * *6.1 Kiểm tra điểm đã duyệt:* Mọi điểm bắt buộc phải khác `NULL` và ở trạng thái `DA_DUYET`.
   * *6.2 Tính điểm theo hệ số:* Áp dụng công thức ĐTB môn có trọng số (ADR-0013) hoặc tính tỷ lệ đạt $\ge 50\%$ (ADR-0015).
   * *6.3 Làm tròn điểm:* Làm tròn toán học đến 1 chữ số thập phân.
   * *6.4 Xếp loại kết quả:* Phân loại Giỏi, Khá, Đạt, Chưa đạt.
   * *6.5 Lưu kết quả & Snapshot:* Lưu bản ghi `ket_qua_tong_ket` kèm bản sao cấu hình hệ số JSONB (`bo_he_so`).
   * *6.6 Công bố & Tra cứu điểm:* QTV công bố học kỳ $\rightarrow$ Học sinh tra cứu điểm cá nhân.
   * *6.7 Thống kê & Xuất Excel:* Thống kê phổ điểm lớp và kết xuất bảng điểm chuẩn `.xlsx`.

---

## 4.4. MÔ HÌNH HÓA USE-CASE HỆ THỐNG (SYSTEM USE-CASE MODELING)

### 4.4.1. Tác nhân hệ thống
* **👤 Quản trị viên (`QUAN_TRI_VIEN`):** Thiết lập tài khoản, danh mục, phân quyền, cấu hình deadline, công bố học kỳ, xem báo cáo toàn trường.
* **👤 Giáo viên (`GIAO_VIEN`):** Thao tác trên bảng điểm lớp–môn được phân công (nhập tay, tải ảnh OCR, đối chiếu duyệt điểm, tính tổng kết, xuất Excel).
* **👤 Học sinh (`HOC_SINH`):** Tra cứu điểm thành phần và kết quả tổng kết của bản thân sau khi công bố.
* **🤖 Dịch vụ Nhận dạng (AI Service):** Tác nhân hệ thống thực thi tác vụ OCR hai kênh bất đồng bộ.

### 4.4.2. Sơ đồ Use-Case Hệ thống Tổng quát

![Hình 4.5: Sơ đồ Use-Case Hệ thống mức Tổng quát](hinh/use_case_tong_quat.png)
*Hình 4.5: Sơ đồ Use-Case Hệ thống mức Tổng quát (6 nhóm chức năng)*

### 4.4.3. Sơ đồ Use-Case Hệ thống Chi tiết (UC01 – UC18)

![Hình 4.6: Sơ đồ Use-Case Hệ thống Chi tiết](hinh/use_case_chi_tiet.png)
*Hình 4.6: Sơ đồ Use-Case Hệ thống Chi tiết (18 Ca sử dụng chính thức UC01 – UC18)*

### 4.4.4. Đặc tả chi tiết các Use-Case trọng yếu

#### 1. Đặc tả UC09 — Quản lý bảng điểm lớp – môn
* **Tác nhân:** Giáo viên bộ môn (thao tác), Quản trị viên (chỉ xem).
* **Tiền điều kiện:** Giáo viên đã đăng nhập; bảng điểm tồn tại và giáo viên có phân công giảng dạy hợp lệ.
* **Luồng sự kiện chính:**
  1. Giáo viên chọn Lớp, Môn và Học kỳ cần quản lý.
  2. Hệ thống kiểm tra phân công ABAC và kiểm tra trạng thái bảng điểm (`DANG_NHAP_LIEU` hay `DA_CHOT`).
  3. Hệ thống tải lưới điểm của học sinh: hiển thị các điểm đã duyệt, điểm chờ đối chiếu hoặc `NULL`.
  4. Giáo viên chọn nhập tay từng ô hoặc chuyển sang tính năng tải ảnh nhận dạng (UC11).
* **Hậu điều kiện:** Điểm được cập nhật và kiểm soát theo thời hạn mở/đóng cột điểm.

#### 2. Đặc tả UC11 — Tải ảnh và nhận diện bảng điểm viết tay («include» UC12)
* **Tác nhân:** Giáo viên bộ môn, Dịch vụ AI nhận dạng.
* **Tiền điều kiện:** Giáo viên có phân công hợp lệ; bảng điểm ở trạng thái `DANG_NHAP_LIEU` và cột điểm đang mở.
* **Luồng sự kiện chính:**
  1. Giáo viên chọn bảng điểm, cột điểm cần nhập và nhập số dòng khai báo $N_{declared}$.
  2. Giáo viên tải ảnh chụp bảng điểm A4 lên hệ thống.
  3. API kiểm tra MIME, dung lượng, tính mã băm SHA-256 (từ chối ảnh trùng).
  4. Hệ thống lưu ảnh gốc vào MinIO, tạo bản ghi `phieu_nhan_dien` (`DANG_XU_LY`), đẩy job vào BullMQ và trả về mã `202 Accepted` cùng `jobId`.
  5. Worker BullMQ thực thi: nắn phối cảnh 2 giai đoạn $\rightarrow$ tách khung lưới $\rightarrow$ đếm số dòng phát hiện $N_{detected}$.
  6. **Chốt chặn số dòng:** So sánh $N_{detected} == N_{declared}$. Nếu lệch, đổi trạng thái phiếu thành `LOI` và báo lỗi cho giáo viên.
  7. Worker cắt ảnh từng ô, đo mật độ mực (nếu ô trống gán nhãn ĐỎ, không gọi mô hình).
  8. Chạy song song Kênh A (CRNN số) và Kênh B (VietOCR chữ).
  9. Giải mã ràng buộc từ điển `tu_dien_diem_chu` và đối chiếu chéo hai kênh («include» UC12).
  10. Phân loại 3 mức Xanh/Vàng/Đỏ; lưu toàn bộ kết quả vào `ket_qua_dong`; đổi trạng thái phiếu thành `CHO_DOI_CHIEU`.
* **Ngoại lệ:** Ảnh mờ, gập góc, lệch lưới $\rightarrow$ Phiếu gán trạng thái `LOI`.

#### 3. Đặc tả UC13 — Đối chiếu và duyệt kết quả nhận diện
* **Tác nhân:** Giáo viên bộ môn.
* **Tiền điều kiện:** Phiếu nhận diện ở trạng thái `CHO_DOI_CHIEU`.
* **Luồng sự kiện chính:**
  1. Giáo viên mở phiếu điểm cần rà soát.
  2. Hệ thống tải danh sách dòng kèm ảnh ô cắt (Presigned URL) và hiển thị theo giao diện so sánh song song Side-by-side.
  3. Hệ thống tự động ưu tiên lọc dòng 🟡 Vàng và 🔴 Đỏ lên đầu trang, thu gọn dòng 🟢 Xanh.
  4. Giáo viên nhìn ảnh ô cắt gốc để chọn giá trị kênh đúng hoặc tự sửa tay.
  5. Hệ thống kiểm tra hợp lệ điểm số trong miền $[0.0, 10.0]$, bước $0.1$.
  6. Giáo viên bấm **"DUYỆT PHIẾU"**.
  7. Hệ thống kiểm tra $100\%$ dòng đã có điểm chốt.
  8. Hệ thống mở một **Atomic Database Transaction**:
     * Ghi giá trị chốt vào `diem_thanh_phan`, trạng thái `DA_DUYET`.
     * Ghi bản ghi kiểm toán vào `lich_su_sua_diem` (Append-only).
     * Đóng dấu người duyệt, thời điểm duyệt lên phiếu và kết quả dòng.
     * Chuyển trạng thái phiếu sang `DA_DUYET`.
* **Ngoại lệ:** Còn dòng chưa quyết định $\rightarrow$ Chặn duyệt, cuộn tới dòng thiếu; Lỗi DB $\rightarrow$ Rollback toàn bộ.

#### 4. Đặc tả UC14 — Tính điểm tổng kết («include» UC15)
* **Tác nhân:** Giáo viên bộ môn.
* **Tiền điều kiện:** Tất cả các cột điểm bắt buộc của học sinh phải có giá trị khác `NULL` và đang ở trạng thái `DA_DUYET`.
* **Luồng sự kiện chính:**
  1. Giáo viên chọn Lớp – Môn – Học kỳ và bấm lệnh "Tính tổng kết".
  2. Hệ thống kiểm tra điều kiện điểm hợp lệ.
  3. Hệ thống tải bộ hệ số học kỳ (TX: 1, GK: 2, CK: 3 theo ADR-0013).
  4. Phân nhánh môn tính điểm số (ĐTB có trọng số) hoặc môn Đạt/Chưa đạt (tỷ lệ đạt $\ge 50\%$ theo ADR-0015).
  5. Làm tròn kết quả toán học đến 1 chữ số thập phân.
  6. Xếp loại học lực môn («include» UC15).
  7. Lưu kết quả vào `ket_qua_tong_ket` kèm bản sao cấu hình hệ số JSONB (`bo_he_so`).
* **Ngoại lệ:** Còn học sinh thiếu điểm $\rightarrow$ Cảnh báo danh sách học sinh và dừng quy trình.

### 4.4.5. Ma trận phân quyền chức năng RBAC

### Bảng 4.1: Ma trận phân quyền tác nhân × Use Case chi tiết

| Nhóm Use-Case | Mã UC | Tên Ca sử dụng | QTV | GV | HS | Cơ chế kiểm soát bổ sung |
|:---|:---:|:---|:---:|:---:|:---:|:---|
| **Cơ bản** | **UC01** | Đăng nhập hệ thống | ● | ● | ● | Rate-limiting chống brute-force |
| | **UC02** | Đăng xuất hệ thống | ● | ● | ● | Thu hồi Refresh Token |
| | **UC03** | Quản lý tài khoản | ● | ◐ | ◐ | GV & HS không được tự đổi họ tên |
| | **UC04** | Phân quyền vai trò | ● | — | — | Chỉ QTV tối cao thực hiện |
| **Danh mục** | **UC05** | Quản lý học sinh | ● | ○ | — | QTV quản lý hồ sơ toàn trường |
| | **UC06** | Quản lý lớp học | ● | ○ | — | QTV phân lớp |
| | **UC07** | Quản lý môn & hệ số | ● | ○ | — | Khóa sửa hệ số khi kỳ có điểm chốt |
| | **UC08** | Phân công giảng dạy | ● | ○ | — | Tiền đề kiểm tra ABAC |
| **Bảng điểm** | **UC09** | Quản lý bảng điểm | ○ | ◐ | — | **Bất biến:** QTV không sửa điểm; GV chỉ sửa lớp được phân công |
| | **UC10** | Lịch sử sửa điểm | ○ | ○ | — | Nhật ký kiểm toán Append-only |
| **Nhận diện** | **UC11** | Tải ảnh nhận diện | — | ◐ | — | Kiểm tra phân công ABAC |
| | **UC12** | Đánh giá tin cậy | — | ◐ | — | Phân loại 3 mức Xanh/Vàng/Đỏ |
| **Đối chiếu** | **UC13** | Đối chiếu và duyệt | — | ◐ | — | Giao dịch nguyên tử trong Transaction |
| **Tổng kết** | **UC14** | Tính điểm tổng kết | ○ | ◐ | — | Chỉ tính khi điểm đã `DA_DUYET` |
| | **UC15** | Xếp loại kết quả | ○ | ◐ | — | Phụ thuộc kết quả UC14 |
| | **UC16** | Thống kê điểm | ● | ◐ | — | QTV xem toàn trường, GV xem lớp phụ trách |
| | **UC17** | Xuất báo cáo Excel | ● | ◐ | — | Xuất tệp `.xlsx` chuẩn mẫu |
| | **UC18** | Tra cứu điểm cá nhân | — | — | ● | **Bất biến:** HS chỉ xem điểm của chính mình sau công bố |

*(Ký hiệu: `●` Toàn quyền; `◐` Quyền giới hạn theo phạm vi phụ trách ABAC; `○` Chỉ xem; `—` Không có quyền)*

---

## 4.5. SƠ ĐỒ LUỒNG DỮ LIỆU (DATA FLOW DIAGRAM — DFD)

### 4.5.1. DFD Mức ngữ cảnh (Context Diagram — Level 0)
Sơ đồ mô tả ranh giới hệ thống cùng 5 thực thể ngoại vi tương tác trực tiếp:

![Hình 4.7: Sơ đồ Luồng Dữ liệu Mức Ngữ cảnh](hinh/dfd_muc_ngu_canh.png)
*Hình 4.7: Sơ đồ Luồng Dữ liệu Mức Ngữ cảnh (Context Diagram — DFD Level 0)*

* **👤 Quản trị viên:** Cung cấp tài khoản, danh mục, phân công, hạn chót $\leftrightarrow$ Nhận báo cáo toàn trường, nhật ký hệ thống.
* **👤 Giáo viên:** Cung cấp điểm nhập tay, ảnh bảng điểm, xác nhận duyệt $\leftrightarrow$ Nhận lưới điểm, danh sách phân công, ảnh ô cắt + gợi ý AI, tệp Excel.
* **👤 Học sinh:** Gửi yêu cầu tra cứu $\leftrightarrow$ Nhận điểm thành phần, ĐTB môn, xếp loại (sau công bố).
* **🤖 Dịch vụ AI:** Nhận ảnh bảng điểm $\leftrightarrow$ Trả kết quả 2 kênh (số/chữ) và độ tin cậy.
* **☁️ Kho MinIO:** Tiếp nhận ảnh gốc và ảnh ô cắt $\leftrightarrow$ Cung cấp Presigned URL ảnh hiển thị đối chiếu.

### 4.5.2. DFD Mức 1 (Level 1 DFD)
Sơ đồ phân rã tiến trình gốc thành 6 tiến trình nghiệp vụ tương tác với 6 kho dữ liệu và kho đối tượng:

![Hình 4.8: Sơ đồ Luồng Dữ liệu Mức 1](hinh/dfd_muc_1.png)
*Hình 4.8: Sơ đồ Luồng Dữ liệu Mức 1 (Level 1 Data Flow Diagram)*

* **Tiến trình 1.0 (Xác thực & Phân quyền):** Đọc/ghi tài khoản, phiên làm việc với kho **`D1: nguoi_dung`**.
* **Tiến trình 2.0 (QL Danh mục & Phân công):** CRUD danh mục trường học với kho **`D2: hoc_sinh, lop, mon_hoc, phan_cong`**.
* **Tiến trình 3.0 (QL Bảng điểm & Nhập tay):** Đọc/ghi ô điểm với kho **`D3: bang_diem, diem_thanh_phan`**; ghi vết sửa điểm vào kho **`D5: lich_su_sua_diem`**.
* **Tiến trình 4.0 (Nhận dạng & Phân loại 3 màu):** Đẩy ảnh gốc vào kho **`OBJ: MinIO`**; gửi job sang Dịch vụ AI; nhận kết quả 2 kênh và lưu thông tin phiếu cùng kết quả dòng vào kho **`D4: phieu_nhan_dien, ket_qua_dong`**.
* **Tiến trình 5.0 (Đối chiếu & Duyệt điểm nguyên tử):** Đọc kết quả dòng từ **`D4`** và lấy ảnh ô cắt từ **`OBJ`**; ghi nhận điểm chính thức `DA_DUYET` vào **`D3`**, ghi log vào **`D5`**, đổi trạng thái phiếu trong **`D4`**.
* **Tiến trình 6.0 (Tổng kết, Thống kê & Báo cáo):** Đọc điểm `DA_DUYET` từ **`D3`** và hệ số từ **`D2`**; lưu kết quả vào **`D6: ket_qua_tong_ket`**; xuất báo cáo cho GV/QTV; trả kết quả tra cứu cho Học sinh.

---

## 4.6. SƠ ĐỒ HOẠT ĐỘNG VÀ LUỒNG VẬN HÀNH CÁC CHỨC NĂNG (ACTIVITY DIAGRAMS)

### 4.6.1. Luồng hoạt động nghiệp vụ tổng thể toàn hệ thống
Phản ánh toàn diện quy trình vận hành từ đầu năm học đến khi kết thúc học kỳ:

![Hình 4.9: Sơ đồ Luồng Hoạt động Nghiệp vụ Tổng thể](hinh/01_luong_nghiep_vu_tong_the.png)
*Hình 4.9: Sơ đồ Luồng Hoạt động Nghiệp vụ Tổng thể Toàn hệ thống*

### 4.6.2. Luồng hoạt động Phân hệ 1: Xác thực & Phân quyền người dùng
Kiểm tra đăng nhập Argon2id, rate-limit, cấp phát JWT và phân luồng RBAC cho 3 vai trò:

![Hình 4.10: Sơ đồ Luồng Xác thực và Phân quyền](hinh/02_luong_xac_thuc_phan_quyen.png)
*Hình 4.10: Sơ đồ Luồng Xác thực và Phân quyền Người dùng*

### 4.6.3. Luồng hoạt động Phân hệ 2: Danh mục học tập & Phân công giảng dạy
Khởi tạo niên khóa, lớp, môn, cấu hình hệ số chung (ADR-0013), gán giáo viên bộ môn và sinh bảng điểm khởi tạo `NULL`:

![Hình 4.11: Sơ đồ Luồng Danh mục và Phân công](hinh/03_luong_danh_muc_phan_cong.png)
*Hình 4.11: Sơ đồ Luồng Quản lý Danh mục và Phân công Giảng dạy*

### 4.6.4. Luồng hoạt động Phân hệ 3: Bảng điểm & Nhập điểm thủ công
Kiểm tra phân công ABAC, kiểm tra hạn chót mở cột, kiểm tra điểm $0.0 - 10.0$ và ghi vết lịch sử Append-only:

![Hình 4.12: Sơ đồ Luồng Nhập điểm Thủ công](hinh/04_luong_nhap_sua_diem_thu_cong.png)
*Hình 4.12: Sơ đồ Luồng Quản lý Bảng điểm và Nhập điểm Thủ công*

### 4.6.5. Luồng hoạt động Phân hệ 4: Pipeline nhận dạng ảnh bảng điểm (AI Worker)
Tải ảnh, SHA-256 chống trùng, nắn phối cảnh 2 giai đoạn, tách lưới, **Chốt chặn số dòng** ($N_{detected} == N_{declared}$), kiểm tra mật độ mực ô, suy luận Kênh A (CRNN) & Kênh B (VietOCR), đối chiếu chéo và phân loại 3 màu:

![Hình 4.13: Sơ đồ Pipeline Nhận dạng ảnh](hinh/05_luong_pipeline_nhan_dang_anh.png)
*Hình 4.13: Sơ đồ Pipeline Nhận dạng Ảnh Bảng điểm (AI Worker)*

### 4.6.6. Thuật toán phân loại 3 mức tin cậy Xanh – Vàng – Đỏ
Cây quyết định phân loại toán học dựa trên kết quả 2 kênh độc lập:

![Hình 4.14: Sơ đồ Thuật toán Phân loại 3 Mức tin cậy](hinh/11_luong_quyet_dinh_phan_loai_3_mau.png)
*Hình 4.14: Sơ đồ Thuật toán Quyết định Phân loại 3 Mức Tin cậy (🟢 Xanh, 🟡 Vàng, 🔴 Đỏ)*

* **🟢 Mức XANH (Tự động chấp nhận — Độ chính xác $\ge 99.8\%$):** Hai kênh độc lập khớp nhau hoàn toàn ($Val_A == Val_B$) VÀ độ tin cậy vượt ngưỡng an toàn ($Conf_A \ge \tau_A \land Conf_B \ge \tau_B$). Chiếm $\sim 85\%$ số dòng; giáo viên chỉ nhìn lướt xác nhận.
* **🟡 Mức VÀNG (Cần kiểm tra):** Khớp nhưng độ tin cậy thấp, hoặc chỉ 1 kênh đọc được, hoặc hai kênh mâu thuẫn ($Val_A \neq Val_B$). Chiếm $\sim 15\%$ số dòng; giáo viên nhìn ảnh ô cắt gốc để chọn giá trị đúng.
* **🔴 Mức ĐỎ (Từ chối nhận dạng):** Ô trống hoặc cả 2 kênh đều không đọc được. Hệ thống kiên quyết không gợi ý giá trị tùy tiện; giáo viên bắt buộc tự nhập điểm.

### 4.6.7. Luồng hoạt động Phân hệ 5: Đối chiếu & Duyệt điểm nguyên tử
Giao diện Side-by-side, ưu tiên dòng Vàng/Đỏ, kiểm tra $100\%$ dòng, commit giao dịch CSDL nguyên tử:

![Hình 4.15: Sơ đồ Luồng Đối chiếu và Duyệt điểm Nguyên tử](hinh/06_luong_doi_chieu_duyet_diem.png)
*Hình 4.15: Sơ đồ Luồng Đối chiếu và Duyệt điểm Nguyên tử (Human-in-the-loop)*

### 4.6.8. Luồng hoạt động Tự động khóa sổ theo hạn chót (ADR-0014)
Cron kiểm tra deadline, tự điền $0.0$ cho ô thiếu của học sinh đang học kèm log, hủy đề xuất phiếu OCR chưa duyệt, khóa cột $\rightarrow$ khóa bảng `DA_CHOT`:

![Hình 4.16: Sơ đồ Luồng Tự động Khóa sổ theo Hạn chót](hinh/07_luong_tu_dong_khoa_so_deadline.png)
*Hình 4.16: Sơ đồ Luồng Tự động Khóa sổ theo Hạn chót (ADR-0014)*

### 4.6.9. Luồng hoạt động Phân hệ 6: Tổng kết kết quả học tập & Xếp loại
Kiểm tra điểm bắt buộc `DA_DUYET`, áp dụng hệ số chung học kỳ, tính ĐTB môn hoặc tỷ lệ Đạt $\ge 50\%$, làm tròn 1 chữ số thập phân, xếp loại, lưu snapshot JSONB, QTV công bố học kỳ:

![Hình 4.17: Sơ đồ Luồng Tính điểm Tổng kết và Xếp loại](hinh/08_luong_tong_ket_va_xep_loai.png)
*Hình 4.17: Sơ đồ Luồng Tính điểm Tổng kết và Xếp loại Học tập*

### 4.6.10. Luồng hoạt động Tra cứu điểm cá nhân của Học sinh
Kiểm tra công bố học kỳ, bảo mật chống IDOR (`ma_hoc_sinh == Session.ma_hoc_sinh`), xem điểm thành phần và xếp loại môn:

![Hình 4.18: Sơ đồ Luồng Tra cứu Điểm của Học sinh](hinh/09_luong_tra_cuu_diem_hoc_sinh.png)
*Hình 4.18: Sơ đồ Luồng Tra cứu Điểm Cá nhân của Học sinh*

### 4.6.11. Luồng hoạt động Quản lý và Tra cứu Thời khóa biểu
QTV tạo/sửa lịch, kiểm tra xung đột tiết dạy và phòng học; GV xem lịch dạy; HS xem lịch học lớp (ẩn thông tin phòng):

![Hình 4.19: Sơ đồ Luồng Quản lý Thời khóa biểu](hinh/10_luong_quan_ly_thoi_khoa_bieu.png)
*Hình 4.19: Sơ đồ Luồng Quản lý và Tra cứu Thời khóa biểu*

---

## 4.7. SƠ ĐỒ TUẦN TỰ CHO CÁC CA SỬ DỤNG TRỌNG YẾU (SEQUENCE DIAGRAMS)

### 4.7.1. Sơ đồ tuần tự UC11: Tải ảnh và Nhận diện bảng điểm
Tương tác động giữa `ManHinhTaiAnh` (Boundary), `DieuKhienNhanDien` (Control), `XuLyAnh` (Control), `DichVuNhanDang` (Service), `PhieuNhanDien` (Entity) và `KetQuaDong` (Entity):

![Hình 4.20: Sơ đồ Tuần tự UC11 — Tải ảnh và Nhận diện](hinh/sequence_uc11_nhan_dien.png)
*Hình 4.20: Sơ đồ Tuần tự UC11: Tải ảnh và Nhận diện Bảng điểm*

* Điểm nhấn: Kiểm tra chốt chặn số đường kẻ $N_{detected} \neq N_{declared} \rightarrow$ gán cờ `LOI` dừng xử lý; chạy 2 kênh song song; giải mã từ điển và phân loại 3 màu.

### 4.7.2. Sơ đồ tuần tự UC13: Đối chiếu và Duyệt điểm nguyên tử
Tương tác giữa `ManHinhDoiChieu`, `DieuKhienDoiChieu`, `KetQuaDong`, `DiemThanhPhan`, `LichSuSuaDiem` trong giao dịch nguyên tử:

![Hình 4.21: Sơ đồ Tuần tự UC13 — Đối chiếu và Duyệt điểm](hinh/sequence_uc13_doi_chieu.png)
*Hình 4.21: Sơ đồ Tuần tự UC13: Đối chiếu và Duyệt điểm Nguyên tử*

* Điểm nhấn: Kiểm tra $100\%$ dòng đã có điểm chốt; bọc toàn bộ thao tác ghi điểm, ghi log kiểm toán, đóng dấu duyệt trong một Atomic Transaction (All-or-Nothing).

---

## 4.8. THIẾT KẾ CƠ SỞ DỮ LIỆU VÀ SƠ ĐỒ QUAN HỆ THỰC THỂ (ERD)

### 4.8.1. Sơ đồ quan hệ thực thể (ERD 16 bảng nghiệp vụ)
Cơ sở dữ liệu quan hệ được thiết kế chuẩn hóa 3NF trên hệ quản trị PostgreSQL gồm 16 bảng nghiệp vụ:

![Hình 4.22: Sơ đồ Quan hệ Thực thể ERD](hinh/erd_16_bang.png)
*Hình 4.22: Sơ đồ Quan hệ Thực thể ERD (16 Bảng Nghiệp vụ Chuẩn 3NF)*

### 4.8.2. Đặc tả chi tiết 16 bảng nghiệp vụ theo 5 cụm chức năng

#### Cụm 1: Quản trị người dùng và Định danh
1. **`NGUOI_DUNG`:** Lưu trữ tài khoản định danh người dùng:
   * `ma_nguoi_dung` (PK, int), `ten_dang_nhap` (UK, varchar - SĐT 10 chữ số), `mat_khau_ma_hoa` (varchar - Argon2id), `vai_tro` (enum: `QUAN_TRI_VIEN`, `GIAO_VIEN`, `HOC_SINH`), `trang_thai` (enum: `HOAT_DONG`, `KHOA`).
2. **`GIAO_VIEN`:** Mở rộng quan hệ $1 - 1$ với `NGUOI_DUNG`:
   * `ma_giao_vien` (PK, int), `ma_nguoi_dung` (FK, int, UK), `ho_ten` (varchar), `to_chuyen_mon` (varchar).
3. **`HOC_SINH`:** Mở rộng quan hệ $1 - 1$ với `NGUOI_DUNG`:
   * `ma_hoc_sinh` (PK, int), `ma_nguoi_dung` (FK, int, UK), `ho_ten` (varchar), `ngay_sinh` (date).

#### Cụm 2: Danh mục học tập và Phân công giảng dạy
4. **`NAM_HOC`:** `ma_nam_hoc` (PK, int), `ten_nam_hoc` (varchar - ví dụ: "2026-2027").
5. **`HOC_KY`:** `ma_hoc_ky` (PK, int), `ma_nam_hoc` (FK, int), `ten_hoc_ky` (varchar), `thu_tu` (int).
6. **`LOP`:** `ma_lop` (PK, int), `ten_lop` (varchar), `khoi` (int: 10, 11, 12), `ma_nam_hoc` (FK, int), `si_so` (int).
7. **`MON_HOC`:** `ma_mon` (PK, int), `ten_mon` (varchar).
8. **`THANH_PHAN_DIEM`:** `ma_thanh_phan` (PK, int), `ma_mon` (FK, int), `ten_thanh_phan` (varchar: ĐGTX, ĐGGK, ĐGCK), `he_so` (int), `bat_buoc` (bool).
9. **`PHAN_CONG_GIANG_DAY`:** Bảng kiểm soát phân quyền ABAC:
   * `ma_phan_cong` (PK, int), `ma_giao_vien` (FK), `ma_lop` (FK), `ma_mon` (FK), `ma_hoc_ky` (FK). Ràng buộc duy nhất `UNIQUE(ma_lop, ma_mon, ma_hoc_ky)`.

#### Cụm 3: Bảng điểm và Quản lý Điểm số
10. **`BANG_DIEM`:** `ma_bang_diem` (PK, int), `ma_lop` (FK), `ma_mon` (FK), `ma_hoc_ky` (FK), `trang_thai` (enum: `DANG_NHAP_LIEU`, `DA_CHOT`). Ràng buộc duy nhất `UNIQUE(ma_lop, ma_mon, ma_hoc_ky)`.
11. **`DIEM_THANH_PHAN`:** Ô điểm chi tiết của học sinh:
    * `ma_diem` (PK, int), `ma_bang_diem` (FK), `ma_hoc_sinh` (FK), `ma_thanh_phan` (FK).
    * `gia_tri` (`numeric(3, 1) NULL`): **Bất biến: `NULL` là chưa có điểm, khác biệt hoàn toàn với `0.0`**.
    * `trang_thai` (enum: `CHUA_CO`, `CHO_DOI_CHIEU`, `DA_DUYET`).
    * `nguon_nhap` (enum: `NHAP_TAY`, `NHAN_DIEN`).
    * Ràng buộc duy nhất: `UNIQUE(ma_bang_diem, ma_hoc_sinh, ma_thanh_phan)`.
12. **`LICH_SU_SUA_DIEM`:** Bảng kiểm toán truy vết lịch sử:
    * `ma_lich_su` (PK, int), `ma_diem` (FK), `gia_tri_cu` (numeric), `gia_tri_moi` (numeric), `nguoi_sua` (FK), `thoi_diem` (timestamptz), `ly_do` (varchar).
    * **Ràng buộc bất biến:** Bảng chỉ cho phép lệnh `INSERT` (**Append-only**), cấm tuyệt đối `UPDATE`/`DELETE`.

#### Cụm 4: Nhận dạng ảnh và Đối chiếu AI
13. **`PHIEU_NHAN_DIEN`:** Quản lý một lần quét tải ảnh:
    * `ma_phieu` (PK, int), `ma_bang_diem` (FK), `ma_bam_tep` (varchar, UK - SHA-256 chống tải trùng), `trang_thai` (enum: `DANG_XU_LY`, `CHO_DOI_CHIEU`, `DA_DUYET`, `LOI`), `nguoi_duyet` (FK, nullable), `thoi_diem_duyet` (timestamptz, nullable).
14. **`KET_QUA_DONG`:** Kết quả chi tiết từng dòng trên phiếu:
    * `ma_ket_qua` (PK, int), `ma_phieu` (FK), `thu_tu_dong` (int), `anh_o_cat` (varchar - đường dẫn MinIO), `gia_tri_kenh_a` (numeric), `do_tin_cay_a` (numeric), `gia_tri_kenh_b` (numeric), `do_tin_cay_b` (numeric), `ket_luan` (enum: `KHOP`, `LECH`, `MOT_KENH`, `KHONG_DOC_DUOC`), `muc_phan_loai` (enum: `XANH`, `VANG`, `DO`), `ma_diem` (FK, nullable - chỉ liên kết khi duyệt thành công). Ràng buộc duy nhất `UNIQUE(ma_phieu, thu_tu_dong)`.
15. **`TU_DIEN_DIEM_CHU`:** Bảng từ điển tra cứu điểm viết tay tiếng Việt:
    * `ma_cach_doc` (PK, int), `cach_doc` (varchar, UK - ví dụ: "tám", "tám rưỡi", "tám năm", "chín phẩy năm"), `gia_tri` (numeric: 0.0 đến 10.0).

#### Cụm 5: Kết quả Tổng kết
16. **`KET_QUA_TONG_KET`:** Lưu kết quả tổng kết môn của học sinh:
    * `ma_ket_qua` (PK, int), `ma_hoc_sinh` (FK), `ma_mon` (FK), `ma_hoc_ky` (FK), `diem_tong_ket` (numeric), `xep_loai` (varchar: Giỏi, Khá, Đạt, Chưa đạt), `phien_ban_he_so` (varchar), `bo_he_so` (jsonb - snapshot cấu hình bộ hệ số bảo đảm tính giải thích được của dữ liệu lịch sử).

---

## 4.9. THIẾT KẾ MÁY TRẠNG THÁI CÁC THỰC THỂ CỐT LÕI (STATE DIAGRAMS)

### 4.9.1. Vòng đời Phiếu nhận diện (`phieu_nhan_dien`)

![Hình 4.23: Sơ đồ Trạng thái Phiếu Nhận diện](hinh/trang_thai_phieu.png)
*Hình 4.23: Sơ đồ Trạng thái Vòng đời Phiếu Nhận diện*

* `DANG_XU_LY`: Khi giáo viên tải ảnh lên, BullMQ Worker đang nắn ảnh, tách lưới và OCR.
* `CHO_DOI_CHIEU`: Khi Worker xử lý thành công, kết quả 2 kênh và phân loại 3 màu sẵn sàng cho giáo viên rà soát.
* `DA_DUYET`: Giáo viên bấm duyệt trong giao dịch nguyên tử. Phiếu chuyển sang chế độ chỉ đọc và đóng băng vĩnh viễn.
* `LOI`: Khi ảnh lệch lưới số dòng, ảnh quá mờ hoặc hết hạn deadline nhập điểm (ADR-0014 tự động hủy đề xuất máy).

### 4.9.2. Vòng đời Bảng điểm Lớp – Môn (`bang_diem`)

![Hình 4.24: Sơ đồ Trạng thái Bảng điểm Lớp - Môn](hinh/trang_thai_bang_diem.png)
*Hình 4.24: Sơ đồ Trạng thái Vòng đời Bảng điểm Lớp - Môn*

* `DANG_NHAP_LIEU`: Bảng điểm đang mở. Các cột điểm có thể ở trạng thái Mở (nhập tay / duyệt OCR) hoặc Khóa (hết hạn deadline điền 0.0).
* `DA_CHOT`: Khi tất cả các cột điểm thành phần đều đã bị khóa, bảng điểm tự động chuyển sang `DA_CHOT`. Bảng điểm đóng băng toàn phần, khóa quyền sửa điểm và sẵn sàng làm đầu vào tính tổng kết.

### 4.9.3. Vòng đời Ô điểm thành phần (`diem_thanh_phan`)

![Hình 4.25: Sơ đồ Trạng thái Ô điểm thành phần](hinh/trang_thai_o_diem.png)
*Hình 4.25: Sơ đồ Trạng thái Vòng đời Ô điểm thành phần*

* `CHUA_CO`: Khởi tạo mặc định khi sinh lưới (giá trị điểm là `NULL`, khác biệt hoàn toàn với `0.0`).
* `CHO_DOI_CHIEU`: Giá trị máy đề xuất từ phiếu OCR, chưa phải điểm chính thức.
* `DA_DUYET`: Điểm chính thức hợp lệ: từ nhập tay trực tiếp, hoặc từ duyệt phiếu OCR nguyên tử, hoặc do hệ thống tự điền 0.0 khi chạm hạn Deadline (ADR-0014). Mọi lần sửa đổi sau đó đều phát sinh bản ghi mới trong `lich_su_sua_diem`.

---

## 4.10. KẾT LUẬN CHƯƠNG 4

Chương 4 đã hoàn thành trọn vẹn và tường tận toàn bộ công tác phân tích và thiết kế hệ thống cho đề tài "Nhận dạng bảng điểm viết tay hỗ trợ nhập điểm tự động":
1. **Phân tích nghiệp vụ sâu sắc:** Làm rõ ranh giới use-case nghiệp vụ đời thực tại Trường THPT Bà Điểm, định vị chính xác "điểm nghẽn nhập liệu thủ công" và chứng minh tính ưu việt của quy trình đề xuất ứng dụng AI hai kênh kết hợp Human-in-the-loop.
2. **Chuẩn hóa chức năng và luồng dữ liệu:** Xây dựng hoàn chỉnh cây BFD 6 phân hệ (46 chức năng con), 18 use-case hệ thống chi tiết (UC01–UC18), sơ đồ DFD mức ngữ cảnh và mức 1, cùng 11 sơ đồ hoạt động chi tiết cho từng phân hệ.
3. **Mô hình hóa hành vi và tương tác động:** Đặc tả chi tiết sơ đồ tuần tự cho hai use-case phức tạp nhất (UC11 Tải ảnh nhận dạng và UC13 Đối chiếu duyệt điểm nguyên tử), làm rõ cơ chế chốt chặn số dòng và giao dịch nguyên tử All-or-Nothing.
4. **Thiết kế CSDL và bảo mật chặt chẽ:** Xây dựng mô hình quan hệ thực thể ERD 16 bảng chuẩn 3NF, kiểm soát phân quyền RBAC/ABAC, nhật ký kiểm toán Append-only, phân biệt rõ ràng giữa giá trị `NULL` và $0.0$, và cơ chế tự động khóa sổ theo hạn chót (ADR-0014).

Toàn bộ các sơ đồ thiết kế trong chương này đã được kết xuất thành hình ảnh chất lượng cao lưu trữ tại thư mục [hinh/](file:///c:/Users/Ho%20Si%20Khai/Downloads/Ki_1_nam_4/KLCN/system/hinh), đóng vai trò là kim chỉ nam kỹ thuật chuẩn xác phục vụ cài đặt và nghiệm thu hệ thống trong các chương tiếp theo.
