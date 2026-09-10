import { test } from "node:test";
import assert from "node:assert/strict";
import { Pool } from "pg";

test("PostgreSQL constraints and actual runtime permissions", async () => {
  const ownerUrl = process.env.TEST_MIGRATION_URL;
  const runtimeUrl = process.env.TEST_RUNTIME_URL;
  if (
    !ownerUrl ||
    !runtimeUrl ||
    !new URL(ownerUrl).pathname.endsWith("_test") ||
    !new URL(runtimeUrl).pathname.endsWith("_test")
  )
    throw new Error(
      "Explicit TEST_MIGRATION_URL / TEST_RUNTIME_URL ending _test required",
    );
  const ownerPool = new Pool({ connectionString: ownerUrl });
  const runtimePool = new Pool({ connectionString: runtimeUrl });
  const owner = await ownerPool.connect();
  const runtime = await runtimePool.connect();
  try {
    const tables = await owner.query(
      "SELECT count(*)::int AS n FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE' AND table_name NOT IN ('_prisma_migrations','phien_lam_viec','nhat_ky_bao_mat','gioi_han_dang_nhap')",
    );
    assert.equal(tables.rows[0].n, 16);
    const denied = async (sql: string) => {
      await assert.rejects(
        runtime.query(sql),
        (e: { code?: string }) => e.code === "42501",
      );
    };
    await denied("DELETE FROM lich_su_sua_diem");
    await denied("UPDATE lich_su_sua_diem SET ly_do=ly_do");
    await denied("TRUNCATE lich_su_sua_diem");
    await denied("CREATE TABLE forbidden (id int)");
    await denied("CREATE SCHEMA forbidden");
    const privileges = await owner.query(
      "SELECT has_database_privilege(current_user, current_database(), 'CREATE') AS can_migrate, has_database_privilege('app_runtime', current_database(), 'CREATE') AS runtime_create",
    );
    assert.equal(privileges.rows[0].can_migrate, true);
    assert.equal(privileges.rows[0].runtime_create, false);
    await denied("UPDATE diem_thanh_phan SET gia_tri=8.55");
    for (const value of ["-0.1", "10.1", "8.55", "NaN"])
      await assert.rejects(
        runtime.query("SELECT kiem_tra_gia_tri_diem($1::numeric)", [value]),
        (e: { code?: string }) => e.code === "23514",
      );
    assert.equal(
      (await runtime.query("SELECT kiem_tra_gia_tri_diem(NULL) AS grade"))
        .rows[0].grade,
      null,
    );
    assert.equal(
      (await runtime.query("SELECT kiem_tra_gia_tri_diem(0.0) AS grade"))
        .rows[0].grade,
      "0.0",
    );
    await owner.query("BEGIN");
    const reject = async (sql: string, params: unknown[], code: string) => {
      await owner.query("SAVEPOINT negative");
      await assert.rejects(
        owner.query(sql, params),
        (e: { code?: string }) =>
          e.code === code || (code === "23503" && e.code === "23001"),
      );
      await owner.query("ROLLBACK TO SAVEPOINT negative");
    };
    const fixture = (
      await owner.query(`SELECT hs.ma_hoc_sinh, hs.ma_lop, pc.ma_mon, pc.ma_hoc_ky, pc.ma_giao_vien, tp.ma_thanh_phan
      FROM hoc_sinh hs JOIN phan_cong_giang_day pc ON pc.ma_lop=hs.ma_lop JOIN thanh_phan_diem tp ON tp.ma_mon=pc.ma_mon LIMIT 1`)
    ).rows[0];
    assert.ok(fixture, "Run synthetic seed first");
    const {
      ma_hoc_sinh: student,
      ma_lop: cls,
      ma_mon: subject,
      ma_hoc_ky: term,
      ma_thanh_phan: component,
      ma_giao_vien: teacher,
    } = fixture;
    const book = (
      await owner.query(
        "INSERT INTO bang_diem (ma_lop,ma_mon,ma_hoc_ky) VALUES ($1,$2,$3) RETURNING ma_bang_diem",
        [cls, subject, term],
      )
    ).rows[0].ma_bang_diem;
    await reject(
      "INSERT INTO bang_diem (ma_lop,ma_mon,ma_hoc_ky) VALUES ($1,$2,$3)",
      [cls, subject, term],
      "23505",
    );
    const grade = (
      await owner.query(
        "INSERT INTO diem_thanh_phan (ma_bang_diem,ma_hoc_sinh,ma_thanh_phan) VALUES ($1,$2,$3) RETURNING ma_diem,gia_tri",
        [book, student, component],
      )
    ).rows[0];
    assert.equal(grade.gia_tri, null);
    const zero = (
      await owner.query(
        "UPDATE diem_thanh_phan SET gia_tri=0.0,trang_thai='DA_DUYET' WHERE ma_diem=$1 RETURNING gia_tri",
        [grade.ma_diem],
      )
    ).rows[0].gia_tri;
    assert.equal(zero, "0.0");
    await reject(
      "UPDATE diem_thanh_phan SET gia_tri=10.1 WHERE ma_diem=$1",
      [grade.ma_diem],
      "23514",
    );
    await reject(
      "DELETE FROM bang_diem WHERE ma_bang_diem=$1",
      [book],
      "23503",
    );
    await reject(
      "INSERT INTO diem_thanh_phan (ma_bang_diem,ma_hoc_sinh,ma_thanh_phan) VALUES ($1,$2,$3)",
      [book, student, component],
      "23505",
    );
    const slip = (
      await owner.query(
        "INSERT INTO phieu_nhan_dien (ma_bang_diem,ma_thanh_phan,nguoi_tai,ma_bam_tep,duong_dan_anh_goc,so_dong_khai_bao) VALUES ($1,$2,$3,$4,'test/image',1) RETURNING ma_phieu",
        [book, component, teacher, "a".repeat(64)],
      )
    ).rows[0].ma_phieu;
    await reject(
      "INSERT INTO phieu_nhan_dien (ma_bang_diem,ma_thanh_phan,nguoi_tai,ma_bam_tep,duong_dan_anh_goc,so_dong_khai_bao) VALUES ($1,$2,$3,$4,'test/image',1)",
      [book, component, teacher, "a".repeat(64)],
      "23505",
    );
    await reject(
      "UPDATE phieu_nhan_dien SET trang_thai='CHO_DOI_CHIEU',so_dong_nhan_dien=2 WHERE ma_phieu=$1",
      [slip],
      "23514",
    );
    await owner.query(
      "INSERT INTO ket_qua_dong (ma_phieu,ma_hoc_sinh,thu_tu_dong,ket_luan_doi_chieu,muc_phan_loai) VALUES ($1,$2,1,'KHONG_DOC_DUOC','DO')",
      [slip, student],
    );
    await reject(
      "INSERT INTO ket_qua_dong (ma_phieu,ma_hoc_sinh,thu_tu_dong,ket_luan_doi_chieu,muc_phan_loai) VALUES ($1,$2,1,'KHONG_DOC_DUOC','DO')",
      [slip, student],
      "23505",
    );
    // SET ROLE uses the actual database role, inside this rollback-only fixture.
    await owner.query("SET LOCAL ROLE app_runtime");
    await owner.query(
      "INSERT INTO lich_su_sua_diem (ma_diem,nguoi_sua,gia_tri_cu,gia_tri_moi,ly_do) VALUES ($1,$2,NULL,0,'Test fixture')",
      [grade.ma_diem, teacher],
    );
    assert.equal(
      (
        await owner.query(
          "SELECT gia_tri FROM diem_thanh_phan WHERE ma_diem=$1",
          [grade.ma_diem],
        )
      ).rows[0].gia_tri,
      "0.0",
    );
    await owner.query("RESET ROLE");
    await owner.query("ROLLBACK");
  } finally {
    await owner.query("ROLLBACK");
    owner.release();
    runtime.release();
    await ownerPool.end();
    await runtimePool.end();
  }
});
