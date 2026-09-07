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

## ket_qua_dong

| Cột (DB = code)     | Kiểu, nullable, default và ràng buộc   |
| ------------------- | -------------------------------------- |
| ma_dong             | `BigInt @id @default(autoincrement())` |
| ma_phieu            | `BigInt`                               |
| ma_hoc_sinh         | `Int`                                  |
| ma_diem             | `BigInt?`                              |
| thu_tu_dong         | `Int`                                  |
| duong_dan_anh_o_so  | `String? @db.VarChar(512)`             |
| duong_dan_anh_o_chu | `String? @db.VarChar(512)`             |
| raw_kenh_a          | `String?`                              |
| raw_kenh_b          | `String?`                              |
| gia_tri_kenh_a      | `Decimal? @db.Decimal(3,1)`            |
| gia_tri_kenh_b      | `Decimal? @db.Decimal(3,1)`            |
| do_tin_cay_a        | `Decimal? @db.Decimal(5,4)`            |
| do_tin_cay_b        | `Decimal? @db.Decimal(5,4)`            |
| ket_luan_doi_chieu  | `KetLuan`                              |
| muc_phan_loai       | `MucPhanLoai`                          |
| gia_tri_chot        | `Decimal? @db.Decimal(3,1)`            |
| nguoi_duyet         | `Int?`                                 |
| thoi_diem_duyet     | `DateTime? @db.Timestamptz(6)`         |

Khóa ghép: `@@unique([ma_phieu, thu_tu_dong])`.

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

Có 16 bảng nghiệp vụ, chưa thêm bảng kỹ thuật ngoài \_prisma_migrations. Quyền và rollback tại ADR-0002. Không hard-delete dữ liệu điểm đã dùng. Seed chỉ dùng dữ liệu giả.
