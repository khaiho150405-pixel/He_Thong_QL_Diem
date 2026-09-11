import { test } from "node:test";
import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import { Pool } from "pg";
import { createApp } from "../../src/app.js";
import type {
  Actor,
  Role,
} from "../../src/modules/authorization/application/policy.js";
import {
  GRADEBOOK_STORE,
  type GradebookStore,
} from "../../src/modules/gradebooks/application/port.js";
import { GradebooksService } from "../../src/modules/gradebooks/application/service.js";

test("UC09-10 part 2: batch update, lock, history, idempotency, IDOR and version conflict", async () => {
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
  );
  await app.listen(0, "127.0.0.1");
  const url = await app.getUrl();
  const store = app.get<GradebookStore>(GRADEBOOK_STORE);
  const service = app.get(GradebooksService);
  const suffix = randomBytes(5).toString("hex");
  const makeActor = async (
    role: Role,
  ): Promise<Actor & { token: string; csrf: string }> => {
    const username = `write_${role}_${randomBytes(4).toString("hex")}`;
    const { rows } = await owner.query(
      "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'test-only-no-login',$2) RETURNING ma_nguoi_dung",
      [username, role],
    );
    const id: number = rows[0].ma_nguoi_dung;
    const token = randomBytes(32).toString("hex");
    const sessionHash = createHash("sha256").update(token).digest("hex");
    const csrf = randomBytes(32).toString("hex");
    await owner.query(
      "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
      [sessionHash, id, csrf],
    );
    return { id, username, role, sessionHash, token, csrf };
  };

  try {
    const teacher = await makeActor("GIAO_VIEN");
    const admin = await makeActor("QUAN_TRI_VIEN");
    const student = await makeActor("HOC_SINH");
    await owner.query(
      "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'GV Write Test')",
      [teacher.id],
    );
    const year = (
      await owner.query(
        "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2026-09-01','2027-06-01') RETURNING ma_nam_hoc",
        [`W-${suffix}`],
      )
    ).rows[0].ma_nam_hoc;
    const term = (
      await owner.query(
        "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'Kỳ write',1,'2026-09-01','2027-01-01') RETURNING ma_hoc_ky",
        [year],
      )
    ).rows[0].ma_hoc_ky;
    const cls = (
      await owner.query(
        "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,'Lớp write',10) RETURNING ma_lop",
        [year, teacher.id],
      )
    ).rows[0].ma_lop;
    // 3 students x 2 components = 6 cells
    await owner.query(
      "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh,dang_theo_hoc) SELECT $1,'HS write ' || n,'2010-01-01',true FROM generate_series(1,3) n",
      [cls],
    );
    const subject = (
      await owner.query(
        "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,3) RETURNING ma_mon",
        [`Môn write ${suffix}`],
      )
    ).rows[0].ma_mon;
    await owner.query(
      "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,he_so,thu_tu_hien_thi) VALUES($1,'TX',1.00,1),($1,'CK',2.00,2)",
      [subject],
    );
    await owner.query(
      "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,CURRENT_DATE)",
      [teacher.id, cls, subject, term],
    );
    const scope = { classId: cls, subjectId: subject, termId: term };
    const book = await service.create(teacher, scope);
    assert.equal(book.status, "DANG_NHAP_LIEU");
    assert.equal(book.version, 0);

    // Get all cells
    const { items: cells } = await service.cells(teacher, book.id);
    assert.equal(cells.length, 6);
    assert.ok(cells.every((c) => c.value === null && c.status === "CHUA_CO"));

    let version = 0;
    const body = (
      value: string | null,
      cellId = cells[0]!.id,
      expectedVersion = version,
    ) => ({
      expectedVersion,
      changes: [{ cellId, value, reason: "Điểm giả kiểm thử" }],
    });
    const request = async (
      path: string,
      method = "GET",
      input?: unknown,
      token = teacher.token,
      key = randomBytes(8).toString("hex"),
      headers: Record<string, string> = {},
    ) => {
      const response = await fetch(url + "/api/v1/gradebooks" + path, {
        method,
        headers: {
          "content-type": "application/json",
          authorization: "Bearer " + token,
          "x-idempotency-key": key,
          ...headers,
        },
        ...(input === undefined ? {} : { body: JSON.stringify(input) }),
      });
      return {
        status: response.status,
        data: await response.json(),
        headers: response.headers,
      };
    };
    const batchBody = {
      expectedVersion: 0,
      changes: [
        { cellId: cells[0]!.id, value: "8.5", reason: "Nhập giả" },
        { cellId: cells[1]!.id, value: "0.0", reason: "Nhập giả" },
        { cellId: cells[2]!.id, value: "10.0", reason: "Nhập giả" },
      ],
    };
    const result = await request(
      "/" + book.id + "/grades",
      "PUT",
      batchBody,
      teacher.token,
      "first",
    );
    assert.equal(result.status, 200);
    assert.deepEqual(
      result.data.items.map((c: { value: unknown }) => c.value),
      ["8.5", "0.0", "10.0"],
    );
    assert.equal(result.data.version, ++version);
    assert.deepEqual(
      (
        await request(
          "/" + book.id + "/grades",
          "PUT",
          batchBody,
          teacher.token,
          "first",
        )
      ).data,
      result.data,
    );
    assert.equal(
      (
        await request(
          "/" + book.id + "/grades",
          "PUT",
          body("9.0"),
          teacher.token,
          "first",
        )
      ).status,
      409,
    );
    // Replays authenticate/authorize before lookup, including a user guessing another user's key.
    assert.equal(
      (
        await request(
          "/" + book.id + "/grades",
          "PUT",
          batchBody,
          admin.token,
          "first",
        )
      ).status,
      403,
    );
    assert.equal(
      (
        await request(
          "/" + book.id + "/grades",
          "PUT",
          batchBody,
          student.token,
          "first",
        )
      ).status,
      403,
    );
    assert.equal(
      (
        await request(
          "/" + book.id + "/grades",
          "PUT",
          body("8.0", cells[0]!.id, 0),
        )
      ).status,
      409,
    );
    assert.equal(
      (await request("/" + book.id + "/grades", "PUT", body(null))).status,
      200,
    );
    version++;
    const grid = await service.cells(teacher, book.id);
    assert.equal(grid.items[0]!.value, null);
    assert.equal(grid.items[1]!.value, "0.0");
    const hist = await request(
      "/" + book.id + "/cells/" + cells[0]!.id + "/history",
    );
    assert.equal(hist.status, 200);
    assert.deepEqual(
      hist.data.items.map((h: { newValue: unknown }) => h.newValue),
      ["8.5", null],
    );
    assert.ok(hist.data.items[0].timestamp.endsWith("Z"));

    for (const invalid of [
      "",
      " ",
      "8.55",
      "1e1",
      "0x0",
      "10.1",
      "-0.1",
      "NaN",
      "8",
      "Infinity",
    ]) {
      assert.equal(
        (await request("/" + book.id + "/grades", "PUT", body(invalid))).status,
        400,
        invalid,
      );
    }
    for (const invalid of [
      { changes: [] },
      { ...body("8.0"), extra: true },
      {
        expectedVersion: version,
        changes: [body("8.0").changes[0], body("8.0").changes[0]],
      },
      {
        expectedVersion: version,
        changes: [{ cellId: cells[0]!.id, reason: "Missing value" }],
      },
      { ...body("8.0"), expectedVersion: -1 },
    ]) {
      assert.equal(
        (await request("/" + book.id + "/grades", "PUT", invalid)).status,
        400,
      );
    }
    const noCsrf = await request(
      "/" + book.id + "/grades",
      "PUT",
      body("8.0"),
      teacher.token,
      "csrf",
      {
        cookie: "qld_session=" + teacher.token,
        origin: "http://localhost:8080",
      },
    );
    assert.equal(noCsrf.status, 403);
    const csrfOk = await request(
      "/" + book.id + "/grades",
      "PUT",
      body("8.0"),
      teacher.token,
      "csrf",
      {
        cookie: "qld_session=" + teacher.token,
        origin: "http://localhost:8080",
        "x-csrf-token": teacher.csrf,
      },
    );
    assert.equal(csrfOk.status, 200);
    version++;
    assert.equal((await request("", "GET")).status, 200);
    assert.equal((await request("", "POST", scope)).status, 200);
    assert.equal(
      (await request("/" + book.id + "/cells", "GET", undefined, student.token))
        .status,
      403,
    );
    const intruder = await makeActor("GIAO_VIEN");
    await owner.query(
      "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'GV giả khác')",
      [intruder.id],
    );
    assert.equal(
      (
        await request(
          "/" + book.id + "/grades",
          "PUT",
          body("9.0"),
          intruder.token,
        )
      ).status,
      403,
    );
    assert.equal(
      (
        await request(
          "/" + book.id + "/cells",
          "GET",
          undefined,
          intruder.token,
        )
      ).status,
      403,
    );

    // A second book, also assigned to this teacher: URL scope still must match each cell.
    const subject2 = (
      await owner.query(
        "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,1) RETURNING ma_mon",
        ["W2-" + suffix],
      )
    ).rows[0].ma_mon;
    await owner.query(
      "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,he_so,thu_tu_hien_thi) VALUES($1,'TX',1,1)",
      [subject2],
    );
    await owner.query(
      "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,CURRENT_DATE)",
      [teacher.id, cls, subject2, term],
    );
    const book2 = await service.create(teacher, {
      classId: cls,
      subjectId: subject2,
      termId: term,
    });
    const foreignCell = (await service.cells(teacher, book2.id)).items[0]!.id;
    assert.equal(
      (await request("/" + book.id + "/cells/" + foreignCell + "/history"))
        .status,
      404,
    );
    // Valid first change then invalid cell: all point/history/version/idempotency changes roll back.
    const historyCount = async () =>
      Number(
        (
          await owner.query(
            "SELECT count(*) FROM lich_su_sua_diem h JOIN diem_thanh_phan d USING(ma_diem) WHERE d.ma_bang_diem=$1",
            [book.id],
          )
        ).rows[0].count,
      );
    const beforeCount = await historyCount();
    assert.equal(
      (
        await request(
          "/" + book.id + "/grades",
          "PUT",
          {
            expectedVersion: version,
            changes: [
              { cellId: cells[0]!.id, value: "1.0", reason: "Rollback" },
              { cellId: foreignCell, value: "2.0", reason: "Wrong book" },
            ],
          },
          teacher.token,
          "rollback",
        )
      ).status,
      404,
    );
    assert.equal(await historyCount(), beforeCount);
    assert.equal((await service.cells(teacher, book.id)).book.version, version);
    assert.equal(
      (await service.cells(teacher, book.id)).items[0]!.value,
      "8.0",
    );
    await assert.rejects(
      store.run(async (tx) => {
        await tx.updateGrades(
          teacher.sessionHash,
          book.id,
          version,
          body("1.0").changes,
        );
        throw new Error("after audit");
      }),
      /after audit/,
    );
    assert.equal(await historyCount(), beforeCount);
    // DB function rejects invalid values even when the application validator is bypassed.
    await assert.rejects(
      store.run((tx) =>
        tx.updateGrades(teacher.sessionHash, book.id, version, [
          { cellId: cells[0]!.id, value: "8.55", reason: "Direct port test" },
        ]),
      ),
      (error: { getStatus?: () => number }) => error.getStatus?.() === 409,
    );
    // Force a real audit INSERT failure for this fixture cell only; every point write rolls back.
    const triggerName = "test_history_" + suffix;
    await owner.query(`CREATE FUNCTION public.${triggerName}() RETURNS trigger LANGUAGE plpgsql AS $$
      BEGIN IF NEW.ma_diem=${cells[0]!.id} THEN RAISE EXCEPTION 'TEST_AUDIT_FAILURE' USING ERRCODE='23514'; END IF; RETURN NEW; END $$`);
    try {
      await owner.query(
        `CREATE TRIGGER ${triggerName} BEFORE INSERT ON public.lich_su_sua_diem FOR EACH ROW EXECUTE FUNCTION public.${triggerName}()`,
      );
      assert.equal(
        (
          await request(
            "/" + book.id + "/grades",
            "PUT",
            body("1.0"),
            teacher.token,
            "audit-fail",
          )
        ).status,
        409,
      );
      assert.equal(await historyCount(), beforeCount);
      assert.equal(
        (await service.cells(teacher, book.id)).book.version,
        version,
      );
      assert.equal(
        (await service.cells(teacher, book.id)).items[0]!.value,
        "8.0",
      );
    } finally {
      await owner.query(
        `DROP TRIGGER IF EXISTS ${triggerName} ON public.lich_su_sua_diem`,
      );
      await owner.query(`DROP FUNCTION public.${triggerName}()`);
    }
    assert.equal(
      (
        await request(
          "/" + book.id + "/grades",
          "PUT",
          body("1.0"),
          teacher.token,
          "audit-fail",
        )
      ).status,
      200,
    );
    version++;
    await owner.query(
      "UPDATE diem_thanh_phan SET gia_tri=7.0,trang_thai='CHO_DOI_CHIEU' WHERE ma_diem=$1",
      [foreignCell],
    );
    assert.equal(
      (
        await request(
          "/" + book2.id + "/grades",
          "PUT",
          body("8.0", foreignCell, 0),
        )
      ).status,
      409,
    );
    assert.equal(
      (await request("/" + book2.id + "/lock", "POST", { expectedVersion: 0 }))
        .status,
      409,
    );
    // Mandatory missing grades prevent lock.
    assert.equal(
      (
        await request("/" + book.id + "/lock", "POST", {
          expectedVersion: version,
        })
      ).status,
      409,
    );
    // Add a new student: GET stays read-only; explicit sync adds NULL cells without losing existing rows.
    await owner.query(
      "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,'HS giả mới','2010-01-01')",
      [cls],
    );
    assert.equal((await service.cells(teacher, book.id)).items.length, 6);
    const syncInput = { expectedVersion: version };
    const synced = await request(
      "/" + book.id + "/sync-roster",
      "POST",
      syncInput,
      teacher.token,
      "sync",
    );
    assert.equal(synced.status, 200);
    version++;
    assert.deepEqual(
      (
        await request(
          "/" + book.id + "/sync-roster",
          "POST",
          syncInput,
          teacher.token,
          "sync",
        )
      ).data,
      synced.data,
    );
    assert.equal((await service.cells(teacher, book.id)).items.length, 8);
    const allCells = (await service.cells(teacher, book.id)).items;
    const fill = await request("/" + book.id + "/grades", "PUT", {
      expectedVersion: version,
      changes: allCells.map((c) => ({
        cellId: c.id,
        value: "7.0",
        reason: "Đủ điểm giả",
      })),
    });
    assert.equal(fill.status, 200);
    version++;

    // Real concurrent edits with identical version: exactly one commits.
    const concurrentBody = body("6.0");
    const races = await Promise.all([
      request("/" + book.id + "/grades", "PUT", concurrentBody),
      request("/" + book.id + "/grades", "PUT", body("5.0")),
    ]);
    assert.deepEqual(races.map((r) => r.status).sort(), [200, 409]);
    version++;
    // Identical-key concurrent calls converge without duplicate history; a conflict can be retried.
    const sameBody = body("9.0");
    const same = await Promise.all([
      request(
        "/" + book.id + "/grades",
        "PUT",
        sameBody,
        teacher.token,
        "same",
      ),
      request(
        "/" + book.id + "/grades",
        "PUT",
        sameBody,
        teacher.token,
        "same",
      ),
    ]);
    assert.ok(same.some((r) => r.status === 200));
    assert.ok(same.every((r) => [200, 409].includes(r.status)));
    assert.equal(
      (
        await request(
          "/" + book.id + "/grades",
          "PUT",
          sameBody,
          teacher.token,
          "same",
        )
      ).status,
      200,
    );
    version++;
    // Expired records retain replay protection until retention is explicitly implemented.
    await owner.query(
      "UPDATE khoa_idempotency SET het_han=now()-interval '1 hour' WHERE ma_nguoi_dung=$1 AND khoa='same'",
      [teacher.id],
    );
    assert.equal(
      (
        await request(
          "/" + book.id + "/grades",
          "PUT",
          sameBody,
          teacher.token,
          "same",
        )
      ).data.version,
      version,
    );

    // Edit vs lock shares the same lock/version. The loser cannot overwrite the winner.
    const lockInput = { expectedVersion: version };
    const lockRace = await Promise.all([
      request(
        "/" + book.id + "/lock",
        "POST",
        lockInput,
        teacher.token,
        "lock-race",
      ),
      request("/" + book.id + "/grades", "PUT", body("8.0")),
    ]);
    assert.deepEqual(lockRace.map((r) => r.status).sort(), [200, 409]);
    version++;
    if (lockRace[0]!.status === 409) {
      assert.equal(
        (
          await request(
            "/" + book.id + "/lock",
            "POST",
            { expectedVersion: version },
            teacher.token,
            "lock-final",
          )
        ).status,
        200,
      );
      version++;
    } else {
      assert.equal(
        (
          await request(
            "/" + book.id + "/lock",
            "POST",
            lockInput,
            teacher.token,
            "lock-race",
          )
        ).data.status,
        "DA_CHOT",
      );
    }
    assert.equal(
      (await request("/" + book.id + "/grades", "PUT", body("4.0"))).status,
      409,
    );
    assert.equal(
      (
        await request("/" + book.id + "/sync-roster", "POST", {
          expectedVersion: version,
        })
      ).status,
      409,
    );
    assert.equal(
      (await service.cells(teacher, book.id)).book.status,
      "DA_CHOT",
    );
    // Same cached payload cannot bypass revoked assignment/session.
    await owner.query(
      "DELETE FROM phan_cong_giang_day WHERE ma_lop=$1 AND ma_mon=$2",
      [cls, subject],
    );
    assert.equal(
      (
        await request(
          "/" + book.id + "/grades",
          "PUT",
          sameBody,
          teacher.token,
          "same",
        )
      ).status,
      403,
    );
    await owner.query(
      "UPDATE phien_lam_viec SET hoat_dong_cuoi=now()-interval '31 minutes' WHERE ma_bam=$1",
      [teacher.sessionHash],
    );
    assert.equal(
      (
        await request(
          "/" + book.id + "/grades",
          "PUT",
          sameBody,
          teacher.token,
          "same",
        )
      ).status,
      401,
    );
    assert.ok(
      Number(
        (
          await owner.query(
            "SELECT count(*) FROM nhat_ky_bao_mat WHERE hanh_dong='GRADEBOOK_ACCESS_DENIED' AND ma_tac_nhan=$1",
            [intruder.id],
          )
        ).rows[0].count,
      ) > 0,
    );
  } finally {
    await app.close();
    await owner.end();
  }
});
