import os, subprocess
from PIL import Image, ImageChops

ADDITIONAL_DIAGRAMS = [
    {
        "id": "use_case_nghiep_vu",
        "title": "Sơ đồ Use-Case Nghiệp vụ (Business Use-Case Diagram)",
        "code": """flowchart LR
    subgraph NV_TRAI[" "]
        GVBM(["👤 Giáo viên bộ môn"])
        GVCN(["👤 Giáo viên chủ nhiệm"])
    end

    subgraph NGHIEP_VU["Nghiệp vụ Quản lý Điểm — Trường THPT Bà Điểm"]
        BUC1(["① Chấm bài và ghi điểm<br/>vào bảng điểm giấy"])
        BUC2(["② Nộp và tiếp nhận<br/>bảng điểm"])
        BUC3(["③ Nhập điểm vào<br/>phần mềm quản lý<br/>⚠️ ĐIỂM NGHẼN"])
        BUC4(["④ Đối chiếu và<br/>ký duyệt bảng điểm"])
        BUC5(["⑤ Tổng kết học kỳ<br/>và xếp loại"])
        BUC6(["⑥ Công bố kết quả<br/>cho HS và PHHS"])
    end

    subgraph NV_PHAI[" "]
        NVGV(["👤 Nhân viên giáo vụ"])
        TTCM(["👤 Tổ trưởng CM / BGH"])
        HSPH(["👤 Học sinh & PHHS"])
    end

    GVBM --> BUC1
    GVBM --> BUC2
    GVBM --> BUC4
    GVCN --> BUC6

    NVGV --> BUC2
    NVGV --> BUC3
    NVGV --> BUC5
    TTCM --> BUC4

    BUC6 --> HSPH

    style BUC3 fill:#ffcccc,stroke:#cc0000,stroke-width:3px,color:#660000
    style NGHIEP_VU fill:#f8f9fa,stroke:#6c757d
"""
    },
    {
        "id": "use_case_tong_quat",
        "title": "Sơ đồ Use-Case Hệ thống mức Tổng quát",
        "code": """flowchart LR
    QTV(["👤 Quản trị viên"])
    GV(["👤 Giáo viên"])
    HS(["👤 Học sinh"])
    AI(["🤖 Dịch vụ Nhận dạng"])

    subgraph HE_THONG["Hệ thống Quản lý Điểm có Nhận dạng Bảng điểm Viết tay"]
        direction TB
        N0["Nhóm Cơ bản (UC01–04)<br/>Xác thực · Tài khoản · Phân quyền"]
        N1["Nhóm 1 — Danh mục (UC05–08)<br/>Học sinh · Lớp · Môn · GV · Phân công"]
        N2["Nhóm 2 — Bảng điểm (UC09–10)<br/>Bảng điểm lớp-môn · Lịch sử sửa điểm"]
        N3["Nhóm 3 — Nhận diện (UC11–12)<br/>Tải ảnh · Đọc 2 kênh · Chấm tin cậy"]
        N4["Nhóm 4 — Đối chiếu (UC13)<br/>Soát ba màu · Sửa · Duyệt nguyên tử"]
        N5["Nhóm 5 — Tổng kết (UC14–18)<br/>Tổng kết · Xếp loại · Thống kê · Excel"]
    end

    QTV --- N0
    QTV --- N1
    QTV -.-|chỉ xem| N2
    QTV --- N5

    GV --- N0
    GV -.-|chỉ xem| N1
    GV --- N2
    GV --- N3
    GV --- N4
    GV --- N5

    HS --- N0
    HS -.-|tra cứu cá nhân| N5

    AI --- N3

    style N3 fill:#fff3cd,stroke:#856404,stroke-width:2px
    style N4 fill:#fff3cd,stroke:#856404,stroke-width:2px
"""
    },
    {
        "id": "use_case_chi_tiet",
        "title": "Sơ đồ Use-Case Hệ thống Chi tiết (UC01 – UC18)",
        "code": """flowchart TB
    QTV(["👤 Quản trị viên"])
    GV(["👤 Giáo viên"])
    HS(["👤 Học sinh"])
    AI(["🤖 Dịch vụ Nhận dạng"])

    subgraph COBAN["Nhóm Cơ bản — Quản lý tài khoản và xác thực"]
        UC01(["UC01: Đăng nhập"])
        UC02(["UC02: Đăng xuất"])
        UC03(["UC03: Quản lý tài khoản"])
        UC04(["UC04: Phân quyền vai trò"])
    end

    subgraph DANHMUC["Nhóm 1 — Quản lý danh mục học tập"]
        UC05(["UC05: Quản lý học sinh"])
        UC06(["UC06: Quản lý lớp học"])
        UC07(["UC07: Quản lý môn học & hệ số"])
        UC08(["UC08: Quản lý GV & phân công"])
    end

    subgraph BANGDIEM["Nhóm 2 — Quản lý bảng điểm"]
        UC09(["UC09: Quản lý bảng điểm lớp – môn"])
        UC10(["UC10: Quản lý lịch sử thay đổi điểm"])
    end

    subgraph NHANDIEN["Nhóm 3 — Nhận diện bảng điểm từ ảnh"]
        UC11(["UC11: Tải ảnh & nhận diện viết tay"])
        UC12(["UC12: Đánh giá tin cậy & 3 màu"])
    end

    subgraph DOICHIEU["Nhóm 4 — Đối chiếu và duyệt kết quả"]
        UC13(["UC13: Đối chiếu & duyệt kết quả"])
    end

    subgraph TONGKET["Nhóm 5 — Tổng kết kết quả học tập"]
        UC14(["UC14: Tính điểm tổng kết"])
        UC15(["UC15: Xếp loại kết quả"])
        UC16(["UC16: Thống kê điểm"])
        UC17(["UC17: Xuất báo cáo Excel"])
        UC18(["UC18: Tra cứu điểm cá nhân"])
    end

    QTV --> UC01 & UC02 & UC03 & UC04
    QTV --> UC05 & UC06 & UC07 & UC08
    QTV -.->|chỉ xem| UC09 & UC10
    QTV --> UC16 & UC17

    GV --> UC01 & UC02
    GV -.->|hồ sơ cá nhân| UC03
    GV --> UC09 & UC10
    GV --> UC11
    GV --> UC13
    GV --> UC14 & UC15 & UC16 & UC17

    HS --> UC01 & UC02
    HS -.->|hồ sơ cá nhân| UC03
    HS --> UC18

    AI --- UC11

    UC11 -.->|include| UC12
    UC15 -.->|include| UC14

    style NHANDIEN fill:#fff8e1,stroke:#f9a825,stroke-width:2px
    style DOICHIEU fill:#fff8e1,stroke:#f9a825,stroke-width:2px
"""
    },
    {
        "id": "phan_ra_chuc_nang_bfd",
        "title": "Sơ đồ Phân rã Chức năng (BFD — 6 Phân hệ, 46 Chức năng)",
        "code": """graph TD
    ROOT["0. HỆ THỐNG QUẢN LÝ ĐIỂM"]

    ROOT --> F1["1. Quản lý tài khoản<br/>và xác thực"]
    ROOT --> F2["2. Quản lý danh mục<br/>học tập"]
    ROOT --> F3["3. Quản lý<br/>bảng điểm"]
    ROOT --> F4["4. Nhận dạng bảng điểm<br/>từ ảnh"]
    ROOT --> F5["5. Đối chiếu và duyệt<br/>kết quả"]
    ROOT --> F6["6. Tổng kết<br/>kết quả học tập"]

    F1 --> F11["1.1 Đăng nhập"]
    F1 --> F12["1.2 Đăng xuất"]
    F1 --> F13["1.3 Xem/cập nhật hồ sơ"]
    F1 --> F14["1.4 Đổi mật khẩu"]
    F1 --> F15["1.5 Quản lý tài khoản"]
    F1 --> F16["1.6 Khóa/mở tài khoản"]
    F1 --> F17["1.7 Phân quyền người dùng"]

    F2 --> F21["2.1 Quản lý năm học"]
    F2 --> F22["2.2 Quản lý học kỳ"]
    F2 --> F23["2.3 Quản lý lớp học"]
    F2 --> F24["2.4 Quản lý học sinh"]
    F2 --> F25["2.5 Quản lý giáo viên"]
    F2 --> F26["2.6 Quản lý môn học"]
    F2 --> F27["2.7 QL cột điểm & hệ số"]
    F2 --> F28["2.8 Phân công giảng dạy"]

    F3 --> F31["3.1 Tạo bảng điểm lớp-môn"]
    F3 --> F32["3.2 Tạo lưới điểm sĩ số"]
    F3 --> F33["3.3 Nhập điểm thủ công"]
    F3 --> F34["3.4 Sửa điểm"]
    F3 --> F35["3.5 Xem lịch sử sửa điểm"]
    F3 --> F36["3.6 Theo dõi trạng thái"]
    F3 --> F37["3.7 Chốt & khóa bảng điểm"]

    F4 --> F41["4.1 Chọn bảng & cột điểm"]
    F4 --> F42["4.2 Tải ảnh bảng điểm"]
    F4 --> F43["4.3 Kiểm tra định dạng & SHA256"]
    F4 --> F44["4.4 Nắn ảnh & kiểm định dòng"]
    F4 --> F45["4.5 Tách ảnh từng ô điểm"]
    F4 --> F46["4.6 Nhận dạng kênh Điểm số"]
    F4 --> F47["4.7 Nhận dạng kênh Điểm chữ"]
    F4 --> F48["4.8 So sánh kết quả 2 kênh"]
    F4 --> F49["4.9 Đánh giá độ tin cậy"]

    F5 --> F51["5.1 Xem ảnh ô điểm"]
    F5 --> F52["5.2 Xem kết quả 2 kênh"]
    F5 --> F53["5.3 Lọc kết quả Xanh-Vàng-Đỏ"]
    F5 --> F54["5.4 Sửa giá trị máy đọc"]
    F5 --> F55["5.5 Chọn điểm cuối cùng"]
    F5 --> F56["5.6 Duyệt phiếu nhận dạng"]
    F5 --> F57["5.7 Ghi điểm đã duyệt"]
    F5 --> F58["5.8 Ghi lịch sử & người duyệt"]

    F6 --> F61["6.1 Kiểm tra điểm đã duyệt"]
    F6 --> F62["6.2 Tính điểm theo hệ số"]
    F6 --> F63["6.3 Làm tròn điểm"]
    F6 --> F64["6.4 Xếp loại kết quả"]
    F6 --> F65["6.5 Lưu kết quả & snapshot"]
    F6 --> F66["6.6 Xem điểm & xếp loại"]
    F6 --> F67["6.7 Thống kê & xuất Excel"]

    style ROOT fill:#1a237e,color:#fff,stroke:#0d47a1,stroke-width:2px
    style F1 fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    style F2 fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style F3 fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style F4 fill:#fce4ec,stroke:#c62828,stroke-width:2px
    style F5 fill:#f3e5f5,stroke:#6a1b9a,stroke-width:2px
    style F6 fill:#e0f7fa,stroke:#00695c,stroke-width:2px
"""
    },
    {
        "id": "kien_truc_tong_the",
        "title": "Sơ đồ Kiến trúc Hệ thống Tổng thể (Modular Monolith + AI Worker)",
        "code": """flowchart LR
    subgraph CLIENT["Flutter Client — Web · Android · iOS"]
        WEB["🌐 Web Browser"]
        AND["📱 Android"]
        IOS["📱 iOS"]
    end

    subgraph BACKEND["API Backend — NestJS + TypeScript"]
        direction TB
        AUTH["identity · authorization"]
        CATALOG["students · classes · subjects · teachers"]
        GRADE["gradebooks · audit"]
        RECOG["recognition · review"]
        FINAL["final-results · reports"]
    end

    subgraph INFRA["Tầng Hạ tầng Dữ liệu"]
        PG[("PostgreSQL<br/>16 bảng nghiệp vụ")]
        REDIS[("Redis<br/>BullMQ Queue")]
        MINIO[("MinIO / S3<br/>Object Storage")]
    end

    subgraph WORKER["Recognition Worker"]
        WK["Job Processor<br/>Node.js Worker"]
    end

    subgraph OCR_SVC["Recognition Service — Python FastAPI"]
        PIPE["Pipeline AI:<br/>Nắn ảnh → Tách lưới<br/>→ CRNN (Số) → VietOCR (Chữ)<br/>→ Phân loại 3 màu"]
    end

    CLIENT -->|REST /api/v1| BACKEND
    BACKEND --> PG
    BACKEND --> MINIO
    BACKEND -->|enqueue job| REDIS
    REDIS -->|dequeue| WORKER
    WORKER -->|HTTP call| OCR_SVC
    WORKER --> MINIO
    WORKER --> PG

    style CLIENT fill:#e3f2fd,stroke:#1565c0
    style BACKEND fill:#fff3e0,stroke:#e65100
    style OCR_SVC fill:#fce4ec,stroke:#c62828
"""
    },
    {
        "id": "dfd_muc_ngu_canh",
        "title": "Sơ đồ Luồng Dữ liệu Mức Ngữ cảnh (Context Diagram — Level 0)",
        "code": """flowchart TB
    QTV["👤 Quản trị viên"]
    GV["👤 Giáo viên"]
    HS["👤 Học sinh"]
    AI["🤖 Dịch vụ AI Nhận dạng"]
    S3["☁️ Kho MinIO / S3"]

    SYSTEM(("0.0<br/>HỆ THỐNG<br/>QUẢN LÝ ĐIỂM<br/>& NHẬN DẠNG BẢNG ĐIỂM<br/>VIẾT TAY"))

    QTV -->|"Thông tin tài khoản, danh mục,<br/>phân công, cấu hình hạn chót"| SYSTEM
    SYSTEM -->|"Báo cáo thống kê toàn trường,<br/>nhật ký kiểm toán hệ thống"| QTV

    GV -->|"Điểm nhập tay, ảnh bảng điểm,<br/>yêu cầu đối chiếu & duyệt"| SYSTEM
    SYSTEM -->|"Lưới điểm, danh sách phân công,<br/>ảnh ô cắt + gợi ý AI, file Excel"| GV

    HS -->|"Yêu cầu tra cứu điểm cá nhân"| SYSTEM
    SYSTEM -->|"Điểm thành phần, ĐTB môn,<br/>xếp loại (sau công bố)"| HS

    SYSTEM -->|"Ảnh bảng điểm cần nhận dạng"| AI
    AI -->|"Kết quả 2 kênh số/chữ + độ tin cậy"| SYSTEM

    SYSTEM -->|"Lưu ảnh gốc và ảnh ô cắt"| S3
    S3 -->|"Presigned URL ảnh hiển thị đối chiếu"| SYSTEM

    style SYSTEM fill:#e3f2fd,stroke:#1565c0,stroke-width:3px
"""
    },
    {
        "id": "dfd_muc_1",
        "title": "Sơ đồ Luồng Dữ liệu Mức 1 (Level 1 Data Flow Diagram)",
        "code": """flowchart TB
    QTV["👤 Quản trị viên"]
    GV["👤 Giáo viên"]
    HS["👤 Học sinh"]
    AI["🤖 Dịch vụ AI"]
    OBJ["☁️ MinIO"]

    D1[("D1: nguoi_dung<br/>phien_lam_viec")]
    D2[("D2: hoc_sinh, lop<br/>mon_hoc, phan_cong")]
    D3[("D3: bang_diem<br/>diem_thanh_phan")]
    D4[("D4: phieu_nhan_dien<br/>ket_qua_dong")]
    D5[("D5: lich_su_sua_diem<br/>Append-only")]
    D6[("D6: ket_qua_tong_ket<br/>snapshot_he_so")]

    P1(("1.0<br/>Xác thực<br/>& Phân quyền"))
    P2(("2.0<br/>QL Danh mục<br/>& Phân công"))
    P3(("3.0<br/>QL Bảng điểm<br/>& Nhập tay"))
    P4(("4.0<br/>Nhận dạng<br/>& Phân loại<br/>3 màu"))
    P5(("5.0<br/>Đối chiếu<br/>& Duyệt điểm<br/>nguyên tử"))
    P6(("6.0<br/>Tổng kết<br/>Thống kê<br/>Báo cáo"))

    QTV & GV & HS -->|"Đăng nhập / Đổi MK"| P1
    P1 <-->|"Đọc/Ghi tài khoản, phiên"| D1

    QTV -->|"Thiết lập danh mục"| P2
    P2 <-->|"CRUD danh mục"| D2

    GV -->|"Nhập/sửa điểm tay"| P3
    QTV -->|"Cấu hình lịch mở/khóa"| P3
    P3 <-->|"Đọc/Ghi ô điểm"| D3
    P3 -->|"Ghi log sửa điểm"| D5

    GV -->|"Tải ảnh bảng điểm"| P4
    P4 -->|"Lưu ảnh gốc"| OBJ
    P4 -->|"Job nhận dạng"| AI
    AI -->|"Kết quả 2 kênh"| P4
    P4 -->|"Lưu phiếu + kết quả dòng"| D4

    GV -->|"Xem đối chiếu + Duyệt"| P5
    D4 -->|"Đọc kết quả dòng"| P5
    OBJ -->|"Signed URL ảnh ô"| P5
    P5 -->|"Ghi điểm DA_DUYET"| D3
    P5 -->|"Ghi nhật ký duyệt"| D5
    P5 -->|"Cập nhật phiếu DA_DUYET"| D4

    D3 -->|"Đọc điểm DA_DUYET"| P6
    D2 -->|"Đọc hệ số môn"| P6
    P6 -->|"Lưu ĐTB + Xếp loại"| D6
    P6 -->|"Xuất Excel"| GV
    P6 -->|"Xuất Excel"| QTV
    HS -->|"Tra cứu điểm"| P6

    style P1 fill:#e3f2fd,stroke:#1565c0
    style P2 fill:#e8f5e9,stroke:#2e7d32
    style P3 fill:#fff3e0,stroke:#e65100
    style P4 fill:#fce4ec,stroke:#c62828
    style P5 fill:#f3e5f5,stroke:#6a1b9a
    style P6 fill:#e0f7fa,stroke:#00695c
"""
    },
    {
        "id": "sequence_uc11_nhan_dien",
        "title": "Sơ đồ Tuần tự UC11: Tải ảnh và Nhận diện Bảng điểm",
        "code": """sequenceDiagram
    actor GV as 👤 Giáo viên
    participant UI as ManHinhTaiAnh<br/>«boundary»
    participant CTRL as DieuKhienNhanDien<br/>«control»
    participant IMG as XuLyAnh<br/>«control»
    participant OCR as DichVuNhanDang<br/>«service»
    participant PHIEU as PhieuNhanDien<br/>«entity»
    participant DONG as KetQuaDong<br/>«entity»

    GV->>UI: 1. Chọn bảng điểm, khai báo số dòng
    GV->>UI: 2. Tải ảnh bảng điểm lên
    UI->>CTRL: 3. xuLyAnhTaiLen(anh, soDong)
    CTRL->>PHIEU: 4. tao(trangThai = DANG_XU_LY)
    CTRL->>IMG: 5. nanPhoiCanh() ×2, tachKhungLuoi()

    IMG-->>CTRL: 6. soDuongKe

    alt soDuongKe ≠ soDong khai báo — CHỐT CHẶN
        CTRL->>PHIEU: 7. ganCo(LOI) — yêu cầu chụp lại
    end

    loop Với mỗi ô điểm trên tờ
        CTRL->>IMG: 8. catO(), doLuongMuc()
        Note right of IMG: Ô trống → không gọi mô hình
        CTRL->>OCR: 9. predict(ô Điểm số) — Kênh A
        CTRL->>OCR: 10. predict(ô Điểm chữ) — Kênh B
        OCR-->>CTRL: 11. (giaTri, doTinCay) cho từng kênh
        CTRL->>CTRL: 12. giaiMaCoRangBuoc(), doiChieuCheo()
        Note right of CTRL: «include» UC12 — phân loại 3 màu
        CTRL->>DONG: 13. tao(anhOCat, kênh A, kênh B, doTinCay, mucPhanLoai)
    end

    CTRL->>PHIEU: 14. capNhatTrangThai(CHO_DOI_CHIEU)
    CTRL-->>UI: 15. tomTat(tổng dòng, số xanh/vàng/đỏ)
    UI-->>GV: 16. Hiển thị màn hình tóm tắt kết quả
"""
    },
    {
        "id": "sequence_uc13_doi_chieu",
        "title": "Sơ đồ Tuần tự UC13: Đối chiếu và Duyệt điểm Nguyên tử",
        "code": """sequenceDiagram
    actor GV as 👤 Giáo viên
    participant UI as ManHinhDoiChieu<br/>«boundary»
    participant CTRL as DieuKhienDoiChieu<br/>«control»
    participant DONG as KetQuaDong<br/>«entity»
    participant DIEM as DiemThanhPhan<br/>«entity»
    participant LOG as LichSuSuaDiem<br/>«entity»

    GV->>UI: 1. Mở phiếu trạng thái CHO_DOI_CHIEU
    UI->>CTRL: 2. layDanhSachDong(maPhieu)
    CTRL->>DONG: 3. truyVan(maPhieu)
    DONG-->>CTRL: 4. dòng + ảnh ô cắt + 2 kênh + tin cậy
    CTRL-->>UI: 5. Dựng bảng soát 3 màu, lọc Vàng/Đỏ
    UI-->>GV: 6. Hiện ảnh ô gốc cạnh giá trị máy đọc

    loop Với mỗi dòng Vàng hoặc Đỏ
        GV->>UI: 7. Nhập hoặc chọn giá trị đúng
        UI->>UI: 8. kiemTraHopLe(0.0 – 10.0, bước 0.1)
    end

    GV->>UI: 9. Bấm DUYỆT
    UI->>CTRL: 10. duyet(maPhieu, giaTriChot[])

    alt Còn dòng chưa được quyết định
        CTRL-->>UI: 11. Chặn duyệt, cuộn tới dòng thiếu
    end

    rect rgb(232, 245, 233)
        Note over CTRL,LOG: GIAO DỊCH NGUYÊN TỬ (Atomic Transaction)
        CTRL->>DIEM: 12. ghiGiaTri(giaTriChot) — DA_DUYET
        CTRL->>LOG: 13. ghiNhatKy(cũ → mới, người sửa, thời điểm)
        CTRL->>DONG: 14. dongDau(nguoiDuyet, thoiDiemDuyet)
    end

    CTRL-->>UI: 15. Tóm tắt: máy đúng N, người sửa M
    UI-->>GV: 16. Hiển thị kết quả duyệt thành công
"""
    },
    {
        "id": "erd_16_bang",
        "title": "Sơ đồ Quan hệ Thực thể (ERD — 16 Bảng Nghiệp vụ)",
        "code": """erDiagram
    NGUOI_DUNG {
        int ma_nguoi_dung PK
        string ten_dang_nhap UK
        string mat_khau_ma_hoa
        enum vai_tro "QTV | GV | HS"
        enum trang_thai "HOAT_DONG | KHOA"
    }

    GIAO_VIEN {
        int ma_giao_vien PK
        int ma_nguoi_dung FK
        string ho_ten
        string to_chuyen_mon
    }

    HOC_SINH {
        int ma_hoc_sinh PK
        int ma_nguoi_dung FK
        string ho_ten
        date ngay_sinh
    }

    NAM_HOC {
        int ma_nam_hoc PK
        string ten_nam_hoc
    }

    HOC_KY {
        int ma_hoc_ky PK
        int ma_nam_hoc FK
        string ten_hoc_ky
        int thu_tu
    }

    LOP {
        int ma_lop PK
        string ten_lop
        int khoi
        int ma_nam_hoc FK
        int si_so
    }

    MON_HOC {
        int ma_mon PK
        string ten_mon
    }

    THANH_PHAN_DIEM {
        int ma_thanh_phan PK
        int ma_mon FK
        string ten_thanh_phan
        int he_so
        bool bat_buoc
    }

    PHAN_CONG_GIANG_DAY {
        int ma_phan_cong PK
        int ma_giao_vien FK
        int ma_lop FK
        int ma_mon FK
        int ma_hoc_ky FK
    }

    BANG_DIEM {
        int ma_bang_diem PK
        int ma_lop FK
        int ma_mon FK
        int ma_hoc_ky FK
        enum trang_thai "DANG_NHAP_LIEU | DA_CHOT"
    }

    DIEM_THANH_PHAN {
        int ma_diem PK
        int ma_bang_diem FK
        int ma_hoc_sinh FK
        int ma_thanh_phan FK
        decimal gia_tri "NULL hoac 0.0-10.0"
        enum trang_thai "CHUA_CO | CHO_DOI_CHIEU | DA_DUYET"
        enum nguon_nhap "NHAP_TAY | NHAN_DIEN"
    }

    LICH_SU_SUA_DIEM {
        int ma_lich_su PK
        int ma_diem FK
        decimal gia_tri_cu
        decimal gia_tri_moi
        int nguoi_sua FK
        timestamp thoi_diem
        string ly_do
    }

    PHIEU_NHAN_DIEN {
        int ma_phieu PK
        int ma_bang_diem FK
        string ma_bam_tep UK "SHA-256"
        enum trang_thai "DANG_XU_LY | CHO_DOI_CHIEU | DA_DUYET | LOI"
        int nguoi_duyet FK
        timestamp thoi_diem_duyet
    }

    KET_QUA_DONG {
        int ma_ket_qua PK
        int ma_phieu FK
        int thu_tu_dong
        string anh_o_cat
        decimal gia_tri_kenh_a
        decimal do_tin_cay_a
        decimal gia_tri_kenh_b
        decimal do_tin_cay_b
        enum ket_luan "KHOP | LECH | MOT_KENH | KHONG_DOC_DUOC"
        enum muc_phan_loai "XANH | VANG | DO"
        decimal ma_diem "nullable - chi gan khi duyet"
    }

    KET_QUA_TONG_KET {
        int ma_ket_qua PK
        int ma_hoc_sinh FK
        int ma_mon FK
        int ma_hoc_ky FK
        decimal diem_tong_ket
        string xep_loai
        string phien_ban_he_so
        jsonb bo_he_so
    }

    TU_DIEN_DIEM_CHU {
        int ma_cach_doc PK
        string cach_doc UK
        decimal gia_tri "0.0 - 10.0"
    }

    NGUOI_DUNG ||--o| GIAO_VIEN : "1 - 0..1"
    NGUOI_DUNG ||--o| HOC_SINH : "1 - 0..1"
    NAM_HOC ||--|{ HOC_KY : "1 - *"
    NAM_HOC ||--|{ LOP : "1 - *"
    MON_HOC ||--|{ THANH_PHAN_DIEM : "1 - 1..*"
    GIAO_VIEN ||--|{ PHAN_CONG_GIANG_DAY : "1 - *"
    LOP ||--|{ PHAN_CONG_GIANG_DAY : "1 - *"
    MON_HOC ||--|{ PHAN_CONG_GIANG_DAY : "1 - *"
    HOC_KY ||--|{ PHAN_CONG_GIANG_DAY : "1 - *"
    LOP ||--|{ BANG_DIEM : "1 - *"
    MON_HOC ||--|{ BANG_DIEM : "1 - *"
    HOC_KY ||--|{ BANG_DIEM : "1 - *"
    BANG_DIEM ||--|{ DIEM_THANH_PHAN : "1 - *"
    HOC_SINH ||--|{ DIEM_THANH_PHAN : "1 - *"
    THANH_PHAN_DIEM ||--|{ DIEM_THANH_PHAN : "1 - *"
    DIEM_THANH_PHAN ||--o{ LICH_SU_SUA_DIEM : "1 - 0..*"
    BANG_DIEM ||--o{ PHIEU_NHAN_DIEN : "1 - 0..*"
    PHIEU_NHAN_DIEN ||--|{ KET_QUA_DONG : "1 - *"
    HOC_SINH ||--o{ KET_QUA_TONG_KET : "1 - 0..*"
"""
    },
    {
        "id": "trang_thai_phieu",
        "title": "Sơ đồ Trạng thái Vòng đời Phiếu Nhận diện",
        "code": """stateDiagram-v2
    [*] --> DANG_XU_LY : GV tải ảnh lên\\nTạo phiếu mới
    DANG_XU_LY --> CHO_DOI_CHIEU : Worker xử lý thành công\\nCó kết quả 2 kênh
    DANG_XU_LY --> LOI : Lệch lưới số dòng\\nhoặc Service AI lỗi
    CHO_DOI_CHIEU --> DA_DUYET : GV đối chiếu và bấm Duyệt\\n(Giao dịch nguyên tử)
    CHO_DOI_CHIEU --> LOI : Hết hạn nhập điểm Deadline\\n(ADR-0014 tự động)
    LOI --> DANG_XU_LY : GV tải lại ảnh mới\\nvà chạy lại pipeline
    DA_DUYET --> [*]
"""
    },
    {
        "id": "trang_thai_bang_diem",
        "title": "Sơ đồ Trạng thái Vòng đời Bảng điểm Lớp - Môn",
        "code": """stateDiagram-v2
    [*] --> DANG_NHAP_LIEU : Tạo bảng điểm mới\\nSinh lưới theo sĩ số lớp
    state DANG_NHAP_LIEU {
        [*] --> CotMo : Cột đang mở nhập liệu
        CotMo --> CotMo : GV nhập/sửa điểm tay\\nhoặc duyệt phiếu OCR
        CotMo --> CotKhoa : QTV đặt Deadline\\nvà hệ thống tự động khóa\\n(điền 0.0 cho ô thiếu)
    }
    DANG_NHAP_LIEU --> DA_CHOT : Tất cả các cột\\nđã bị khóa
    DA_CHOT --> [*]
"""
    },
    {
        "id": "trang_thai_o_diem",
        "title": "Sơ đồ Trạng thái Vòng đời Ô điểm thành phần",
        "code": """stateDiagram-v2
    [*] --> CHUA_CO : Tạo lưới điểm ban đầu\\nGiá trị = NULL
    CHUA_CO --> CHO_DOI_CHIEU : Đề xuất từ phiếu OCR\\n(nguồn: NHAN_DIEN)
    CHUA_CO --> DA_DUYET : GV nhập tay trực tiếp\\n(nguồn: NHAP_TAY)
    CHO_DOI_CHIEU --> DA_DUYET : GV duyệt phiếu OCR\\nGiao dịch nguyên tử
    DA_DUYET --> DA_DUYET : GV sửa điểm trong hạn\\n(sinh bản ghi lịch sử mới)
    CHUA_CO --> DA_DUYET : Hết hạn Deadline\\nHệ thống tự điền 0.0 (ADR-0014)
"""
    }
]

def render_additional():
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

    print(f"Total additional diagrams to render: {len(ADDITIONAL_DIAGRAMS)}")

    for idx, d in enumerate(ADDITIONAL_DIAGRAMS, 1):
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
            '--window-size=3500,4500',
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
                print(f"[{idx}/{len(ADDITIONAL_DIAGRAMS)}] Generated: {diag_id}.png -> final size: {cropped.size}")
            else:
                print(f"[{idx}/{len(ADDITIONAL_DIAGRAMS)}] Generated: {diag_id}.png -> uncropped size: {im.size}")

        if os.path.exists(html_filename):
            os.remove(html_filename)

    print("\nAll additional diagrams successfully rendered into 'hinh/'!")

if __name__ == '__main__':
    render_additional()
