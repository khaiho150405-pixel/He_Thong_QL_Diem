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
import { ReportsService } from "../../src/modules/reports/application/service.js";

test("UC14-15 calculates approved grades, snapshots policy and preserves append-only history", async () => {
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
    const initialPolicy = await finalResults.activatePolicy(
      admin,
      `initial-${suffix}`,
      {
        version: `I-${suffix}`,
        name: "Policy nền kiểm thử",
        roundingDigits: 1,
        criteria: [
          { code: "GIOI", minimum: "8.0", passing: true, order: 1 },
          { code: "KHA", minimum: "6.5", passing: true, order: 2 },
          { code: "TRUNG_BINH", minimum: "5.0", passing: true, order: 3 },
          { code: "YEU", minimum: "0.0", passing: false, order: 4 },
        ],
      },
    );
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
    const updated = await gradebooks.batchUpdate(
      teacher,
      book.id,
      "final-grades",
      { expectedVersion: 0, changes },
    );
    const locked = await gradebooks.lock(teacher, book.id, "final-lock", {
      expectedVersion: updated.version,
    });
    assert.equal(locked.status, "DA_CHOT");

    const first = await finalResults.calculate(
      teacher,
      book.id,
      "final-calculate",
      { expectedVersion: locked.version, reason: "Tính kết quả kỳ kiểm thử" },
    );
    assert.equal(first.calculatedStudents, 2);
    assert.equal(first.skippedStudents, 0);
    assert.equal(first.policyVersion, initialPolicy.version);
    assert.match(first.weightVersion, /^W-[0-9a-f]{18}$/);
    assert.deepEqual(
      first.results
        .map((item) => [item.finalScore, item.classification])
        .sort((a, b) => a[0]!.localeCompare(b[0]!)),
      [
        ["4.0", "YEU"],
        ["8.7", "GIOI"],
      ],
    );
    assert.deepEqual(
      await finalResults.calculate(teacher, book.id, "final-calculate", {
        expectedVersion: locked.version,
        reason: "Tính kết quả kỳ kiểm thử",
      }),
      first,
    );
    await assert.rejects(
      finalResults.calculate(teacher, book.id, "final-calculate", {
        expectedVersion: locked.version,
        reason: "Cùng key nhưng body khác",
      }),
      ConflictException,
    );
    await assert.rejects(
      finalResults.calculate(otherTeacher, book.id, "other", {
        expectedVersion: locked.version,
        reason: "Không có phân công",
      }),
      ForbiddenException,
    );
    await assert.rejects(
      finalResults.list(studentActor, book.id),
      ForbiddenException,
    );
    assert.equal((await finalResults.list(admin, book.id)).items.length, 2);

    const summary = await reports.summary(teacher, book.id);
    assert.deepEqual(
      {
        students: summary.students,
        average: summary.average,
        highest: summary.highest,
        lowest: summary.lowest,
        passed: summary.passed,
        failed: summary.failed,
      },
      {
        students: 2,
        average: "6.4",
        highest: "8.7",
        lowest: "4.0",
        passed: 1,
        failed: 1,
      },
    );
    const exported = await reports.export(teacher, book.id);
    assert.equal(exported.filename, `bang-diem-${book.id}.xlsx`);
    assert.equal(exported.bytes.subarray(0, 2).toString("ascii"), "PK");
    assert.equal(
      (
        await owner.query(
          "SELECT count(*)::integer AS n FROM nhat_ky_bao_mat WHERE ma_tac_nhan=$1 AND hanh_dong='GRADEBOOK_EXPORTED' AND doi_tuong=$2",
          [teacher.id, `bang_diem:${book.id}`],
        )
      ).rows[0].n,
      1,
    );

    const policy = await finalResults.activatePolicy(admin, "policy-v2", {
      version: `T-${suffix}`,
      name: "Policy giả kiểm thử",
      roundingDigits: 1,
      criteria: [
        { code: "DAT_CAO", minimum: "7.0", passing: true, order: 1 },
        { code: "DAT", minimum: "5.0", passing: true, order: 2 },
        { code: "CHUA_DAT", minimum: "0.0", passing: false, order: 3 },
      ],
    });
    assert.equal(policy.version, `T-${suffix}`);
    assert.equal(
      (await finalResults.activePolicy(teacher)).version,
      policy.version,
    );
    assert.throws(
      () =>
        finalResults.activatePolicy(teacher, "policy-denied", {
          version: "DENIED",
          name: "Denied",
          roundingDigits: 1,
          criteria: [
            { code: "DAT", minimum: "5.0", passing: true, order: 1 },
            { code: "ROT", minimum: "0.0", passing: false, order: 2 },
          ],
        }),
      ForbiddenException,
    );

    const second = await finalResults.calculate(
      teacher,
      book.id,
      "final-recalculate",
      { expectedVersion: locked.version, reason: "Tính lại để kiểm lịch sử" },
    );
    const history = await finalResults.history(
      teacher,
      book.id,
      second.results[0]!.id,
    );
    assert.equal(history.items.length, 2);
    assert.equal(history.items[0]!.oldScore, null);
    assert.equal(history.items[1]!.oldScore, second.results[0]!.finalScore);
    await assert.rejects(
      runtime.query("UPDATE lich_su_tong_ket SET ly_do='tamper'"),
      /permission denied|APPEND_ONLY/i,
    );
    await assert.rejects(
      owner.query("DELETE FROM lich_su_tong_ket"),
      /APPEND_ONLY/i,
    );
    const snapshot = (
      await owner.query(
        "SELECT bo_he_so FROM ket_qua_tong_ket WHERE ma_ket_qua=$1",
        [second.results[0]!.id],
      )
    ).rows[0].bo_he_so as Record<string, unknown>;
    assert.ok(snapshot.weights);
    assert.ok(snapshot.classificationPolicy);

    const mine = await finalResults.myResults(studentActor, term);
    assert.equal(mine.length, 1);
    assert.equal(mine[0]!.components.length, 2);
    assert.equal(
      mine[0]!.finalScore,
      second.results.find((item) => item.studentId === linkedStudentId)!
        .finalScore,
    );
    assert.throws(() => finalResults.myResults(teacher), ForbiddenException);
    const hiddenCell = cells.find(
      (cell) => cell.studentId === linkedStudentId,
    )!.id;
    await owner.query(
      "UPDATE diem_thanh_phan SET trang_thai='CHO_DOI_CHIEU' WHERE ma_diem=$1",
      [hiddenCell],
    );
    const filtered = await finalResults.myResults(studentActor, term);
    assert.equal(filtered[0]!.components.length, 1);
  } finally {
    await app.close();
    await runtime.end();
    await owner.end();
  }
});
