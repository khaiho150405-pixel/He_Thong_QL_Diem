import { closedFixture } from "./legacy-closed-fixture.js";
import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import { test } from "node:test";
import { ConflictException, ForbiddenException } from "@nestjs/common";
import { Pool } from "pg";
import { createApp } from "../../src/app.js";
import type {
  Actor,
  Role,
} from "../../src/modules/authorization/application/policy.js";
import { FinalResultsService } from "../../src/modules/final-results/application/service.js";
import { GradebooksService } from "../../src/modules/gradebooks/application/service.js";
import { SemesterWeightsService } from "../../src/modules/subjects/application/semester-weights.js";

test("UC14 semester coefficients are isolated, authorized, snapshotted and frozen after locking", async () => {
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
  const app = await createApp(
    { environment: "development", origins: [], databaseUrl: runtimeUrl },
    { check: async () => true, close: async () => {} },
  );
  await app.init();
  const gradebooks = app.get(GradebooksService);
  const finalResults = app.get(FinalResultsService);
  const weights = app.get(SemesterWeightsService);
  const suffix = randomBytes(5).toString("hex");
  const makeActor = async (role: Role): Promise<Actor> => {
    const username = `final_${role}_${randomBytes(4).toString("hex")}`;
    const id = (
      await owner.query(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'test-only-no-login',$2) RETURNING ma_nguoi_dung",
        [username, role],
      )
    ).rows[0].ma_nguoi_dung as number;
    const sessionHash = createHash("sha256")
      .update(randomBytes(32))
      .digest("hex");
    await owner.query(
      "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
      [sessionHash, id, randomBytes(32).toString("hex")],
    );
    return { id, username, role, sessionHash };
  };

  try {
    const teacher = await makeActor("GIAO_VIEN");
    const otherTeacher = await makeActor("GIAO_VIEN");
    const admin = await makeActor("QUAN_TRI_VIEN");
    const studentActor = await makeActor("HOC_SINH");
    await finalResults.activatePolicy(admin, `initial-${suffix}`, {
      version: `I-${suffix}`,
      name: "Policy nền kiểm thử",
      roundingDigits: 1,
      criteria: [
        { code: "GIOI", minimum: "8.0", passing: true, order: 1 },
        { code: "KHA", minimum: "6.5", passing: true, order: 2 },
        { code: "TRUNG_BINH", minimum: "5.0", passing: true, order: 3 },
        { code: "YEU", minimum: "0.0", passing: false, order: 4 },
      ],
    });
    await owner.query(
      "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'GV Final'),($2,'GV Other')",
      [teacher.id, otherTeacher.id],
    );
    const year = (
      await owner.query(
        "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2026-09-01','2027-06-01') RETURNING ma_nam_hoc",
        [`F-${suffix}`],
      )
    ).rows[0].ma_nam_hoc as number;
    const term = (
      await owner.query(
        "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'Kỳ final',1,'2026-09-01','2027-01-01') RETURNING ma_hoc_ky",
        [year],
      )
    ).rows[0].ma_hoc_ky as number;
    const cls = (
      await owner.query(
        "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,10) RETURNING ma_lop",
        [year, teacher.id, `F-${suffix}`],
      )
    ).rows[0].ma_lop as number;
    await owner.query(
      "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh,dang_theo_hoc) VALUES($1,'HS Giỏi','2010-01-01',true),($1,'HS Yếu','2010-01-02',true)",
      [cls],
    );
    const linkedStudentId = (
      await owner.query(
        "UPDATE hoc_sinh SET ma_nguoi_dung=$1 WHERE ma_hoc_sinh=(SELECT min(ma_hoc_sinh) FROM hoc_sinh WHERE ma_lop=$2) RETURNING ma_hoc_sinh",
        [studentActor.id, cls],
      )
    ).rows[0].ma_hoc_sinh as number;
    const subject = (
      await owner.query(
        "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,3) RETURNING ma_mon",
        [`Môn final ${suffix}`],
      )
    ).rows[0].ma_mon as number;
    await owner.query(
      "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,he_so,bat_buoc,thu_tu_hien_thi) VALUES($1,'TX',1.00,true,1),($1,'CK',2.00,true,2)",
      [subject],
    );
    await owner.query(
      "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,CURRENT_DATE)",
      [teacher.id, cls, subject, term],
    );
    const book = await gradebooks.create(teacher, {
      classId: cls,
      subjectId: subject,
      termId: term,
    });
    const cells = (await gradebooks.cells(teacher, book.id)).items;
    const byStudent = new Map<number, typeof cells>();
    for (const cell of cells)
      byStudent.set(cell.studentId, [
        ...(byStudent.get(cell.studentId) ?? []),
        cell,
      ]);
    const rows = [...byStudent.values()];
    const changes = [
      ...rows[0]!.map((cell, index) => ({
        cellId: cell.id,
        value: index === 0 ? "8.0" : "9.0",
        reason: "Fixture Phase 5",
      })),
      ...rows[1]!.map((cell, index) => ({
        cellId: cell.id,
        value: index === 0 ? "0.0" : "6.0",
        reason: "Fixture Phase 5",
      })),
    ];
    const component = cells.find(
      (cell) => cell.componentName === "CK",
    )!.componentId;
    await owner.query(
      "UPDATE thanh_phan_diem SET loai_he_so='CK' WHERE ma_thanh_phan=$1",
      [component],
    );
    const input = { loai_he_so: "CK", ma_hoc_ky: term, he_so: "4.00" };
    await assert.rejects(weights.save(teacher, input), ForbiddenException);
    await assert.rejects(weights.list(studentActor), ForbiddenException);
    const override = await weights.save(admin, input);
    const overrideId = Number((override as Record<string, unknown>).ma_he_so);
    assert.match(override.label, /Kỳ final/);
    assert.match(override.label, new RegExp(suffix));
    assert.equal(
      (await weights.list(teacher, undefined, `F-${suffix}`)).items.length,
      1,
    );
    await assert.rejects(weights.save(admin, input), ConflictException);
    await assert.rejects(weights.save(admin, { ...input, he_so: "0.00" }));
    await assert.rejects(
      runtime.query("UPDATE he_so_hoc_ky_chung SET he_so=0 WHERE ma_he_so=$1", [
        overrideId,
      ]),
      { code: "23514" },
    );
    const term2 = (
      await owner.query(
        "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'Kỳ 2',2,'2027-01-02','2027-06-01') RETURNING ma_hoc_ky",
        [year],
      )
    ).rows[0].ma_hoc_ky as number;
    const effective = async (termId: number) =>
      (
        await runtime.query("SELECT he_so_ap_dung($1,$2)::text AS value", [
          component,
          termId,
        ])
      ).rows[0].value;
    assert.equal(await effective(term), "4.00");
    assert.equal(await effective(term2), "3.00");
    const second = await weights.save(admin, {
      ...input,
      ma_hoc_ky: term2,
      he_so: "3.00",
    });
    assert.equal(await effective(term2), "3.00");
    await weights.remove(
      admin,
      Number((second as Record<string, unknown>).ma_he_so),
    );
    assert.equal(await effective(term2), "3.00");
    assert.equal(
      (await gradebooks.cells(teacher, book.id)).items.find(
        (c) => c.componentId === component,
      )!.coefficient,
      "4.00",
    );
    const updated = await gradebooks.batchUpdate(
      teacher,
      book.id,
      "semester-grades",
      { expectedVersion: 0, changes },
    );
    let locked = { ...book, version: updated.version };
    for (const componentId of new Set(cells.map((c) => c.componentId)))
      locked = await closedFixture(
        owner,
        gradebooks,
        teacher,
        book.id,
        componentId,
        "semester-lock-" + componentId,
        { expectedVersion: locked.version },
      );
    await assert.rejects(
      weights.save(admin, { ...input, he_so: "3.00" }, overrideId),
      ConflictException,
    );
    await assert.rejects(weights.remove(admin, overrideId), ConflictException);
    await assert.rejects(
      runtime.query("UPDATE he_so_hoc_ky_chung SET he_so=3 WHERE ma_he_so=$1", [
        overrideId,
      ]),
      { code: "23514" },
    );
    await assert.rejects(
      runtime.query(
        "INSERT INTO he_so_hoc_ky_chung(loai_he_so,ma_hoc_ky,he_so) VALUES($1,$2,3)",
        ["GK", term],
      ),
      { code: "23514" },
    );
    // A different semester is still editable after this one is locked.
    await weights.save(admin, { ...input, ma_hoc_ky: term2, he_so: "5.00" });
    const result = await finalResults.calculate(
      teacher,
      book.id,
      "semester-calculate",
      { expectedVersion: locked.version, reason: "Kiểm thử hệ số theo học kỳ" },
    );
    assert.deepEqual(result.results.map((r) => r.finalScore).sort(), [
      "4.8",
      "8.8",
    ]);
    const snapshot = (
      await owner.query(
        "SELECT bo_he_so FROM ket_qua_tong_ket WHERE ma_ket_qua=$1",
        [result.results[0]!.id],
      )
    ).rows[0].bo_he_so;
    assert.ok(
      snapshot.weights.some(
        (w: { coefficient: string }) => w.coefficient === "4.00",
      ),
    );
    const mine = await finalResults.myResults(studentActor, term);
    assert.ok(linkedStudentId > 0);
    assert.equal(
      mine[0]!.components.find((c) => c.componentId === component)!.coefficient,
      "4.00",
    );
  } finally {
    await app.close();
    await runtime.end();
    await owner.end();
  }
});
