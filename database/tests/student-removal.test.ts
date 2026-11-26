import { test } from "node:test";
import assert from "node:assert/strict";
import { randomBytes, randomUUID } from "node:crypto";
import { Pool } from "pg";

test("quản trị viên xóa học sinh: chưa có dữ liệu thì xóa hẳn, có điểm thì ẩn danh", async () => {
  const ownerUrl = process.env.TEST_MIGRATION_URL;
  const runtimeUrl = process.env.TEST_RUNTIME_URL;
  if (!ownerUrl || !runtimeUrl || !new URL(ownerUrl).pathname.endsWith("_test"))
    throw new Error("Cần TEST_MIGRATION_URL/TEST_RUNTIME_URL kết thúc _test");
  const pool = new Pool({ connectionString: ownerUrl });
  const db = await pool.connect();
  const tag = randomUUID().slice(0, 8);
  const one = async (sql: string, params: unknown[] = []) =>
    (await db.query(sql, params)).rows[0] as Record<string, unknown>;
  const id = async (sql: string, params: unknown[] = []) =>
    Number((await one(sql, params)).id);
  const rejected = async (pattern: RegExp, sql: string, params: unknown[]) => {
    await db.query("SAVEPOINT s");
    await assert.rejects(db.query(sql, params), pattern);
    await db.query("ROLLBACK TO SAVEPOINT s");
  };
  try {
    await db.query("BEGIN ISOLATION LEVEL SERIALIZABLE");
    const admin = await id(
      "SELECT ma_nguoi_dung AS id FROM nguoi_dung WHERE vai_tro='QUAN_TRI_VIEN' AND trang_thai LIMIT 1",
    );
    const account = (role: string, name: string) =>
      id(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'x',$2) RETURNING ma_nguoi_dung AS id",
        [`rm_${name}_${tag}`, role],
      );
    const session = async (user: number) => {
      const hash = randomBytes(32).toString("hex");
      await db.query(
        "INSERT INTO phien_lam_viec(ma_bam,ma_nguoi_dung,csrf,het_han,hoat_dong_cuoi) VALUES($1,$2,$3,now()+interval '1 hour',now())",
        [hash, user, randomBytes(16).toString("hex")],
      );
      return hash;
    };
    const teacher = await account("GIAO_VIEN", "gv");
    const pupil = await account("HOC_SINH", "hs");
    await db.query(
      "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'Giáo viên giả')",
      [teacher],
    );
    const year = await id(
      "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,CURRENT_DATE-30,CURRENT_DATE+200) RETURNING ma_nam_hoc AS id",
      [`RM-${tag}`],
    );
    const term = await id(
      "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'HK1',1,CURRENT_DATE-30,CURRENT_DATE+100) RETURNING ma_hoc_ky AS id",
      [year],
    );
    const klass = await id(
      "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,10) RETURNING ma_lop AS id",
      [year, teacher, `RM-${tag}`],
    );
    const subject = await id(
      "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,2) RETURNING ma_mon AS id",
      [`RM ${tag}`],
    );
    const component = await id(
      "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,thu_tu_hien_thi) VALUES($1,'TX1',1) RETURNING ma_thanh_phan AS id",
      [subject],
    );
    const student = (name: string, user: number | null) =>
      id(
        "INSERT INTO hoc_sinh(ma_nguoi_dung,ma_lop,ho_ten,ngay_sinh) VALUES($1,$2,$3,'2010-01-01') RETURNING ma_hoc_sinh AS id",
        [user, klass, name],
      );
    const graded = await student("Học sinh có điểm", pupil);
    const empty = await student("Học sinh chưa có điểm", null);
    const book = await id(
      "INSERT INTO bang_diem(ma_lop,ma_mon,ma_hoc_ky) VALUES($1,$2,$3) RETURNING ma_bang_diem AS id",
      [klass, subject, term],
    );
    await db.query(
      "INSERT INTO diem_thanh_phan(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan,gia_tri,trang_thai) VALUES($1,$2,$3,0.0,'DA_DUYET'),($1,$4,$3,NULL,'CHUA_CO')",
      [book, graded, component, empty],
    );
    const adminSession = await session(admin);
    const pupilSession = await session(pupil);
    const remove = "SELECT xoa_hoc_sinh($1,$2,'Kiểm thử') ->> 'mode' AS mode";

    await rejected(/FORBIDDEN/, remove, [pupilSession, empty]);
    await rejected(
      /ENROLLMENT_APPEND_ONLY/,
      "DELETE FROM hoc_sinh_lop WHERE ma_hoc_sinh=$1",
      [empty],
    );

    assert.equal((await one(remove, [adminSession, empty])).mode, "DELETED");
    assert.equal(
      (
        await one(
          "SELECT (SELECT count(*) FROM hoc_sinh WHERE ma_hoc_sinh=$1)+(SELECT count(*) FROM hoc_sinh_lop WHERE ma_hoc_sinh=$1)+(SELECT count(*) FROM diem_thanh_phan WHERE ma_hoc_sinh=$1) AS n",
          [empty],
        )
      ).n,
      "0",
    );

    assert.equal(
      (await one(remove, [adminSession, graded])).mode,
      "ANONYMIZED",
    );
    const kept = await one(
      "SELECT ho_ten,ngay_sinh::text AS ngay_sinh,ma_nguoi_dung,dang_theo_hoc,da_xoa_luc IS NOT NULL AS xoa,(SELECT gia_tri::text FROM diem_thanh_phan d WHERE d.ma_hoc_sinh=h.ma_hoc_sinh) AS diem,(SELECT count(*)::int FROM hoc_sinh_lop g WHERE g.ma_hoc_sinh=h.ma_hoc_sinh AND g.trang_thai='DANG_HOC') AS dang_hoc FROM hoc_sinh h WHERE ma_hoc_sinh=$1",
      [graded],
    );
    assert.deepEqual(kept, {
      ho_ten: `Học sinh đã xóa #${graded}`,
      ngay_sinh: "1900-01-01",
      ma_nguoi_dung: null,
      dang_theo_hoc: false,
      xoa: true,
      diem: "0.0",
      dang_hoc: 0,
    });
    assert.deepEqual(
      await one(
        "SELECT ten_dang_nhap,trang_thai,(SELECT count(*)::int FROM phien_lam_viec s WHERE s.ma_nguoi_dung=n.ma_nguoi_dung) AS phien FROM nguoi_dung n WHERE ma_nguoi_dung=$1",
        [pupil],
      ),
      { ten_dang_nhap: `da_xoa_${pupil}`, trang_thai: false, phien: 0 },
    );
    await rejected(/STUDENT_ALREADY_REMOVED/, remove, [adminSession, graded]);
    await rejected(
      /STUDENT_REMOVED_READONLY/,
      "UPDATE hoc_sinh SET ho_ten='Tên mới' WHERE ma_hoc_sinh=$1",
      [graded],
    );
    await rejected(
      /ENROLLMENT_APPEND_ONLY/,
      "DELETE FROM hoc_sinh_lop WHERE ma_hoc_sinh=$1",
      [graded],
    );
    await db.query("ROLLBACK");

    const runtime = new Pool({ connectionString: runtimeUrl });
    try {
      await assert.rejects(
        runtime.query(
          "SELECT set_config('qld.student_removal','1',false); DELETE FROM hoc_sinh_lop WHERE ma_hoc_sinh=1",
        ),
        /permission denied/,
      );
    } finally {
      await runtime.end();
    }
  } finally {
    await db.query("ROLLBACK").catch(() => {});
    db.release();
    await pool.end();
  }
});
