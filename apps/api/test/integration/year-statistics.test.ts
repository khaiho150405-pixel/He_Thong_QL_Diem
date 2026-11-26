import { test } from "node:test";
import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import ExcelJS from "exceljs";
import { Pool } from "pg";
import { createApp } from "../../src/app.js";

test("year statistics, comparison and workbook over HTTP read the snapshot of a closed year", async () => {
  const migration = process.env.TEST_MIGRATION_URL,
    runtime = process.env.TEST_RUNTIME_URL;
  if (
    !migration ||
    !runtime ||
    !new URL(migration).pathname.endsWith("_test") ||
    !new URL(runtime).pathname.endsWith("_test")
  )
    throw Error("Isolated DB required");
  const owner = new Pool({ connectionString: migration });
  const app = await createApp(
    { environment: "development", origins: [], databaseUrl: runtime },
    { check: async () => true, close: async () => {} },
  );
  await app.listen(0, "127.0.0.1");
  const base = `${await app.getUrl()}/api/v1`;
  const suffix = randomBytes(5).toString("hex");
  const one = async (sql: string, params: unknown[]) =>
    Number(Object.values((await owner.query(sql, params)).rows[0])[0]);
  try {
    const actor = async (role: string, tag: string) => {
      const id = await one(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'fixture',$2) RETURNING ma_nguoi_dung",
        [`${tag}${suffix}`, role],
      );
      const token = randomBytes(32).toString("hex");
      await owner.query(
        "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
        [
          createHash("sha256").update(token).digest("hex"),
          id,
          randomBytes(32).toString("hex"),
        ],
      );
      return { id, token };
    };
    const admin = await actor("QUAN_TRI_VIEN", "ysa");
    const teacher = await actor("GIAO_VIEN", "yst");
    await owner.query(
      "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'Chủ nhiệm giả')",
      [teacher.id],
    );
    const year = await one(
      "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2017-09-01','2018-06-01') RETURNING ma_nam_hoc",
      [`YS ${suffix}`],
    );
    const term = await one(
      "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'Học kỳ I',1,'2017-09-01','2018-01-15') RETURNING ma_hoc_ky",
      [year],
    );
    const className = `S ${suffix}`.slice(0, 20);
    const classId = await one(
      "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,11) RETURNING ma_lop",
      [year, teacher.id, className],
    );
    const student = await one(
      "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,'=Học sinh giả','2000-03-04') RETURNING ma_hoc_sinh",
      [classId],
    );
    const subject = await one(
      "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,2) RETURNING ma_mon",
      [`Môn ${suffix}`],
    );
    const component = await one(
      "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,loai_he_so,he_so,bat_buoc,thu_tu_hien_thi) VALUES($1,'Cuối kỳ','CK',1,true,1) RETURNING ma_thanh_phan",
      [subject],
    );
    await owner.query(
      "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,'2017-09-01')",
      [teacher.id, classId, subject, term],
    );
    await owner.query(
      "UPDATE diem_thanh_phan SET gia_tri=7.5,trang_thai='DA_DUYET' WHERE ma_hoc_sinh=$1 AND ma_thanh_phan=$2",
      [student, component],
    );
    await owner.query(
      "INSERT INTO ket_qua_tong_ket(ma_hoc_sinh,ma_mon,ma_hoc_ky,diem_tong_ket,phien_ban_he_so,bo_he_so,ngay_tinh) VALUES($1,$2,$3,7.5,'T','{}',now())",
      [student, subject, term],
    );
    await owner.query(
      "UPDATE bang_diem SET trang_thai='DA_CHOT' WHERE ma_lop=$1",
      [classId],
    );
    await owner.query("UPDATE hoc_ky SET da_cong_bo=true WHERE ma_hoc_ky=$1", [
      term,
    ]);
    await owner.query(
      "UPDATE hoc_sinh_lop SET trang_thai='LEN_LOP',den_ngay='2018-06-01' WHERE ma_lop=$1",
      [classId],
    );
    const get = (path: string, token = admin.token) =>
      fetch(`${base}${path}`, {
        headers: { authorization: `Bearer ${token}` },
      });
    const json = async (path: string) => {
      const response = await get(path);
      return {
        status: response.status,
        body: JSON.parse(await response.text()),
      };
    };
    const statistics = `/reports/admin/years/${year}/statistics?term=1`;
    const exportPath = `/reports/admin/years/${year}/export.xlsx?term=1`;
    for (const path of [
      statistics,
      exportPath,
      "/reports/admin/years/comparison?term=1",
    ])
      assert.equal((await get(path, teacher.token)).status, 403, path);
    assert.equal(
      (await get(`/reports/admin/years/${year}/statistics`)).status,
      400,
    );
    assert.equal(
      (await get("/reports/admin/years/comparison?term=9")).status,
      400,
    );
    assert.equal(
      (await get("/reports/admin/years/2147483000/statistics?term=1")).status,
      404,
    );
    assert.equal(
      (await get(`/reports/admin/years/${year}/export.xlsx?term=2`)).status,
      404,
    );

    const live = await json(statistics);
    assert.equal(live.status, 200, JSON.stringify(live.body));
    assert.equal(live.body.source, "HIEN_TAI");
    assert.equal(live.body.snapshotVersion, null);
    assert.equal("schoolName" in live.body, false);

    const closed = await fetch(`${base}/catalog/years/${year}/close`, {
      method: "POST",
      headers: {
        authorization: `Bearer ${admin.token}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({ reason: "Hết năm" }),
    });
    assert.equal(closed.status, 200, await closed.text());
    await owner.query("UPDATE mon_hoc SET ten_mon=$2 WHERE ma_mon=$1", [
      subject,
      `Tên mới ${suffix}`,
    ]);

    const frozen = await json(statistics);
    assert.equal(frozen.body.source, "BAN_CHOT");
    assert.equal(frozen.body.snapshotVersion, 1);
    assert.equal(frozen.body.total.average, "7.50");
    assert.equal(frozen.body.total.fromSixHalf, 1);
    assert.equal(frozen.body.total.levels.CHUA_DU_MON, 1);
    assert.deepEqual(
      frozen.body.subjects.map((s: { label: string; levels: unknown }) => [
        s.label,
        s.levels,
      ]),
      [[`Môn ${suffix}`, null]],
    );
    const comparison = await json("/reports/admin/years/comparison?term=1");
    const mine = comparison.body.items.find(
      (item: { yearId: number }) => item.yearId === year,
    );
    assert.deepEqual([mine.source, mine.students], ["BAN_CHOT", 1]);

    const file = await get(exportPath);
    assert.equal(file.status, 200);
    assert.match(
      file.headers.get("content-disposition")!,
      /tong-hop-ys-[a-f0-9]+-hoc-ky-1\.xlsx/,
    );
    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(await file.arrayBuffer());
    assert.deepEqual(
      workbook.worksheets.map((sheet) => sheet.name),
      ["Thong tin", "Thong ke", className, "Chi tiet diem"],
    );
    const sheet = workbook.getWorksheet(className)!;
    assert.deepEqual((sheet.getRow(2).values as unknown[]).slice(1), [
      "STT",
      "Họ tên",
      "Ngày sinh",
      `Môn ${suffix}`,
      "Mức học tập",
    ]);
    assert.deepEqual((sheet.getRow(3).values as unknown[]).slice(1), [
      1,
      "'=Học sinh giả",
      "04/03/2000",
      7.5,
      "Chưa đủ môn để xếp mức",
    ]);
    assert.equal(
      workbook.getWorksheet("Chi tiet diem")!.getCell(2, 5).value,
      "Cuối kỳ: 7.5",
    );
    assert.equal(
      await one(
        "SELECT count(*) FROM nhat_ky_bao_mat WHERE ma_tac_nhan=$1 AND hanh_dong='YEAR_RECORD_EXPORTED'",
        [admin.id],
      ),
      1,
    );
  } finally {
    await app.close();
    await owner.end();
  }
});
