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
import { IdentityService } from "../../src/modules/identity/application/service.js";
import { SemestersService } from "../../src/modules/academic-years/application/semesters.js";
import { ReportsService } from "../../src/modules/reports/application/service.js";
import { SemesterWeightsService } from "../../src/modules/subjects/application/semester-weights.js";

test("school workflow: column locks, publication, global coefficients, pass/fail and identity restrictions", async () => {
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
  const identity = app.get(IdentityService);
  const semesters = app.get(SemestersService);
  const reports = app.get(ReportsService);
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
    assert.ok(linkedStudentId > 0);
    const subject = (
      await owner.query(
        "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,3) RETURNING ma_mon",
        [`Môn final ${suffix}`],
      )
    ).rows[0].ma_mon as number;
    await owner.query(
      "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,he_so,bat_buoc,thu_tu_hien_thi) VALUES($1,'TX',1.00,true,1),($1,'CK',3.00,true,2)",
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
      ...rows[0]!.map((cell) => ({
        cellId: cell.id,
        value: cell.componentName === "TX" ? "8.0" : "9.0",
        reason: "Fixture Phase 5",
      })),
      ...rows[1]!.map((cell) => ({
        cellId: cell.id,
        value: cell.componentName === "TX" ? "0.0" : "6.0",
        reason: "Fixture Phase 5",
      })),
    ];

    await owner.query(
      "UPDATE thanh_phan_diem SET loai_he_so='CK' WHERE ma_mon=$1 AND ten_thanh_phan='CK'",
      [subject],
    );
    const component = cells.find((c) => c.componentName === "CK")!.componentId;
    const txComponent = cells.find(
      (c) => c.componentName === "TX",
    )!.componentId;
    const input = { loai_he_so: "CK", ma_hoc_ky: term, he_so: "4.00" };
    await assert.rejects(weights.save(teacher, input), ForbiddenException);
    const override = await weights.save(admin, input);
    await weights.save(admin, {
      loai_he_so: "TX",
      ma_hoc_ky: term,
      he_so: "2.00",
    });
    await assert.rejects(
      identity.profile(teacher, {
        name: "Tự đổi tên",
        email: null,
        phone: null,
      }),
      ForbiddenException,
    );
    await assert.rejects(
      identity.profile(studentActor, { name: "Tự đổi tên" }),
      ForbiddenException,
    );
    await assert.rejects(
      identity.changePassword(
        studentActor,
        "anything",
        "Not-a-real-password-2026",
      ),
      ForbiddenException,
    );
    await assert.rejects(
      identity.createAccount(admin, {
        username: "teacher_name",
        password: "Test-account-2026!",
        role: "GIAO_VIEN",
      }),
    );
    assert.throws(() => reports.adminOverview(teacher), ForbiddenException);
    assert.throws(
      () => gradebooks.lock(teacher, book.id, "legacy", { expectedVersion: 0 }),
      ForbiddenException,
    );
    await assert.rejects(
      closedFixture(
        owner,
        gradebooks,
        teacher,
        book.id,
        txComponent,
        "incomplete",
        {
          expectedVersion: 0,
        },
      ),
      ConflictException,
    );
    const updated = await gradebooks.batchUpdate(teacher, book.id, "grades", {
      expectedVersion: 0,
      changes,
    });
    const firstLock = await closedFixture(
      owner,
      gradebooks,
      teacher,
      book.id,
      txComponent,
      "lock-tx",
      { expectedVersion: updated.version },
    );
    assert.equal(firstLock.status, "DANG_NHAP_LIEU");
    assert.deepEqual(
      await closedFixture(
        owner,
        gradebooks,
        teacher,
        book.id,
        txComponent,
        "lock-tx",
        {
          expectedVersion: updated.version,
        },
      ),
      firstLock,
    );
    await assert.rejects(
      closedFixture(
        owner,
        gradebooks,
        otherTeacher,
        book.id,
        component,
        "foreign",
        {
          expectedVersion: firstLock.version,
        },
      ),
      ForbiddenException,
    );
    await assert.rejects(
      gradebooks.batchUpdate(teacher, book.id, "closed-write", {
        expectedVersion: firstLock.version,
        changes: [
          {
            cellId: cells.find((c) => c.componentId === txComponent)!.id,
            value: "1.0",
            reason: "Forbidden",
          },
        ],
      }),
      ConflictException,
    );
    const minePartial = await finalResults.myResults(studentActor, term);
    assert.equal(minePartial[0]!.components.length, 1);
    const otherCell = cells.find((c) => c.componentId === component)!;
    const stillEditable = await gradebooks.batchUpdate(
      teacher,
      book.id,
      "open-write",
      {
        expectedVersion: firstLock.version,
        changes: [
          {
            cellId: otherCell.id,
            value:
              otherCell.studentId === rows[0]![0]!.studentId ? "9.0" : "6.0",
            reason: "Other column stays editable",
          },
        ],
      },
    );
    await assert.rejects(
      weights.save(
        admin,
        { ...input, he_so: "3.00" },
        Number((override as Record<string, unknown>).ma_he_so),
      ),
      ConflictException,
    );
    const locked = await closedFixture(
      owner,
      gradebooks,
      teacher,
      book.id,
      component,
      "lock-ck",
      { expectedVersion: stillEditable.version },
    );
    assert.equal(locked.status, "DA_CHOT");
    const result = await finalResults.calculate(teacher, book.id, "calculate", {
      expectedVersion: locked.version,
      reason: "Test school results",
    });
    assert.ok(result.results.every((r) => r.classification === "CHUA_CONG_BO"));
    assert.ok(
      (await finalResults.myResults(studentActor, term)).every(
        (r) => r.classification === null,
      ),
    );
    assert.equal(
      (await finalResults.myOverview(studentActor, term)).summary.classRank,
      null,
    );
    assert.deepEqual(
      (await reports.summary(teacher, book.id)).distribution,
      [],
    );
    const termInput = {
      ma_nam_hoc: year,
      ten: "Kỳ final",
      thu_tu: 1,
      ngay_bat_dau: "2026-09-01",
      ngay_ket_thuc: "2027-01-01",
      da_cong_bo: true,
    };
    // Pass/fail grades use identical semester-wide coefficients, never numeric partial values.
    const passSubject = (
      await owner.query(
        "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan,danh_gia_dat) VALUES($1,2,true) RETURNING ma_mon",
        ["PF-" + suffix],
      )
    ).rows[0].ma_mon;
    await owner.query(
      "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,he_so,bat_buoc,thu_tu_hien_thi,loai_he_so) VALUES($1,'TX',1,true,1,'TX'),($1,'GK',2,true,2,'GK'),($1,'CK',3,true,3,'CK')",
      [passSubject],
    );
    await owner.query(
      "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,CURRENT_DATE)",
      [teacher.id, cls, passSubject, term],
    );
    const pf = await gradebooks.create(teacher, {
      classId: cls,
      subjectId: passSubject,
      termId: term,
    });
    const pfCells = (await gradebooks.cells(teacher, pf.id)).items;
    assert.equal(
      pfCells.find((c) => c.componentName === "CK")!.coefficient,
      "4.00",
    );
    await assert.rejects(
      gradebooks.batchUpdate(teacher, pf.id, "invalid-pf", {
        expectedVersion: 0,
        changes: [{ cellId: pfCells[0]!.id, value: "8.0", reason: "Invalid" }],
      }),
      ConflictException,
    );
    await assert.rejects(
      semesters.save(admin, termInput, term),
      ConflictException,
    );
    let pfBook = pf;
    const pfWrite = await gradebooks.batchUpdate(teacher, pf.id, "pf-grades", {
      expectedVersion: 0,
      changes: pfCells.map((c) => ({
        cellId: c.id,
        value:
          c.componentName === "CK" ||
          (c.studentId === linkedStudentId && c.componentName === "GK")
            ? "10.0"
            : "0.0",
        reason: "Pass/fail fixture",
      })),
    });
    pfBook = { ...pf, version: pfWrite.version };
    for (const componentId of new Set(pfCells.map((c) => c.componentId)))
      pfBook = await closedFixture(
        owner,
        gradebooks,
        teacher,
        pf.id,
        componentId,
        "pf-lock-" + componentId,
        { expectedVersion: pfBook.version },
      );
    const pfResult = await finalResults.calculate(
      teacher,
      pf.id,
      "pf-calculate",
      { expectedVersion: pfBook.version, reason: "Weighted pass/fail" },
    );
    assert.ok(pfResult.results.every((r) => r.finalScore === "10.0"));
    // The second student passes only CK: 4/(2+2+4) is exactly 50%.
    await semesters.save(admin, termInput, term);
    const pfSummary = await reports.summary(teacher, pf.id);
    assert.equal(pfSummary.average, null);
    assert.equal(pfSummary.passed, 2);
    const mine = await finalResults.myResults(studentActor, term);
    assert.ok(mine.every((r) => r.classification !== null));
    assert.equal(mine.find((r) => r.passFail)!.classification, "DAT");
    const summary = (await finalResults.myOverview(studentActor, term)).summary;
    const numericScore = mine.find((r) => !r.passFail)!.finalScore;
    assert.equal(Number(summary.averageScore), Number(numericScore));
    await assert.rejects(
      finalResults.calculate(teacher, book.id, "after-publish", {
        expectedVersion: locked.version,
        reason: "Forbidden recalculate",
      }),
      ConflictException,
    );
    assert.ok(
      (
        await owner.query(
          "SELECT count(*)::int AS count FROM nhat_ky_bao_mat WHERE ma_tac_nhan=$1 AND hanh_dong='GRADE_COLUMN_LOCKED'",
          [teacher.id],
        )
      ).rows[0].count >= 5,
    );
  } finally {
    await app.close();
    await runtime.end();
    await owner.end();
  }
});
