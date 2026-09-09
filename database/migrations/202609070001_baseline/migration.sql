-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "VaiTro" AS ENUM ('QUAN_TRI_VIEN', 'GIAO_VIEN', 'HOC_SINH');

-- CreateEnum
CREATE TYPE "TrangThaiBangDiem" AS ENUM ('DANG_NHAP_LIEU', 'DA_CHOT');

-- CreateEnum
CREATE TYPE "TrangThaiDiem" AS ENUM ('CHUA_CO', 'CHO_DOI_CHIEU', 'DA_DUYET');

-- CreateEnum
CREATE TYPE "NguonNhap" AS ENUM ('NHAP_TAY', 'NHAN_DIEN');

-- CreateEnum
CREATE TYPE "TrangThaiPhieu" AS ENUM ('DANG_XU_LY', 'CHO_DOI_CHIEU', 'DA_DUYET', 'LOI');

-- CreateEnum
CREATE TYPE "KetLuan" AS ENUM ('KHOP', 'LECH', 'MOT_KENH', 'KHONG_DOC_DUOC');

-- CreateEnum
CREATE TYPE "MucPhanLoai" AS ENUM ('XANH', 'VANG', 'DO');

-- CreateTable
CREATE TABLE "nguoi_dung" (
    "ma_nguoi_dung" SERIAL NOT NULL,
    "ten_dang_nhap" VARCHAR(50) NOT NULL,
    "mat_khau_ma_hoa" VARCHAR(255) NOT NULL,
    "vai_tro" "VaiTro" NOT NULL,
    "trang_thai" BOOLEAN NOT NULL DEFAULT true,
    "so_lan_dang_nhap_sai" SMALLINT NOT NULL DEFAULT 0,
    "khoa_den" TIMESTAMPTZ(6),

    CONSTRAINT "nguoi_dung_pkey" PRIMARY KEY ("ma_nguoi_dung")
);

-- CreateTable
CREATE TABLE "giao_vien" (
    "ma_giao_vien" INTEGER NOT NULL,
    "ho_ten" VARCHAR(100) NOT NULL,
    "to_chuyen_mon" VARCHAR(50),
    "email" VARCHAR(254),
    "dien_thoai" VARCHAR(20),

    CONSTRAINT "giao_vien_pkey" PRIMARY KEY ("ma_giao_vien")
);

-- CreateTable
CREATE TABLE "nam_hoc" (
    "ma_nam_hoc" SERIAL NOT NULL,
    "ten" VARCHAR(20) NOT NULL,
    "ngay_bat_dau" DATE NOT NULL,
    "ngay_ket_thuc" DATE NOT NULL,
    "hien_hanh" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "nam_hoc_pkey" PRIMARY KEY ("ma_nam_hoc")
);

-- CreateTable
CREATE TABLE "hoc_ky" (
    "ma_hoc_ky" SERIAL NOT NULL,
    "ma_nam_hoc" INTEGER NOT NULL,
    "ten" VARCHAR(20) NOT NULL,
    "thu_tu" SMALLINT NOT NULL,
    "ngay_bat_dau" DATE NOT NULL,
    "ngay_ket_thuc" DATE NOT NULL,

    CONSTRAINT "hoc_ky_pkey" PRIMARY KEY ("ma_hoc_ky")
);

-- CreateTable
CREATE TABLE "lop" (
    "ma_lop" SERIAL NOT NULL,
    "ma_nam_hoc" INTEGER NOT NULL,
    "ma_gv_chu_nhiem" INTEGER NOT NULL,
    "ten_lop" VARCHAR(20) NOT NULL,
    "khoi" SMALLINT NOT NULL,

    CONSTRAINT "lop_pkey" PRIMARY KEY ("ma_lop")
);

-- CreateTable
CREATE TABLE "hoc_sinh" (
    "ma_hoc_sinh" SERIAL NOT NULL,
    "ma_nguoi_dung" INTEGER,
    "ma_lop" INTEGER NOT NULL,
    "ho_ten" VARCHAR(100) NOT NULL,
    "ngay_sinh" DATE NOT NULL,
    "dang_theo_hoc" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "hoc_sinh_pkey" PRIMARY KEY ("ma_hoc_sinh")
);

-- CreateTable
CREATE TABLE "mon_hoc" (
    "ma_mon" SERIAL NOT NULL,
    "ten_mon" VARCHAR(80) NOT NULL,
    "so_tiet_tuan" SMALLINT NOT NULL,

    CONSTRAINT "mon_hoc_pkey" PRIMARY KEY ("ma_mon")
);

-- CreateTable
CREATE TABLE "thanh_phan_diem" (
    "ma_thanh_phan" SERIAL NOT NULL,
    "ma_mon" INTEGER NOT NULL,
    "ten_thanh_phan" VARCHAR(50) NOT NULL,
    "he_so" DECIMAL(3,2) NOT NULL,
    "bat_buoc" BOOLEAN NOT NULL DEFAULT true,
    "thu_tu_hien_thi" SMALLINT NOT NULL,

    CONSTRAINT "thanh_phan_diem_pkey" PRIMARY KEY ("ma_thanh_phan")
);

-- CreateTable
CREATE TABLE "phan_cong_giang_day" (
    "ma_phan_cong" SERIAL NOT NULL,
    "ma_giao_vien" INTEGER NOT NULL,
    "ma_lop" INTEGER NOT NULL,
    "ma_mon" INTEGER NOT NULL,
    "ma_hoc_ky" INTEGER NOT NULL,
    "ngay_phan_cong" DATE NOT NULL,

    CONSTRAINT "phan_cong_giang_day_pkey" PRIMARY KEY ("ma_phan_cong")
);

-- CreateTable
CREATE TABLE "bang_diem" (
    "ma_bang_diem" SERIAL NOT NULL,
    "ma_lop" INTEGER NOT NULL,
    "ma_mon" INTEGER NOT NULL,
    "ma_hoc_ky" INTEGER NOT NULL,
    "trang_thai" "TrangThaiBangDiem" NOT NULL DEFAULT 'DANG_NHAP_LIEU',
    "version" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "bang_diem_pkey" PRIMARY KEY ("ma_bang_diem")
);

-- CreateTable
CREATE TABLE "diem_thanh_phan" (
    "ma_diem" BIGSERIAL NOT NULL,
    "ma_bang_diem" INTEGER NOT NULL,
    "ma_hoc_sinh" INTEGER NOT NULL,
    "ma_thanh_phan" INTEGER NOT NULL,
    "gia_tri" DECIMAL(3,1),
    "trang_thai" "TrangThaiDiem" NOT NULL DEFAULT 'CHUA_CO',
    "nguon_nhap" "NguonNhap" NOT NULL DEFAULT 'NHAP_TAY',

    CONSTRAINT "diem_thanh_phan_pkey" PRIMARY KEY ("ma_diem")
);

-- CreateTable
CREATE TABLE "lich_su_sua_diem" (
    "ma_lich_su" BIGSERIAL NOT NULL,
    "ma_diem" BIGINT NOT NULL,
    "nguoi_sua" INTEGER NOT NULL,
    "gia_tri_cu" DECIMAL(3,1),
    "gia_tri_moi" DECIMAL(3,1),
    "ly_do" VARCHAR(500) NOT NULL,
    "thoi_diem" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "lich_su_sua_diem_pkey" PRIMARY KEY ("ma_lich_su")
);

-- CreateTable
CREATE TABLE "ket_qua_tong_ket" (
    "ma_ket_qua" BIGSERIAL NOT NULL,
    "ma_hoc_sinh" INTEGER NOT NULL,
    "ma_mon" INTEGER NOT NULL,
    "ma_hoc_ky" INTEGER NOT NULL,
    "diem_tong_ket" DECIMAL(3,1) NOT NULL,
    "xep_loai" VARCHAR(20),
    "phien_ban_he_so" VARCHAR(20) NOT NULL,
    "bo_he_so" JSONB NOT NULL,
    "ngay_tinh" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ket_qua_tong_ket_pkey" PRIMARY KEY ("ma_ket_qua")
);

-- CreateTable
CREATE TABLE "phieu_nhan_dien" (
    "ma_phieu" BIGSERIAL NOT NULL,
    "ma_bang_diem" INTEGER NOT NULL,
    "ma_thanh_phan" INTEGER NOT NULL,
    "nguoi_tai" INTEGER NOT NULL,
    "ma_bam_tep" VARCHAR(64) NOT NULL,
    "duong_dan_anh_goc" VARCHAR(512) NOT NULL,
    "so_dong_khai_bao" INTEGER NOT NULL,
    "so_dong_nhan_dien" INTEGER,
    "trang_thai" "TrangThaiPhieu" NOT NULL DEFAULT 'DANG_XU_LY',
    "ma_loi" VARCHAR(80),
    "phien_ban_mo_hinh" VARCHAR(80),
    "version" INTEGER NOT NULL DEFAULT 0,
    "ngay_tao" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "phieu_nhan_dien_pkey" PRIMARY KEY ("ma_phieu")
);

-- CreateTable
CREATE TABLE "ket_qua_dong" (
    "ma_dong" BIGSERIAL NOT NULL,
    "ma_phieu" BIGINT NOT NULL,
    "ma_hoc_sinh" INTEGER NOT NULL,
    "ma_diem" BIGINT,
    "thu_tu_dong" INTEGER NOT NULL,
    "duong_dan_anh_o_so" VARCHAR(512),
    "duong_dan_anh_o_chu" VARCHAR(512),
    "raw_kenh_a" TEXT,
    "raw_kenh_b" TEXT,
    "gia_tri_kenh_a" DECIMAL(3,1),
    "gia_tri_kenh_b" DECIMAL(3,1),
    "do_tin_cay_a" DECIMAL(5,4),
    "do_tin_cay_b" DECIMAL(5,4),
    "ket_luan_doi_chieu" "KetLuan" NOT NULL,
    "muc_phan_loai" "MucPhanLoai" NOT NULL,
    "gia_tri_chot" DECIMAL(3,1),
    "nguoi_duyet" INTEGER,
    "thoi_diem_duyet" TIMESTAMPTZ(6),

    CONSTRAINT "ket_qua_dong_pkey" PRIMARY KEY ("ma_dong")
);

-- CreateTable
CREATE TABLE "tu_dien_diem_chu" (
    "ma_cach_doc" SERIAL NOT NULL,
    "cach_doc" VARCHAR(32) NOT NULL,
    "gia_tri" DECIMAL(3,1) NOT NULL,

    CONSTRAINT "tu_dien_diem_chu_pkey" PRIMARY KEY ("ma_cach_doc")
);

-- CreateIndex
CREATE UNIQUE INDEX "nguoi_dung_ten_dang_nhap_key" ON "nguoi_dung"("ten_dang_nhap");

-- CreateIndex
CREATE UNIQUE INDEX "nam_hoc_ten_key" ON "nam_hoc"("ten");

-- CreateIndex
CREATE INDEX "hoc_ky_ma_nam_hoc_idx" ON "hoc_ky"("ma_nam_hoc");

-- CreateIndex
CREATE UNIQUE INDEX "hoc_ky_ma_nam_hoc_thu_tu_key" ON "hoc_ky"("ma_nam_hoc", "thu_tu");

-- CreateIndex
CREATE INDEX "lop_ma_nam_hoc_idx" ON "lop"("ma_nam_hoc");

-- CreateIndex
CREATE INDEX "lop_ma_gv_chu_nhiem_idx" ON "lop"("ma_gv_chu_nhiem");

-- CreateIndex
CREATE UNIQUE INDEX "lop_ma_nam_hoc_ten_lop_key" ON "lop"("ma_nam_hoc", "ten_lop");

-- CreateIndex
CREATE UNIQUE INDEX "hoc_sinh_ma_nguoi_dung_key" ON "hoc_sinh"("ma_nguoi_dung");

-- CreateIndex
CREATE INDEX "hoc_sinh_ma_lop_idx" ON "hoc_sinh"("ma_lop");

-- CreateIndex
CREATE UNIQUE INDEX "mon_hoc_ten_mon_key" ON "mon_hoc"("ten_mon");

-- CreateIndex
CREATE INDEX "thanh_phan_diem_ma_mon_idx" ON "thanh_phan_diem"("ma_mon");

-- CreateIndex
CREATE UNIQUE INDEX "thanh_phan_diem_ma_mon_ten_thanh_phan_key" ON "thanh_phan_diem"("ma_mon", "ten_thanh_phan");

-- CreateIndex
CREATE INDEX "phan_cong_giang_day_ma_giao_vien_idx" ON "phan_cong_giang_day"("ma_giao_vien");

-- CreateIndex
CREATE INDEX "phan_cong_giang_day_ma_lop_idx" ON "phan_cong_giang_day"("ma_lop");

-- CreateIndex
CREATE INDEX "phan_cong_giang_day_ma_mon_idx" ON "phan_cong_giang_day"("ma_mon");

-- CreateIndex
CREATE INDEX "phan_cong_giang_day_ma_hoc_ky_idx" ON "phan_cong_giang_day"("ma_hoc_ky");

-- CreateIndex
CREATE UNIQUE INDEX "phan_cong_giang_day_ma_lop_ma_mon_ma_hoc_ky_key" ON "phan_cong_giang_day"("ma_lop", "ma_mon", "ma_hoc_ky");

-- CreateIndex
CREATE INDEX "bang_diem_ma_lop_idx" ON "bang_diem"("ma_lop");

-- CreateIndex
CREATE INDEX "bang_diem_ma_mon_idx" ON "bang_diem"("ma_mon");

-- CreateIndex
CREATE INDEX "bang_diem_ma_hoc_ky_idx" ON "bang_diem"("ma_hoc_ky");

-- CreateIndex
CREATE UNIQUE INDEX "bang_diem_ma_lop_ma_mon_ma_hoc_ky_key" ON "bang_diem"("ma_lop", "ma_mon", "ma_hoc_ky");

-- CreateIndex
CREATE INDEX "diem_thanh_phan_ma_bang_diem_idx" ON "diem_thanh_phan"("ma_bang_diem");

-- CreateIndex
CREATE INDEX "diem_thanh_phan_ma_hoc_sinh_idx" ON "diem_thanh_phan"("ma_hoc_sinh");

-- CreateIndex
CREATE INDEX "diem_thanh_phan_ma_thanh_phan_idx" ON "diem_thanh_phan"("ma_thanh_phan");

-- CreateIndex
CREATE UNIQUE INDEX "diem_thanh_phan_ma_bang_diem_ma_hoc_sinh_ma_thanh_phan_key" ON "diem_thanh_phan"("ma_bang_diem", "ma_hoc_sinh", "ma_thanh_phan");

-- CreateIndex
CREATE INDEX "lich_su_sua_diem_ma_diem_idx" ON "lich_su_sua_diem"("ma_diem");

-- CreateIndex
CREATE INDEX "lich_su_sua_diem_nguoi_sua_idx" ON "lich_su_sua_diem"("nguoi_sua");

-- CreateIndex
CREATE INDEX "ket_qua_tong_ket_ma_hoc_sinh_idx" ON "ket_qua_tong_ket"("ma_hoc_sinh");

-- CreateIndex
CREATE INDEX "ket_qua_tong_ket_ma_mon_idx" ON "ket_qua_tong_ket"("ma_mon");

-- CreateIndex
CREATE INDEX "ket_qua_tong_ket_ma_hoc_ky_idx" ON "ket_qua_tong_ket"("ma_hoc_ky");

-- CreateIndex
CREATE UNIQUE INDEX "ket_qua_tong_ket_ma_hoc_sinh_ma_mon_ma_hoc_ky_key" ON "ket_qua_tong_ket"("ma_hoc_sinh", "ma_mon", "ma_hoc_ky");

-- CreateIndex
CREATE UNIQUE INDEX "phieu_nhan_dien_ma_bam_tep_key" ON "phieu_nhan_dien"("ma_bam_tep");

-- CreateIndex
CREATE INDEX "phieu_nhan_dien_ma_bang_diem_idx" ON "phieu_nhan_dien"("ma_bang_diem");

-- CreateIndex
CREATE INDEX "phieu_nhan_dien_ma_thanh_phan_idx" ON "phieu_nhan_dien"("ma_thanh_phan");

-- CreateIndex
CREATE INDEX "phieu_nhan_dien_nguoi_tai_idx" ON "phieu_nhan_dien"("nguoi_tai");

-- CreateIndex
CREATE INDEX "ket_qua_dong_ma_phieu_idx" ON "ket_qua_dong"("ma_phieu");

-- CreateIndex
CREATE INDEX "ket_qua_dong_ma_hoc_sinh_idx" ON "ket_qua_dong"("ma_hoc_sinh");

-- CreateIndex
CREATE INDEX "ket_qua_dong_ma_diem_idx" ON "ket_qua_dong"("ma_diem");

-- CreateIndex
CREATE INDEX "ket_qua_dong_nguoi_duyet_idx" ON "ket_qua_dong"("nguoi_duyet");

-- CreateIndex
CREATE UNIQUE INDEX "ket_qua_dong_ma_phieu_thu_tu_dong_key" ON "ket_qua_dong"("ma_phieu", "thu_tu_dong");

-- CreateIndex
CREATE UNIQUE INDEX "tu_dien_diem_chu_cach_doc_key" ON "tu_dien_diem_chu"("cach_doc");

-- AddForeignKey
ALTER TABLE "giao_vien" ADD CONSTRAINT "giao_vien_ma_giao_vien_fkey" FOREIGN KEY ("ma_giao_vien") REFERENCES "nguoi_dung"("ma_nguoi_dung") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "hoc_ky" ADD CONSTRAINT "hoc_ky_ma_nam_hoc_fkey" FOREIGN KEY ("ma_nam_hoc") REFERENCES "nam_hoc"("ma_nam_hoc") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "lop" ADD CONSTRAINT "lop_ma_nam_hoc_fkey" FOREIGN KEY ("ma_nam_hoc") REFERENCES "nam_hoc"("ma_nam_hoc") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "lop" ADD CONSTRAINT "lop_ma_gv_chu_nhiem_fkey" FOREIGN KEY ("ma_gv_chu_nhiem") REFERENCES "giao_vien"("ma_giao_vien") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "hoc_sinh" ADD CONSTRAINT "hoc_sinh_ma_nguoi_dung_fkey" FOREIGN KEY ("ma_nguoi_dung") REFERENCES "nguoi_dung"("ma_nguoi_dung") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "hoc_sinh" ADD CONSTRAINT "hoc_sinh_ma_lop_fkey" FOREIGN KEY ("ma_lop") REFERENCES "lop"("ma_lop") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "thanh_phan_diem" ADD CONSTRAINT "thanh_phan_diem_ma_mon_fkey" FOREIGN KEY ("ma_mon") REFERENCES "mon_hoc"("ma_mon") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "phan_cong_giang_day" ADD CONSTRAINT "phan_cong_giang_day_ma_giao_vien_fkey" FOREIGN KEY ("ma_giao_vien") REFERENCES "giao_vien"("ma_giao_vien") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "phan_cong_giang_day" ADD CONSTRAINT "phan_cong_giang_day_ma_lop_fkey" FOREIGN KEY ("ma_lop") REFERENCES "lop"("ma_lop") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "phan_cong_giang_day" ADD CONSTRAINT "phan_cong_giang_day_ma_mon_fkey" FOREIGN KEY ("ma_mon") REFERENCES "mon_hoc"("ma_mon") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "phan_cong_giang_day" ADD CONSTRAINT "phan_cong_giang_day_ma_hoc_ky_fkey" FOREIGN KEY ("ma_hoc_ky") REFERENCES "hoc_ky"("ma_hoc_ky") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "bang_diem" ADD CONSTRAINT "bang_diem_ma_lop_fkey" FOREIGN KEY ("ma_lop") REFERENCES "lop"("ma_lop") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "bang_diem" ADD CONSTRAINT "bang_diem_ma_mon_fkey" FOREIGN KEY ("ma_mon") REFERENCES "mon_hoc"("ma_mon") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "bang_diem" ADD CONSTRAINT "bang_diem_ma_hoc_ky_fkey" FOREIGN KEY ("ma_hoc_ky") REFERENCES "hoc_ky"("ma_hoc_ky") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "diem_thanh_phan" ADD CONSTRAINT "diem_thanh_phan_ma_bang_diem_fkey" FOREIGN KEY ("ma_bang_diem") REFERENCES "bang_diem"("ma_bang_diem") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "diem_thanh_phan" ADD CONSTRAINT "diem_thanh_phan_ma_hoc_sinh_fkey" FOREIGN KEY ("ma_hoc_sinh") REFERENCES "hoc_sinh"("ma_hoc_sinh") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "diem_thanh_phan" ADD CONSTRAINT "diem_thanh_phan_ma_thanh_phan_fkey" FOREIGN KEY ("ma_thanh_phan") REFERENCES "thanh_phan_diem"("ma_thanh_phan") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "lich_su_sua_diem" ADD CONSTRAINT "lich_su_sua_diem_ma_diem_fkey" FOREIGN KEY ("ma_diem") REFERENCES "diem_thanh_phan"("ma_diem") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "lich_su_sua_diem" ADD CONSTRAINT "lich_su_sua_diem_nguoi_sua_fkey" FOREIGN KEY ("nguoi_sua") REFERENCES "nguoi_dung"("ma_nguoi_dung") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "ket_qua_tong_ket" ADD CONSTRAINT "ket_qua_tong_ket_ma_hoc_sinh_fkey" FOREIGN KEY ("ma_hoc_sinh") REFERENCES "hoc_sinh"("ma_hoc_sinh") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "ket_qua_tong_ket" ADD CONSTRAINT "ket_qua_tong_ket_ma_mon_fkey" FOREIGN KEY ("ma_mon") REFERENCES "mon_hoc"("ma_mon") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "ket_qua_tong_ket" ADD CONSTRAINT "ket_qua_tong_ket_ma_hoc_ky_fkey" FOREIGN KEY ("ma_hoc_ky") REFERENCES "hoc_ky"("ma_hoc_ky") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "phieu_nhan_dien" ADD CONSTRAINT "phieu_nhan_dien_ma_bang_diem_fkey" FOREIGN KEY ("ma_bang_diem") REFERENCES "bang_diem"("ma_bang_diem") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "phieu_nhan_dien" ADD CONSTRAINT "phieu_nhan_dien_ma_thanh_phan_fkey" FOREIGN KEY ("ma_thanh_phan") REFERENCES "thanh_phan_diem"("ma_thanh_phan") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "phieu_nhan_dien" ADD CONSTRAINT "phieu_nhan_dien_nguoi_tai_fkey" FOREIGN KEY ("nguoi_tai") REFERENCES "nguoi_dung"("ma_nguoi_dung") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "ket_qua_dong" ADD CONSTRAINT "ket_qua_dong_ma_phieu_fkey" FOREIGN KEY ("ma_phieu") REFERENCES "phieu_nhan_dien"("ma_phieu") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "ket_qua_dong" ADD CONSTRAINT "ket_qua_dong_ma_hoc_sinh_fkey" FOREIGN KEY ("ma_hoc_sinh") REFERENCES "hoc_sinh"("ma_hoc_sinh") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "ket_qua_dong" ADD CONSTRAINT "ket_qua_dong_ma_diem_fkey" FOREIGN KEY ("ma_diem") REFERENCES "diem_thanh_phan"("ma_diem") ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AddForeignKey
ALTER TABLE "ket_qua_dong" ADD CONSTRAINT "ket_qua_dong_nguoi_duyet_fkey" FOREIGN KEY ("nguoi_duyet") REFERENCES "nguoi_dung"("ma_nguoi_dung") ON DELETE RESTRICT ON UPDATE RESTRICT;
