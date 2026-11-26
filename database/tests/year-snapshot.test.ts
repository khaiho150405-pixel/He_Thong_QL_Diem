import { test } from "node:test";
import assert from "node:assert/strict";
import { randomBytes, randomUUID } from "node:crypto";
import { Pool, type PoolClient } from "pg";

async function rejected(client: PoolClient, expected: RegExp, sql: string) {
  await client.query("SAVEPOINT guard");
  let failure = "";
  try {
    await client.query(sql);
  } catch (error) {
    failure = String((error as Error).message);
  }
  await client.query("ROLLBACK TO SAVEPOINT guard");
  assert.match(failure, expected, sql);
}

test("đóng năm lập bản chốt chỉ ghi thêm; thống kê năm đã đóng không đổi theo danh mục", async () => {
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
        [`ys_${name}_${tag}`, role],
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
      "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'Giáo viên cũ')",
      [teacher.id],
    );
    const year = await id(
      "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2018-09-01','2019-06-01') RETURNING ma_nam_hoc AS id",
      [`YS-${tag}`],
    );
    const term = await id(
      "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc,da_cong_bo) VALUES($1,'HK1',1,'2018-09-01','2019-01-15',false) RETURNING ma_hoc_ky AS id",
      [year],
    );
    const klass = await id(
      "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,12) RETURNING ma_lop AS id",
      [year, teacher.id, `YS-${tag}`],
    );
    const students: number[] = [];
    for (const name of ["Học sinh Một", "Học sinh Hai"])
      students.push(
        await id(
          "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,$2,'2001-02-03') RETURNING ma_hoc_sinh AS id",
          [klass, name],
        ),
      );
    const scores: Array<[string, boolean, number, number]> = [
      ["Toan", false, 9, 6],
      ["Van", false, 9, 6],
      ["Anh", false, 9, 6],
      ["Ly", false, 9, 6],
      ["Hoa", false, 9, 6],
      ["Sinh", false, 9, 4],
      ["TheDuc", true, 10, 0],
    ];
    const subjects: number[] = [];
    for (const [name, passFail, first, second] of scores) {
      const subject = await id(
        "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan,danh_gia_dat) VALUES($1,2,$2) RETURNING ma_mon AS id",
        [`${name} ${tag}`, passFail],
      );
      subjects.push(subject);
      const component = await id(
        "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,loai_he_so,he_so,bat_buoc,thu_tu_hien_thi) VALUES($1,'CK','CK',1,true,1) RETURNING ma_thanh_phan AS id",
        [subject],
      );
      await db.query(
        "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,'2018-09-01')",
        [teacher.id, klass, subject, term],
      );
      for (const [index, value] of [first, second].entries()) {
        await db.query(
          "UPDATE diem_thanh_phan SET gia_tri=$3,trang_thai='DA_DUYET' WHERE ma_hoc_sinh=$1 AND ma_thanh_phan=$2",
          [students[index], component, value],
        );
        await db.query(
          "INSERT INTO ket_qua_tong_ket(ma_hoc_sinh,ma_mon,ma_hoc_ky,diem_tong_ket,xep_loai,phien_ban_he_so,bo_he_so,ngay_tinh) VALUES($1,$2,$3,$4,$5,'T','{}',now())",
          [
            students[index],
            subject,
            term,
            value,
            passFail ? (value === 10 ? "DAT" : "CHUA_DAT") : null,
          ],
        );
      }
    }
    await db.query(
      "UPDATE bang_diem SET trang_thai='DA_CHOT' WHERE ma_lop=$1",
      [klass],
    );
    await db.query("UPDATE hoc_ky SET da_cong_bo=true WHERE ma_hoc_ky=$1", [
      term,
    ]);
    await db.query(
      "UPDATE hoc_sinh_lop SET trang_thai='TOT_NGHIEP',den_ngay='2019-06-01' WHERE ma_lop=$1",
      [klass],
    );

    const statistics = async () =>
      (await db.query("SELECT thong_ke_nam_hoc($1,1) AS r", [year])).rows[0].r;
    const change = (close: boolean) =>
      db.query("SELECT doi_trang_thai_nam_hoc($1,$2,$3,'Kiểm thử')", [
        admin.session,
        year,
        close,
      ]);

    const live = await statistics();
    assert.equal(live.source, "HIEN_TAI");
    await change(true);
    const frozen = await statistics();
    assert.deepEqual([frozen.source, frozen.snapshotVersion], ["BAN_CHOT", 1]);
    assert.deepEqual(frozen.total, live.total);
    assert.deepEqual(
      {
        students: frozen.total.students,
        average: frozen.total.average,
        fromEight: frozen.total.fromEight,
        fromSixHalf: frozen.total.fromSixHalf,
        fromFive: frozen.total.fromFive,
        belowFive: frozen.total.belowFive,
        passed: frozen.total.passed,
        failed: frozen.total.failed,
        levels: frozen.total.levels,
      },
      {
        students: 2,
        average: "7.33",
        fromEight: 6,
        fromSixHalf: 0,
        fromFive: 5,
        belowFive: 1,
        passed: 1,
        failed: 1,
        levels: { TOT: 1, KHA: 0, DAT: 0, CHUA_DAT: 1, CHUA_DU_MON: 0 },
      },
    );
    assert.deepEqual(
      [
        frozen.grades.length,
        frozen.classes.length,
        frozen.subjects.length,
        frozen.grades[0].label,
      ],
      [1, 1, 7, "Khối 12"],
    );

    await db.query("UPDATE mon_hoc SET ten_mon=$2 WHERE ma_mon=$1", [
      subjects[0],
      `Đổi tên ${tag}`,
    ]);
    await db.query(
      "UPDATE giao_vien SET ho_ten='Giáo viên mới' WHERE ma_giao_vien=$1",
      [teacher.id],
    );
    assert.deepEqual((await statistics()).subjects, frozen.subjects);
    const row = (
      await db.query(
        "SELECT ho_ten,gv_chu_nhiem,muc_hoc_tap FROM nguon_hoc_sinh_nam($1) WHERE ma_hoc_sinh=$2",
        [year, students[0]],
      )
    ).rows[0];
    assert.deepEqual(row, {
      ho_ten: "Học sinh Một",
      gv_chu_nhiem: "Giáo viên cũ",
      muc_hoc_tap: "TOT",
    });
    const level = (
      await db.query("SELECT xep_muc_hoc_tap($1,$2) AS r", [students[0], term])
    ).rows[0].r;
    assert.equal(level.level, "TOT");

    for (const sql of [
      `UPDATE ban_chot_hoc_sinh SET muc_hoc_tap='KHA' WHERE ma_hoc_sinh=${students[0]}`,
      `UPDATE ban_chot_hoc_sinh SET ho_ten='Sửa lén' WHERE ma_hoc_sinh=${students[0]}`,
      `DELETE FROM ban_chot_mon WHERE ma_hoc_sinh=${students[0]}`,
      `UPDATE ban_chot_nam SET ten_truong='Khác' WHERE ma_nam_hoc=${year}`,
    ])
      await rejected(db, /APPEND_ONLY/, sql);
    await db.query("SET LOCAL ROLE app_runtime");
    await rejected(
      db,
      /permission denied/,
      "DELETE FROM ban_chot_hoc_sinh WHERE false",
    );
    await rejected(
      db,
      /permission denied/,
      `SELECT lap_ban_chot_nam(${year},${admin.id})`,
    );
    await db.query("RESET ROLE");

    await db.query("SELECT xoa_hoc_sinh($1,$2,'Yêu cầu xóa')", [
      admin.session,
      students[1],
    ]);
    const scrubbed = (
      await db.query(
        "SELECT ho_ten,ngay_sinh::text AS ngay_sinh,muc_hoc_tap FROM ban_chot_hoc_sinh WHERE ma_hoc_sinh=$1",
        [students[1]],
      )
    ).rows[0];
    assert.deepEqual(scrubbed, {
      ho_ten: `Học sinh đã xóa #${students[1]}`,
      ngay_sinh: "1900-01-01",
      muc_hoc_tap: "CHUA_DAT",
    });

    await change(false);
    const reopened = await statistics();
    assert.equal(reopened.source, "HIEN_TAI");
    assert.ok(
      reopened.subjects.some(
        (s: { label: string }) => s.label === `Đổi tên ${tag}`,
      ),
    );
    await change(true);
    assert.equal((await statistics()).snapshotVersion, 2);
    const comparison = (await db.query("SELECT so_sanh_nam_hoc(1) AS r"))
      .rows[0].r as Array<{ yearId: number; source: string }>;
    assert.equal(
      comparison.find((item) => item.yearId === year)?.source,
      "BAN_CHOT",
    );
  } finally {
    await db.query("ROLLBACK");
    db.release();
    await pool.end();
  }
});
