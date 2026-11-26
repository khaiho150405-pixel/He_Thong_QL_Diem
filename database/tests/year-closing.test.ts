import { test } from "node:test";
import assert from "node:assert/strict";
import { randomBytes, randomUUID } from "node:crypto";
import { Pool, type PoolClient } from "pg";

async function rejected(
  client: PoolClient,
  expected: RegExp,
  sql: string,
  params: unknown[] = [],
) {
  await client.query("SAVEPOINT guard");
  let failure = "";
  try {
    await client.query(sql, params);
  } catch (error) {
    failure = String((error as Error).message);
  }
  await client.query("ROLLBACK TO SAVEPOINT guard");
  assert.match(failure, expected, sql);
}

test("đóng năm học: chỉ khi hết việc dở, sau đó không ghi được và không bỏ công bố; mở lại phải có lý do", async () => {
  const url = process.env.TEST_MIGRATION_URL;
  if (!url || !new URL(url).pathname.endsWith("_test"))
    throw new Error("Cần TEST_MIGRATION_URL trỏ DB kết thúc _test");
  const pool = new Pool({ connectionString: url });
  const db = await pool.connect();
  const tag = randomUUID().slice(0, 8);
  const id = async (sql: string, params: unknown[] = []) =>
    Number((await db.query(sql, params)).rows[0].id);
  try {
    await db.query("BEGIN ISOLATION LEVEL SERIALIZABLE");
    const user = async (role: string, name: string) => {
      const userId = await id(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'x',$2) RETURNING ma_nguoi_dung AS id",
        [`yc_${name}_${tag}`, role],
      );
      const session = randomBytes(32).toString("hex");
      await db.query(
        "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
        [session, userId, randomBytes(32).toString("hex")],
      );
      return { id: userId, session };
    };
    const admin = await user("QUAN_TRI_VIEN", "qt");
    const teacher = await user("GIAO_VIEN", "gv");
    await db.query(
      "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'Giáo viên giả')",
      [teacher.id],
    );
    const year = await id(
      "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2020-09-01','2021-06-01') RETURNING ma_nam_hoc AS id",
      [`YC-${tag}`],
    );
    const term = await id(
      "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'HK1',1,'2020-09-01','2021-01-15') RETURNING ma_hoc_ky AS id",
      [year],
    );
    const klass = await id(
      "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,12) RETURNING ma_lop AS id",
      [year, teacher.id, `YC-${tag}`],
    );
    const student = await id(
      "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,'Học sinh giả','2003-01-01') RETURNING ma_hoc_sinh AS id",
      [klass],
    );

    const readiness = async () =>
      (await db.query("SELECT kiem_san_sang_dong_nam($1) AS r", [year])).rows[0]
        .r as { ready: boolean; issues: Array<{ code: string }> };
    const change = (session: string, close: boolean, reason: string) =>
      db.query("SELECT doi_trang_thai_nam_hoc($1,$2,$3,$4) AS r", [
        session,
        year,
        close,
        reason,
      ]);
    const changeRejected = (
      expected: RegExp,
      session: string,
      close: boolean,
      reason: string,
    ) =>
      rejected(db, expected, "SELECT doi_trang_thai_nam_hoc($1,$2,$3,$4)", [
        session,
        year,
        close,
        reason,
      ]);

    assert.deepEqual(
      (await readiness()).issues.map((issue) => issue.code),
      ["STUDENTS_NOT_PROMOTED"],
    );
    await changeRejected(/YEAR_NOT_READY/, admin.session, true, "Hết năm");
    await db.query(
      "UPDATE hoc_sinh_lop SET trang_thai='TOT_NGHIEP',den_ngay='2021-06-01' WHERE ma_hoc_sinh=$1",
      [student],
    );
    assert.equal((await readiness()).ready, true);
    await changeRejected(/FORBIDDEN/, teacher.session, true, "Hết năm");
    await changeRejected(
      /INVALID_YEAR_CLOSE_REQUEST/,
      admin.session,
      true,
      "   ",
    );
    await changeRejected(/YEAR_NOT_CLOSED/, admin.session, false, "Mở");

    await db.query(
      "UPDATE hoc_ky SET ngay_ket_thuc='2021-01-10' WHERE ma_hoc_ky=$1",
      [term],
    );
    await change(admin.session, true, "Hết năm");
    await changeRejected(/YEAR_ALREADY_CLOSED/, admin.session, true, "Lại");

    for (const [sql, params] of [
      ["UPDATE hoc_ky SET da_cong_bo=false,ten='X' WHERE ma_hoc_ky=$1", [term]],
      [
        "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'HK2',2,'2021-01-16','2021-06-01')",
        [year],
      ],
      ["UPDATE lop SET ten_lop='Doi ten' WHERE ma_lop=$1", [klass]],
      [
        "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,'Thêm sau','2003-01-01')",
        [klass],
      ],
      ["UPDATE hoc_sinh_lop SET ly_do='sửa' WHERE ma_hoc_sinh=$1", [student]],
      ["UPDATE nam_hoc SET ten='Khac' WHERE ma_nam_hoc=$1", [year]],
      ["UPDATE nam_hoc SET hien_hanh=true WHERE ma_nam_hoc=$1", [year]],
      ["DELETE FROM nam_hoc WHERE ma_nam_hoc=$1", [year]],
    ] as Array<[string, unknown[]]>)
      await rejected(
        db,
        /YEAR_CLOSED|nam_hoc_dong_khong_hien_hanh/,
        sql,
        params,
      );
    await rejected(
      db,
      /APPEND_ONLY/,
      "DELETE FROM lich_su_dong_nam WHERE ma_nam_hoc=$1",
      [year],
    );

    await db.query("SET LOCAL ROLE app_runtime");
    await rejected(
      db,
      /permission denied/,
      "UPDATE nam_hoc SET da_dong_luc=NULL WHERE ma_nam_hoc=$1",
      [year],
    );
    await rejected(
      db,
      /YEAR_CLOSED/,
      "UPDATE lop SET khoi=11 WHERE ma_lop=$1",
      [klass],
    );
    await db.query("RESET ROLE");

    await changeRejected(
      /INVALID_YEAR_CLOSE_REQUEST/,
      admin.session,
      false,
      "",
    );
    await change(admin.session, false, "Sửa sai điểm theo biên bản");
    await db.query("UPDATE lop SET ten_lop=$2 WHERE ma_lop=$1", [
      klass,
      `YC2-${tag}`,
    ]);
    assert.deepEqual(
      (
        await db.query(
          "SELECT hanh_dong,ly_do,nguoi_thuc_hien FROM lich_su_dong_nam WHERE ma_nam_hoc=$1 ORDER BY ma",
          [year],
        )
      ).rows,
      [
        { hanh_dong: "DONG", ly_do: "Hết năm", nguoi_thuc_hien: admin.id },
        {
          hanh_dong: "MO_LAI",
          ly_do: "Sửa sai điểm theo biên bản",
          nguoi_thuc_hien: admin.id,
        },
      ],
    );
  } finally {
    await db.query("ROLLBACK");
    db.release();
    await pool.end();
  }
});
