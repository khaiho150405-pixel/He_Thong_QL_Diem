import { test } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { Pool, type PoolClient } from "pg";

async function violation(
  client: PoolClient,
  code: string,
  sql: string,
  params: unknown[] = [],
) {
  await client.query("SAVEPOINT guard");
  let failure: { code?: string; message?: string } | null = null;
  try {
    await client.query(sql, params);
  } catch (error) {
    failure = error as { code?: string; message?: string };
  }
  await client.query("ROLLBACK TO SAVEPOINT guard");
  assert.ok(failure, `kỳ vọng lỗi ${code} nhưng câu lệnh chạy được`);
  assert.equal(failure.code, "23514", `${code}: ${failure.message}`);
  assert.match(String(failure.message), new RegExp(code));
}

async function accepted(
  client: PoolClient,
  sql: string,
  params: unknown[] = [],
) {
  await client.query("SAVEPOINT guard");
  try {
    return await client.query(sql, params);
  } finally {
    await client.query("RELEASE SAVEPOINT guard");
  }
}

test("liên kết giữa các bảng được ràng buộc ngay ở PostgreSQL", async () => {
  const ownerUrl = process.env.TEST_MIGRATION_URL;
  if (!ownerUrl || !new URL(ownerUrl).pathname.endsWith("_test"))
    throw new Error("Cần TEST_MIGRATION_URL trỏ DB kết thúc _test");
  const pool = new Pool({ connectionString: ownerUrl });
  const db = await pool.connect();
  const tag = randomUUID().slice(0, 8);
  const id = async (sql: string, params: unknown[] = []) =>
    Number((await db.query(sql, params)).rows[0].id);
  try {
    await db.query("BEGIN");
    const account = (role: string, name: string) =>
      id(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'x',$2) RETURNING ma_nguoi_dung AS id",
        [`sr_${name}_${tag}`, role],
      );
    const teacher = await account("GIAO_VIEN", "gv1");
    const teacher2 = await account("GIAO_VIEN", "gv2");
    const studentAccount = await account("HOC_SINH", "hs1");
    for (const [accountId, name] of [
      [teacher, "Giáo viên một"],
      [teacher2, "Giáo viên hai"],
    ] as const)
      await db.query(
        "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,$2)",
        [accountId, name],
      );
    const year1 = await id(
      "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2040-09-01','2041-06-01') RETURNING ma_nam_hoc AS id",
      [`SR1-${tag}`],
    );
    const year2 = await id(
      "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2041-09-01','2042-06-01') RETURNING ma_nam_hoc AS id",
      [`SR2-${tag}`],
    );
    const term1 = await id(
      "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'HK1',1,'2040-09-01','2041-01-15') RETURNING ma_hoc_ky AS id",
      [year1],
    );
    const term2 = await id(
      "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'HK1',1,'2041-09-01','2042-01-15') RETURNING ma_hoc_ky AS id",
      [year2],
    );
    const class1 = await id(
      "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,10) RETURNING ma_lop AS id",
      [year1, teacher, `SR1-${tag}`],
    );
    const class2 = await id(
      "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,10) RETURNING ma_lop AS id",
      [year2, teacher, `SR2-${tag}`],
    );
    const subject1 = await id(
      "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,2) RETURNING ma_mon AS id",
      [`SR Môn 1 ${tag}`],
    );
    const subject2 = await id(
      "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,2) RETURNING ma_mon AS id",
      [`SR Môn 2 ${tag}`],
    );
    const component1 = await id(
      "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,thu_tu_hien_thi) VALUES($1,'TX1',1) RETURNING ma_thanh_phan AS id",
      [subject1],
    );
    const component2 = await id(
      "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,thu_tu_hien_thi) VALUES($1,'TX1',1) RETURNING ma_thanh_phan AS id",
      [subject2],
    );
    const student = await id(
      "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,'Học sinh một','2030-01-01') RETURNING ma_hoc_sinh AS id",
      [class1],
    );
    const stranger = await id(
      "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,'Học sinh khác lớp','2030-01-01') RETURNING ma_hoc_sinh AS id",
      [class2],
    );
    const book = await id(
      "INSERT INTO bang_diem(ma_lop,ma_mon,ma_hoc_ky) VALUES($1,$2,$3) RETURNING ma_bang_diem AS id",
      [class1, subject1, term1],
    );
    await db.query(
      "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,CURRENT_DATE)",
      [teacher, class1, subject1, term1],
    );

    await violation(
      db,
      "GRADEBOOK_YEAR_MISMATCH",
      "INSERT INTO bang_diem(ma_lop,ma_mon,ma_hoc_ky) VALUES($1,$2,$3)",
      [class1, subject2, term2],
    );
    await violation(
      db,
      "ASSIGNMENT_YEAR_MISMATCH",
      "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,CURRENT_DATE)",
      [teacher, class1, subject2, term2],
    );
    await violation(
      db,
      "TIMETABLE_YEAR_MISMATCH",
      "INSERT INTO thoi_khoa_bieu(ma_lop,ma_mon,ma_giao_vien,ma_hoc_ky,thu,tiet) VALUES($1,$2,$3,$4,2,1)",
      [class1, subject1, teacher, term2],
    );
    await violation(
      db,
      "TIMETABLE_ASSIGNMENT_REQUIRED",
      "INSERT INTO thoi_khoa_bieu(ma_lop,ma_mon,ma_giao_vien,ma_hoc_ky,thu,tiet) VALUES($1,$2,$3,$4,2,1)",
      [class1, subject1, teacher2, term1],
    );
    const slot = Number(
      (
        await accepted(
          db,
          "INSERT INTO thoi_khoa_bieu(ma_lop,ma_mon,ma_giao_vien,ma_hoc_ky,thu,tiet) VALUES($1,$2,$3,$4,2,1) RETURNING ma_tiet_hoc AS id",
          [class1, subject1, teacher, term1],
        )
      ).rows[0].id,
    );
    await violation(
      db,
      "ASSIGNMENT_IN_TIMETABLE",
      "DELETE FROM phan_cong_giang_day WHERE ma_lop=$1 AND ma_mon=$2 AND ma_hoc_ky=$3",
      [class1, subject1, term1],
    );
    await violation(
      db,
      "ASSIGNMENT_IN_TIMETABLE",
      "UPDATE phan_cong_giang_day SET ma_giao_vien=$1 WHERE ma_lop=$2 AND ma_mon=$3 AND ma_hoc_ky=$4",
      [teacher2, class1, subject1, term1],
    );
    await accepted(
      db,
      "UPDATE phan_cong_giang_day SET ngay_phan_cong=CURRENT_DATE WHERE ma_lop=$1 AND ma_mon=$2 AND ma_hoc_ky=$3",
      [class1, subject1, term1],
    );
    await accepted(db, "DELETE FROM thoi_khoa_bieu WHERE ma_tiet_hoc=$1", [
      slot,
    ]);

    await violation(
      db,
      "COMPONENT_SUBJECT_MISMATCH",
      "INSERT INTO diem_thanh_phan(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan) VALUES($1,$2,$3)",
      [book, student, component2],
    );
    await violation(
      db,
      "COMPONENT_SUBJECT_MISMATCH",
      "INSERT INTO chot_cot_diem(ma_bang_diem,ma_thanh_phan) VALUES($1,$2)",
      [book, component2],
    );
    await violation(
      db,
      "GRADE_STUDENT_NOT_ENROLLED",
      "INSERT INTO diem_thanh_phan(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan) VALUES($1,$2,$3)",
      [book, stranger, component1],
    );
    await accepted(
      db,
      "INSERT INTO diem_thanh_phan(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan) VALUES($1,$2,$3)",
      [book, student, component1],
    );

    await violation(
      db,
      "PROFILE_ROLE_MISMATCH",
      "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'Sai vai trò')",
      [studentAccount],
    );
    await violation(
      db,
      "PROFILE_ROLE_MISMATCH",
      "INSERT INTO hoc_sinh(ma_nguoi_dung,ma_lop,ho_ten,ngay_sinh) VALUES($1,$2,'Sai vai trò','2030-01-01')",
      [teacher2, class1],
    );
    await violation(
      db,
      "PROFILE_ROLE_MISMATCH",
      "UPDATE nguoi_dung SET vai_tro='HOC_SINH' WHERE ma_nguoi_dung=$1",
      [teacher],
    );

    await violation(
      db,
      "TERM_OUTSIDE_YEAR",
      "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'HK2',2,'2039-01-01','2039-06-01')",
      [year1],
    );
    await violation(
      db,
      "YEAR_RANGE_EXCLUDES_TERM",
      "UPDATE nam_hoc SET ngay_ket_thuc='2040-12-01' WHERE ma_nam_hoc=$1",
      [year1],
    );

    await violation(
      db,
      "UNKNOWN_CLASSIFICATION",
      "INSERT INTO ket_qua_tong_ket(ma_hoc_sinh,ma_mon,ma_hoc_ky,diem_tong_ket,xep_loai,phien_ban_he_so,bo_he_so) VALUES($1,$2,$3,8.0,'MA_KHONG_CO','v1','{}')",
      [student, subject1, term1],
    );

    const left = await db.query(
      "SELECT indexname FROM pg_indexes WHERE schemaname='public' AND indexname = ANY($1)",
      [
        [
          "hoc_ky_ma_nam_hoc_idx",
          "lop_ma_nam_hoc_idx",
          "thanh_phan_diem_ma_mon_idx",
          "phan_cong_giang_day_ma_lop_idx",
          "bang_diem_ma_lop_idx",
          "diem_thanh_phan_ma_bang_diem_idx",
          "ket_qua_tong_ket_ma_hoc_sinh_idx",
          "ket_qua_dong_ma_phieu_idx",
        ],
      ],
    );
    assert.deepEqual(left.rows, []);
  } finally {
    await db.query("ROLLBACK");
    db.release();
    await pool.end();
  }
});
