import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import { test } from "node:test";
import { Pool } from "pg";
import { createApp } from "../../src/app.js";

// Một phiên, nhiều GET danh sách song song (màn "Môn học & hệ số" tải subjects, components, semester-weights, semesters cùng lúc).
// Trước đây mỗi request đều GHI hoat_dong_cuoi của phiên rồi đọc lại đúng dòng đó dưới Serializable → 40001 → 409
// "Dữ liệu vừa thay đổi; tải lại và thử lại.". Chỉ chạy trên DB *_test, dữ liệu giả.

const PATHS = [
  "/catalog/subjects",
  "/catalog/components",
  "/catalog/semester-weights",
  "/catalog/semesters",
];

test("many parallel catalog reads on one session never fail with 409", async () => {
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
  const app = await createApp(
    {
      environment: "development",
      origins: ["http://localhost:8080"],
      databaseUrl: runtimeUrl,
    },
    { check: async () => true, close: async () => {} },
    {
      objectStorage: {
        put: async () => {},
        get: async () => new Uint8Array(),
        signedGetUrl: async (key) => key,
        remove: async () => {},
      },
    },
  );
  await app.listen(0, "127.0.0.1");
  const base = `${await app.getUrl()}/api/v1`;
  try {
    const adminId: number = (
      await owner.query(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'test-only','QUAN_TRI_VIEN') RETURNING ma_nguoi_dung",
        [`cc_${randomBytes(4).toString("hex")}`],
      )
    ).rows[0].ma_nguoi_dung;
    const token = randomBytes(32).toString("hex");
    const hash = createHash("sha256").update(token).digest("hex");
    // hoat_dong_cuoi đã cũ hơn 60 giây: request đầu tiên của mỗi vòng là lần "chạm" phiên duy nhất.
    await owner.query(
      "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now()-interval '5 minutes')",
      [hash, adminId, randomBytes(32).toString("hex")],
    );
    const statuses: number[] = [];
    for (let round = 0; round < 8; round++) {
      // Làm cũ phiên mỗi vòng để mọi request của vòng đó cùng đua nhau chạm phiên.
      await owner.query(
        "UPDATE phien_lam_viec SET hoat_dong_cuoi=now()-interval '5 minutes' WHERE ma_bam=$1",
        [hash],
      );
      const responses = await Promise.all(
        Array.from({ length: 20 }, (_, index) =>
          fetch(`${base}${PATHS[index % PATHS.length]}`, {
            headers: { authorization: `Bearer ${token}` },
          }),
        ),
      );
      statuses.push(...responses.map((response) => response.status));
    }
    const conflicts = statuses.filter((status) => status === 409).length;
    console.log(
      JSON.stringify({
        event: "concurrent_catalog_result",
        total: statuses.length,
        conflicts,
      }),
    );
    assert.equal(
      conflicts,
      0,
      `${conflicts}/${statuses.length} request bị 409`,
    );
    assert.ok(statuses.every((status) => status === 200));
  } finally {
    await app.close();
    await owner.end();
  }
});

test("the session is touched only when last activity is older than 60 seconds; idle expiry is unchanged", async () => {
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
  const app = await createApp(
    {
      environment: "development",
      origins: ["http://localhost:8080"],
      databaseUrl: runtimeUrl,
    },
    { check: async () => true, close: async () => {} },
    {
      objectStorage: {
        put: async () => {},
        get: async () => new Uint8Array(),
        signedGetUrl: async (key) => key,
        remove: async () => {},
      },
    },
  );
  await app.listen(0, "127.0.0.1");
  const base = `${await app.getUrl()}/api/v1`;
  try {
    const adminId: number = (
      await owner.query(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'test-only','QUAN_TRI_VIEN') RETURNING ma_nguoi_dung",
        [`ct_${randomBytes(4).toString("hex")}`],
      )
    ).rows[0].ma_nguoi_dung;
    const token = randomBytes(32).toString("hex");
    const hash = createHash("sha256").update(token).digest("hex");
    await owner.query(
      "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
      [hash, adminId, randomBytes(32).toString("hex")],
    );
    const setAge = (seconds: number) =>
      owner.query(
        "UPDATE phien_lam_viec SET hoat_dong_cuoi=now()-($2::int * interval '1 second') WHERE ma_bam=$1",
        [hash, seconds],
      );
    const ageSeconds = async () =>
      Number(
        (
          await owner.query(
            "SELECT extract(epoch FROM now()-hoat_dong_cuoi) AS age FROM phien_lam_viec WHERE ma_bam=$1",
            [hash],
          )
        ).rows[0].age,
      );
    const status = async () =>
      (
        await fetch(`${base}/catalog/subjects`, {
          headers: { authorization: `Bearer ${token}` },
        })
      ).status;

    // Hoạt động trong vòng 60 giây: không ghi gì (giá trị giữ nguyên).
    await setAge(30);
    assert.equal(await status(), 200);
    const untouched = await ageSeconds();
    assert.ok(untouched >= 29, `không được ghi lại phiên (tuổi ${untouched}s)`);
    // Quá 60 giây: được chạm về "bây giờ".
    await setAge(120);
    assert.equal(await status(), 200);
    assert.ok((await ageSeconds()) < 10);
    // Hết hạn idle 30 phút vẫn là 401 và không được hồi sinh phiên.
    await setAge(31 * 60);
    assert.equal(await status(), 401);
    assert.ok((await ageSeconds()) >= 31 * 60 - 5);
    // Phiên hết hạn tuyệt đối vẫn là 401.
    await owner.query(
      "UPDATE phien_lam_viec SET hoat_dong_cuoi=now(), het_han=now()-interval '1 second' WHERE ma_bam=$1",
      [hash],
    );
    assert.equal(await status(), 401);
  } finally {
    await app.close();
    await owner.end();
  }
});
