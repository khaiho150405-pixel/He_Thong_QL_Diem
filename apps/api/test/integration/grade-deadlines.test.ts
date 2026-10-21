import { test } from "node:test";
import assert from "node:assert/strict";
import { randomBytes, createHash } from "node:crypto";
import { Pool } from "pg";
import { ForbiddenException, ConflictException } from "@nestjs/common";
import { createApp } from "../../src/app.js";
import { FinalResultsService } from "../../src/modules/final-results/application/service.js";
import { GradebooksService } from "../../src/modules/gradebooks/application/service.js";
import { ComponentsService } from "../../src/modules/subjects/application/components.js";
import type {
  Actor,
  Role,
} from "../../src/modules/authorization/application/policy.js";

test("school deadlines enforce windows, atomically zero missing grades, preserve approved values and close once", async () => {
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
  await app.init();
  const service = app.get(GradebooksService);
  await service.processDue();
  const suffix = randomBytes(5).toString("hex");
  const actor = async (role: Role): Promise<Actor> => {
    const username = role + suffix;
    const id = (
      await owner.query(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'fixture',$2) RETURNING ma_nguoi_dung",
        [username, role],
      )
    ).rows[0].ma_nguoi_dung;
    const sessionHash = createHash("sha256").update(username).digest("hex");
    await owner.query(
      "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
      [sessionHash, id, randomBytes(32).toString("hex")],
    );
    return { id, username, role, sessionHash };
  };
  try {
    const admin = await actor("QUAN_TRI_VIEN"),
      teacher = await actor("GIAO_VIEN");
    await owner.query(
      "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'Fixture')",
      [teacher.id],
    );
    const year = (
      await owner.query(
        "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2026-01-01','2027-01-01') RETURNING ma_nam_hoc",
        ["Deadline " + suffix],
      )
    ).rows[0].ma_nam_hoc;
    const term = (
      await owner.query(
        "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'Kỳ',1,'2026-01-01','2027-01-01') RETURNING ma_hoc_ky",
        [year],
      )
    ).rows[0].ma_hoc_ky;
    const cls = (
      await owner.query(
        "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,10) RETURNING ma_lop",
        [year, teacher.id, "L " + suffix],
      )
    ).rows[0].ma_lop;
    const subject = (
      await owner.query(
        "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,2) RETURNING ma_mon",
        ["M " + suffix],
      )
    ).rows[0].ma_mon;
    const componentService = app.get(ComponentsService);
    const components: number[] = [];
    for (const [index, name] of ["TX", "CK"].entries()) {
      const created = await componentService.save(admin, {
        ma_mon: subject,
        ten_thanh_phan: name,
        loai_he_so: name,
        bat_buoc: true,
        thu_tu_hien_thi: index + 1,
      });
      components.push(
        Number((created as Record<string, unknown>).ma_thanh_phan),
      );
    }
    await owner.query(
      "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,CURRENT_DATE)",
      [teacher.id, cls, subject, term],
    );
    const students = (
      await owner.query(
        "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,'Approved','2010-01-01'),($1,'Zero','2010-01-01'),($1,'Missing','2010-01-01'),($1,'Pending','2010-01-01') RETURNING ma_hoc_sinh",
        [cls],
      )
    ).rows.map((r) => r.ma_hoc_sinh);
    const book = await service.create(teacher, {
      classId: cls,
      subjectId: subject,
      termId: term,
    });
    await owner.query(
      "UPDATE diem_thanh_phan SET gia_tri=CASE WHEN ma_hoc_sinh=$2 THEN 9.0 WHEN ma_hoc_sinh=$3 THEN 0.0 WHEN ma_hoc_sinh=$4 THEN 8.0 END,trang_thai=CASE WHEN ma_hoc_sinh=$4 THEN 'CHO_DOI_CHIEU'::\"TrangThaiDiem\" WHEN ma_hoc_sinh IN ($2,$3) THEN 'DA_DUYET'::\"TrangThaiDiem\" ELSE 'CHUA_CO'::\"TrangThaiDiem\" END WHERE ma_bang_diem=$1",
      [book.id, students[0], students[1], students[3]],
    );
    const future = {
      opensAt: new Date(Date.now() + 60000).toISOString(),
      closesAt: new Date(Date.now() + 3600000).toISOString(),
      expectedVersion: 0,
    };
    await assert.rejects(
      service.setDeadline(teacher, book.id, components[0]!, future),
      ForbiddenException,
    );
    await service.setDeadline(admin, book.id, components[0]!, future);
    await assert.rejects(
      service.setDeadline(admin, book.id, components[0]!, future),
      ConflictException,
    );
    assert.throws(
      () =>
        service.lockColumn(teacher, book.id, components[0]!, "manual", {
          expectedVersion: 0,
        }),
      ForbiddenException,
    );
    const cells = (await service.cells(teacher, book.id)).items;
    const approved = cells.find(
      (c) => c.studentId === students[0] && c.componentId === components[0],
    )!;
    assert.equal(approved.openForInput, false);
    await assert.rejects(
      service.batchUpdate(teacher, book.id, "before-open", {
        expectedVersion: 0,
        changes: [{ cellId: approved.id, value: "7.0", reason: "Too early" }],
      }),
      ConflictException,
    );
    // An enrolled student without grid cells must also receive audited zeros.
    await owner.query(
      "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,'New','2010-01-01')",
      [cls],
    );
    await service.setDeadline(admin, book.id, components[1]!, {
      ...future,
      opensAt: new Date(Date.now() - 60000).toISOString(),
    });
    await owner.query(
      "UPDATE lich_nhap_diem SET mo_luc=now()-interval '2 hours',dong_luc=now()-interval '1 hour' WHERE ma_bang_diem=$1",
      [book.id],
    );
    await assert.rejects(
      service.batchUpdate(teacher, book.id, "after-deadline", {
        expectedVersion: 0,
        changes: [{ cellId: approved.id, value: "7.0", reason: "Too late" }],
      }),
      ConflictException,
    );
    // Force audit failure: no partial fill/lock survives.
    const name = "deadline_audit_" + suffix;
    await owner.query(
      `CREATE FUNCTION ${name}() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN IF NEW.ma_diem IN (SELECT ma_diem FROM public.diem_thanh_phan WHERE ma_bang_diem=${book.id}) THEN RAISE EXCEPTION 'AUDIT_FAILURE' USING ERRCODE='23514'; END IF; RETURN NEW; END $$`,
    );
    await owner.query(
      `CREATE TRIGGER ${name} BEFORE INSERT ON lich_su_sua_diem FOR EACH ROW EXECUTE FUNCTION ${name}()`,
    );
    try {
      await assert.rejects(service.processDue(), ConflictException);
      assert.equal((await service.cells(teacher, book.id)).book.version, 0);
    } finally {
      await owner.query(`DROP TRIGGER ${name} ON lich_su_sua_diem`);
      await owner.query(`DROP FUNCTION ${name}()`);
    }
    const outcomes = await Promise.all([
      service.processDue(),
      service.processDue(),
    ]);
    assert.equal(
      outcomes.reduce((a, b) => a + b, 0),
      2,
    );
    assert.equal(await service.processDue(), 0);
    const closed = await service.cells(teacher, book.id);
    assert.equal(closed.book.status, "DA_CHOT");
    assert.equal(closed.items.length, 10);
    assert.ok(
      closed.items.every(
        (c) =>
          c.columnLocked &&
          c.status === "DA_DUYET" &&
          c.value === (c.studentId === students[0] ? "9.0" : "0.0"),
      ),
    );
    const history = (
      await owner.query(
        "SELECT count(*)::int n FROM lich_su_sua_diem h JOIN diem_thanh_phan d USING(ma_diem) WHERE d.ma_bang_diem=$1 AND ly_do LIKE 'Hệ thống tự ghi 0%'",
        [book.id],
      )
    ).rows[0].n;
    assert.equal(history, 6);
    await assert.rejects(
      service.setDeadline(admin, book.id, components[0]!, {
        ...future,
        expectedVersion: 1,
      }),
      ConflictException,
    );
  } finally {
    await app.close();
    await owner.end();
  }
});

// ── Lịch theo học kỳ, cột không bắt buộc và khởi tạo hàng loạt (migration 202610210001) ──

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
  const app = await createApp(
    { environment: "development", origins: [], databaseUrl: runtime },
    { check: async () => true, close: async () => {} },
  );
  await app.listen(0, "127.0.0.1");
  const base = `${await app.getUrl()}/api/v1`;
  const service = app.get(GradebooksService);
  const finalResults = app.get(FinalResultsService);
  const suffix = randomBytes(5).toString("hex");
  const tokens = new Map<number, string>();
  const actor = async (role: Role, tag: string): Promise<Actor> => {
    const username = `${tag}${role}${suffix}`.slice(0, 50);
    const id = (
      await owner.query(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'fixture',$2) RETURNING ma_nguoi_dung",
        [username, role],
      )
    ).rows[0].ma_nguoi_dung;
    const token = randomBytes(32).toString("hex");
    tokens.set(id, token);
    const sessionHash = createHash("sha256").update(token).digest("hex");
    await owner.query(
      "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
      [sessionHash, id, randomBytes(32).toString("hex")],
    );
    return { id, username, role, sessionHash };
  };
  const admin = await actor("QUAN_TRI_VIEN", "a");
  const teacher = await actor("GIAO_VIEN", "t");
  await owner.query(
    "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'Fixture')",
    [teacher.id],
  );
  const one = async (sql: string, params: unknown[]) =>
    (await owner.query(sql, params)).rows[0] as Record<string, number>;
  const year = (
    await one(
      "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2026-01-01','2027-01-01') RETURNING ma_nam_hoc",
      ["SD " + suffix],
    )
  ).ma_nam_hoc!;
  const term = (
    await one(
      "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'Kỳ',1,'2026-01-01','2027-01-01') RETURNING ma_hoc_ky",
      [year],
    )
  ).ma_hoc_ky!;
  const klass = async (name: string, students: number) => {
    const id = (
      await one(
        "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,10) RETURNING ma_lop",
        [year, teacher.id, `${name} ${suffix}`.slice(0, 20)],
      )
    ).ma_lop!;
    for (let i = 1; i <= students; i++)
      await owner.query(
        "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,$2,'2010-01-01')",
        [id, `Học sinh giả ${i}`],
      );
    return id;
  };
  const subject = async (
    name: string,
    comps: Array<[type: string, required: boolean]>,
  ) => {
    const id = (
      await one(
        "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,2) RETURNING ma_mon",
        [`${name} ${suffix}`],
      )
    ).ma_mon!;
    const ids: number[] = [];
    for (const [index, [type, required]] of comps.entries())
      ids.push(
        (
          await one(
            "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,loai_he_so,he_so,bat_buoc,thu_tu_hien_thi) VALUES($1,$2,$3,1,$4,$5) RETURNING ma_thanh_phan",
            [id, `${type}-${index}`, type, required, index + 1],
          )
        ).ma_thanh_phan!,
      );
    return { id, ids };
  };
  const assign = (cls: number, subjectId: number) =>
    owner.query(
      "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,CURRENT_DATE)",
      [teacher.id, cls, subjectId, term],
    );
  const window = (openMinutes: number, closeMinutes: number, version = 0) => ({
    opensAt: new Date(Date.now() + openMinutes * 60000).toISOString(),
    closesAt: new Date(Date.now() + closeMinutes * 60000).toISOString(),
    expectedVersion: version,
  });
  const expire = (type: string) =>
    owner.query(
      "UPDATE lich_nhap_hoc_ky SET mo_luc=now()-interval '2 hours',dong_luc=now()-interval '1 hour' WHERE ma_hoc_ky=$1 AND loai_he_so=$2",
      [term, type],
    );
  const http = async (method: string, path: string, body?: unknown) => {
    const response = await fetch(`${base}${path}`, {
      method,
      headers: {
        authorization: `Bearer ${tokens.get(admin.id)}`,
        "content-type": "application/json",
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    return { status: response.status, body: (await response.json()) as any };
  };
  return {
    owner,
    actor,
    service,
    finalResults,
    http,
    year,
    admin,
    teacher,
    term,
    klass,
    subject,
    assign,
    window,
    expire,
    done: async () => {
      await app.close();
      await owner.end();
    },
  };
}

test("expiry zero-fills only required columns; optional columns stay empty yet are still locked", async () => {
  const f = await fixture();
  try {
    const cls = await f.klass("opt", 2);
    const subject = await f.subject("opt", [
      ["TX", true],
      ["CK", false],
    ]);
    await f.assign(cls, subject.id);
    const book = await f.service.create(f.teacher, {
      classId: cls,
      subjectId: subject.id,
      termId: f.term,
    });
    for (const type of ["TX", "CK"])
      await f.service.setSemesterDeadline(
        f.admin,
        f.term,
        type,
        f.window(-1, 60),
      );
    await f.expire("TX");
    await f.expire("CK");
    assert.ok((await f.service.processDue()) >= 2);
    const cells = (await f.service.cells(f.teacher, book.id)).items;
    assert.equal(cells.length, 4);
    for (const cell of cells) {
      assert.ok(cell.columnLocked);
      if (cell.componentId === subject.ids[0]) {
        assert.equal(cell.value, "0.0");
        assert.equal(cell.status, "DA_DUYET");
      } else {
        assert.equal(cell.value, null);
        assert.equal(cell.status, "CHUA_CO");
      }
    }
    const history = await f.owner.query(
      "SELECT d.ma_thanh_phan FROM lich_su_sua_diem h JOIN diem_thanh_phan d USING(ma_diem) WHERE d.ma_bang_diem=$1",
      [book.id],
    );
    assert.equal(history.rowCount, 2);
    assert.ok(history.rows.every((r) => r.ma_thanh_phan === subject.ids[0]));
    assert.equal(
      (await f.service.cells(f.teacher, book.id)).book.status,
      "DA_CHOT",
    );
  } finally {
    await f.done();
  }
});

test("a semester schedule alone gates entry and locks by coefficient type; a per-book schedule overrides one column", async () => {
  const f = await fixture();
  try {
    const cls = await f.klass("sem", 2);
    const subject = await f.subject("sem", [
      ["TX", true],
      ["GK", true],
      ["CK", true],
    ]);
    await f.assign(cls, subject.id);
    const book = await f.service.create(f.teacher, {
      classId: cls,
      subjectId: subject.id,
      termId: f.term,
    });
    const [tx, gk, ck] = subject.ids as [number, number, number];
    await f.service.setSemesterDeadline(
      f.admin,
      f.term,
      "TX",
      f.window(30, 90),
    );
    await f.service.setSemesterDeadline(
      f.admin,
      f.term,
      "GK",
      f.window(-1, 90),
    );
    let cells = (await f.service.cells(f.teacher, book.id)).items;
    const cellOf = (componentId: number) =>
      cells.find((c) => c.componentId === componentId)!;
    assert.equal(cellOf(tx).openForInput, false);
    assert.equal(cellOf(tx).deadlineSource, "HOC_KY");
    assert.equal(cellOf(gk).openForInput, true);
    assert.equal(cellOf(gk).deadlineSource, "HOC_KY");
    assert.equal(cellOf(gk).deadlineVersion, 0);
    assert.equal(cellOf(ck).openForInput, true);
    assert.equal(cellOf(ck).deadlineSource, null);
    assert.equal(cellOf(ck).opensAt, null);
    await assert.rejects(
      f.service.batchUpdate(f.teacher, book.id, "early", {
        expectedVersion: 0,
        changes: [{ cellId: cellOf(tx).id, value: "7.0", reason: "Too early" }],
      }),
      ConflictException,
    );
    // Lịch riêng cho cột GK ghi đè lịch học kỳ.
    await f.service.setDeadline(f.admin, book.id, gk, f.window(-1, 120));
    cells = (await f.service.cells(f.teacher, book.id)).items;
    assert.equal(cellOf(gk).deadlineSource, "RIENG");
    assert.equal(cellOf(gk).deadlineVersion, 1);
    // Hết hạn lịch học kỳ của TX và GK: chỉ TX bị chốt (GK có lịch riêng còn hạn); CK không có lịch nên vẫn mở.
    await f.expire("TX");
    await f.expire("GK");
    await f.service.processDue();
    cells = (await f.service.cells(f.teacher, book.id)).items;
    assert.ok(cellOf(tx).columnLocked);
    assert.equal(cellOf(tx).value, "0.0");
    assert.ok(!cellOf(gk).columnLocked);
    assert.equal(cellOf(gk).value, null);
    assert.ok(!cellOf(ck).columnLocked);
    assert.equal(
      (await f.service.cells(f.teacher, book.id)).book.status,
      "DANG_NHAP_LIEU",
    );
    // Lịch riêng của GK hết hạn thì cột GK bị chốt; CK không có lịch nên không bao giờ bị chốt.
    await f.owner.query(
      "UPDATE lich_nhap_diem SET mo_luc=now()-interval '2 hours',dong_luc=now()-interval '1 hour' WHERE ma_bang_diem=$1",
      [book.id],
    );
    await f.service.processDue();
    cells = (await f.service.cells(f.teacher, book.id)).items;
    assert.ok(cellOf(gk).columnLocked);
    assert.ok(!cellOf(ck).columnLocked);
  } finally {
    await f.done();
  }
});

test("semester deadline setter: admin only, optimistic version, no editing after expiry, future window", async () => {
  const f = await fixture();
  try {
    await assert.rejects(
      f.service.setSemesterDeadline(f.teacher, f.term, "TX", f.window(0, 60)),
      ForbiddenException,
    );
    const empty = await f.service.semesterDeadlines(f.teacher, f.term);
    assert.deepEqual(
      empty.items.map((i) => [
        i.type,
        i.opensAt,
        i.closesAt,
        i.version,
        i.expired,
      ]),
      [
        ["TX", null, null, 0, false],
        ["GK", null, null, 0, false],
        ["CK", null, null, 0, false],
      ],
    );
    await assert.rejects(
      f.service.setSemesterDeadline(f.admin, f.term, "TX", f.window(0, 60, 3)),
      (e: { code?: string }) => e.code === "DEADLINE_VERSION_CONFLICT",
    );
    assert.throws(
      () =>
        f.service.setSemesterDeadline(f.admin, f.term, "TX", f.window(0, -5)),
      (e: { code?: string }) => e.code === "INVALID_ENTRY_WINDOW",
    );
    const saved = await f.service.setSemesterDeadline(
      f.admin,
      f.term,
      "TX",
      f.window(0, 60),
    );
    assert.equal(saved.version, 1);
    assert.equal(saved.expired, false);
    const updated = await f.service.setSemesterDeadline(
      f.admin,
      f.term,
      "TX",
      f.window(0, 90, 1),
    );
    assert.equal(updated.version, 2);
    await f.expire("TX");
    await assert.rejects(
      f.service.setSemesterDeadline(f.admin, f.term, "TX", f.window(0, 90, 2)),
      (e: { code?: string }) => e.code === "COLUMN_LOCKED",
    );
    assert.equal(
      (await f.service.semesterDeadlines(f.admin, f.term)).items[0]!.expired,
      true,
    );
  } finally {
    await f.done();
  }
});

test("initialize creates missing gradebooks, is safe to repeat and reports skipped pairs", async () => {
  const f = await fixture();
  try {
    const full = await f.klass("full", 2);
    const empty = await f.klass("empty", 0);
    const withComponents = await f.subject("with", [["TX", true]]);
    const bare = await f.subject("bare", []);
    await f.assign(full, withComponents.id);
    await f.assign(empty, withComponents.id);
    await f.assign(full, bare.id);
    await assert.rejects(
      f.service.initializeSemesterGradebooks(f.teacher, f.term, "k-teacher"),
      ForbiddenException,
    );
    const first = await f.service.initializeSemesterGradebooks(
      f.admin,
      f.term,
      "k-1",
    );
    assert.equal(first.created.length, 1);
    assert.equal(first.created[0]!.classId, full);
    assert.equal(first.created[0]!.subjectId, withComponents.id);
    assert.deepEqual(
      first.skipped
        .map((s) => `${s.classId}:${s.subjectId}:${s.reason}`)
        .sort(),
      [
        `${empty}:${withComponents.id}:EMPTY_ROSTER`,
        `${full}:${bare.id}:NO_COMPONENTS`,
      ].sort(),
    );
    const count = async () =>
      Number(
        (
          await f.owner.query(
            "SELECT count(*) FROM bang_diem WHERE ma_hoc_ky=$1",
            [f.term],
          )
        ).rows[0].count,
      );
    assert.equal(await count(), 1);
    // Cùng khóa idempotency: cùng kết quả. Khóa mới: không tạo trùng, chỉ báo lại các cặp bị bỏ qua.
    assert.deepEqual(
      await f.service.initializeSemesterGradebooks(f.admin, f.term, "k-1"),
      first,
    );
    const again = await f.service.initializeSemesterGradebooks(
      f.admin,
      f.term,
      "k-2",
    );
    assert.equal(again.created.length, 0);
    assert.equal(again.skipped.length, 2);
    assert.equal(await count(), 1);
    // Lớp có học sinh sau đó thì lần chạy sau tạo thêm bảng còn thiếu.
    await f.owner.query(
      "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,'Học sinh giả mới','2010-01-01')",
      [empty],
    );
    const third = await f.service.initializeSemesterGradebooks(
      f.admin,
      f.term,
      "k-3",
    );
    assert.equal(third.created.length, 1);
    assert.equal(third.created[0]!.classId, empty);
    assert.equal(await count(), 2);
  } finally {
    await f.done();
  }
});

// ── Ô "Miễn", học sinh vào lớp sau chốt và điều kiện công bố học kỳ (migration 202610210002–4) ──

type Fixture = Awaited<ReturnType<typeof fixture>>;
const codeIs = (code: string) => (e: { code?: string }) => e.code === code;
const uniqueKey = (tag: string) => `${tag}-${randomBytes(4).toString("hex")}`;

async function bookView(f: Fixture, bookId: number) {
  const view = await f.service.cells(f.teacher, bookId);
  return {
    version: view.book.version,
    status: view.book.status,
    items: view.items,
    students: [...new Set(view.items.map((c) => c.studentId))].sort(
      (a, b) => a - b,
    ),
    cell: (studentId: number, componentId: number) =>
      view.items.find(
        (c) => c.studentId === studentId && c.componentId === componentId,
      )!,
  };
}

/** Điền điểm 7.0 cho mọi ô, đặt lịch riêng đã hết hạn cho mọi cột, chốt và tính tổng kết. */
async function finishBook(f: Fixture, bookId: number, componentIds: number[]) {
  await f.owner.query(
    "UPDATE diem_thanh_phan SET gia_tri=7.0,trang_thai='DA_DUYET' WHERE ma_bang_diem=$1 AND trang_thai='CHUA_CO'",
    [bookId],
  );
  for (const componentId of componentIds)
    await f.owner.query(
      "INSERT INTO lich_nhap_diem(ma_bang_diem,ma_thanh_phan,mo_luc,dong_luc,nguoi_dat) VALUES($1,$2,now()-interval '2 hours',now()-interval '1 hour',$3)",
      [bookId, componentId, f.admin.id],
    );
  await f.service.processDue();
  const view = await bookView(f, bookId);
  assert.equal(view.status, "DA_CHOT");
  return f.finalResults.calculate(f.teacher, bookId, uniqueKey("calc"), {
    expectedVersion: view.version,
    reason: "Tính kết quả kiểm thử",
  });
}

test("teacher exempts and un-exempts empty cells; expiry never zero-fills an exempt cell", async () => {
  const f = await fixture();
  try {
    const cls = await f.klass("mien", 2);
    const subject = await f.subject("mien", [
      ["TX", true],
      ["GK", true],
    ]);
    await f.assign(cls, subject.id);
    const book = await f.service.create(f.teacher, {
      classId: cls,
      subjectId: subject.id,
      termId: f.term,
    });
    const [tx, gk] = subject.ids as [number, number];
    for (const type of ["TX", "GK"])
      await f.service.setSemesterDeadline(
        f.admin,
        f.term,
        type,
        f.window(-1, 60),
      );
    let view = await bookView(f, book.id);
    const [s1, s2] = view.students as [number, number];
    const change = (
      cellId: string,
      exempt: boolean,
      reason = "Vào lớp giữa kỳ",
    ) => ({
      cellId,
      exempt,
      reason,
    });
    const send = async (
      actor: Actor,
      changes: ReturnType<typeof change>[],
      key = uniqueKey("ex"),
    ) =>
      f.service.exemptions(actor, book.id, key, {
        expectedVersion: (await bookView(f, book.id)).version,
        changes,
      });

    await assert.rejects(
      send(f.admin, [change(view.cell(s1, tx).id, true)]),
      ForbiddenException,
    );
    const done = await send(f.teacher, [change(view.cell(s1, tx).id, true)]);
    assert.equal(done.items[0]!.status, "MIEN");
    assert.equal(done.items[0]!.value, null);
    assert.equal(done.items[0]!.exemptionReason, "Vào lớp giữa kỳ");
    assert.equal(done.version, view.version + 1);
    assert.equal((await bookView(f, book.id)).version, done.version);

    // Ô đã có điểm không miễn được; ô MIEN không nhận điểm.
    view = await bookView(f, book.id);
    await f.service.batchUpdate(f.teacher, book.id, uniqueKey("grade"), {
      expectedVersion: view.version,
      changes: [{ cellId: view.cell(s2, tx).id, value: "8.0", reason: "Nhập" }],
    });
    await assert.rejects(
      send(f.teacher, [change(view.cell(s2, tx).id, true)]),
      codeIs("CELL_HAS_VALUE"),
    );
    await assert.rejects(
      f.service.batchUpdate(f.teacher, book.id, uniqueKey("grade"), {
        expectedVersion: (await bookView(f, book.id)).version,
        changes: [
          { cellId: view.cell(s1, tx).id, value: "5.0", reason: "Sai" },
        ],
      }),
      codeIs("CELL_EXEMPT"),
    );
    // Bỏ miễn → chưa có điểm; bỏ miễn ô không miễn → CELL_NOT_EXEMPT.
    const undone = await send(f.teacher, [
      change(view.cell(s1, tx).id, false, "Nhầm"),
    ]);
    assert.equal(undone.items[0]!.status, "CHUA_CO");
    assert.equal(undone.items[0]!.exemptionReason, null);
    await assert.rejects(
      send(f.teacher, [change(view.cell(s1, tx).id, false, "Nhầm")]),
      codeIs("CELL_NOT_EXEMPT"),
    );
    // Miễn lại hai ô của học sinh 1; gửi lặp cùng khóa không đổi gì thêm.
    view = await bookView(f, book.id);
    const key = uniqueKey("again");
    const payload = {
      expectedVersion: view.version,
      changes: [
        change(view.cell(s1, tx).id, true),
        change(view.cell(s1, gk).id, true),
      ],
    };
    const first = await f.service.exemptions(f.teacher, book.id, key, payload);
    const replay = await f.service.exemptions(f.teacher, book.id, key, payload);
    assert.equal(replay.version, first.version);
    assert.equal(first.items.length, 2);
    const history = await f.owner.query(
      "SELECT hanh_dong FROM lich_su_mien_diem h JOIN diem_thanh_phan d USING(ma_diem) WHERE d.ma_bang_diem=$1 ORDER BY ma",
      [book.id],
    );
    assert.deepEqual(
      history.rows.map((r) => r.hanh_dong),
      ["MIEN", "BO_MIEN", "MIEN", "MIEN"],
    );

    // Hết hạn cột GK: ô MIEN giữ NULL, ô trống khác bị ghi 0; cột đã chốt thì không đặt miễn được nữa.
    await f.expire("GK");
    await f.service.processDue();
    view = await bookView(f, book.id);
    assert.equal(view.cell(s1, gk).status, "MIEN");
    assert.equal(view.cell(s1, gk).value, null);
    assert.equal(view.cell(s2, gk).value, "0.0");
    assert.equal(view.cell(s1, tx).status, "MIEN");
    await assert.rejects(
      send(f.teacher, [change(view.cell(s2, gk).id, true)]),
      codeIs("COLUMN_NOT_OPEN"),
    );
  } finally {
    await f.done();
  }
});

test("final results leave exempt cells out of numerator, denominator and missing list; fully exempt students are listed apart", async () => {
  const f = await fixture();
  try {
    const cls = await f.klass("calc", 3);
    const subject = await f.subject("calc", [
      ["TX", true],
      ["GK", true],
    ]);
    await f.assign(cls, subject.id);
    const book = await f.service.create(f.teacher, {
      classId: cls,
      subjectId: subject.id,
      termId: f.term,
    });
    const [tx, gk] = subject.ids as [number, number];
    for (const type of ["TX", "GK"])
      await f.service.setSemesterDeadline(
        f.admin,
        f.term,
        type,
        f.window(-1, 60),
      );
    const view = await bookView(f, book.id);
    const [a, b, c] = view.students as [number, number, number];
    const setValue = (student: number, component: number, value: number) =>
      f.owner.query(
        "UPDATE diem_thanh_phan SET gia_tri=$4,trang_thai='DA_DUYET' WHERE ma_bang_diem=$1 AND ma_hoc_sinh=$2 AND ma_thanh_phan=$3",
        [book.id, student, component, value],
      );
    await setValue(a, tx, 8);
    await setValue(c, tx, 6);
    await setValue(c, gk, 7);
    await f.service.exemptions(f.teacher, book.id, uniqueKey("ex"), {
      expectedVersion: view.version,
      changes: [
        { cellId: view.cell(a, gk).id, exempt: true, reason: "Miễn GK" },
        { cellId: view.cell(b, tx).id, exempt: true, reason: "Miễn toàn bộ" },
        { cellId: view.cell(b, gk).id, exempt: true, reason: "Miễn toàn bộ" },
      ],
    });
    await f.expire("TX");
    await f.expire("GK");
    await f.service.processDue();
    const locked = await bookView(f, book.id);
    assert.equal(locked.status, "DA_CHOT");
    const result = await f.finalResults.calculate(
      f.teacher,
      book.id,
      uniqueKey("calc"),
      { expectedVersion: locked.version, reason: "Tính có ô miễn" },
    );
    assert.equal(result.calculatedStudents, 2);
    assert.equal(result.skippedStudents, 0);
    assert.deepEqual(
      result.results.map((r) => [r.studentId, r.finalScore]).sort(),
      [
        [a, "8.0"],
        [c, "6.7"],
      ].sort(),
    );
    assert.equal(result.exemptedStudents, 1);
    assert.deepEqual(
      result.exempted.map((s) => s.studentId),
      [b],
    );
    // Học sinh xem điểm của mình: ô MIEN vẫn được trả về, giá trị null.
    const student = await f.actor("HOC_SINH", "s");
    await f.owner.query(
      "UPDATE hoc_sinh SET ma_nguoi_dung=$1 WHERE ma_hoc_sinh=$2",
      [student.id, a],
    );
    const mine = (await f.finalResults.myResults(student, f.term)).find(
      (r) => r.gradebookId === book.id,
    )!;
    assert.deepEqual(
      mine.components
        .map((item) => [item.componentId, item.value, item.status])
        .sort(),
      [
        [tx, "8.0", "DA_DUYET"],
        [gk, null, "MIEN"],
      ].sort(),
    );
  } finally {
    await f.done();
  }
});

test("late student after every column is locked: publishing is blocked, then fixed by the admin", async () => {
  const f = await fixture();
  try {
    const cls = await f.klass("late", 2);
    const subject = await f.subject("late", [["TX", true]]);
    await f.assign(cls, subject.id);
    const book = await f.service.create(f.teacher, {
      classId: cls,
      subjectId: subject.id,
      termId: f.term,
    });
    const first = await finishBook(f, book.id, subject.ids);
    assert.equal(first.calculatedStudents, 2);
    const lateId = (
      await f.owner.query(
        "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,'Học sinh vào muộn','2010-01-01') RETURNING ma_hoc_sinh",
        [cls],
      )
    ).rows[0].ma_hoc_sinh as number;

    const readiness = await f.service.publishReadiness(f.admin, f.term);
    assert.equal(readiness.ready, false);
    assert.deepEqual(
      readiness.issues.map((i) => [i.code, i.severity, i.studentIds]),
      [["STUDENT_NOT_IN_GRADEBOOK", "BLOCKING", [lateId]]],
    );
    await assert.rejects(
      f.service.publishReadiness(f.teacher, f.term),
      ForbiddenException,
    );
    for (const actor of [f.teacher, f.admin])
      assert.deepEqual(
        (await f.service.missingStudents(actor, book.id)).items.map(
          (s) => s.studentId,
        ),
        [lateId],
      );
    const publish = () =>
      f.http("PUT", `/catalog/semesters/${f.term}`, {
        ma_nam_hoc: f.year,
        ten: "Kỳ",
        thu_tu: 1,
        ngay_bat_dau: "2026-01-01",
        ngay_ket_thuc: "2027-01-01",
        da_cong_bo: true,
      });
    const blocked = await publish();
    assert.equal(blocked.status, 409);
    assert.equal(blocked.body.code, "TERM_RESULTS_INCOMPLETE");
    assert.equal(
      blocked.body.details.issues[0].code,
      "STUDENT_NOT_IN_GRADEBOOK",
    );
    assert.deepEqual(blocked.body.details.issues[0].studentIds, [lateId]);

    const version = (await bookView(f, book.id)).version;
    const reason = "Vào lớp sau khi chốt";
    await assert.rejects(
      f.service.lateStudent(f.teacher, book.id, uniqueKey("late"), {
        studentId: lateId,
        reason,
      }),
      ForbiddenException,
    );
    await assert.rejects(
      f.service.lateStudent(f.admin, book.id, uniqueKey("late"), {
        studentId: 2147483000,
        reason,
      }),
      codeIs("STUDENT_NOT_IN_CLASS"),
    );
    const key = uniqueKey("late");
    const added = await f.service.lateStudent(f.admin, book.id, key, {
      studentId: lateId,
      reason,
    });
    assert.deepEqual(added, {
      bookId: book.id,
      version: version + 1,
      createdCells: 1,
      exemptedCells: 1,
    });
    assert.deepEqual(
      await f.service.lateStudent(f.admin, book.id, key, {
        studentId: lateId,
        reason,
      }),
      added,
    );
    const lateCell = (await bookView(f, book.id)).items.find(
      (c) => c.studentId === lateId,
    )!;
    assert.equal(lateCell.status, "MIEN");
    assert.equal(lateCell.exemptionReason, reason);
    assert.deepEqual(
      (await f.service.missingStudents(f.admin, book.id)).items,
      [],
    );

    const again = await f.finalResults.calculate(
      f.teacher,
      book.id,
      uniqueKey("calc"),
      {
        expectedVersion: added.version,
        reason: "Tính lại sau khi thêm học sinh",
      },
    );
    assert.deepEqual(
      again.exempted.map((s) => s.studentId),
      [lateId],
    );
    assert.equal(again.calculatedStudents, 2);
    assert.equal(
      (await f.service.publishReadiness(f.admin, f.term)).ready,
      true,
    );
    assert.equal((await publish()).status, 200);
    await assert.rejects(
      f.service.lateStudent(f.admin, book.id, uniqueKey("late"), {
        studentId: lateId,
        reason,
      }),
      codeIs("TERM_ALREADY_PUBLISHED"),
    );
  } finally {
    await f.done();
  }
});

test("publication needs every assignment to have a locked gradebook with results", async () => {
  const f = await fixture();
  try {
    const clsA = await f.klass("pubA", 2);
    const clsB = await f.klass("pubB", 2);
    const subjectA = await f.subject("pubA", [["TX", true]]);
    const subjectB = await f.subject("pubB", [["TX", true]]);
    await f.assign(clsA, subjectA.id);
    await f.assign(clsB, subjectB.id);
    const bookA = await f.service.create(f.teacher, {
      classId: clsA,
      subjectId: subjectA.id,
      termId: f.term,
    });
    await finishBook(f, bookA.id, subjectA.ids);
    const publishBody = {
      ma_nam_hoc: f.year,
      ten: "Kỳ",
      thu_tu: 1,
      ngay_bat_dau: "2026-01-01",
      ngay_ket_thuc: "2027-01-01",
      da_cong_bo: true,
    };
    const codes = async () =>
      (await f.service.publishReadiness(f.admin, f.term)).issues.map((i) => [
        i.code,
        i.severity,
        i.classId,
      ]);
    // Phân công của lớp B chưa có bảng điểm: trước đây vẫn công bố được.
    assert.deepEqual(await codes(), [["GRADEBOOK_MISSING", "BLOCKING", clsB]]);
    const missing = await f.http(
      "PUT",
      `/catalog/semesters/${f.term}`,
      publishBody,
    );
    assert.equal(missing.status, 409);
    assert.equal(missing.body.code, "TERM_RESULTS_INCOMPLETE");
    assert.equal(missing.body.details.issues[0].code, "GRADEBOOK_MISSING");
    // Có bảng nhưng chưa chốt.
    const bookB = await f.service.create(f.teacher, {
      classId: clsB,
      subjectId: subjectB.id,
      termId: f.term,
    });
    assert.deepEqual(
      (await f.service.publishReadiness(f.admin, f.term)).issues.map((i) => [
        i.code,
        i.severity,
      ]),
      [
        ["GRADEBOOK_NOT_LOCKED", "BLOCKING"],
        ["COLUMNS_WITHOUT_DEADLINE", "WARNING"],
      ],
    );
    assert.equal(
      (await f.http("PUT", `/catalog/semesters/${f.term}`, publishBody)).status,
      409,
    );
    // Đủ điều kiện.
    await finishBook(f, bookB.id, subjectB.ids);
    assert.deepEqual(await f.service.publishReadiness(f.admin, f.term), {
      ready: true,
      issues: [],
    });
    assert.equal(
      (await f.http("PUT", `/catalog/semesters/${f.term}`, publishBody)).status,
      200,
    );
  } finally {
    await f.done();
  }
});

test("a term without assignments cannot be published", async () => {
  const f = await fixture();
  try {
    assert.deepEqual(await f.service.publishReadiness(f.admin, f.term), {
      ready: false,
      issues: [],
    });
    const response = await f.http("PUT", `/catalog/semesters/${f.term}`, {
      ma_nam_hoc: f.year,
      ten: "Kỳ",
      thu_tu: 1,
      ngay_bat_dau: "2026-01-01",
      ngay_ket_thuc: "2027-01-01",
      da_cong_bo: true,
    });
    assert.equal(response.status, 409);
    assert.match(response.body.message, /chưa có kết quả/);
  } finally {
    await f.done();
  }
});
