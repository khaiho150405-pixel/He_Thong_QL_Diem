import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import { test } from "node:test";
import { Pool } from "pg";
import { createApp } from "../../src/app.js";
import type { ObjectStorage } from "../../src/modules/files/public.js";

// Thông tin trường (ADR-0019, migration 202610280001). Chạy qua HTTP thật trên DB *_test; kho ảnh là bản trong bộ nhớ.

const sha = (v: string | Uint8Array) =>
  createHash("sha256").update(v).digest("hex");
/** PNG 1x1 hợp lệ tối thiểu (chữ ký + IHDR); inspectImage chỉ đọc kích thước, không giải mã ảnh. */
const PNG = Buffer.concat([
  Buffer.from([137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13]),
  Buffer.from("IHDR"),
  Buffer.from([0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137]),
]);

async function fixture() {
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
  const runtimePool = new Pool({ connectionString: runtime });
  const objects = new Map<string, Uint8Array>();
  const storage: ObjectStorage = {
    put: async (o) => void objects.set(o.key, o.bytes),
    get: async (key) => objects.get(key)!,
    signedGetUrl: async (key) => key,
    remove: async (key) => void objects.delete(key),
  };
  const app = await createApp(
    { origins: [], environment: "development", databaseUrl: runtime },
    { check: async () => true, close: async () => {} },
    { objectStorage: storage },
  );
  await app.listen(0, "127.0.0.1");
  const url = await app.getUrl();
  const suffix = randomBytes(5).toString("hex");
  const login = async (role: string, tag: string) => {
    const id = (
      await owner.query(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'fixture',$2) RETURNING ma_nguoi_dung",
        [`${tag}${suffix}`, role],
      )
    ).rows[0].ma_nguoi_dung as number;
    const token = randomBytes(32).toString("hex");
    await owner.query(
      "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
      [sha(token), id, randomBytes(32).toString("hex")],
    );
    return token;
  };
  const admin = await login("QUAN_TRI_VIEN", "sa");
  const teacher = await login("GIAO_VIEN", "st");
  const student = await login("HOC_SINH", "ss");
  const call = async (
    path: string,
    init: { method?: string; token?: string; key?: string; body?: BodyInit } & {
      json?: unknown;
    } = {},
  ) => {
    const response = await fetch(`${url}/api/v1/${path}`, {
      method: init.method ?? "GET",
      headers: {
        ...(init.json === undefined
          ? {}
          : { "content-type": "application/json" }),
        ...(init.token ? { authorization: `Bearer ${init.token}` } : {}),
        ...(init.key ? { "x-idempotency-key": init.key } : {}),
      },
      body: init.json === undefined ? init.body : JSON.stringify(init.json),
    });
    const bytes = Buffer.from(await response.arrayBuffer());
    const type = response.headers.get("content-type") ?? "";
    return {
      status: response.status,
      headers: response.headers,
      bytes,
      body: type.includes("json") ? JSON.parse(bytes.toString()) : null,
    };
  };
  const logoForm = (version: number, bytes: Buffer, type = "image/png") => {
    const form = new FormData();
    form.set("expectedVersion", String(version));
    form.set("file", new Blob([new Uint8Array(bytes)], { type }), "logo.png");
    return form;
  };
  return {
    admin,
    teacher,
    student,
    call,
    logoForm,
    objects,
    runtimePool,
    key: (tag: string) => `${tag}-${randomBytes(4).toString("hex")}`,
    done: async () => {
      // Trả bảng truong về mặc định để các lần chạy sau (và test khác) thấy trạng thái ban đầu.
      await owner.query(
        "UPDATE truong SET ten_truong='Trường THPT Bà Điểm',ten_ngan='THPT Bà Điểm',co_quan_chu_quan='Sở Giáo dục và Đào tạo TP. Hồ Chí Minh',dia_chi=NULL,dien_thoai=NULL,email=NULL,hieu_truong=NULL,logo_key=NULL,logo_content_type=NULL,logo_checksum=NULL",
      );
      await app.close();
      await owner.end();
      await runtimePool.end();
    },
  };
}

test("public profile, admin update, role and version checks, idempotency", async () => {
  const f = await fixture();
  try {
    const first = await f.call("school-profile");
    assert.equal(first.status, 200);
    assert.equal(first.body.name, "Trường THPT Bà Điểm");
    assert.equal(first.body.hasLogo, false);
    assert.equal((await f.call("school-profile/logo")).status, 404);

    const version = first.body.version as number;
    const payload = {
      expectedVersion: version,
      name: "  Trường THPT Mẫu ",
      shortName: "THPT Mẫu",
      phone: "0912345678",
      email: "truong@example.test",
      address: "",
    };
    // Giáo viên và học sinh không sửa được; không phiên thì 401.
    for (const token of [f.teacher, f.student])
      assert.equal(
        (
          await f.call("admin/school-profile", {
            method: "PUT",
            token,
            key: f.key("x"),
            json: payload,
          })
        ).status,
        403,
      );
    assert.equal(
      (
        await f.call("admin/school-profile", {
          method: "PUT",
          key: f.key("x"),
          json: payload,
        })
      ).status,
      401,
    );

    const key = f.key("upd");
    const updated = await f.call("admin/school-profile", {
      method: "PUT",
      token: f.admin,
      key,
      json: payload,
    });
    assert.equal(updated.status, 200);
    assert.equal(updated.body.version, version + 1);
    assert.equal(updated.body.name, "Trường THPT Mẫu");
    assert.equal(updated.body.address, null);
    const pub = await f.call("school-profile");
    assert.deepEqual(pub.body, updated.body);

    // Gửi lại cùng khóa + cùng nội dung: cùng kết quả, version không tăng thêm.
    const replay = await f.call("admin/school-profile", {
      method: "PUT",
      token: f.admin,
      key,
      json: payload,
    });
    assert.equal(replay.status, 200);
    assert.equal(replay.body.version, version + 1);

    // Sai version → conflict; dữ liệu sai → INVALID_SCHOOL_PROFILE kèm trường sai.
    const stale = await f.call("admin/school-profile", {
      method: "PUT",
      token: f.admin,
      key: f.key("stale"),
      json: payload,
    });
    assert.equal(stale.status, 409);
    assert.equal(stale.body.code, "SCHOOL_PROFILE_VERSION_CONFLICT");
    const bad = await f.call("admin/school-profile", {
      method: "PUT",
      token: f.admin,
      key: f.key("bad"),
      json: {
        ...payload,
        expectedVersion: version + 1,
        phone: "12ab",
        name: "x",
      },
    });
    assert.equal(bad.status, 409);
    assert.equal(bad.body.code, "INVALID_SCHOOL_PROFILE");
    assert.deepEqual(bad.body.details.fields.sort(), ["name", "phone"]);
  } finally {
    await f.done();
  }
});

test("logo upload validates content, serves bytes, and can be removed", async () => {
  const f = await fixture();
  try {
    let version = (await f.call("school-profile")).body.version as number;
    const put = (form: FormData, token = f.admin) =>
      f.call("admin/school-profile/logo", {
        method: "PUT",
        token,
        key: f.key("logo"),
        body: form,
      });

    // File giả đuôi .png, quá 1 MB, hoặc khai sai loại đều bị từ chối.
    for (const form of [
      f.logoForm(version, Buffer.from("not a png at all")),
      f.logoForm(version, Buffer.concat([PNG, Buffer.alloc(1024 * 1024)])),
      f.logoForm(version, PNG, "image/jpeg"),
    ]) {
      const r = await put(form);
      assert.equal(r.status, 409);
      assert.equal(r.body.code, "INVALID_LOGO_FILE");
    }
    assert.equal((await put(f.logoForm(version, PNG), f.teacher)).status, 403);
    assert.equal(f.objects.size, 0);

    const ok = await put(f.logoForm(version, PNG));
    assert.equal(ok.status, 200);
    assert.equal(ok.body.hasLogo, true);
    assert.equal(ok.body.version, version + 1);
    version = ok.body.version;
    assert.ok(f.objects.has(`school/logo-${sha(PNG)}.png`));

    const logo = await f.call("school-profile/logo");
    assert.equal(logo.status, 200);
    assert.equal(logo.headers.get("content-type"), "image/png");
    assert.equal(logo.headers.get("cache-control"), "public, max-age=300");
    assert.deepEqual(logo.bytes, PNG);

    const stale = await put(f.logoForm(version - 1, PNG));
    assert.equal(stale.body.code, "SCHOOL_PROFILE_VERSION_CONFLICT");

    const removed = await f.call(
      `admin/school-profile/logo?expectedVersion=${version}`,
      { method: "DELETE", token: f.admin, key: f.key("rm") },
    );
    assert.equal(removed.status, 200);
    assert.equal(removed.body.hasLogo, false);
    assert.equal((await f.call("school-profile/logo")).status, 404);
    assert.equal(f.objects.size, 1, "file cũ trong kho được giữ lại");
  } finally {
    await f.done();
  }
});

test("runtime role cannot write truong directly", async () => {
  const f = await fixture();
  try {
    for (const sql of [
      "UPDATE truong SET ten_ngan='Hack'",
      "INSERT INTO truong(ma_truong,ten_truong,ten_ngan) VALUES(2,'Trường khác','Khác')",
      "DELETE FROM truong",
      "TRUNCATE truong",
    ])
      await assert.rejects(f.runtimePool.query(sql), /permission denied/i, sql);
  } finally {
    await f.done();
  }
});
