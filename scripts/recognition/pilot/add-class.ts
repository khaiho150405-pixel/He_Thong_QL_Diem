import "dotenv/config";
import { readFileSync } from "node:fs";
import { Pool } from "pg";

const className = process.argv[2] ?? "10A10";
const file = process.argv[3] ?? ".local/pilot/class-10A10.json";
const url =
  process.env.TEST_MIGRATION_URL ?? process.env.MIGRATION_DATABASE_URL ?? "";
if (!new URL(url || "http://x/").pathname.endsWith("_test"))
  throw new Error("Database tên kết thúc _test là bắt buộc");

const students = JSON.parse(readFileSync(file, "utf8")) as Array<{
  stt: number;
  name: string;
}>;
const pool = new Pool({ connectionString: url });
const db = await pool.connect();
try {
  await db.query("BEGIN");
  const year = (
    await db.query("SELECT ma_nam_hoc FROM nam_hoc WHERE hien_hanh LIMIT 1")
  ).rows[0];
  const term = year
    ? (
        await db.query(
          "SELECT ma_hoc_ky FROM hoc_ky WHERE ma_nam_hoc=$1 AND thu_tu=1",
          [year.ma_nam_hoc],
        )
      ).rows[0]
    : undefined;
  if (!term)
    throw new Error(
      "Chưa có năm học hiện hành và học kỳ 1. Chạy `pnpm db:seed` trước.",
    );
  if (
    (
      await db.query("SELECT 1 FROM lop WHERE ma_nam_hoc=$1 AND ten_lop=$2", [
        year.ma_nam_hoc,
        className,
      ])
    ).rowCount
  ) {
    await db.query("ROLLBACK");
    console.log(`Lớp ${className} đã có, không thêm.`);
  } else {
    const math = (
      await db.query("SELECT ma_mon FROM mon_hoc WHERE ten_mon='Toán học'")
    ).rows[0];
    const teacher = (
      await db.query(
        "SELECT ma_giao_vien FROM phan_cong_giang_day WHERE ma_mon=$1 AND ma_hoc_ky=$2 ORDER BY ma_giao_vien LIMIT 1",
        [math?.ma_mon, term.ma_hoc_ky],
      )
    ).rows[0];
    if (!math || !teacher)
      throw new Error(
        "Chưa có giáo viên Toán được phân công. Chạy `pnpm db:seed` trước.",
      );
    const classId = (
      await db.query(
        "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,10) RETURNING ma_lop",
        [year.ma_nam_hoc, teacher.ma_giao_vien, className],
      )
    ).rows[0].ma_lop as number;
    for (const student of [...students].sort((a, b) => a.stt - b.stt)) {
      await db.query(
        "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh,dang_theo_hoc) VALUES($1,$2,'2009-01-01',true)",
        [classId, student.name],
      );
    }
    await db.query(
      `INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong)
       VALUES($1,$2,$3,$4,CURRENT_DATE) ON CONFLICT (ma_lop,ma_mon,ma_hoc_ky) DO NOTHING`,
      [teacher.ma_giao_vien, classId, math.ma_mon, term.ma_hoc_ky],
    );
    await db.query("COMMIT");
    console.log(
      `Đã thêm lớp ${className}: ${students.length} học sinh, môn Toán học kỳ 1 do giáo viên mã ${teacher.ma_giao_vien} phụ trách.`,
    );
  }
} catch (error) {
  await db.query("ROLLBACK");
  throw error;
} finally {
  db.release();
  await pool.end();
}
