import os, subprocess, shutil
from PIL import Image, ImageChops

DIAGRAMS = [
    {
        "id": "01_luong_nghiep_vu_tong_the",
        "title": "Sơ đồ luồng hoạt động nghiệp vụ tổng thể toàn hệ thống",
        "code": """flowchart TD
    START([Bắt đầu năm học mới]) --> DM[1. QTV thiết lập Danh mục<br/>Năm học · Học kỳ · Lớp · Môn học]
    DM --> PC[2. QTV Phân công giảng dạy<br/>Gán Giáo viên phụ trách từng Lớp - Môn]
    PC --> BD[3. Khởi tạo Bảng điểm & Lưới điểm<br/>Theo sĩ số lớp, giá trị khởi tạo ban đầu là NULL]
    BD --> DL[4. QTV cấu hình Hạn chót Deadline<br/>Thiết lập thời gian mở và khóa từng cột điểm]

    DL --> INPUT_FORK{Giáo viên chọn<br/>hình thức nhập điểm}

    INPUT_FORK -->|Hình thức 1: Nhập tay| MANUAL[5a. Nhập tay trực tiếp trên lưới<br/>Điểm kiểm tra miệng, 15 phút, bài làm bù...]
    INPUT_FORK -->|Hình thức 2: Nhận dạng ảnh| OCR[5b. Tải ảnh bảng điểm viết tay A4<br/>Chụp ảnh bảng điểm đã chấm]

    OCR --> PIPE[6. Pipeline AI bóc tách dữ liệu<br/>Nắn phối cảnh · Tách khung lưới · CRNN + VietOCR]
    PIPE --> REVIEW[7. Giáo viên đối chiếu ba màu<br/>Lọc ưu tiên Vàng/Đỏ · Soi ảnh crop · Duyệt nguyên tử]

    MANUAL --> VERIFY[8. Điểm số ghi nhận trạng thái DA_DUYET]
    REVIEW --> VERIFY

    VERIFY --> LOCK_CHECK{Cột điểm đến<br/>hạn chót Deadline?}
    LOCK_CHECK -->|Tự động theo ADR-0014| AUTO_LOCK[9. Hệ thống tự động khóa cột điểm<br/>- Điền 0.0 cho ô thiếu của HS đang học<br/>- Khóa bảng sang DA_CHOT khi mọi cột đã đóng]

    AUTO_LOCK --> CALC[10. Tính tổng kết & Xếp loại học lực<br/>- Áp dụng bộ hệ số chung học kỳ ADR-0013<br/>- Tính ĐTB môn hoặc tỷ lệ Đạt/Chưa đạt ADR-0015]

    CALC --> PUB_CHECK{QTV kích hoạt<br/>Công bố học kỳ?}
    PUB_CHECK -->|Chưa công bố| WAIT_PUB[Lưu trữ nội bộ<br/>Chờ kiểm duyệt và phê duyệt toàn trường]
    PUB_CHECK -->|Đã công bố| REPORT[11. Xuất báo cáo & Tra cứu điểm<br/>- GV/QTV xuất bảng tổng hợp Excel .xlsx<br/>- Học sinh tra cứu điểm cá nhân trực tuyến]

    REPORT --> END_STATE([Kết thúc học kỳ])

    style START fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    style OCR fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style PIPE fill:#fce4ec,stroke:#c62828,stroke-width:2px
    style REVIEW fill:#fff8e1,stroke:#f9a825,stroke-width:2px
    style AUTO_LOCK fill:#ffcdd2,stroke:#d32f2f,stroke-width:2px
    style CALC fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style REPORT fill:#cce5ff,stroke:#007bff,stroke-width:2px
    style END_STATE fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
"""
    },
    {
        "id": "02_luong_xac_thuc_phan_quyen",
        "title": "Sơ đồ luồng hoạt động Xác thực và Phân quyền người dùng",
        "code": """flowchart TD
    START([Người dùng truy cập]) --> INP[Nhập Tên đăng nhập SĐT<br/>và Mật khẩu]
    INP --> RATE{Kiểm tra tần suất<br/>Rate-limiting?}
    RATE -->|Vượt ngưỡng| BLOCK[⛔ Tạm khóa IP / Tài khoản<br/>Ghi nhận nhật ký bảo mật]
    BLOCK --> FAIL_END([Từ chối truy cập])

    RATE -->|Hợp lệ| FIND[Tìm tài khoản trong CSDL<br/>Bảng nguoi_dung]
    FIND --> FOUND{Tài khoản<br/>tồn tại?}
    FOUND -->|Không| ERR_USER[⚠️ Báo lỗi: Sai thông tin đăng nhập]
    ERR_USER --> INP

    FOUND -->|Có| STATUS{Trạng thái<br/>hoạt động?}
    STATUS -->|Bị khóa KHOA| ERR_LOCK[⚠️ Báo lỗi: Tài khoản đã bị khóa<br/>Liên hệ Quản trị viên để mở lại]
    ERR_LOCK --> FAIL_END

    STATUS -->|HOAT_DONG| HASH[Băm kiểm tra Argon2id<br/>với Salt và Pepper bảo mật]
    HASH --> MATCH{Mật khẩu<br/>chính xác?}
    MATCH -->|Sai| LOG_FAIL[Ghi nhận lần đăng nhập thất bại<br/>Tăng bộ đếm cảnh báo]
    LOG_FAIL --> ERR_USER

    MATCH -->|Đúng| ISSUE[Cấp phát mã bảo mật phiên:<br/>- Access Token JWT thời hạn 15 phút<br/>- Refresh Token Rotation an toàn]
    ISSUE --> ROLE_FORK{Phân luồng điều hướng<br/>theo Vai trò người dùng}

    ROLE_FORK -->|QUAN_TRI_VIEN| R_ADMIN[Bảng điều khiển Quản trị viên<br/>Quản lý danh mục, tài khoản, phân quyền, deadline]
    ROLE_FORK -->|GIAO_VIEN| R_TEACHER[Giao diện Giáo viên bộ môn<br/>Kiểm tra quyền ABAC theo phân công lớp - môn]
    ROLE_FORK -->|HOC_SINH| R_STUDENT[Giao diện Học sinh<br/>Bảo mật IDOR: Chỉ xem điểm cá nhân]

    R_ADMIN --> SUCCESS([Đăng nhập thành công])
    R_TEACHER --> SUCCESS
    R_STUDENT --> SUCCESS

    style START fill:#e3f2fd,stroke:#1565c0
    style SUCCESS fill:#d4edda,stroke:#28a745,stroke-width:2px
    style FAIL_END fill:#f8d7da,stroke:#dc3545
    style ERR_USER fill:#fff3cd,stroke:#ffc107
    style ISSUE fill:#cce5ff,stroke:#007bff
"""
    },
    {
        "id": "03_luong_danh_muc_phan_cong",
        "title": "Sơ đồ luồng hoạt động Quản lý danh mục học tập & Phân công giảng dạy",
        "code": """flowchart TD
    START([QTV đăng nhập hệ thống]) --> Y1[1. Khởi tạo Năm học mới<br/>Bảng nam_hoc: 2026 - 2027]
    Y1 --> Y2[2. Khởi tạo Học kỳ 1 & Học kỳ 2<br/>Bảng hoc_ky]
    Y2 --> Y3[3. Cấu hình Bộ hệ số dùng chung học kỳ<br/>TX: 1 · GK: 2 · CK: 3  ADR-0013]

    Y3 --> FORK_CAT{Khởi tạo các danh mục<br/>học tập cơ sở}
    FORK_CAT --> C1[Tạo Khối và Danh sách Lớp học<br/>Bảng lop: 10A1, 11B2...]
    FORK_CAT --> C2[Cập nhật Danh mục Môn học<br/>Toán, Ngữ văn, Vật lý, GDTC...]
    FORK_CAT --> C3[Hồ sơ Đội ngũ Giáo viên<br/>Bảng giao_vien]

    C1 --> HS[Nhập Danh sách Học sinh theo Lớp<br/>Bảng hoc_sinh]

    C2 & C3 & HS --> PC[4. Thiết lập Phân công giảng dạy<br/>Bảng phan_cong_giang_day<br/>Gán: Giáo viên + Lớp + Môn + Học kỳ]

    PC --> GEN_BG[5. Tự động khởi tạo Bảng điểm rỗng<br/>Bảng bang_diem]
    GEN_BG --> GEN_CELLS[6. Sinh lưới ô điểm theo sĩ số lớp<br/>Bảng diem_thanh_phan: giá trị ban đầu là NULL]

    GEN_CELLS --> DL_SET[7. QTV thiết lập Thời hạn nhập điểm<br/>Cấu hình Deadline từng cột kiểm tra  ADR-0014]

    DL_SET --> END_STATE([Sẵn sàng cho Giáo viên nhập điểm])

    style START fill:#e3f2fd,stroke:#1565c0
    style Y3 fill:#fff8e1,stroke:#f9a825,stroke-width:2px
    style PC fill:#cce5ff,stroke:#007bff,stroke-width:2px
    style GEN_CELLS fill:#d4edda,stroke:#28a745
    style END_STATE fill:#e3f2fd,stroke:#1565c0
"""
    },
    {
        "id": "04_luong_nhap_sua_diem_thu_cong",
        "title": "Sơ đồ luồng hoạt động Quản lý bảng điểm & Nhập điểm thủ công",
        "code": """flowchart TD
    START([GV chọn Bảng điểm Lớp - Môn]) --> CHK_AUTH{Kiểm tra thẩm quyền<br/>giảng dạy ABAC?}
    CHK_AUTH -->|Không thuộc phân công| DENY[⛔ Báo lỗi: Bạn không được phân công<br/>giảng dạy lớp - môn này]
    DENY --> END_ERR([Dừng thao tác])

    CHK_AUTH -->|Hợp lệ| CHK_STATUS{Trạng thái hiện tại<br/>của Bảng điểm?}
    CHK_STATUS -->|DA_CHOT| READ_ONLY[Bảng điểm đã đóng chốt toàn phần<br/>Chỉ cho phép xem, khóa mọi thao tác sửa]
    READ_ONLY --> END_ERR

    CHK_STATUS -->|DANG_NHAP_LIEU| LOAD_GRID[Tải danh sách học sinh và lưới điểm<br/>Hiển thị điểm hiện có hoặc giá trị NULL]
    LOAD_GRID --> CHK_COL{Cột điểm cần nhập<br/>còn trong hạn Deadline?}
    CHK_COL -->|Đã hết hạn| LOCK_COL[Cột điểm đã bị khóa hạn chót<br/>Không cho phép thêm hoặc sửa điểm]
    LOCK_COL --> LOAD_GRID

    CHK_COL -->|Đang mở| INPUT[Giáo viên nhập hoặc sửa giá trị điểm<br/>tại ô điểm của học sinh]
    INPUT --> VALID{Giá trị điểm số<br/>nằm trong 0.0 - 10.0<br/>bước nhảy 0.1?}
    VALID -->|Không hợp lệ| WARN[⚠️ Báo lỗi ngay tại ô nhập liệu:<br/>Điểm phải từ 0.0 đến 10.0, bước 0.1]
    WARN --> INPUT

    VALID -->|Hợp lệ| TX[Mở Giao dịch CSDL nguyên tử]
    TX --> SAVE_POINT[Ghi giá trị mới vào diem_thanh_phan<br/>Trạng thái: DA_DUYET · Nguồn: NHAP_TAY]
    SAVE_POINT --> LOG[Ghi nhật ký lich_su_sua_diem<br/>Append-only: Điểm cũ, Điểm mới,<br/>Người sửa, Thời điểm, Lý do]
    LOG --> COMMIT[Commit Giao dịch thành công]

    COMMIT --> UPDATE_UI[Cập nhật lưới điểm hiển thị tức thì]
    UPDATE_UI --> CONTINUE{Tiếp tục nhập<br/>ô điểm khác?}
    CONTINUE -->|Có| INPUT
    CONTINUE -->|Không| DONE([Hoàn tất phiên nhập điểm])

    style START fill:#e3f2fd,stroke:#1565c0
    style DENY fill:#ffcdd2,stroke:#d32f2f
    style LOCK_COL fill:#fff3cd,stroke:#ffc107
    style SAVE_POINT fill:#d4edda,stroke:#28a745
    style LOG fill:#cce5ff,stroke:#007bff,stroke-width:2px
    style DONE fill:#e3f2fd,stroke:#1565c0
"""
    },
    {
        "id": "05_luong_pipeline_nhan_dang_anh",
        "title": "Sơ đồ luồng hoạt động Pipeline nhận dạng ảnh bảng điểm",
        "code": """flowchart TD
    START([Giáo viên chọn Bảng điểm & Cột điểm]) --> UPLOAD[Tải ảnh chụp bảng điểm A4 lên hệ thống<br/>Khai báo số dòng dự kiến N_declared]
    UPLOAD --> VAL_FILE{Kiểm tra MIME, Dung lượng <= 10MB,<br/>Tính mã băm SHA-256}
    VAL_FILE -->|Sai định dạng / Trùng mã băm| REJECT[⛔ Từ chối tệp: Định dạng không hỗ trợ<br/>hoặc ảnh đã được tải lên trước đó]
    REJECT --> UPLOAD

    VAL_FILE -->|Hợp lệ| STORE_RAW[Lưu ảnh gốc an toàn vào MinIO<br/>Tạo bản ghi PhieuNhanDien: DANG_XU_LY]
    STORE_RAW --> QUEUE[Đẩy tác vụ vào hàng đợi BullMQ Redis<br/>API trả mã 202 Accepted + jobId theo dõi]

    QUEUE --> WORKER[═══ RECOGNITION WORKER BẮT ĐẦU ═══]
    WORKER --> WARP1[Nắn phối cảnh Giai đoạn 1:<br/>Phát hiện 4 góc tờ giấy A4 qua Canny + Đa giác]
    WARP1 --> WARP2[Nắn phối cảnh Giai đoạn 2:<br/>Định vị 4 góc khung lưới bảng điểm]
    WARP2 --> GRID[Tách khung lưới bằng phép toán hình thái học<br/>Bóc tách đường kẻ ngang và dọc]
    GRID --> COUNT[Đếm số lượng đường kẻ ngang thực tế: N_detected]

    COUNT --> ASSERT{N_detected == N_declared<br/>Số dòng phát hiện khớp hoàn toàn?}
    ASSERT -->|Lệch dòng| ERR_GRID[⛔ CHỐT CHẶN AN TOÀN:<br/>Đánh dấu phiếu LOI · Yêu cầu GV chụp lại ảnh<br/>Loại trừ hoàn toàn rủi ro lệch dòng học sinh]
    ERR_GRID --> STOP_JOB([Dừng xử lý tác vụ])

    ASSERT -->|Khớp chuẩn| CROP[Cắt ảnh từng ô điểm độc lập:<br/>Ô Điểm số & Ô Điểm chữ]
    CROP --> FOR_EACH{Lặp qua từng dòng học sinh}

    FOR_EACH --> INK{Kiểm tra Mật độ mực ô cắt<br/>Ink Density Gating}
    INK -->|Mật độ < ngưỡng ô trống| EMPTY[Gán nhãn: Ô TRỐNG<br/>Phân loại: MỨC ĐỎ<br/>Ngắt xử lý, không gọi mô hình AI]

    INK -->|Có nét chữ viết tay| INFER_FORK[Kích hoạt song song 2 kênh độc lập]
    INFER_FORK --> OCR_NUM[Kênh A — Chữ số:<br/>Mô hình CRNN<br/>-> Giá trị số Val_A, Conf_A]
    INFER_FORK --> OCR_TXT[Kênh B — Chữ tiếng Việt:<br/>Mô hình VietOCR<br/>-> Chuỗi văn bản B, Conf_B]

    OCR_TXT --> DICT[Tra từ điển tu_dien_diem_chu<br/>Chuẩn hóa văn bản -> Số thực Val_B]

    OCR_NUM & DICT --> CROSS[Đối chiếu chéo Val_A vs Val_B<br/>Đánh giá tương quan 2 kênh độc lập]
    CROSS --> CLASSIFY[Phân loại 3 mức tin cậy toán học:<br/>🟢 Xanh · 🟡 Vàng · 🔴 Đỏ]

    EMPTY --> SAVE_ROW[Lưu KetQuaDong vào CSDL<br/>kèm đường dẫn ảnh ô cắt trong MinIO]
    CLASSIFY --> SAVE_ROW

    SAVE_ROW --> MORE{Còn dòng tiếp theo?}
    MORE -->|Còn| FOR_EACH
    MORE -->|Hết| FINISH[Chuyển trạng thái phiếu sang CHO_DOI_CHIEU<br/>Gửi thông báo hoàn tất cho Giáo viên]

    FINISH --> DONE([Sẵn sàng cho phiên đối chiếu])

    style START fill:#e3f2fd,stroke:#1565c0
    style ERR_GRID fill:#ffcdd2,stroke:#d32f2f,stroke-width:2px
    style OCR_NUM fill:#cce5ff,stroke:#007bff
    style OCR_TXT fill:#e8f5e9,stroke:#2e7d32
    style CLASSIFY fill:#fff8e1,stroke:#f9a825,stroke-width:2px
    style DONE fill:#d4edda,stroke:#28a745
"""
    },
    {
        "id": "06_luong_doi_chieu_duyet_diem",
        "title": "Sơ đồ luồng hoạt động Đối chiếu và Duyệt điểm nguyên tử",
        "code": """flowchart TD
    START([GV mở phiếu CHO_DOI_CHIEU]) --> LOAD[Tải danh sách dòng & Presigned URL ảnh ô cắt<br/>Bố cục so sánh trực quan Side-by-side]
    LOAD --> FILTER[Bộ lọc thông minh Human-in-the-loop:<br/>Ưu tiên dòng 🟡 Vàng và 🔴 Đỏ lên đầu trang<br/>Thu gọn các dòng 🟢 Xanh đã khớp tuyệt đối]

    FILTER --> ROW_LOOP{Xét từng dòng<br/>Vàng hoặc Đỏ}
    ROW_LOOP --> VIEW[Giáo viên nhìn ảnh ô cắt gốc<br/>và kết quả 2 kênh đọc được của máy]
    VIEW --> CHOOSE{Chọn phương thức<br/>quyết định giá trị}
    CHOOSE -->|Chọn Kênh A| SET_A[Lấy giá trị Kênh Điểm số]
    CHOOSE -->|Chọn Kênh B| SET_B[Lấy giá trị Kênh Điểm chữ]
    CHOOSE -->|Tự sửa tay| SET_MAN[Gõ điểm đúng từ bàn phím]

    SET_A & SET_B & SET_MAN --> VAL_SCORE{Điểm trong đoạn<br/>0.0 đến 10.0<br/>bước 0.1?}
    VAL_SCORE -->|Không hợp lệ| ERR_SCORE[⚠️ Báo lỗi ngay tại dòng:<br/>Giá trị điểm không hợp lệ]
    ERR_SCORE --> VIEW

    VAL_SCORE -->|Hợp lệ| SAVE_CONFIRM[Ghi nhận điểm chốt tạm thời của dòng]
    SAVE_CONFIRM --> MORE_ROWS{Còn dòng Vàng/Đỏ<br/>chưa xác nhận?}
    MORE_ROWS -->|Còn| ROW_LOOP

    MORE_ROWS -->|Đã xử lý hết| BTN_COMMIT[Giáo viên bấm nút DUYỆT PHIẾU]
    BTN_COMMIT --> CHK_ALL{100% các dòng trên phiếu<br/>đều đã có điểm chốt?}
    CHK_ALL -->|Còn sót dòng| PREVENT[⛔ Chặn duyệt phiếu:<br/>Tự động cuộn màn hình tới dòng còn thiếu]
    PREVENT --> ROW_LOOP

    CHK_ALL -->|Đầy đủ 100%| ATOMIC_TX[═══ GIAO DỊCH DATABASE NGUYÊN TỬ ═══]

    subgraph TX_BOX["Atomic Database Transaction (All-or-Nothing)"]
        T1[1. Ghi giá trị điểm chốt vào diem_thanh_phan<br/>Cập nhật trạng thái: DA_DUYET]
        T2[2. Ghi nhật ký kiểm toán lich_su_sua_diem<br/>Append-only: Cũ -> Mới, Người duyệt, Thời điểm]
        T3[3. Đóng dấu nguoi_duyet & thoi_diem_duyet<br/>lên phieu_nhan_dien và ket_qua_dong]
        T4[4. Đổi trạng thái phiếu nhận diện: DA_DUYET]
        T1 --> T2 --> T3 --> T4
    end

    ATOMIC_TX --> TX_BOX
    TX_BOX --> COMMIT_RES{Giao dịch commit<br/>thành công?}
    COMMIT_RES -->|Lỗi rớt mạng hoặc DB| ROLLBACK[Rollback toàn phần<br/>Khôi phục trạng thái ban đầu<br/>Không có dữ liệu dở dang]
    ROLLBACK --> LOAD

    COMMIT_RES -->|Thành công| SUMMARY[Hiển thị bảng tổng kết nghiệm thu:<br/>- Số dòng máy nhận dạng chính xác<br/>- Số dòng giáo viên can thiệp sửa đổi]
    SUMMARY --> DONE([Hoàn tất duyệt bảng điểm])

    style START fill:#e3f2fd,stroke:#1565c0
    style FILTER fill:#fff8e1,stroke:#f9a825
    style TX_BOX fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style ROLLBACK fill:#ffcdd2,stroke:#d32f2f
    style DONE fill:#d4edda,stroke:#28a745
"""
    },
    {
        "id": "07_luong_tu_dong_khoa_so_deadline",
        "title": "Sơ đồ luồng hoạt động Tự động khóa sổ theo hạn chót (ADR-0014)",
        "code": """flowchart TD
    START([QTV cấu hình Hạn chót Deadline]) --> SAVE_DL[Lưu mốc thời gian đóng từng cột điểm<br/>Bảng bang_diem / thanh_phan_diem]
    SAVE_DL --> CRON[Hệ thống chạy Worker kiểm tra định kỳ<br/>Quét các cột điểm đã chạm mốc Deadline]

    CRON --> CHK_EXPIRED{Phát hiện cột điểm<br/>vừa hết hạn?}
    CHK_EXPIRED -->|Chưa hết hạn| IDLE[Cột điểm tiếp tục mở cho GV nhập liệu]
    IDLE --> CRON

    CHK_EXPIRED -->|Đã hết hạn| START_LOCK[Bắt đầu quy trình Tự động khóa cột điểm]

    START_LOCK --> SCAN_UNFINISHED[Quét toàn bộ ô điểm của học sinh đang học<br/>đang ở trạng thái CHUA_CO hoặc CHO_DOI_CHIEU]

    SCAN_UNFINISHED --> FILL_ZERO[Ghi nhận giá trị 0.0 cho các ô điểm còn thiếu<br/>Chuyển trạng thái điểm sang DA_DUYET]
    FILL_ZERO --> LOG_AUDIT[Ghi nhật ký lich_su_sua_diem:<br/>Lý do: 'Hệ thống tự động điền 0.0 do hết hạn']

    LOG_AUDIT --> CANCEL_OCR[Kiểm tra các Phiếu nhận diện OCR<br/>đang ở trạng thái CHO_DOI_CHIEU của cột này]
    CANCEL_OCR --> MARK_ERR[Đổi trạng thái phiếu OCR sang LOI<br/>Hủy bỏ toàn bộ đề xuất máy, không ghi nhận]

    MARK_ERR --> LOCK_COL[Đánh dấu Cột điểm: ĐÃ KHÓA HOÀN TOÀN]
    LOCK_COL --> CHK_ALL_COLS{Tất cả các cột điểm<br/>của Bảng điểm đã khóa?}

    CHK_ALL_COLS -->|Còn cột khác chưa khóa| KEEP_OPEN[Bảng điểm duy trì trạng thái DANG_NHAP_LIEU]
    CHK_ALL_COLS -->|Tất cả cột đều đã khóa| LOCK_BOOK[Chuyển Bảng điểm sang DA_CHOT]

    LOCK_BOOK --> FROZEN[Bảng điểm đóng băng toàn phần<br/>Khóa mọi quyền sửa đổi thông thường<br/>Sẵn sàng làm đầu vào tính Tổng kết]

    KEEP_OPEN --> DONE([Hoàn tất chu kỳ quét])
    FROZEN --> DONE

    style START fill:#e3f2fd,stroke:#1565c0
    style FILL_ZERO fill:#ffcdd2,stroke:#d32f2f,stroke-width:2px
    style MARK_ERR fill:#fff3cd,stroke:#ffc107
    style FROZEN fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style DONE fill:#e3f2fd,stroke:#1565c0
"""
    },
    {
        "id": "08_luong_tong_ket_va_xep_loai",
        "title": "Sơ đồ luồng hoạt động Tính điểm tổng kết & Xếp loại học tập",
        "code": """flowchart TD
    START([GV chọn Lớp - Môn - Học kỳ]) --> BTN_CALC[Bấm lệnh 'Tính Tổng kết']
    BTN_CALC --> CHK_READY{Tất cả điểm bắt buộc<br/>đều có giá trị và ở trạng thái<br/>DA_DUYET?}
    CHK_READY -->|Còn điểm NULL / Chờ duyệt| WARN_MISS[⚠️ Cảnh báo: Lớp còn học sinh thiếu điểm<br/>hoặc phiếu điểm chưa được duyệt xong]
    WARN_MISS --> STOP([Dừng tính tổng kết])

    CHK_READY -->|Đủ điều kiện| LOAD_CONFIG[Tải Cấu hình Bộ hệ số Học kỳ hiện hành<br/>TX: 1 · GK: 2 · CK: 3  ADR-0013]

    LOAD_CONFIG --> HS_LOOP{Lặp qua từng học sinh<br/>trong danh sách lớp}

    HS_LOOP --> SUB_TYPE{Hình thức đánh giá<br/>của Môn học?}

    SUB_TYPE -->|Môn tính điểm số| CALC_AVG[Tính Điểm Trung Bình có trọng số:<br/>ĐTB = Σ Điểm × Hệ số / Σ Hệ số<br/>Làm tròn toán học đến 1 chữ số thập phân]
    CALC_AVG --> RANK_NUM{Xếp loại học lực môn}
    RANK_NUM -->|ĐTB >= 8.0| R_GIOI[Loại: GIỎI]
    RANK_NUM -->|6.5 <= ĐTB < 8.0| R_KHA[Loại: KHÁ]
    RANK_NUM -->|5.0 <= ĐTB < 6.5| R_DAT[Loại: ĐẠT]
    RANK_NUM -->|ĐTB < 5.0| R_CHUA[Loại: CHƯA ĐẠT]

    SUB_TYPE -->|Môn Đạt / Chưa đạt| CALC_PASS[Tính tỷ lệ cột Đạt / tổng cột điểm<br/>ADR-0015]
    CALC_PASS --> PASS_CHK{Tỷ lệ cột Đạt<br/>>= 50%?}
    PASS_CHK -->|Đúng| R_DAT_M[Loại: ĐẠT]
    PASS_CHK -->|Sai| R_CHUA_M[Loại: CHƯA ĐẠT]

    R_GIOI & R_KHA & R_DAT & R_CHUA & R_DAT_M & R_CHUA_M --> SAVE_REC[Lưu bản ghi ket_qua_tong_ket<br/>kèm Snapshot cấu hình bộ hệ số JSONB]

    SAVE_REC --> MORE_HS{Còn học sinh tiếp theo?}
    MORE_HS -->|Còn| HS_LOOP

    MORE_HS -->|Hết danh sách| SHOW_GV[Hiển thị Bảng kết quả tổng hợp cho Giáo viên]
    SHOW_GV --> PUB_CHK{Quản trị viên<br/>đã công bố Học kỳ?}

    PUB_CHK -->|Chưa công bố| WAIT_PUB[Học sinh chưa thể xem kết quả]
    PUB_CHK -->|Đã công bố| PUB_LIVE[Kích hoạt quyền tra cứu điểm cho Học sinh]

    SHOW_GV --> EXPORT[Giáo viên / QTV có thể:<br/>- Xem thống kê biểu đồ phổ điểm<br/>- Xuất tệp báo cáo Excel .xlsx chuẩn]

    WAIT_PUB --> DONE([Hoàn tất])
    PUB_LIVE --> DONE
    EXPORT --> DONE

    style START fill:#e3f2fd,stroke:#1565c0
    style CALC_AVG fill:#cce5ff,stroke:#007bff
    style CALC_PASS fill:#fff8e1,stroke:#f9a825
    style SAVE_REC fill:#d4edda,stroke:#28a745,stroke-width:2px
    style PUB_LIVE fill:#e8f5e9,stroke:#2e7d32
"""
    },
    {
        "id": "09_luong_tra_cuu_diem_hoc_sinh",
        "title": "Sơ đồ luồng hoạt động Tra cứu điểm cá nhân của Học sinh",
        "code": """flowchart TD
    START([Học sinh đăng nhập hệ thống]) --> AUTH[Xác thực tài khoản thành công<br/>Trích xuất ma_hoc_sinh từ Session Token JWT]
    AUTH --> MENU[Chọn chức năng: 'Tra cứu điểm cá nhân']
    MENU --> SELECT[Chọn Năm học và Học kỳ cần xem]

    SELECT --> CHK_PUB{Học kỳ đã được QTV<br/>công bố kết quả?}
    CHK_PUB -->|Chưa công bố| MSG_WAIT[Thông báo: Kết quả học kỳ đang được xử lý<br/>và chưa đến ngày công bố chính thức]
    MSG_WAIT --> DONE([Kết thúc xem])

    CHK_PUB -->|Đã công bố| QUERY_DB[Hệ thống thực hiện truy vấn CSDL]

    QUERY_DB --> SEC_FILTER[Kiểm tra Bảo mật chống IDOR:<br/>WHERE ma_hoc_sinh == Session.ma_hoc_sinh<br/>Nghiêm cấm truyền mã học sinh tùy ý từ Client]

    SEC_FILTER --> LOAD_DATA[Tải danh sách các môn học:<br/>- Điểm kiểm tra miệng, 15 phút, 1 tiết<br/>- Điểm thi giữa kỳ, cuối kỳ<br/>- Điểm trung bình môn học<br/>- Xếp loại học lực môn]

    LOAD_DATA --> RENDER_UI[Hiển thị bảng điểm điện tử trực quan<br/>Tối ưu hóa giao diện di động / web]
    RENDER_UI --> VIEW_DETAIL{Học sinh muốn xem<br/>lịch sử thay đổi?}
    VIEW_DETAIL -->|Có| SHOW_AUDIT[Xem lý do đính chính điểm nếu có]
    VIEW_DETAIL -->|Không| DONE
    SHOW_AUDIT --> DONE

    style START fill:#e3f2fd,stroke:#1565c0
    style SEC_FILTER fill:#ffcdd2,stroke:#d32f2f,stroke-width:2px
    style LOAD_DATA fill:#d4edda,stroke:#28a745
    style RENDER_UI fill:#cce5ff,stroke:#007bff
    style DONE fill:#e3f2fd,stroke:#1565c0
"""
    },
    {
        "id": "10_luong_quan_ly_thoi_khoa_bieu",
        "title": "Sơ đồ luồng hoạt động Quản lý và Tra cứu Thời khóa biểu",
        "code": """flowchart TD
    START([Người dùng truy cập Thời khóa biểu]) --> CHECK_ROLE{Vai trò của người dùng?}

    CHECK_ROLE -->|QUAN_TRI_VIEN| ADMIN_FLOW[Giao diện Quản trị Thời khóa biểu]
    ADMIN_FLOW --> ADM_ACTION{Hành động của QTV}
    ADM_ACTION -->|Thiết lập lịch mới| CREATE_TB[Chọn Lớp · Môn · GV · Thứ · Tiết · Phòng học]
    CREATE_TB --> CHK_CONFLICT{Kiểm tra xung đột lịch:<br/>- GV có trùng tiết dạy lớp khác?<br/>- Phòng học có bị trùng lớp khác?}
    CHK_CONFLICT -->|Có xung đột| ERR_CONF[⚠️ Báo lỗi: Trùng tiết giáo viên hoặc phòng học]
    ERR_CONF --> CREATE_TB
    CHK_CONFLICT -->|Không xung đột| SAVE_TB[Lưu Thời khóa biểu vào CSDL]

    ADM_ACTION -->|Xem tổng hợp| VIEW_ALL[Xem ma trận TKB theo Lớp hoặc theo Phòng học]

    CHECK_ROLE -->|GIAO_VIEN| TEACHER_FLOW[Giao diện TKB Giáo viên]
    TEACHER_FLOW --> LOAD_TCH[Tải lịch dạy cá nhân của Giáo viên<br/>Hiển thị: Thứ, Tiết, Lớp, Môn, Phòng học]

    CHECK_ROLE -->|HOC_SINH| STUDENT_FLOW[Giao diện TKB Học sinh]
    STUDENT_FLOW --> LOAD_STD[Tải lịch học theo Lớp của Học sinh<br/>Hiển thị: Thứ, Tiết, Môn, Giáo viên dạy]
    LOAD_STD --> HIDE_ROOM[Bảo mật: Ẩn thông tin Phòng học<br/>theo yêu cầu quản lý của nhà trường]

    SAVE_TB --> DONE([Hoàn tất thao tác])
    VIEW_ALL --> DONE
    LOAD_TCH --> DONE
    HIDE_ROOM --> DONE

    style START fill:#e3f2fd,stroke:#1565c0
    style CHK_CONFLICT fill:#fff8e1,stroke:#f9a825,stroke-width:2px
    style SAVE_TB fill:#d4edda,stroke:#28a745
    style HIDE_ROOM fill:#cce5ff,stroke:#007bff,stroke-width:2px
    style DONE fill:#e3f2fd,stroke:#1565c0
"""
    },
    {
        "id": "11_luong_quyet_dinh_phan_loai_3_mau",
        "title": "Sơ đồ luồng quyết định phân loại 3 mức tin cậy Xanh - Vàng - Đỏ",
        "code": """flowchart TD
    START([Kết quả đầu ra của một ô điểm:<br/>Kênh A Số: Val_A, Conf_A<br/>Kênh B Chữ: Val_B, Conf_B]) --> CHK_EMPTY{Ô được phát hiện là<br/>Ô TRỐNG hoặc cả 2 kênh<br/>đều không đọc được?}

    CHK_EMPTY -->|Đúng| RED_EMPTY[🔴 MỨC ĐỎ<br/>Lý do: Ô trống / Kém chất lượng<br/>Hệ thống KHÔNG gợi ý giá trị bừa bãi<br/>Giáo viên bắt buộc tự nhập tay]

    CHK_EMPTY -->|Không| CHK_MATCH{Val_A == Val_B<br/>Giá trị hai kênh<br/>khớp nhau hoàn toàn?}

    CHK_MATCH -->|Khớp nhau| CHK_CONF{Độ tin cậy cả hai kênh<br/>vượt ngưỡng an toàn?<br/>Conf_A >= τ_A AND Conf_B >= τ_B}

    CHK_CONF -->|Đủ tin cậy| GREEN[🟢 MỨC XANH<br/>Độ tin cậy cực cao >= 99.8%<br/>Tự động chấp nhận đề xuất<br/>Giáo viên chỉ cần nhìn lướt xác nhận]

    CHK_CONF -->|Tin cậy thấp| YEL_LOW_CONF[🟡 MỨC VÀNG<br/>Lý do: Khớp giá trị nhưng ảnh mờ/nhiễu<br/>Gợi ý giá trị khớp nhưng yêu cầu GV kiểm tra]

    CHK_MATCH -->|Khác nhau| CHK_SINGLE{Chỉ một kênh đọc được,<br/>kênh kia không hợp lệ?}

    CHK_SINGLE -->|Một kênh| YEL_SINGLE[🟡 MỨC VÀNG<br/>Lý do: Một kênh bị mất nét hoặc lỗi<br/>Gợi ý giá trị kênh đọc được<br/>Yêu cầu GV nhìn ảnh gốc đối soát]

    CHK_SINGLE -->|Cả hai đều đọc nhưng lệch nhau| YEL_CONFLICT[🟡 MỨC VÀNG<br/>Lý do: Hai kênh mâu thuẫn<br/>Ví dụ: Số đọc 7.5, Chữ đọc 'Tám'<br/>KHÔNG gợi ý thiên lệch<br/>Bắt buộc GV nhìn ảnh gốc quyết định]

    GREEN --> SAVE_DB([Ghi kết quả dòng vào CSDL])
    YEL_LOW_CONF --> SAVE_DB
    YEL_SINGLE --> SAVE_DB
    YEL_CONFLICT --> SAVE_DB
    RED_EMPTY --> SAVE_DB

    style START fill:#e3f2fd,stroke:#1565c0
    style GREEN fill:#d4edda,stroke:#28a745,stroke-width:3px
    style YEL_LOW_CONF fill:#fff3cd,stroke:#ffc107,stroke-width:2px
    style YEL_SINGLE fill:#fff3cd,stroke:#ffc107,stroke-width:2px
    style YEL_CONFLICT fill:#fff3cd,stroke:#ffc107,stroke-width:2px
    style RED_EMPTY fill:#f8d7da,stroke:#dc3545,stroke-width:3px
"""
    },
    {
        "id": "12_luong_so_sanh_hien_tai_vs_de_xuat",
        "title": "Sơ đồ so sánh Quy trình Hiện tại vs Quy trình Đề xuất",
        "code": """flowchart LR
    subgraph HIEN_TAI["QUY TRÌNH HIỆN TẠI (THỦ CÔNG)"]
        direction TB
        HT1["1. Chấm thi và ghi điểm<br/>vào Bảng điểm giấy A4"]
        HT2["2. Nộp bảng giấy<br/>cho bộ phận Giáo vụ"]
        HT3["3. GÕ TAY TỪNG Ô VÀO PHẦN MỀM<br/>⚠️ ĐIỂM NGHẼN NGHIỆP VỤ<br/>Mệt mỏi thị giác, tốn hàng chục giờ,<br/>rất dễ gõ nhầm điểm hoặc lệch dòng"]
        HT4["4. In bản kiểm dò ra giấy<br/>và dò tay từng dòng đối chiếu"]
        HT5["5. Ký duyệt thủ công<br/>và chốt sổ điểm"]
        HT1 --> HT2 --> HT3 --> HT4 --> HT5
    end

    subgraph DE_XUAT["QUY TRÌNH ĐỀ XUẤT (ỨNG DỤNG AI & HUMAN-IN-THE-LOOP)"]
        direction TB
        DX1["1. Chấm thi và ghi điểm<br/>vào Bảng điểm giấy A4"]
        DX2["2. Chụp ảnh bảng điểm<br/>và tải lên hệ thống"]
        DX3["3. MÁY TỰ ĐỘNG NHẬN DẠNG 2 KÊNH<br/>- Nắn ảnh & Tách khung lưới chuẩn<br/>- Kênh Số CRNN & Kênh Chữ VietOCR<br/>- Định lượng độ tin cậy toán học"]
        DX4["4. ĐỐI SOÁT 3 MÀU THÔNG MINH<br/>- Dòng Xanh 85%: Tự động khớp<br/>- Dòng Vàng/Đỏ 15%: GV soi ảnh crop<br/>- Duyệt nguyên tử trong 2 phút"]
        DX5["5. Tự động Tổng kết & Xuất Excel<br/>Truy vết lịch sử Append-only"]
        DX1 --> DX2 --> DX3 --> DX4 --> DX5
    end

    style HT3 fill:#ffcdd2,stroke:#d32f2f,stroke-width:3px
    style DX3 fill:#d4edda,stroke:#28a745,stroke-width:2px
    style DX4 fill:#cce5ff,stroke:#007bff,stroke-width:2px
    style DX5 fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
"""
    }
]

def render_diagrams():
    os.makedirs('hinh', exist_ok=True)
    chrome_path = r'C:\Program Files\Google\Chrome\Application\chrome.exe'
    
    html_template = '''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * {{ box-sizing: border-box; }}
  html, body {{
    margin: 0;
    padding: 0;
    background-color: #ffffff;
    overflow: hidden;
  }}
  ::-webkit-scrollbar {{ display: none; }}
  #container {{
    display: inline-block;
    padding: 40px;
    background: #ffffff;
  }}
  .diagram-header {{
    text-align: center;
    margin-bottom: 25px;
  }}
  .diagram-header h2 {{
    margin: 0;
    font-size: 20px;
    color: #1a237e;
    font-family: 'Segoe UI', Arial, sans-serif;
    font-weight: 700;
  }}
  .mermaid {{
    font-size: 14px;
    font-family: 'Segoe UI', Arial, sans-serif;
    font-weight: 500;
  }}
</style>
<script src="mermaid.min.js"></script>
</head>
<body>
<div id="container">
  <div class="diagram-header">
    <h2>{title}</h2>
  </div>
  <div class="mermaid">
{code}
  </div>
</div>
<script>
  mermaid.initialize({{
    startOnLoad: true,
    theme: 'default',
    flowchart: {{
      useMaxWidth: false,
      htmlLabels: true,
      curve: 'basis'
    }}
  }});
</script>
</body>
</html>'''

    print(f"Total diagrams to render: {len(DIAGRAMS)}")

    for idx, d in enumerate(DIAGRAMS, 1):
        diag_id = d["id"]
        diag_title = d["title"]
        diag_code = d["code"]

        html_filename = f"hinh/{diag_id}.html"
        png_filename = f"hinh/{diag_id}.png"

        html_content = html_template.format(title=diag_title, code=diag_code)
        with open(html_filename, 'w', encoding='utf-8') as f:
            f.write(html_content)

        abs_html = os.path.abspath(html_filename).replace('\\', '/')
        abs_png = os.path.abspath(png_filename)

        cmd = [
            chrome_path,
            '--headless=new',
            '--disable-gpu',
            '--hide-scrollbars',
            '--force-device-scale-factor=2',
            f'--screenshot={abs_png}',
            '--window-size=3200,4200',
            '--run-all-compositor-stages-before-draw',
            '--virtual-time-budget=4000',
            f'file:///{abs_html}'
        ]
        
        subprocess.run(cmd, check=True)

        if os.path.exists(abs_png):
            im = Image.open(abs_png)
            bg = Image.new(im.mode, im.size, (255, 255, 255, 255) if im.mode == 'RGBA' else (255, 255, 255))
            diff = ImageChops.difference(im, bg)
            bbox = diff.getbbox()
            if bbox:
                pad = 40
                crop_box = (
                    max(0, bbox[0] - pad),
                    max(0, bbox[1] - pad),
                    min(im.size[0], bbox[2] + pad),
                    min(im.size[1], bbox[3] + pad)
                )
                cropped = im.crop(crop_box)
                cropped.save(abs_png)
                print(f"[{idx}/{len(DIAGRAMS)}] Generated: {diag_id}.png -> final size: {cropped.size}")
            else:
                print(f"[{idx}/{len(DIAGRAMS)}] Generated: {diag_id}.png -> uncropped size: {im.size}")

        if os.path.exists(html_filename):
            os.remove(html_filename)

    print("\nAll 12 diagrams successfully re-rendered with perfect crops into 'hinh/'!")

if __name__ == '__main__':
    render_diagrams()
