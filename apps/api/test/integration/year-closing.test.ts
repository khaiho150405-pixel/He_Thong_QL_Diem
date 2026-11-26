import { test } from "node:test";
import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import { Pool } from "pg";
import { createApp } from "../../src/app.js";

test("closing a school year over HTTP: admin only, blocked writes keep a stable code, overview is scoped by year", async () => {
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
    const admin = await actor("QUAN_TRI_VIEN", "yca");
    const teacher = await actor("GIAO_VIEN", "yct");
    await owner.query(
      "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'Fixture')",
      [teacher.id],
    );
    const yearInput = {
      ten: `YC ${suffix}`,
      ngay_bat_dau: "2019-09-01",
      ngay_ket_thuc: "2020-06-01",
      hien_hanh: false,
    };
    const year = await one(
      "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,$2,$3) RETURNING ma_nam_hoc",
      [yearInput.ten, yearInput.ngay_bat_dau, yearInput.ngay_ket_thuc],
    );
    const classInput = {
      ma_nam_hoc: year,
      ma_gv_chu_nhiem: teacher.id,
      ten_lop: `Y ${suffix}`.slice(0, 20),
      khoi: 12,
    };
    const classId = await one(
      "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,$4) RETURNING ma_lop",
      [year, teacher.id, classInput.ten_lop, 12],
    );
    const student = await one(
      "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,'Học sinh giả','2002-01-01') RETURNING ma_hoc_sinh",
      [classId],
    );
    const call = async (
      method: string,
      path: string,
      body?: unknown,
      token = admin.token,
    ) => {
      const response = await fetch(`${base}${path}`, {
        method,
        headers: {
          authorization: `Bearer ${token}`,
          "content-type": "application/json",
        },
        body: body === undefined ? undefined : JSON.stringify(body),
      });
      const text = await response.text();
      return {
        status: response.status,
        body: text ? JSON.parse(text) : null,
      };
    };
    const closing = `/catalog/years/${year}/closing`;
    const close = `/catalog/years/${year}/close`;
    const reopen = `/catalog/years/${year}/reopen`;
    const reason = { reason: "Hết năm học" };

    assert.equal(
      (await call("GET", closing, undefined, teacher.token)).status,
      403,
    );
    assert.equal(
      (await call("POST", close, reason, teacher.token)).status,
      403,
    );
    const before = await call("GET", closing);
    assert.equal(before.status, 200);
    assert.equal(before.body.ready, false);
    assert.deepEqual(
      before.body.issues.map((i: { code: string; count: number }) => [
        i.code,
        i.count,
      ]),
      [["STUDENTS_NOT_PROMOTED", 1]],
    );
    const early = await call("POST", close, reason);
    assert.equal(early.status, 409);
    assert.equal(early.body.code, "YEAR_NOT_READY");

    await owner.query(
      "UPDATE hoc_sinh_lop SET trang_thai='TOT_NGHIEP',den_ngay='2020-06-01' WHERE ma_hoc_sinh=$1",
      [student],
    );
    assert.equal((await call("POST", close, {})).status, 400);
    assert.equal(
      (await call("POST", close, { reason: "x", extra: 1 })).status,
      400,
    );
    const closed = await call("POST", close, reason);
    assert.equal(closed.status, 200, JSON.stringify(closed.body));
    assert.ok(closed.body.closedAt);
    assert.deepEqual(
      closed.body.history.map((h: { action: string; reason: string }) => [
        h.action,
        h.reason,
      ]),
      [["DONG", reason.reason]],
    );
    const again = await call("POST", close, reason);
    assert.equal(again.body.code, "YEAR_ALREADY_CLOSED");

    const years = await call("GET", `/catalog/years?q=${suffix}`);
    assert.ok(
      years.body.items.find(
        (y: { ma_nam_hoc: number }) => y.ma_nam_hoc === year,
      ).da_dong_luc,
    );
    for (const [method, path, body] of [
      ["PUT", `/catalog/classes/${classId}`, { ...classInput, khoi: 11 }],
      ["POST", "/catalog/classes", { ...classInput, ten_lop: "Moi" }],
      [
        "POST",
        "/catalog/semesters",
        {
          ma_nam_hoc: year,
          ten: "HK1",
          thu_tu: 1,
          ngay_bat_dau: "2019-09-01",
          ngay_ket_thuc: "2020-01-01",
        },
      ],
      ["PUT", `/catalog/years/${year}`, { ...yearInput, ten: "Đổi tên" }],
      ["PUT", `/catalog/years/${year}`, { ...yearInput, hien_hanh: true }],
    ] as const) {
      const response = await call(method, path, body);
      assert.equal(response.status, 409, `${method} ${path}`);
      assert.equal(response.body.code, "YEAR_CLOSED", `${method} ${path}`);
      assert.match(response.body.message, /Năm học đã đóng/);
    }
    assert.equal((await call("DELETE", `/catalog/years/${year}`)).status, 409);

    const overview = await call(
      "GET",
      `/reports/admin/overview?yearId=${year}`,
    );
    assert.equal(overview.status, 200, JSON.stringify(overview.body));
    assert.deepEqual(
      [
        overview.body.kpi.totalClasses,
        overview.body.kpi.totalStudents,
        overview.body.kpi.totalTeachers,
        overview.body.kpi.totalGradebooks,
        overview.body.ocrAccuracy.totalCells,
        overview.body.recentActivities.length,
      ],
      [1, 1, 0, 0, 0, 0],
    );
    const everything = await call("GET", "/reports/admin/overview");
    assert.ok(everything.body.kpi.totalClasses >= 1);
    assert.equal(
      (await call("GET", "/reports/admin/overview?yearId=2147483000")).status,
      404,
    );
    assert.equal(
      (await call("GET", "/reports/admin/overview?yearId=abc")).status,
      400,
    );

    const opened = await call("POST", reopen, { reason: "Đính chính" });
    assert.equal(opened.status, 200);
    assert.equal(opened.body.closedAt, null);
    assert.equal(opened.body.history.length, 2);
    assert.equal(
      (
        await call("PUT", `/catalog/classes/${classId}`, {
          ...classInput,
          khoi: 11,
        })
      ).status,
      200,
    );
    assert.equal(
      (await call("POST", reopen, reason)).body.code,
      "YEAR_NOT_CLOSED",
    );
  } finally {
    await app.close();
    await owner.end();
  }
});
