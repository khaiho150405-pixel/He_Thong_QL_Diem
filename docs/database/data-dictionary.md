# Data dictionary — baseline

Nguồn: HTML §07–08 và AGENTS.md §6–8. Tên Prisma và tên PostgreSQL trùng nhau, không có mapping ngầm. `?` nghĩa nullable; trường không có default phải được cung cấp. `@id/@unique/@@unique` là PK/UQ, `@db` là kiểu PostgreSQL. Tất cả FK dùng RESTRICT cho delete/update và có index riêng trừ PK/UQ đã đủ. Các back relation Prisma không tạo cột.

## nguoi_dung

| Cột (DB = code)      | Kiểu, nullable, default và ràng buộc |
| -------------------- | ------------------------------------ |
| ma_nguoi_dung        | `Int @id @default(autoincrement())`  |
| ten_dang_nhap        | `String @unique @db.VarChar(50)`     |
| mat_khau_ma_hoa      | `String @db.VarChar(255)`            |
| vai_tro              | `VaiTro`                             |
| trang_thai           | `Boolean @default(true)`             |
| so_lan_dang_nhap_sai | `Int @default(0) @db.SmallInt`       |
| khoa_den             | `DateTime? @db.Timestamptz(6)`       |

## giao_vien

| Cột (DB = code) | Kiểu, nullable, default và ràng buộc |
| --------------- | ------------------------------------ |
| ma_giao_vien    | `Int @id`                            |
| ho_ten          | `String @db.VarChar(100)`            |
| to_chuyen_mon   | `String? @db.VarChar(50)`            |
| email           | `String? @db.VarChar(254)`           |
| dien_thoai      | `String? @db.VarChar(20)`            |

FK: `ma_giao_vien` → `nguoi_dung.ma_nguoi_dung`.

## nam_hoc

| Cột (DB = code) | Kiểu, nullable, default và ràng buộc |
| --------------- | ------------------------------------ |
| ma_nam_hoc      | `Int @id @default(autoincrement())`  |
| ten             | `String @unique @db.VarChar(20)`     |
| ngay_bat_dau    | `DateTime @db.Date`                  |
| ngay_ket_thuc   | `DateTime @db.Date`                  |
| hien_hanh       | `Boolean @default(false)`            |

## hoc_ky

| Cột (DB = code) | Kiểu, nullable, default và ràng buộc |
| --------------- | ------------------------------------ |
| ma_hoc_ky       | `Int @id @default(autoincrement())`  |
| ma_nam_hoc      | `Int`                                |
| ten             | `String @db.VarChar(20)`             |
| thu_tu          | `Int @db.SmallInt`                   |
| ngay_bat_dau    | `DateTime @db.Date`                  |
| ngay_ket_thuc   | `DateTime @db.Date`                  |

Khóa ghép: `@@unique([ma_nam_hoc, thu_tu])`.

FK: `ma_nam_hoc` → `nam_hoc.ma_nam_hoc`.

## lop

| Cột (DB = code) | Kiểu, nullable, default và ràng buộc |
| --------------- | ------------------------------------ |
| ma_lop          | `Int @id @default(autoincrement())`  |
| ma_nam_hoc      | `Int`                                |
| ma_gv_chu_nhiem | `Int`                                |
| ten_lop         | `String @db.VarChar(20)`             |
| khoi            | `Int @db.SmallInt`                   |

Khóa ghép: `@@unique([ma_nam_hoc, ten_lop])`.

FK: `ma_nam_hoc` → `nam_hoc.ma_nam_hoc`; `ma_gv_chu_nhiem` → `giao_vien.ma_giao_vien`.

## hoc_sinh

| Cột (DB = code) | Kiểu, nullable, default và ràng buộc |
| --------------- | ------------------------------------ |
| ma_hoc_sinh     | `Int @id @default(autoincrement())`  |
| ma_nguoi_dung   | `Int? @unique`                       |
| ma_lop          | `Int`                                |
| ho_ten          | `String @db.VarChar(100)`            |
| ngay_sinh       | `DateTime @db.Date`                  |
| dang_theo_hoc   | `Boolean @default(true)`             |

FK: `ma_nguoi_dung` → `nguoi_dung.ma_nguoi_dung`; `ma_lop` → `lop.ma_lop`.

## mon_hoc

| Cột (DB = code) | Kiểu, nullable, default và ràng buộc |
| --------------- | ------------------------------------ |
| ma_mon          | `Int @id @default(autoincrement())`  |
| ten_mon         | `String @unique @db.VarChar(80)`     |
| so_tiet_tuan    | `Int @db.SmallInt`                   |

## thanh_phan_diem

| Cột (DB = code) | Kiểu, nullable, default và ràng buộc |
| --------------- | ------------------------------------ |
| ma_thanh_phan   | `Int @id @default(autoincrement())`  |
| ma_mon          | `Int`                                |
| ten_thanh_phan  | `String @db.VarChar(50)`             |
| he_so           | `Decimal @db.Decimal(3,2)`           |
| bat_buoc        | `Boolean @default(true)`             |
| thu_tu_hien_thi | `Int @db.SmallInt`                   |

Khóa ghép: `@@unique([ma_mon, ten_thanh_phan])`.

FK: `ma_mon` → `mon_hoc.ma_mon`.

## phan_cong_giang_day

| Cột (DB = code) | Kiểu, nullable, default và ràng buộc |
| --------------- | ------------------------------------ |
| ma_phan_cong    | `Int @id @default(autoincrement())`  |
| ma_giao_vien    | `Int`                                |
| ma_lop          | `Int`                                |
| ma_mon          | `Int`                                |
| ma_hoc_ky       | `Int`                                |
| ngay_phan_cong  | `DateTime @db.Date`                  |

Khóa ghép: `@@unique([ma_lop, ma_mon, ma_hoc_ky])`.

FK: `ma_giao_vien` → `giao_vien.ma_giao_vien`; `ma_lop` → `lop.ma_lop`; `ma_mon` → `mon_hoc.ma_mon`; `ma_hoc_ky` → `hoc_ky.ma_hoc_ky`.

## bang_diem

| Cột (DB = code) | Kiểu, nullable, default và ràng buộc         |
| --------------- | -------------------------------------------- |
| ma_bang_diem    | `Int @id @default(autoincrement())`          |
| ma_lop          | `Int`                                        |
| ma_mon          | `Int`                                        |
| ma_hoc_ky       | `Int`                                        |
| trang_thai      | `TrangThaiBangDiem @default(DANG_NHAP_LIEU)` |
| version         | `Int @default(0)`                            |

Khóa ghép: `@@unique([ma_lop, ma_mon, ma_hoc_ky])`.

FK: `ma_lop` → `lop.ma_lop`; `ma_mon` → `mon_hoc.ma_mon`; `ma_hoc_ky` → `hoc_ky.ma_hoc_ky`.

## diem_thanh_phan

| Cột (DB = code) | Kiểu, nullable, default và ràng buộc   |
| --------------- | -------------------------------------- |
| ma_diem         | `BigInt @id @default(autoincrement())` |
| ma_bang_diem    | `Int`                                  |
| ma_hoc_sinh     | `Int`                                  |
| ma_thanh_phan   | `Int`                                  |
| gia_tri         | `Decimal? @db.Decimal(3,1)`            |
| trang_thai      | `TrangThaiDiem @default(CHUA_CO)`      |
| nguon_nhap      | `NguonNhap @default(NHAP_TAY)`         |

Khóa ghép: `@@unique([ma_bang_diem, ma_hoc_sinh, ma_thanh_phan])`.

FK: `ma_bang_diem` → `bang_diem.ma_bang_diem`; `ma_hoc_sinh` → `hoc_sinh.ma_hoc_sinh`; `ma_thanh_phan` → `thanh_phan_diem.ma_thanh_phan`.

## lich_su_sua_diem

| Cột (DB = code) | Kiểu, nullable, default và ràng buộc          |
| --------------- | --------------------------------------------- |
| ma_lich_su      | `BigInt @id @default(autoincrement())`        |
| ma_diem         | `BigInt`                                      |
| nguoi_sua       | `Int`                                         |
| gia_tri_cu      | `Decimal? @db.Decimal(3,1)`                   |
| gia_tri_moi     | `Decimal? @db.Decimal(3,1)`                   |
| ly_do           | `String @db.VarChar(500)`                     |
| thoi_diem       | `DateTime @default(now()) @db.Timestamptz(6)` |

FK: `ma_diem` → `diem_thanh_phan.ma_diem`; `nguoi_sua` → `nguoi_dung.ma_nguoi_dung`.

## ket_qua_tong_ket

| Cột (DB = code) | Kiểu, nullable, default và ràng buộc          |
| --------------- | --------------------------------------------- |
| ma_ket_qua      | `BigInt @id @default(autoincrement())`        |
| ma_hoc_sinh     | `Int`                                         |
| ma_mon          | `Int`                                         |
| ma_hoc_ky       | `Int`                                         |
| diem_tong_ket   | `Decimal @db.Decimal(3,1)`                    |
| xep_loai        | `String? @db.VarChar(20)`                     |
| phien_ban_he_so | `String @db.VarChar(20)`                      |
| bo_he_so        | `Json`                                        |
| ngay_tinh       | `DateTime @default(now()) @db.Timestamptz(6)` |

Khóa ghép: `@@unique([ma_hoc_sinh, ma_mon, ma_hoc_ky])`.

FK: `ma_hoc_sinh` → `hoc_sinh.ma_hoc_sinh`; `ma_mon` → `mon_hoc.ma_mon`; `ma_hoc_ky` → `hoc_ky.ma_hoc_ky`.

## phieu_nhan_dien

| Cột (DB = code)   | Kiểu, nullable, default và ràng buộc          |
| ----------------- | --------------------------------------------- |
| ma_phieu          | `BigInt @id @default(autoincrement())`        |
| ma_bang_diem      | `Int`                                         |
| ma_thanh_phan     | `Int`                                         |
| nguoi_tai         | `Int`                                         |
| ma_bam_tep        | `String @unique @db.VarChar(64)`              |
| duong_dan_anh_goc | `String @db.VarChar(512)`                     |
| so_dong_khai_bao  | `Int`                                         |
| so_dong_nhan_dien | `Int?`                                        |
| trang_thai        | `TrangThaiPhieu @default(DANG_XU_LY)`         |
| ma_loi            | `String? @db.VarChar(80)`                     |
| phien_ban_mo_hinh | `String? @db.VarChar(80)`                     |
| version           | `Int @default(0)`                             |
| ngay_tao          | `DateTime @default(now()) @db.Timestamptz(6)` |

FK: `ma_bang_diem` → `bang_diem.ma_bang_diem`; `ma_thanh_phan` → `thanh_phan_diem.ma_thanh_phan`; `nguoi_tai` → `nguoi_dung.ma_nguoi_dung`.

Cột bổ sung theo ADR-0016 (migration 202610190001, P2): `ma_mau Int?` → `mau_bang_diem.ma_mau` (FK RESTRICT, chỉ mục một phần `WHERE ma_mau IS NOT NULL`). Từ P3 chỉ phiếu thuộc lô ghi cột này; cũng dùng để biết mẫu đã được phiếu tham chiếu hay chưa (`TEMPLATE_IN_USE`).

Cột bổ sung cho lô (migration 202610200001, P3): `ma_lo BigInt?` → `lo_nhan_dien.ma_lo` (RESTRICT) và `chi_so_cot_mau Int?` (CHECK 0..63) — cùng NULL (phiếu một ảnh cũ) hoặc cùng có giá trị kèm `ma_mau` (CHECK `phieu_lo_day_du`). Duy nhất `(ma_lo, ma_thanh_phan)` và `(ma_lo, chi_so_cot_mau)`. `ma_bam_tep` của phiếu thuộc lô là SHA-256 của `checksum các trang theo thứ tự (nối bằng ',') + ':' + mã thành phần`, nên chỉ mục duy nhất một phần `WHERE trang_thai <> 'DA_HUY'` vẫn phát hiện tải trùng. `duong_dan_anh_goc` là ảnh trang 1; ảnh các trang nằm ở `trang_lo_nhan_dien`.

## lo_nhan_dien (ADR-0016 mục 3, bảng kỹ thuật — không thuộc 16 bảng nghiệp vụ)

| Cột (DB = code)   | Kiểu, nullable, default và ràng buộc                                                         |
| ----------------- | -------------------------------------------------------------------------------------------- |
| ma_lo             | `BigInt @id @default(autoincrement())`                                                       |
| ma_bang_diem      | `Int` → `bang_diem.ma_bang_diem` (RESTRICT)                                                  |
| ma_mau            | `Int` → `mau_bang_diem.ma_mau` (RESTRICT)                                                    |
| nguoi_tai         | `Int` → `nguoi_dung.ma_nguoi_dung` (RESTRICT)                                                |
| so_trang          | `Int`; CHECK 1..4                                                                            |
| trang_thai        | `TrangThaiLo @default(DANG_XU_LY)` (`DANG_XU_LY`, `XONG`, `LOI`, `DA_HUY`)                   |
| ma_loi            | `String? @db.VarChar(80)`; CHECK: bắt buộc khi `LOI`, chỉ có khi `LOI`/`DA_HUY`              |
| trang_loi         | `Int?`; chỉ khi có `ma_loi`, trong `1..so_trang`; NULL khi lỗi không gắn với trang           |
| phien_ban_mo_hinh | `String? @db.VarChar(80)`                                                                    |
| version           | `Int @default(0)`; tăng mỗi lần đổi trạng thái                                               |
| ly_do_huy         | `String? @db.VarChar(200)`; cùng `nguoi_huy`, `thoi_diem_huy`: có đủ khi và chỉ khi `DA_HUY` |
| nguoi_huy         | `Int?` → `nguoi_dung.ma_nguoi_dung`                                                          |
| thoi_diem_huy     | `DateTime? @db.Timestamptz(6)`                                                               |
| ngay_tao          | `DateTime @default(now()) @db.Timestamptz(6)`                                                |

Runtime chỉ `SELECT`; ghi qua hàm `SECURITY DEFINER`, tất cả yêu cầu giao dịch `SERIALIZABLE`: `tao_lo_nhan_dien` (phiên giáo viên được phân công; tạo lô, trang, phiếu, danh sách lớp, audit, idempotency `RECOGNITION_BATCH_UPLOAD` và MỘT sự kiện outbox `RECOGNITION_BATCH_REQUESTED`), `luu_ket_qua_lo` (ghi kết quả mọi phiếu của lô; lô `DA_HUY`/`XONG` thì bỏ qua), `danh_dau_lo_nhan_dien_loi` (cả lô và mọi phiếu đang xử lý → `LOI` cùng mã) và `huy_lo_nhan_dien` (hủy mềm mọi phiếu chưa duyệt; idempotency `RECOGNITION_BATCH_CANCEL`; lô phải thuộc đúng bảng điểm). Trigger chặn DELETE/TRUNCATE: không hard-delete lô.

## trang_lo_nhan_dien (ADR-0016 mục 3, bảng kỹ thuật)

| Cột (DB = code) | Kiểu, nullable, default và ràng buộc                                        |
| --------------- | --------------------------------------------------------------------------- |
| ma_lo           | `BigInt` → `lo_nhan_dien.ma_lo` (RESTRICT)                                  |
| so_trang        | `Int`; CHECK 1..4                                                           |
| ma_bam_tep      | `String @db.Char(64)`; CHECK SHA-256 hex                                    |
| duong_dan_anh   | `String @db.VarChar(512)`; CHECK `^recognition/original/<uuid>.(png\|jpg)$` |

Khóa chính `(ma_lo, so_trang)`; duy nhất `(ma_lo, ma_bam_tep)` (một ảnh không dùng cho hai trang). Trigger chặn UPDATE/DELETE/TRUNCATE: trang là bất biến.

## mau_bang_diem (ADR-0016, bảng danh mục — không thuộc 16 bảng nghiệp vụ baseline)

| Cột (DB = code)   | Kiểu, nullable, default và ràng buộc                                                                         |
| ----------------- | ------------------------------------------------------------------------------------------------------------ |
| ma_mau            | `Int @id @default(autoincrement())`                                                                          |
| ten_mau           | `String @db.VarChar(100)`; CHECK không rỗng                                                                  |
| mo_ta             | `String? @db.VarChar(500)`                                                                                   |
| trang_thai        | `TrangThaiMau @default(NHAP)` (`NHAP`, `DANG_DUNG`, `NGUNG`)                                                 |
| phien_ban         | `Int @default(1)`; CHECK ≥ 1                                                                                 |
| ma_mau_goc        | `Int?`; CHECK: null khi và chỉ khi `phien_ban = 1`, khác chính nó                                            |
| chu_ky_luoi       | `Json`; CHECK: object, `version = 1`, `columnWidths` là mảng 2–64 phần tử (dịch vụ nhận dạng tính, ADR-0016) |
| duong_dan_anh_mau | `String @db.VarChar(512)`; CHECK `^form-templates/<uuid>.(png\|jpg)$` (khóa object private)                  |
| ma_bam_anh_mau    | `String @db.Char(64)`; CHECK SHA-256 hex                                                                     |
| nguoi_tao         | `Int` → `nguoi_dung.ma_nguoi_dung`                                                                           |
| ngay_tao          | `DateTime @default(now()) @db.Timestamptz(6)`                                                                |
| version           | `Int @default(0)`; khóa lạc quan (`expectedVersion`), tăng khi sửa/đổi trạng thái                            |

Duy nhất: `(coalesce(ma_mau_goc, ma_mau), phien_ban)` (chỉ mục biểu thức, Prisma không biểu diễn được). Trigger `mau_bang_diem_khong_xoa` chặn DELETE: không hard-delete mẫu. Runtime chỉ `SELECT`; mọi ghi qua hàm `SECURITY DEFINER` `luu_mau_bang_diem` (chế độ `TAO` / `SUA` / `PHIEN_BAN`) và `doi_trang_thai_mau_bang_diem` (`NHAP→DANG_DUNG`, `NHAP|DANG_DUNG→NGUNG`): kiểm phiên QTV, `SERIALIZABLE`, version, ghi `nhat_ky_bao_mat` trong cùng giao dịch. Luật nhiều dòng (đủ cột 0..n-1, đúng một `HO_TEN`, tối đa một `STT`, ít nhất một `DIEM`, `(nhóm, thứ tự)` không trùng, `DIEM_CHU` trỏ tới `DIEM` có thật, mỗi `DIEM` tối đa một cột chữ) kiểm trong `kiem_tra_dinh_nghia_mau`, lặp lại luật của `form-templates/domain/definition.ts`.

## cot_mau (ADR-0016)

| Cột (DB = code)   | Kiểu, nullable, default và ràng buộc                               |
| ----------------- | ------------------------------------------------------------------ |
| ma_mau            | `Int` → `mau_bang_diem.ma_mau` (RESTRICT)                          |
| chi_so_cot        | `Int`; CHECK 0..63; cột dữ liệu trái → phải                        |
| vai_tro           | `VaiTroCot` (`STT`, `HO_TEN`, `DIEM`, `DIEM_CHU`, `BO_QUA`)        |
| loai_he_so        | `String? @db.VarChar(2)`; chỉ `DIEM`: `TX`/`GK`/`CK`               |
| thu_tu_trong_nhom | `Int?`; chỉ `DIEM`: 1..20                                          |
| cot_diem_di_kem   | `Int?`; chỉ `DIEM_CHU`: `chi_so_cot` của cột `DIEM`, khác chính nó |
| nhan_tieu_de      | `String? @db.VarChar(100)`; CHECK không rỗng                       |

Khóa chính `(ma_mau, chi_so_cot)`. CHECK `cot_mau_theo_vai_tro` ràng buộc các trường theo vai trò. Duy nhất `(ma_mau, loai_he_so, thu_tu_trong_nhom)` và `(ma_mau, cot_diem_di_kem)`. FK tự tham chiếu `(ma_mau, cot_diem_di_kem)` → `(ma_mau, chi_so_cot)` hoãn tới COMMIT. Trigger `cot_mau_da_dung_khong_sua` chặn INSERT/UPDATE/DELETE cột của mẫu đã có phiếu tham chiếu. Kiểu đọc (một hay hai kênh) suy từ có hay không cột `DIEM_CHU` đi kèm, không lưu riêng. Hạn mức thao tác: `tieu_thu_han_muc_tac_vu` nhận thêm `FORM_TEMPLATE_TRY` và `FORM_TEMPLATE_ANALYZE` (chỉ QTV); `RECOGNITION_UPLOAD` vẫn chỉ giáo viên.

## ket_qua_dong

| Cột (DB = code)     | Kiểu, nullable, default và ràng buộc        |
| ------------------- | ------------------------------------------- |
| ma_dong             | `BigInt @id @default(autoincrement())`      |
| ma_phieu            | `BigInt`                                    |
| ma_hoc_sinh         | `Int`                                       |
| ma_diem             | `BigInt?`                                   |
| thu_tu_dong         | `Int`                                       |
| duong_dan_anh_o_so  | `String? @db.VarChar(512)`                  |
| duong_dan_anh_o_chu | `String? @db.VarChar(512)`                  |
| raw_kenh_a          | `String?`                                   |
| raw_kenh_b          | `String?`                                   |
| gia_tri_kenh_a      | `Decimal? @db.Decimal(3,1)`                 |
| gia_tri_kenh_b      | `Decimal? @db.Decimal(3,1)`                 |
| do_tin_cay_a        | `Decimal? @db.Decimal(5,4)`                 |
| do_tin_cay_b        | `Decimal? @db.Decimal(5,4)`                 |
| ket_luan_doi_chieu  | `KetLuan`                                   |
| muc_phan_loai       | `MucPhanLoai`                               |
| gia_tri_chot        | `Decimal? @db.Decimal(3,1)`                 |
| nguoi_duyet         | `Int?`                                      |
| thoi_diem_duyet     | `DateTime? @db.Timestamptz(6)`              |
| so_trang            | `Int?`; CHECK 1..4 (migration 202610200001) |

Khóa ghép: `@@unique([ma_phieu, thu_tu_dong])`. `so_trang` là trang trong lô mà dòng được đọc; NULL với phiếu một ảnh cũ. Trigger `kiem_dong_theo_lo`: dòng của phiếu thuộc lô bắt buộc có `so_trang` ≤ số trang của lô, dòng của phiếu cũ bắt buộc không có. Với phiếu thuộc lô, `thu_tu_dong = (so_trang − 1) × 1000 + vị trí dòng trên trang`.

FK: `ma_phieu` → `phieu_nhan_dien.ma_phieu`; `ma_hoc_sinh` → `hoc_sinh.ma_hoc_sinh`; `ma_diem` → `diem_thanh_phan.ma_diem`; `nguoi_duyet` → `nguoi_dung.ma_nguoi_dung`.

## tu_dien_diem_chu

| Cột (DB = code) | Kiểu, nullable, default và ràng buộc |
| --------------- | ------------------------------------ |
| ma_cach_doc     | `Int @id @default(autoincrement())`  |
| cach_doc        | `String @unique @db.VarChar(32)`     |
| gia_tri         | `Decimal @db.Decimal(3,1)`           |

## CHECK, permissions và kiểm tra application

Migration 202609070002_constraints là nguồn SQL cho miền điểm, hệ số dương, khoảng ngày, năm hiện hành duy nhất, checksum SHA-256, số dòng và dấu duyệt đầy đủ. Validator numeric kiểm trước ép scale; runtime không được DML điểm trong phase 0. Lịch sử không UPDATE/DELETE/TRUNCATE ở quyền runtime và có trigger append-only.

Ngày sinh/ngày lịch là date; thời điểm là timestamptz UTC. Lớp của học sinh, môn của thành phần và năm học/học kỳ tương ứng cần kiểm trong transaction của use case khi triển khai ghi; FK đơn không chứng minh những quan hệ đó. Snapshot bo_he_so giữ bộ hệ số bất biến theo kết quả, format nghiệp vụ chốt ở Giai đoạn 5. Không lưu ảnh binary/signed URL trong DB. Đường dẫn ảnh là private object key.

Có đúng 16 bảng nghiệp vụ. Các bảng kỹ thuật hiện có gồm `_prisma_migrations`, `phien_lam_viec`, `nhat_ky_bao_mat`, `gioi_han_dang_nhap`, `gioi_han_tac_vu`, `khoa_idempotency`, `recognition_outbox`, `mau_bang_diem`, `cot_mau`, `lo_nhan_dien` và `trang_lo_nhan_dien`. `recognition_outbox.ma_phieu` nullable và có thêm `ma_lo` (duy nhất): sự kiện phiếu (`RECOGNITION_REQUESTED`, có `ma_phieu`) hoặc sự kiện lô (`RECOGNITION_BATCH_REQUESTED`, có `ma_lo`), CHECK đúng một trong hai. `gioi_han_tac_vu` giữ khóa `(ma_nguoi_dung, thao_tac)`, đầu cửa sổ UTC và bộ đếm đã chặn tràn; runtime chỉ gọi hàm nguyên tử `tieu_thu_han_muc_tac_vu`, không có DML trực tiếp. Outbox giữ `ma_phieu`, payload tối thiểu, số lần thử, lease, thời điểm sẵn sàng/gửi và mã lỗi cuối; không chứa binary ảnh hoặc điểm chính thức. Quyền và rollback xem ADR-0002, ADR-0004 và ADR-0008. Không hard-delete dữ liệu điểm đã dùng. Seed chỉ dùng dữ liệu giả.
