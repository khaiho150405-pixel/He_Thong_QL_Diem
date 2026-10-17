import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import { test } from "node:test";
import { ConflictException, ForbiddenException } from "@nestjs/common";
import { Pool } from "pg";
import { createApp } from "../../src/app.js";
import { createGridFailure } from "../../src/modules/gradebooks/infrastructure/prisma-store.js";

// Tạo bảng điểm: thông báo tiếng Việt rõ ràng, giữ nguyên mã trạng thái 403/409. Dữ liệu giả, chỉ trên DB *_test.

test("create gradebook reports exactly what is wrong", async () => {
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
  const suffix = randomBytes(4).toString("hex");
  const makeUser = async (role: "QUAN_TRI_VIEN" | "GIAO_VIEN") => {
    const id: number = (
      await owner.query(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'test-only',$2) RETURNING ma_nguoi_dung",
        [`gc_${role.slice(0, 2)}_${randomBytes(4).toString("hex")}`, role],
      )
    ).rows[0].ma_nguoi_dung;
    const token = randomBytes(32).toString("hex");
    await owner.query(
      "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
      [
        createHash("sha256").update(token).digest("hex"),
        id,
        randomBytes(32).toString("hex"),
      ],
    );
    if (role === "GIAO_VIEN")
      await owner.query(
        "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'GV tạo bảng giả')",
        [id],
      );
    return { id, token };
  };
  const create = async (
    token: string,
    scope: { classId: number; subjectId: number; termId: number },
  ) => {
    const response = await fetch(`${base}/gradebooks`, {
      method: "POST",
      headers: {
        authorization: `Bearer ${token}`,
        "content-type": "application/json",
      },
      body: JSON.stringify(scope),
    });
    return {
      status: response.status,
      body: (await response.json()) as { message?: string },
    };
  };
  const insert = async (sql: string, params: unknown[]) =>
    (await owner.query(sql, params)).rows[0] as Record<string, number>;
  try {
    const teacher = await makeUser("GIAO_VIEN");
    const other = await makeUser("GIAO_VIEN");
    const admin = await makeUser("QUAN_TRI_VIEN");
    const year = (
      await insert(
        "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2026-09-01','2027-06-01') RETURNING ma_nam_hoc",
        [`GC-${suffix}`],
      )
    ).ma_nam_hoc!;
    const otherYear = (
      await insert(
        "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2027-09-01','2028-06-01') RETURNING ma_nam_hoc",
        [`GD-${suffix}`],
      )
    ).ma_nam_hoc!;
    const term = (
      await insert(
        "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'HK1',1,'2026-09-05','2027-01-10') RETURNING ma_hoc_ky",
        [year],
      )
    ).ma_hoc_ky!;
    const wrongYearTerm = (
      await insert(
        "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'HK1',1,'2027-09-05','2028-01-10') RETURNING ma_hoc_ky",
        [otherYear],
      )
    ).ma_hoc_ky!;
    const makeClass = async (name: string, students: number) => {
      const cls = (
        await insert(
          "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,10) RETURNING ma_lop",
          [year, teacher.id, `${name}-${suffix}`.slice(0, 20)],
        )
      ).ma_lop!;
      for (let i = 1; i <= students; i++)
        await owner.query(
          "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,$2,'2010-01-01')",
          [cls, `Học sinh giả ${i}`],
        );
      return cls;
    };
    const fullClass = await makeClass("full", 2);
    const emptyClass = await makeClass("empty", 0);
    const makeSubject = async (name: string, withComponent: boolean) => {
      const subject = (
        await insert(
          "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,2) RETURNING ma_mon",
          [`${name}-${suffix}`],
        )
      ).ma_mon!;
      if (withComponent)
        await owner.query(
          "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,he_so,thu_tu_hien_thi) VALUES($1,'Thành phần giả',1,1)",
          [subject],
        );
      return subject;
    };
    const subject = await makeSubject("ok", true);
    const bareSubject = await makeSubject("bare", false);
    const assign = (cls: number, subj: number, termId: number) =>
      owner.query(
        "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,CURRENT_DATE)",
        [teacher.id, cls, subj, termId],
      );
    await assign(fullClass, subject, wrongYearTerm);
    await assign(emptyClass, subject, term);
    await assign(fullClass, bareSubject, term);
    const books = async () =>
      Number(
        (
          await owner.query(
            "SELECT count(*) FROM bang_diem WHERE ma_lop IN ($1,$2)",
            [fullClass, emptyClass],
          )
        ).rows[0].count,
      );

    // 1) Không phải giáo viên (kể cả quản trị viên).
    const asAdmin = await create(admin.token, {
      classId: fullClass,
      subjectId: subject,
      termId: term,
    });
    assert.equal(asAdmin.status, 403);
    assert.equal(
      asAdmin.body.message,
      "Chỉ giáo viên được phân công mới tạo được bảng điểm.",
    );
    // 2) Giáo viên không có phân công khớp.
    const unassigned = await create(other.token, {
      classId: fullClass,
      subjectId: subject,
      termId: term,
    });
    assert.equal(unassigned.status, 403);
    assert.equal(
      unassigned.body.message,
      "Bạn chưa được phân công dạy môn này cho lớp và học kỳ đã chọn.",
    );
    // 3) Học kỳ khác năm học của lớp.
    const mismatch = await create(teacher.token, {
      classId: fullClass,
      subjectId: subject,
      termId: wrongYearTerm,
    });
    assert.equal(mismatch.status, 409);
    assert.equal(
      mismatch.body.message,
      "Học kỳ đã chọn không thuộc năm học của lớp.",
    );
    // 4) Lớp không có học sinh đang học, hoặc môn chưa có thành phần điểm.
    for (const scope of [
      { classId: emptyClass, subjectId: subject, termId: term },
      { classId: fullClass, subjectId: bareSubject, termId: term },
    ]) {
      const empty = await create(teacher.token, scope);
      assert.equal(empty.status, 409);
      assert.equal(
        empty.body.message,
        "Lớp chưa có học sinh đang theo học hoặc môn học chưa có thành phần điểm.",
      );
    }
    assert.equal(await books(), 0);
  } finally {
    await app.close();
    await owner.end();
  }
});

test("SQL error names map to messages, everything else is left to the generic handling", () => {
  const sql = (name: string) => ({
    code: "P2010",
    meta: { code: "23514", message: `ERROR: ${name}` },
  });
  const forbidden = createGridFailure(sql("GRADEBOOK_FORBIDDEN"));
  assert.ok(forbidden instanceof ForbiddenException);
  assert.equal(
    forbidden.message,
    "Bạn chưa được phân công dạy môn này cho lớp và học kỳ đã chọn.",
  );
  assert.ok(
    createGridFailure(sql("GRADEBOOK_YEAR_MISMATCH")) instanceof
      ConflictException,
  );
  assert.ok(
    createGridFailure(sql("GRADEBOOK_EMPTY_ROSTER_OR_COMPONENTS")) instanceof
      ConflictException,
  );
  assert.equal(createGridFailure(sql("SOMETHING_ELSE")), null);
  assert.equal(createGridFailure(new Error("boom")), null);
  // Không lộ chi tiết SQL/phiên trong message trả ra.
  assert.doesNotMatch(
    String(createGridFailure(sql("GRADEBOOK_YEAR_MISMATCH"))?.message),
    /ERROR|SELECT|public\./,
  );
});
