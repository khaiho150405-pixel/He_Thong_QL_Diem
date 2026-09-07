import "dotenv/config";
import { Pool } from "pg";
import { hash, argon2id } from "argon2";

if (!["development", "test"].includes(process.env.APP_ENV ?? ""))
  throw new Error("Seed restricted to development/test");
if (
  !process.env.SEED_PASSWORD ||
  process.env.SEED_PASSWORD === "REPLACE_LOCALLY"
)
  throw new Error("SEED_PASSWORD required");
if (!process.env.MIGRATION_DATABASE_URL)
  throw new Error("MIGRATION_DATABASE_URL required");
const pool = new Pool({ connectionString: process.env.MIGRATION_DATABASE_URL });
const db = await pool.connect();
try {
  await db.query("BEGIN");
  const passwordHash = await hash(process.env.SEED_PASSWORD, {
    type: argon2id,
    memoryCost: 65536,
    timeCost: 3,
    parallelism: 1,
  });
  const users: number[] = [];
  for (const [name, role] of [
    ["demo_admin", "QUAN_TRI_VIEN"],
    ["demo_teacher_a", "GIAO_VIEN"],
    ["demo_teacher_b", "GIAO_VIEN"],
    ["demo_student_a", "HOC_SINH"],
    ["demo_student_b", "HOC_SINH"],
  ]) {
    await db.query(
      "INSERT INTO nguoi_dung (ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES ($1,$2,$3) ON CONFLICT (ten_dang_nhap) DO NOTHING",
      [name, passwordHash, role],
    );
    users.push(
      (
        await db.query(
          "SELECT ma_nguoi_dung FROM nguoi_dung WHERE ten_dang_nhap=$1",
          [name],
        )
      ).rows[0].ma_nguoi_dung as number,
    );
  }
  for (const id of users.slice(1, 3))
    await db.query(
      "INSERT INTO giao_vien (ma_giao_vien,ho_ten) VALUES ($1,$2) ON CONFLICT DO NOTHING",
      [id, `Giáo viên giả ${id}`],
    );
  await db.query(
    "INSERT INTO nam_hoc (ten,ngay_bat_dau,ngay_ket_thuc) VALUES ('DEMO-2026','2026-09-01','2027-06-01') ON CONFLICT DO NOTHING",
  );
  const year = (
    await db.query("SELECT ma_nam_hoc FROM nam_hoc WHERE ten='DEMO-2026'")
  ).rows[0].ma_nam_hoc;
  for (const order of [1, 2])
    await db.query(
      "INSERT INTO hoc_ky (ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES ($1,$2,$3,$4,$5) ON CONFLICT DO NOTHING",
      [
        year,
        `Học kỳ ${order}`,
        order,
        order === 1 ? "2026-09-01" : "2027-01-02",
        order === 1 ? "2027-01-01" : "2027-06-01",
      ],
    );
  await db.query(
    "INSERT INTO mon_hoc (ten_mon,so_tiet_tuan) VALUES ('Môn mẫu',3) ON CONFLICT DO NOTHING",
  );
  const subject = (
    await db.query("SELECT ma_mon FROM mon_hoc WHERE ten_mon='Môn mẫu'")
  ).rows[0].ma_mon;
  await db.query(
    "INSERT INTO thanh_phan_diem (ma_mon,ten_thanh_phan,he_so,thu_tu_hien_thi) VALUES ($1,'Điểm mẫu',1,1) ON CONFLICT DO NOTHING",
    [subject],
  );
  const term = (
    await db.query(
      "SELECT ma_hoc_ky FROM hoc_ky WHERE ma_nam_hoc=$1 AND thu_tu=1",
      [year],
    )
  ).rows[0].ma_hoc_ky;
  for (let i = 0; i < 2; i++) {
    const name = `DEMO-${i + 1}`;
    await db.query(
      "INSERT INTO lop (ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES ($1,$2,$3,10) ON CONFLICT DO NOTHING",
      [year, users[i + 1], name],
    );
    const cls = (
      await db.query(
        "SELECT ma_lop FROM lop WHERE ma_nam_hoc=$1 AND ten_lop=$2",
        [year, name],
      )
    ).rows[0].ma_lop;
    await db.query(
      "INSERT INTO hoc_sinh (ma_nguoi_dung,ma_lop,ho_ten,ngay_sinh) VALUES ($1,$2,$3,'2010-01-01') ON CONFLICT (ma_nguoi_dung) DO NOTHING",
      [users[i + 3], cls, `Học sinh giả ${i + 1}`],
    );
    await db.query(
      "INSERT INTO phan_cong_giang_day (ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES ($1,$2,$3,$4,CURRENT_DATE) ON CONFLICT DO NOTHING",
      [users[i + 1], cls, subject, term],
    );
  }
  await db.query(
    "INSERT INTO tu_dien_diem_chu (cach_doc,gia_tri) VALUES ('không',0),('tám rưỡi',8.5),('mười',10) ON CONFLICT DO NOTHING",
  );
  await db.query("COMMIT");
  console.log("Synthetic seed complete; existing records unchanged.");
} catch (error) {
  await db.query("ROLLBACK");
  throw error;
} finally {
  db.release();
  await pool.end();
}
