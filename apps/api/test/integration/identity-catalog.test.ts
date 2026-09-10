import { test } from "node:test";
import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import { hash, argon2id } from "argon2";
import { Pool } from "pg";
import { createApp } from "../../src/app.js";
import { STORE, type Store } from "../../src/common/store.js";

test("UC01–08: real PostgreSQL sessions, CSRF, catalog scope, rollback and revocation", async () => {
  const ownerUrl = process.env.TEST_MIGRATION_URL;
  const runtimeUrl = process.env.TEST_RUNTIME_URL;
  if (
    !ownerUrl ||
    !runtimeUrl ||
    !new URL(ownerUrl).pathname.endsWith("_test") ||
    !new URL(runtimeUrl).pathname.endsWith("_test")
  )
    throw new Error("Explicit isolated test URLs required");
  const owner = new Pool({ connectionString: ownerUrl });
  const runtime = new Pool({ connectionString: runtimeUrl });
  const suffix = randomBytes(5).toString("hex");
  const password = randomBytes(20).toString("hex");
  const origin = "http://localhost:8080";
  const app = await createApp(
    { origins: [origin], environment: "development", databaseUrl: runtimeUrl },
    { check: async () => true, close: async () => {} },
  );
  await app.listen(0, "127.0.0.1");
  const url = await app.getUrl();
  const call = async (
    path: string,
    method = "GET",
    body?: unknown,
    token?: string,
    extra: Record<string, string> = {},
  ) => {
    const response = await fetch(`${url}/api/v1/${path}`, {
      method,
      headers: {
        "content-type": "application/json",
        ...(token ? { authorization: `Bearer ${token}` } : {}),
        ...extra,
      },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });
    const text = await response.text();
    return {
      status: response.status,
      body: text ? JSON.parse(text) : null,
      headers: response.headers,
    };
  };
  try {
    await owner.query("DELETE FROM gioi_han_dang_nhap WHERE ma_bam=$1", [
      createHash("sha256").update("127.0.0.1").digest("hex"),
    ]);
    const encrypted = await hash(password, {
      type: argon2id,
      memoryCost: 65536,
      timeCost: 3,
      parallelism: 1,
    });
    const insert = await owner.query(
      "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,$2,'QUAN_TRI_VIEN') RETURNING ma_nguoi_dung",
      [`test_${suffix}`, encrypted],
    );
    const adminId = insert.rows[0].ma_nguoi_dung;
    const login = (username: string, pass = password) =>
      call("identity/login", "POST", { username, password: pass }, undefined, {
        "x-client-platform": "native",
      });
    assert.equal((await call("catalog/classes")).status, 401);
    assert.equal(
      (
        await call("identity/login", "POST", {
          username: `test_${suffix}`,
          password,
        })
      ).status,
      403,
    );
    const session = await login(`test_${suffix}`);
    assert.equal(session.status, 200);
    const token: string = session.body.token;
    assert.equal(
      (
        await owner.query(
          "SELECT ma_bam FROM phien_lam_viec WHERE ma_nguoi_dung=$1",
          [adminId],
        )
      ).rows.some((r) => r.ma_bam === token),
      false,
    );
    const makeAccount = async (role: string, name: string) => {
      const result = await call(
        "identity/accounts",
        "POST",
        { username: `${name}_${suffix}`, password, role },
        token,
      );
      assert.equal(result.status, 200);
      return result.body.id as number;
    };
    const teacher = await makeAccount("GIAO_VIEN", "teacher");
    const other = await makeAccount("GIAO_VIEN", "other");
    const student = await makeAccount("HOC_SINH", "student");
    const create = async (resource: string, data: unknown) => {
      const result = await call(`catalog/${resource}`, "POST", data, token);
      assert.equal(
        result.status,
        200,
        `${resource}: ${JSON.stringify(result.body)}`,
      );
      return result.body;
    };
    await create("teachers", {
      ma_giao_vien: teacher,
      ho_ten: "Giáo viên giả",
      to_chuyen_mon: null,
      email: null,
      dien_thoai: null,
    });
    await create("teachers", {
      ma_giao_vien: other,
      ho_ten: "Giáo viên giả khác",
      to_chuyen_mon: null,
      email: null,
      dien_thoai: null,
    });
    const year = await create("years", {
      ten: `T${suffix}`,
      ngay_bat_dau: "2026-09-01",
      ngay_ket_thuc: "2027-06-01",
      hien_hanh: false,
    });
    const semester = await create("semesters", {
      ma_nam_hoc: year.ma_nam_hoc,
      ten: "HK1",
      thu_tu: 1,
      ngay_bat_dau: "2026-09-01",
      ngay_ket_thuc: "2027-01-01",
    });
    const classroom = await create("classes", {
      ma_nam_hoc: year.ma_nam_hoc,
      ma_gv_chu_nhiem: teacher,
      ten_lop: "10A",
      khoi: 10,
    });
    const otherClass = await create("classes", {
      ma_nam_hoc: year.ma_nam_hoc,
      ma_gv_chu_nhiem: other,
      ten_lop: "10B",
      khoi: 10,
    });
    const subject = await create("subjects", {
      ten_mon: `Môn giả ${suffix}`,
      so_tiet_tuan: 3,
    });
    const component = await create("components", {
      ma_mon: subject.ma_mon,
      ten_thanh_phan: "Kiểm tra",
      he_so: "1.00",
      bat_buoc: true,
      thu_tu_hien_thi: 1,
    });
    assert.equal(component.he_so, "1.00");
    await create("assignments", {
      ma_giao_vien: teacher,
      ma_lop: classroom.ma_lop,
      ma_mon: subject.ma_mon,
      ma_hoc_ky: semester.ma_hoc_ky,
      ngay_phan_cong: "2026-09-01",
    });
    const pupil = await create("students", {
      ma_nguoi_dung: student,
      ma_lop: classroom.ma_lop,
      ho_ten: "Học sinh giả",
      ngay_sinh: "2010-01-01",
      dang_theo_hoc: true,
    });
    await create("students", {
      ma_nguoi_dung: null,
      ma_lop: otherClass.ma_lop,
      ho_ten: "Học sinh khác",
      ngay_sinh: "2010-01-01",
      dang_theo_hoc: true,
    });
    const teacherToken = (await login(`teacher_${suffix}`)).body.token;
    const studentToken = (await login(`student_${suffix}`)).body.token;
    const otherToken = (await login(`other_${suffix}`)).body.token;
    assert.equal(
      (await call("identity/profile", "GET", undefined, studentToken)).body
        .name,
      "Học sinh giả",
    );
    assert.equal(
      (
        await call(
          "identity/profile",
          "PUT",
          { name: "Tên giả đã sửa", email: null, phone: null },
          studentToken,
        )
      ).status,
      200,
    );
    assert.equal(
      (
        await call(
          "identity/profile",
          "PUT",
          {
            name: "Sai quyền",
            email: null,
            phone: null,
            ma_lop: otherClass.ma_lop,
          },
          studentToken,
        )
      ).status,
      400,
    );
    assert.equal(
      (
        await call(
          "catalog/students?q=kh%C3%A1c",
          "GET",
          undefined,
          studentToken,
        )
      ).body.items.length,
      0,
    );
    assert.equal(
      (await call("catalog/years?cursor=9999999999", "GET", undefined, token))
        .status,
      400,
    );
    const rollbackName = `Rollback ${suffix}`;
    await assert.rejects(
      app.get<Store>(STORE).run(async (tx) => {
        await tx.create("mon_hoc", { ten_mon: rollbackName, so_tiet_tuan: 1 });
        await tx.create("nhat_ky_bao_mat", {
          ma_tac_nhan: adminId,
          hanh_dong: "TEST_ROLLBACK",
          doi_tuong: rollbackName,
        });
        throw new Error("Deliberate test failure after data and audit writes");
      }),
    );
    assert.equal(
      (
        await owner.query("SELECT 1 FROM mon_hoc WHERE ten_mon=$1", [
          rollbackName,
        ])
      ).rowCount,
      0,
    );
    assert.equal(
      (
        await owner.query("SELECT 1 FROM nhat_ky_bao_mat WHERE doi_tuong=$1", [
          rollbackName,
        ])
      ).rowCount,
      0,
    );
    assert.deepEqual(
      (
        await call("catalog/students", "GET", undefined, studentToken)
      ).body.items.map((x: { ma_hoc_sinh: number }) => x.ma_hoc_sinh),
      [pupil.ma_hoc_sinh],
    );
    assert.deepEqual(
      (
        await call("catalog/students", "GET", undefined, teacherToken)
      ).body.items.map((x: { ma_hoc_sinh: number }) => x.ma_hoc_sinh),
      [pupil.ma_hoc_sinh],
    );
    assert.deepEqual(
      (await call("catalog/students", "GET", undefined, otherToken)).body.items,
      [],
    );
    assert.equal(
      (await call("identity/accounts", "GET", undefined, teacherToken)).status,
      403,
    );
    assert.equal(
      (await call("catalog/classes", "POST", {}, teacherToken)).status,
      403,
    );
    assert.equal(
      (await call("catalog/classes", "GET", undefined, studentToken)).status,
      403,
    );
    assert.equal(
      (await call("catalog/classes", "POST", { bad: true }, token)).status,
      400,
    );
    assert.equal(
      (
        await call(
          `catalog/classes/${classroom.ma_lop}`,
          "DELETE",
          undefined,
          token,
        )
      ).status,
      409,
    );
    const countBefore = (
      await owner.query("SELECT count(*) FROM nhat_ky_bao_mat")
    ).rows[0].count;
    assert.equal(
      (
        await call(
          "catalog/semesters",
          "POST",
          {
            ma_nam_hoc: year.ma_nam_hoc,
            ten: "Sai ngày",
            thu_tu: 2,
            ngay_bat_dau: "2020-01-01",
            ngay_ket_thuc: "2020-02-01",
          },
          token,
        )
      ).status,
      400,
    );
    assert.equal(
      (await owner.query("SELECT count(*) FROM nhat_ky_bao_mat")).rows[0].count,
      countBefore,
    );
    for (const sql of [
      "UPDATE nhat_ky_bao_mat SET hanh_dong=hanh_dong",
      "DELETE FROM nhat_ky_bao_mat",
      "TRUNCATE nhat_ky_bao_mat",
    ])
      await assert.rejects(runtime.query(sql));
    const web = await call(
      "identity/login",
      "POST",
      { username: `test_${suffix}`, password },
      undefined,
      { origin, "x-client-platform": "web" },
    );
    assert.equal(web.status, 200);
    assert.equal(web.body.token, null);
    const cookie = web.headers.get("set-cookie")!;
    assert.match(cookie, /HttpOnly/);
    assert.match(cookie, /SameSite=Strict/);
    assert.equal(
      (
        await call("identity/logout", "POST", undefined, undefined, {
          cookie,
          origin,
        })
      ).status,
      403,
    );
    assert.equal(
      (
        await call("identity/logout", "POST", undefined, undefined, {
          cookie,
          origin: "http://evil.invalid",
          "x-csrf-token": web.body.csrf,
        })
      ).status,
      403,
    );
    assert.equal(
      (
        await call("identity/logout", "POST", undefined, undefined, {
          cookie,
          origin,
          "x-csrf-token": web.body.csrf,
        })
      ).status,
      204,
    );
    assert.equal(
      (await call("identity/me", "GET", undefined, undefined, { cookie }))
        .status,
      401,
    );
    assert.equal(
      (
        await call(
          `identity/accounts/${teacher}`,
          "PUT",
          { role: "GIAO_VIEN", active: false },
          token,
        )
      ).status,
      200,
    );
    assert.equal(
      (await call("identity/me", "GET", undefined, teacherToken)).status,
      401,
    );
    for (let i = 0; i < 5; i++)
      assert.equal((await login(`other_${suffix}`, "wrong")).status, 401);
    assert.equal((await login(`other_${suffix}`)).status, 401);
    assert.equal(
      (
        await call(
          `identity/accounts/${other}`,
          "PUT",
          { role: "GIAO_VIEN", active: true },
          token,
        )
      ).status,
      200,
    );
    assert.equal((await login(`other_${suffix}`)).status, 200);
    await owner.query(
      "UPDATE phien_lam_viec SET hoat_dong_cuoi=now()-interval '31 minutes' WHERE ma_nguoi_dung=$1",
      [student],
    );
    assert.equal(
      (await call("identity/me", "GET", undefined, studentToken)).status,
      401,
    );
    assert.equal(
      (
        await call(
          "identity/password",
          "POST",
          { currentPassword: password, newPassword: `${password}x` },
          token,
        )
      ).status,
      204,
    );
    assert.equal(
      (await call("identity/me", "GET", undefined, token)).status,
      401,
    );
    assert.equal((await login(`test_${suffix}`)).status, 401);
    assert.equal((await login(`test_${suffix}`, `${password}x`)).status, 200);
  } finally {
    await app.close();
    await owner.end();
    await runtime.end();
  }
});
