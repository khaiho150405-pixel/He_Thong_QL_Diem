import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import { test } from "node:test";
import { ForbiddenException } from "@nestjs/common";
import { Pool } from "pg";
import { createApp } from "../../src/app.js";
import { SemestersService } from "../../src/modules/academic-years/application/semesters.js";
import { AdjustmentsService } from "../../src/modules/adjustments/application/service.js";
import type {
  Actor,
  Role,
} from "../../src/modules/authorization/application/policy.js";
import { FinalResultsService } from "../../src/modules/final-results/application/service.js";
import { GradebooksService } from "../../src/modules/gradebooks/application/service.js";

// Điều chỉnh điểm sau chốt (migration 202610220001): dữ liệu giả, chỉ chạy trên DB *_test.

const codeIs = (code: string) => (e: { code?: string }) => e.code === code;
const uniqueKey = (tag: string) => `${tag}-${randomBytes(4).toString("hex")}`;

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
  await app.init();
  const gradebooks = app.get(GradebooksService);
  const adjustments = app.get(AdjustmentsService);
  const finalResults = app.get(FinalResultsService);
  const suffix = randomBytes(5).toString("hex");
  const actor = async (role: Role, tag: string): Promise<Actor> => {
    const username = `${tag}${role}${suffix}`.slice(0, 50);
    const id = (
      await owner.query(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'fixture',$2) RETURNING ma_nguoi_dung",
        [username, role],
      )
    ).rows[0].ma_nguoi_dung;
    const sessionHash = createHash("sha256")
      .update(randomBytes(16))
      .digest("hex");
    await owner.query(
      "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
      [sessionHash, id, randomBytes(32).toString("hex")],
    );
    if (role === "GIAO_VIEN")
      await owner.query(
        "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'Giáo viên giả')",
        [id],
      );
    return { id, username, role, sessionHash };
  };
  const admin = await actor("QUAN_TRI_VIEN", "a");
  const teacher = await actor("GIAO_VIEN", "t");
  const other = await actor("GIAO_VIEN", "o");
  const one = async (sql: string, params: unknown[]) =>
    (await owner.query(sql, params)).rows[0] as Record<string, number>;
  const year = (
    await one(
      "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2026-01-01','2027-01-01') RETURNING ma_nam_hoc",
      ["ADJ " + suffix],
    )
  ).ma_nam_hoc!;
  const term = (
    await one(
      "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'Kỳ',1,'2026-01-01','2027-01-01') RETURNING ma_hoc_ky",
      [year],
    )
  ).ma_hoc_ky!;
  /** Lớp + môn + phân công + bảng điểm cho `teacher`, mọi ô có điểm 6.0 (cột TX) / 7.0 (cột GK). */
  const gradebook = async (
    name: string,
    comps: Array<[type: string, required: boolean]>,
    options: { passFail?: boolean; students?: number } = {},
  ) => {
    const cls = (
      await one(
        "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,10) RETURNING ma_lop",
        [year, teacher.id, `${name} ${suffix}`.slice(0, 20)],
      )
    ).ma_lop!;
    for (let i = 1; i <= (options.students ?? 2); i++)
      await owner.query(
        "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,$2,'2010-01-01')",
        [cls, `Học sinh giả ${i}`],
      );
    const subject = (
      await one(
        "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan,danh_gia_dat) VALUES($1,2,$2) RETURNING ma_mon",
        [`${name} ${suffix}`, options.passFail ?? false],
      )
    ).ma_mon!;
    const components: number[] = [];
    for (const [index, [type, required]] of comps.entries())
      components.push(
        (
          await one(
            "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,loai_he_so,he_so,bat_buoc,thu_tu_hien_thi) VALUES($1,$2,$3,1,$4,$5) RETURNING ma_thanh_phan",
            [subject, `${type}-${index}`, type, required, index + 1],
          )
        ).ma_thanh_phan!,
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
    await owner.query(
      "UPDATE diem_thanh_phan SET gia_tri=$2,trang_thai='DA_DUYET' WHERE ma_bang_diem=$1 AND ma_thanh_phan=$3",
      [book.id, options.passFail ? 10 : 6, components[0]],
    );
    if (components[1] !== undefined)
      await owner.query(
        "UPDATE diem_thanh_phan SET gia_tri=$2,trang_thai='DA_DUYET' WHERE ma_bang_diem=$1 AND ma_thanh_phan=$3",
        [book.id, options.passFail ? 10 : 7, components[1]],
      );
    return { book, cls, subject, components };
  };
  /** Chốt các cột bằng lịch riêng đã hết hạn rồi để hệ thống tự khóa. */
  const lock = async (bookId: number, componentIds: number[]) => {
    for (const componentId of componentIds)
      await owner.query(
        "INSERT INTO lich_nhap_diem(ma_bang_diem,ma_thanh_phan,mo_luc,dong_luc,nguoi_dat) VALUES($1,$2,now()-interval '2 hours',now()-interval '1 hour',$3)",
        [bookId, componentId, admin.id],
      );
    await gradebooks.processDue();
  };
  const view = async (bookId: number) => {
    const page = await gradebooks.cells(teacher, bookId);
    return {
      book: page.book,
      items: page.items,
      students: [...new Set(page.items.map((c) => c.studentId))].sort(
        (a, b) => a - b,
      ),
      cell: (studentId: number, componentId: number) =>
        page.items.find(
          (c) => c.studentId === studentId && c.componentId === componentId,
        )!,
    };
  };
  const submit = async (
    who: Actor,
    bookId: number,
    changes: Array<{
      cellId: string;
      value: string | null;
      exempt: boolean;
      note?: string | null;
    }>,
    reason = "Phúc khảo",
  ) =>
    adjustments.submit(who, bookId, uniqueKey("sub"), {
      expectedVersion: (await view(bookId)).book.version,
      reason,
      changes: changes.map((c) => ({ note: null, ...c })),
    });
  const approve = (id: string, version: number, key = uniqueKey("ok")) =>
    adjustments.approve(admin, id, key, { expectedVersion: version });
  return {
    owner,
    app,
    year,
    term,
    admin,
    teacher,
    other,
    gradebooks,
    adjustments,
    finalResults,
    gradebook,
    lock,
    view,
    submit,
    approve,
    done: async () => {
      await app.close();
      await owner.end();
    },
  };
}
type Fixture = Awaited<ReturnType<typeof fixture>>;

async function finish(f: Fixture, bookId: number) {
  const view = await f.view(bookId);
  assert.equal(view.book.status, "DA_CHOT");
  return f.finalResults.calculate(f.teacher, bookId, uniqueKey("calc"), {
    expectedVersion: view.book.version,
    reason: "Tính kết quả kiểm thử",
  });
}

test("teacher submits adjustments only for locked columns, one pending per gradebook; others are forbidden", async () => {
  const f = await fixture();
  try {
    const { book, components } = await f.gradebook("sub", [
      ["TX", true],
      ["GK", true],
    ]);
    const [tx, gk] = components as [number, number];
    await f.lock(book.id, [tx]);
    const v = await f.view(book.id);
    const [s1, s2] = v.students as [number, number];

    // Ô của cột còn mở, giá trị sai, không đổi gì: lỗi có mã.
    await assert.rejects(
      f.submit(f.teacher, book.id, [
        { cellId: v.cell(s1, gk).id, value: "5.0", exempt: false },
      ]),
      codeIs("CELL_NOT_LOCKED"),
    );
    await assert.rejects(
      f.submit(f.teacher, book.id, [
        { cellId: v.cell(s1, tx).id, value: "11.0", exempt: false },
      ]),
      codeIs("INVALID_GRADE"),
    );
    await assert.rejects(
      f.submit(f.teacher, book.id, [
        { cellId: v.cell(s2, tx).id, value: "6.0", exempt: false },
      ]),
      codeIs("ADJUSTMENT_NO_CHANGE"),
    );
    const pendingBefore = await f.owner.query(
      "SELECT count(*)::int n FROM phieu_dieu_chinh WHERE ma_bang_diem=$1",
      [book.id],
    );
    assert.equal(pendingBefore.rows[0].n, 0);

    const sent = await f.submit(
      f.teacher,
      book.id,
      [
        {
          cellId: v.cell(s1, tx).id,
          value: "8.0",
          exempt: false,
          note: "Chấm lại câu 3",
        },
        { cellId: v.cell(s2, tx).id, value: "6.0", exempt: false },
      ],
      "Phúc khảo bài giữa kỳ",
    );
    assert.equal(sent.status, "CHO_DUYET");
    assert.equal(sent.lineCount, 1); // dòng không đổi bị bỏ
    assert.equal(sent.lines![0]!.oldValue, "6.0");
    assert.equal(sent.lines![0]!.newValue, "8.0");
    assert.equal(sent.lines![0]!.note, "Chấm lại câu 3");
    assert.equal(sent.submittedBy.id, f.teacher.id);
    assert.equal((await f.view(book.id)).book.pendingAdjustmentId, sent.id);

    await assert.rejects(
      f.submit(f.teacher, book.id, [
        { cellId: v.cell(s2, tx).id, value: "9.0", exempt: false },
      ]),
      codeIs("ADJUSTMENT_PENDING_EXISTS"),
    );
    for (const who of [f.other, f.admin])
      await assert.rejects(
        f.submit(who, book.id, [
          { cellId: v.cell(s2, tx).id, value: "9.0", exempt: false },
        ]),
        ForbiddenException,
      );
    await assert.rejects(
      f.adjustments.detail(f.other, sent.id),
      ForbiddenException,
    );

    // Hủy: GV khác không hủy được; GV đã gửi hủy được, rồi gửi lại được.
    await assert.rejects(
      f.adjustments.cancel(f.other, sent.id, uniqueKey("c"), {
        expectedVersion: sent.version,
      }),
      ForbiddenException,
    );
    await assert.rejects(
      f.adjustments.cancel(f.admin, sent.id, uniqueKey("c"), {
        expectedVersion: sent.version,
      }),
      ForbiddenException,
    );
    const cancelled = await f.adjustments.cancel(
      f.teacher,
      sent.id,
      uniqueKey("c"),
      { expectedVersion: sent.version },
    );
    assert.equal(cancelled.status, "DA_HUY");
    assert.equal(cancelled.decidedBy?.id, f.teacher.id);
    assert.equal((await f.view(book.id)).book.pendingAdjustmentId, null);
    await assert.rejects(
      f.adjustments.cancel(f.teacher, sent.id, uniqueKey("c"), {
        expectedVersion: cancelled.version,
      }),
      codeIs("ADJUSTMENT_NOT_PENDING"),
    );
    const again = await f.submit(f.teacher, book.id, [
      { cellId: v.cell(s2, tx).id, value: "9.0", exempt: false },
    ]);
    assert.equal(again.status, "CHO_DUYET");
    assert.deepEqual(
      (await f.adjustments.listForBook(f.teacher, book.id)).items.map((a) => [
        a.id,
        a.status,
      ]),
      [
        [again.id, "CHO_DUYET"],
        [sent.id, "DA_HUY"],
      ],
    );
    const pending = await f.adjustments.list(f.admin, "CHO_DUYET");
    assert.ok(pending.items.some((a) => a.id === again.id));
    await assert.rejects(f.adjustments.list(f.teacher), ForbiddenException);
  } finally {
    await f.done();
  }
});

test("admin approval rewrites the locked cells atomically, audits them and outdates the results until recalculated", async () => {
  const f = await fixture();
  try {
    const { book, components } = await f.gradebook("app", [
      ["TX", true],
      ["GK", true],
    ]);
    const [tx, gk] = components as [number, number];
    await f.lock(book.id, [tx, gk]);
    assert.equal((await finish(f, book.id)).calculatedStudents, 2);
    assert.deepEqual(await f.gradebooks.publishReadiness(f.admin, f.term), {
      ready: true,
      issues: [],
    });
    const v = await f.view(book.id);
    const [s1, s2] = v.students as [number, number];
    const sent = await f.submit(
      f.teacher,
      book.id,
      [
        {
          cellId: v.cell(s1, tx).id,
          value: "8.0",
          exempt: false,
          note: "Phúc khảo",
        },
        { cellId: v.cell(s2, gk).id, value: "9.5", exempt: false },
      ],
      "Chấm lại sau phúc khảo",
    );
    await assert.rejects(
      f.adjustments.approve(f.teacher, sent.id, uniqueKey("ok"), {
        expectedVersion: sent.version,
      }),
      ForbiddenException,
    );
    const key = uniqueKey("ok");
    const approved = await f.adjustments.approve(f.admin, sent.id, key, {
      expectedVersion: sent.version,
    });
    assert.equal(approved.status, "DA_DUYET");
    assert.equal(approved.decidedBy?.id, f.admin.id);
    assert.deepEqual(
      await f.adjustments.approve(f.admin, sent.id, key, {
        expectedVersion: sent.version,
      }),
      approved,
    );
    await assert.rejects(
      f.adjustments.approve(f.admin, sent.id, uniqueKey("ok"), {
        expectedVersion: approved.version,
      }),
      codeIs("ADJUSTMENT_NOT_PENDING"),
    );
    const after = await f.view(book.id);
    assert.equal(after.cell(s1, tx).value, "8.0");
    assert.equal(after.cell(s2, gk).value, "9.5");
    assert.equal(after.cell(s2, tx).value, "6.0");
    assert.equal(after.book.version, v.book.version + 1);
    assert.equal(after.book.resultsOutdated, true);
    assert.equal(after.book.pendingAdjustmentId, null);
    const history = await f.owner.query(
      "SELECT nguoi_sua,gia_tri_cu::text cu,gia_tri_moi::text moi,ly_do FROM lich_su_sua_diem WHERE ma_diem=$1",
      [after.cell(s1, tx).id],
    );
    assert.equal(history.rowCount, 1);
    assert.equal(history.rows[0].nguoi_sua, f.teacher.id);
    assert.equal(history.rows[0].cu, "6.0");
    assert.equal(history.rows[0].moi, "8.0");
    assert.equal(
      history.rows[0].ly_do,
      `Điều chỉnh sau chốt #${sent.id}: Chấm lại sau phúc khảo; Phúc khảo — duyệt bởi ${f.admin.username}`,
    );

    // Công bố bị chặn đến khi tính lại tổng kết.
    const outdated = await f.gradebooks.publishReadiness(f.admin, f.term);
    assert.equal(outdated.ready, false);
    assert.deepEqual(
      outdated.issues.map((i) => [i.code, i.severity]),
      [["RESULTS_OUTDATED", "BLOCKING"]],
    );
    const recalculated = await f.finalResults.calculate(
      f.teacher,
      book.id,
      uniqueKey("calc"),
      {
        expectedVersion: after.book.version,
        reason: "Tính lại sau điều chỉnh",
      },
    );
    assert.deepEqual(recalculated.results.map((r) => r.finalScore).sort(), [
      "7.3",
      "8.3",
    ]);
    assert.equal((await f.view(book.id)).book.resultsOutdated, false);
    assert.equal(
      (await f.gradebooks.publishReadiness(f.admin, f.term)).ready,
      true,
    );
  } finally {
    await f.done();
  }
});

test("a cell changed between submission and approval makes the whole approval fail without writing anything", async () => {
  const f = await fixture();
  try {
    const { book, components } = await f.gradebook("stale", [["TX", true]]);
    const [tx] = components as [number];
    await f.lock(book.id, [tx]);
    const v = await f.view(book.id);
    const [s1, s2] = v.students as [number, number];
    const sent = await f.submit(f.teacher, book.id, [
      { cellId: v.cell(s1, tx).id, value: "8.0", exempt: false },
      { cellId: v.cell(s2, tx).id, value: "9.0", exempt: false },
    ]);
    // Đổi ô thứ hai ngoài luồng thường (chủ DB tắt trigger tạm thời) để mô phỏng thay đổi giữa lúc gửi và duyệt.
    await f.owner.query(
      "ALTER TABLE diem_thanh_phan DISABLE TRIGGER grade_column_policy",
    );
    try {
      await f.owner.query(
        "UPDATE diem_thanh_phan SET gia_tri=3.0 WHERE ma_diem=$1",
        [v.cell(s2, tx).id],
      );
    } finally {
      await f.owner.query(
        "ALTER TABLE diem_thanh_phan ENABLE TRIGGER grade_column_policy",
      );
    }
    const versionBefore = (await f.view(book.id)).book.version;
    await assert.rejects(
      f.approve(sent.id, sent.version),
      codeIs("ADJUSTMENT_STALE"),
    );
    const after = await f.view(book.id);
    assert.equal(after.cell(s1, tx).value, "6.0"); // dòng đầu không bị ghi
    assert.equal(after.cell(s2, tx).value, "3.0");
    assert.equal(after.book.version, versionBefore);
    assert.equal(after.book.resultsOutdated, false);
    const history = await f.owner.query(
      "SELECT count(*)::int n FROM lich_su_sua_diem WHERE ma_diem=$1",
      [v.cell(s1, tx).id],
    );
    assert.equal(history.rows[0].n, 0);
    assert.equal(
      (await f.adjustments.detail(f.admin, sent.id)).status,
      "CHO_DUYET",
    );

    // Từ chối: lý do bắt buộc, chỉ QTV; sau đó GV không hủy được nữa.
    await assert.rejects(
      f.adjustments.reject(f.teacher, sent.id, uniqueKey("r"), {
        expectedVersion: sent.version,
        reason: "Không",
      }),
      ForbiddenException,
    );
    assert.throws(() =>
      f.adjustments.reject(f.admin, sent.id, uniqueKey("r"), {
        expectedVersion: sent.version,
        reason: "  ",
      }),
    );
    const rejected = await f.adjustments.reject(
      f.admin,
      sent.id,
      uniqueKey("r"),
      {
        expectedVersion: sent.version,
        reason: "Ô đã thay đổi; gửi lại phiếu mới",
      },
    );
    assert.equal(rejected.status, "TU_CHOI");
    assert.equal(rejected.decisionReason, "Ô đã thay đổi; gửi lại phiếu mới");
    await assert.rejects(
      f.adjustments.cancel(f.teacher, sent.id, uniqueKey("c"), {
        expectedVersion: rejected.version,
      }),
      codeIs("ADJUSTMENT_NOT_PENDING"),
    );
  } finally {
    await f.done();
  }
});

test("adjustments can exempt and un-exempt cells; pass/fail subjects only take 0.0 or 10.0", async () => {
  const f = await fixture();
  try {
    const { book, components } = await f.gradebook("mien", [["TX", true]]);
    const [tx] = components as [number];
    await f.lock(book.id, [tx]);
    const v = await f.view(book.id);
    const [s1] = v.students as [number];
    const toExempt = await f.submit(f.teacher, book.id, [
      { cellId: v.cell(s1, tx).id, value: null, exempt: true },
    ]);
    assert.equal(toExempt.lines![0]!.newExempt, true);
    await f.approve(toExempt.id, toExempt.version);
    let cell = (await f.view(book.id)).cell(s1, tx);
    assert.equal(cell.status, "MIEN");
    assert.equal(cell.value, null);
    assert.match(cell.exemptionReason ?? "", /Điều chỉnh sau chốt/);
    const unExempt = await f.submit(f.teacher, book.id, [
      { cellId: cell.id, value: "5.0", exempt: false },
    ]);
    assert.equal(unExempt.lines![0]!.oldStatus, "MIEN");
    await f.approve(unExempt.id, unExempt.version);
    cell = (await f.view(book.id)).cell(s1, tx);
    assert.equal(cell.status, "DA_DUYET");
    assert.equal(cell.value, "5.0");
    const marks = await f.owner.query(
      "SELECT hanh_dong FROM lich_su_mien_diem WHERE ma_diem=$1 ORDER BY ma",
      [cell.id],
    );
    assert.deepEqual(
      marks.rows.map((r) => r.hanh_dong),
      ["MIEN", "BO_MIEN"],
    );

    const pf = await f.gradebook("pf", [["TX", true]], { passFail: true });
    await f.lock(pf.book.id, pf.components);
    const pv = await f.view(pf.book.id);
    const student = pv.students[0]!;
    await assert.rejects(
      f.submit(f.teacher, pf.book.id, [
        {
          cellId: pv.cell(student, pf.components[0]!).id,
          value: "7.0",
          exempt: false,
        },
      ]),
      codeIs("PASS_FAIL_VALUE_REQUIRED"),
    );
    const ok = await f.submit(f.teacher, pf.book.id, [
      {
        cellId: pv.cell(student, pf.components[0]!).id,
        value: "0.0",
        exempt: false,
      },
    ]);
    await f.approve(ok.id, ok.version);
    assert.equal(
      (await f.view(pf.book.id)).cell(student, pf.components[0]!).value,
      "0.0",
    );
  } finally {
    await f.done();
  }
});

test("a published term accepts no new adjustment and approves none", async () => {
  const f = await fixture();
  try {
    const { book, components } = await f.gradebook("pub", [["TX", true]]);
    await f.lock(book.id, components);
    await finish(f, book.id);
    const v = await f.view(book.id);
    const [s1, s2] = v.students as [number, number];
    const waiting = await f.submit(f.teacher, book.id, [
      { cellId: v.cell(s1, components[0]!).id, value: "8.0", exempt: false },
    ]);
    // Phiếu còn chờ nên công bố thường bị chặn (ADJUSTMENT_PENDING); tắt trigger để dựng đúng tình huống đã công bố.
    await f.owner.query("ALTER TABLE hoc_ky DISABLE TRIGGER term_publication");
    try {
      await f.owner.query(
        "UPDATE hoc_ky SET da_cong_bo=true WHERE ma_hoc_ky=$1",
        [f.term],
      );
    } finally {
      await f.owner.query("ALTER TABLE hoc_ky ENABLE TRIGGER term_publication");
    }
    await assert.rejects(
      f.submit(f.teacher, book.id, [
        { cellId: v.cell(s2, components[0]!).id, value: "9.0", exempt: false },
      ]),
      codeIs("TERM_ALREADY_PUBLISHED"),
    );
    await assert.rejects(
      f.approve(waiting.id, waiting.version),
      codeIs("TERM_ALREADY_PUBLISHED"),
    );
    assert.equal((await f.view(book.id)).cell(s1, components[0]!).value, "6.0");
  } finally {
    await f.done();
  }
});

test("the runtime role cannot write locked cells directly, with or without the transaction flag", async () => {
  const f = await fixture();
  const runtime = new Pool({ connectionString: process.env.TEST_RUNTIME_URL });
  try {
    const { book, components } = await f.gradebook("rt", [["TX", true]]);
    const [tx] = components as [number];
    // Cột chốt kiểu cũ (không có lịch) để cap_nhat_diem không bị chặn bởi khung giờ.
    await f.owner.query(
      "INSERT INTO chot_cot_diem(ma_bang_diem,ma_thanh_phan,nguoi_chot) VALUES($1,$2,$3)",
      [book.id, tx, f.admin.id],
    );
    const v = await f.view(book.id);
    const [s1, s2] = v.students as [number, number];
    const sent = await f.submit(f.teacher, book.id, [
      { cellId: v.cell(s1, tx).id, value: "8.0", exempt: false },
    ]);
    const denied = (e: { code?: string }) => e.code === "42501";
    await assert.rejects(
      runtime.query("UPDATE diem_thanh_phan SET gia_tri=9.0 WHERE ma_diem=$1", [
        v.cell(s1, tx).id,
      ]),
      denied,
    );
    const client = await runtime.connect();
    try {
      await client.query("BEGIN ISOLATION LEVEL SERIALIZABLE");
      await client.query(
        "SELECT set_config('qld.dieu_chinh_sau_chot',$1,true)",
        [sent.id],
      );
      await assert.rejects(
        client.query(
          "UPDATE diem_thanh_phan SET gia_tri=8.0 WHERE ma_diem=$1",
          [v.cell(s1, tx).id],
        ),
        denied,
      );
      await client.query("ROLLBACK");
      // Cờ giả không cho ghi giá trị khác phiếu, hay ô không có trong phiếu, qua hàm nhập điểm.
      for (const [cell, value] of [
        [v.cell(s1, tx).id, "9.0"],
        [v.cell(s2, tx).id, "8.0"],
        // Đúng ô và đúng giá trị của phiếu chờ: trigger sẽ cho qua, nhưng cap_nhat_diem tự chặn cột đã chốt.
        [v.cell(s1, tx).id, "8.0"],
      ] as const) {
        await client.query("BEGIN ISOLATION LEVEL SERIALIZABLE");
        await client.query(
          "SELECT set_config('qld.dieu_chinh_sau_chot',$1,true)",
          [sent.id],
        );
        await assert.rejects(
          client.query("SELECT public.cap_nhat_diem($1,$2,$3,$4::jsonb)", [
            f.teacher.sessionHash,
            book.id,
            v.book.version,
            JSON.stringify([{ cellId: cell, value, reason: "Thử" }]),
          ]),
          (e: { code?: string; message?: string }) =>
            e.code === "23514" && /COLUMN_LOCKED/.test(e.message ?? ""),
        );
        await client.query("ROLLBACK");
      }
    } finally {
      client.release();
    }
    const cells = await f.view(book.id);
    assert.equal(cells.cell(s1, tx).value, "6.0");
    assert.equal(cells.cell(s2, tx).value, "6.0");
  } finally {
    await runtime.end();
    await f.done();
  }
});

test("a pending adjustment blocks publication until it is approved or cancelled", async () => {
  const f = await fixture();
  try {
    const { book, components } = await f.gradebook("pend", [["TX", true]]);
    const [tx] = components as [number];
    await f.lock(book.id, components);
    await finish(f, book.id);
    const v = await f.view(book.id);
    const [s1, s2] = v.students as [number, number];
    const termInput = {
      ma_nam_hoc: f.year,
      ten: "Kỳ",
      thu_tu: 1,
      ngay_bat_dau: "2026-01-01",
      ngay_ket_thuc: "2027-01-01",
      da_cong_bo: true,
    };
    const semesters = f.app.get(SemestersService);
    const issues = async () =>
      (await f.gradebooks.publishReadiness(f.admin, f.term)).issues.map((i) => [
        i.code,
        i.severity,
        i.gradebookId,
        i.count,
      ]);
    assert.deepEqual(await issues(), []);

    const sent = await f.submit(f.teacher, book.id, [
      { cellId: v.cell(s1, tx).id, value: "8.0", exempt: false },
    ]);
    assert.deepEqual(await issues(), [
      ["ADJUSTMENT_PENDING", "BLOCKING", book.id, 1],
    ]);
    const blocked = await semesters.save(f.admin, termInput, f.term).then(
      () => null,
      (e: { code?: string; details?: { issues: Array<{ code: string }> } }) =>
        e,
    );
    assert.equal(blocked?.code, "TERM_RESULTS_INCOMPLETE");
    assert.deepEqual(
      blocked?.details?.issues.map((i) => i.code),
      ["ADJUSTMENT_PENDING"],
    );

    // Hủy phiếu: hết vấn đề.
    await f.adjustments.cancel(f.teacher, sent.id, uniqueKey("c"), {
      expectedVersion: sent.version,
    });
    assert.deepEqual(await issues(), []);

    // Duyệt phiếu: chỉ còn kết quả lỗi thời (không còn phiếu chờ); tính lại thì công bố được.
    const second = await f.submit(f.teacher, book.id, [
      { cellId: v.cell(s2, tx).id, value: "9.0", exempt: false },
    ]);
    assert.equal((await issues())[0]![0], "ADJUSTMENT_PENDING");
    await f.approve(second.id, second.version);
    assert.deepEqual(
      (await issues()).map((i) => i[0]),
      ["RESULTS_OUTDATED"],
    );
    await f.finalResults.calculate(f.teacher, book.id, uniqueKey("calc"), {
      expectedVersion: (await f.view(book.id)).book.version,
      reason: "Tính lại sau điều chỉnh",
    });
    assert.deepEqual(await issues(), []);
    await semesters.save(f.admin, termInput, f.term);
  } finally {
    await f.done();
  }
});
