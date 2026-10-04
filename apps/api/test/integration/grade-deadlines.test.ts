import { test } from "node:test";
import assert from "node:assert/strict";
import { randomBytes, createHash } from "node:crypto";
import { Pool } from "pg";
import { ForbiddenException, ConflictException } from "@nestjs/common";
import { createApp } from "../../src/app.js";
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
