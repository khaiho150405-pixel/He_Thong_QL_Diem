import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import { test } from "node:test";
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
} from "@nestjs/common";
import { Pool } from "pg";
import { createApp } from "../../src/app.js";
import type {
  Actor,
  Role,
} from "../../src/modules/authorization/application/policy.js";
import { FinalResultsService } from "../../src/modules/final-results/application/service.js";
import { GradebooksService } from "../../src/modules/gradebooks/application/service.js";
import { EnrollmentsService } from "../../src/modules/enrollments/application/service.js";
import { ReportsService } from "../../src/modules/reports/application/service.js";

// Ghi danh há»c sinh theo lá»›p/nÄƒm há»c (migration 202610230001). Dá»¯ liá»‡u giáº£, chá»‰ cháº¡y trÃªn DB *_test.

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
  const runtimePool = new Pool({ connectionString: runtime });
  const app = await createApp(
    { environment: "development", origins: [], databaseUrl: runtime },
    { check: async () => true, close: async () => {} },
  );
  await app.init();
  const gradebooks = app.get(GradebooksService);
  const finalResults = app.get(FinalResultsService);
  const enrollments = app.get(EnrollmentsService);
  const reports = app.get(ReportsService);
  const suffix = randomBytes(5).toString("hex");
  const one = async (sql: string, params: unknown[] = []) =>
    (await owner.query(sql, params)).rows[0] as Record<string, number>;
  const actor = async (role: Role, tag: string): Promise<Actor> => {
    const username = `${tag}${role}${suffix}`.slice(0, 50);
    const id = (
      await one(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'fixture',$2) RETURNING ma_nguoi_dung",
        [username, role],
      )
    ).ma_nguoi_dung!;
    const sessionHash = createHash("sha256")
      .update(randomBytes(16))
      .digest("hex");
    await owner.query(
      "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
      [sessionHash, id, randomBytes(32).toString("hex")],
    );
    if (role === "GIAO_VIEN")
      await owner.query(
        "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'GiÃ¡o viÃªn giáº£')",
        [id],
      );
    return { id, username, role, sessionHash };
  };
  const admin = await actor("QUAN_TRI_VIEN", "a");
  const teacher = await actor("GIAO_VIEN", "t");
  const year = async (name: string, from: string, to: string) =>
    (
      await one(
        "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,$2,$3) RETURNING ma_nam_hoc",
        [`${name.slice(0, 9)} ${suffix}`, from, to],
      )
    ).ma_nam_hoc!;
  const term = async (yearId: number, from: string, to: string, order = 1) =>
    (
      await one(
        "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,$5,$4,$2,$3) RETURNING ma_hoc_ky",
        [yearId, from, to, order, `Ká»³ ${order}`],
      )
    ).ma_hoc_ky!;
  const klass = async (yearId: number, name: string, grade = 10) =>
    (
      await one(
        "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,$4) RETURNING ma_lop",
        [yearId, teacher.id, `${name} ${suffix}`.slice(0, 20), grade],
      )
    ).ma_lop!;
  const student = async (cls: number, name: string) =>
    (
      await one(
        "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,$2,'2010-01-01') RETURNING ma_hoc_sinh",
        [cls, name],
      )
    ).ma_hoc_sinh!;
  const subject = async () => {
    const id = (
      await one(
        "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,2) RETURNING ma_mon",
        [`MÃ´n ${suffix}`],
      )
    ).ma_mon!;
    const component = (
      await one(
        "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,loai_he_so,he_so,bat_buoc,thu_tu_hien_thi) VALUES($1,'TX','TX',1,true,1) RETURNING ma_thanh_phan",
        [id],
      )
    ).ma_thanh_phan!;
    return { id, component };
  };
  const book = async (cls: number, subjectId: number, termId: number) => {
    await owner.query(
      "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,CURRENT_DATE)",
      [teacher.id, cls, subjectId, termId],
    );
    return gradebooks.create(teacher, { classId: cls, subjectId, termId });
  };
  /** Äiá»n Ä‘iá»ƒm cho má»i Ã´ cÃ²n trá»‘ng, chá»‘t cá»™t báº±ng lá»‹ch Ä‘Ã£ háº¿t háº¡n vÃ  tÃ­nh tá»•ng káº¿t. */
  const finish = async (bookId: number, component: number, value = 6) => {
    await owner.query(
      "UPDATE diem_thanh_phan SET gia_tri=$2,trang_thai='DA_DUYET' WHERE ma_bang_diem=$1 AND trang_thai='CHUA_CO'",
      [bookId, value],
    );
    await owner.query(
      "INSERT INTO lich_nhap_diem(ma_bang_diem,ma_thanh_phan,mo_luc,dong_luc,nguoi_dat) VALUES($1,$2,now()-interval '2 hours',now()-interval '1 hour',$3)",
      [bookId, component, admin.id],
    );
    await gradebooks.processDue();
    const view = await gradebooks.cells(teacher, bookId);
    assert.equal(view.book.status, "DA_CHOT");
    return finalResults.calculate(teacher, bookId, uniqueKey("calc"), {
      expectedVersion: view.book.version,
      reason: "TÃ­nh káº¿t quáº£ kiá»ƒm thá»­",
    });
  };
  return {
    owner,
    runtimePool,
    app,
    admin,
    teacher,
    actor,
    gradebooks,
    finalResults,
    enrollments,
    reports,
    year,
    term,
    klass,
    student,
    subject,
    book,
    finish,
    done: async () => {
      await app.close();
      await runtimePool.end();
      await owner.end();
    },
  };
}

type Fx = Awaited<ReturnType<typeof fixture>>;

async function snapshot(f: Fx, ids: number[]) {
  return (
    await f.owner.query(
      "SELECT ma,ma_hoc_sinh,ma_lop,trang_thai,den_ngay::text FROM hoc_sinh_lop WHERE ma_hoc_sinh = ANY($1) ORDER BY ma",
      [ids],
    )
  ).rows;
}
const failsWith =
  (code: string, studentId?: number) =>
  (e: {
    code?: string;
    details?: { studentId?: number; reason?: string } | null;
  }) =>
    e.code === code &&
    (studentId === undefined ||
      (e.details?.studentId === studentId && e.details?.reason === code));

test("end-of-year promotion keeps last year's gradebook, results, report and publication untouched", async () => {
  const f = await fixture();
  try {
    const x = await f.year("NÄƒm X", "2026-09-01", "2027-06-01");
    const y = await f.year("NÄƒm Y", "2027-09-01", "2028-06-01");
    const termX = await f.term(x, "2026-09-05", "2027-01-10");
    const termY = await f.term(y, "2027-09-05", "2028-01-10");
    const a1 = await f.klass(x, "10A1", 10);
    const target11a1 = await f.klass(y, "11A1", 11);
    const target11a2 = await f.klass(y, "11A2", 11);
    const target10a3 = await f.klass(y, "10A3", 10);
    const students: number[] = [];
    for (const name of ["An", "BÃ¬nh", "ChÃ¢u", "DÅ©ng", "Em"])
      students.push(await f.student(a1, `Há»c sinh ${name}`));
    const subject = await f.subject();
    const bookX = await f.book(a1, subject.id, termX);
    await f.finish(bookX.id, subject.component, 6);
    await f.owner.query(
      "UPDATE hoc_ky SET da_cong_bo=true WHERE ma_hoc_ky=$1",
      [termX],
    );

    const before = {
      cells: (await f.gradebooks.cells(f.teacher, bookX.id)).items.map((c) => [
        c.studentId,
        c.value,
        c.active,
        c.stt,
      ]),
      results: (await f.finalResults.list(f.teacher, bookX.id)).items.map(
        (r) => [r.studentId, r.finalScore, r.classification],
      ),
      summary: await f.reports.summary(f.teacher, bookX.id),
    };
    assert.equal(before.cells.length, 5);

    // Xem trÆ°á»›c: STT, gá»£i Ã½ lá»›p Ä‘Ã­ch cÃ¹ng háº­u tá»‘ (10A1 â†’ 11A1) vÃ  hÃ nh Ä‘á»™ng.
    const preview = await f.enrollments.preview(f.admin, a1, String(y));
    assert.equal(preview.items.length, 5);
    assert.deepEqual(
      preview.items.map((i) => i.order),
      [1, 2, 3, 4, 5],
    );
    assert.ok(
      preview.items.every(
        (i) =>
          i.suggestedAction === "LEN_LOP" &&
          i.suggestedTargetClassId === target11a1 &&
          !i.alreadyEnrolledInTargetYear,
      ),
    );
    assert.equal(preview.targetClasses.length, 3);
    assert.equal(preview.sourceClass.grade, 10);
    await assert.rejects(
      f.enrollments.preview(f.admin, a1, String(x)),
      failsWith("TARGET_YEAR_NOT_AFTER"),
    );

    const [s1, s2, s3, s4, s5] = students as [
      number,
      number,
      number,
      number,
      number,
    ];
    const key = uniqueKey("promo");
    const body = {
      targetYearId: y,
      items: [
        { studentId: s1, action: "LEN_LOP", targetClassId: target11a2 },
        { studentId: s2, action: "LEN_LOP", targetClassId: target11a2 },
        { studentId: s3, action: "LEN_LOP", targetClassId: target11a2 },
        { studentId: s4, action: "LUU_BAN", targetClassId: target10a3 },
        { studentId: s5, action: "NGHI_HOC", reason: "Chuyá»ƒn trÆ°á»ng" },
      ],
    };
    const done = await f.enrollments.promote(f.admin, a1, key, body);
    assert.deepEqual(done, {
      processed: 5,
      promoted: 3,
      retained: 1,
      graduated: 0,
      withdrawn: 1,
    });
    assert.deepEqual(await f.enrollments.promote(f.admin, a1, key, body), done);

    // NÄƒm X khÃ´ng Ä‘á»•i.
    const after = {
      cells: (await f.gradebooks.cells(f.teacher, bookX.id)).items.map((c) => [
        c.studentId,
        c.value,
        c.active,
        c.stt,
      ]),
      results: (await f.finalResults.list(f.teacher, bookX.id)).items.map(
        (r) => [r.studentId, r.finalScore, r.classification],
      ),
      summary: await f.reports.summary(f.teacher, bookX.id),
    };
    assert.deepEqual(after, before);
    assert.ok(after.cells.every((c) => c[2] === true));
    assert.deepEqual(await f.gradebooks.publishReadiness(f.admin, termX), {
      ready: true,
      issues: [],
    });
    assert.deepEqual(
      (await f.gradebooks.missingStudents(f.admin, bookX.id)).items,
      [],
    );

    // Lá»›p Ä‘Ã­ch Ä‘Ãºng há»c sinh; cá»™t lá»›p hiá»‡n táº¡i Ä‘á»•i theo ghi danh.
    const roster = async (cls: number) =>
      (
        await f.owner.query(
          "SELECT ma_hoc_sinh FROM hoc_sinh_cua_lop($1,$2) WHERE con_hoc ORDER BY 1",
          [cls, termY],
        )
      ).rows.map((r) => r.ma_hoc_sinh);
    assert.deepEqual(await roster(target11a2), [s1, s2, s3]);
    assert.deepEqual(await roster(target10a3), [s4]);
    assert.deepEqual(await roster(target11a1), []);
    const legacy = await f.owner.query(
      "SELECT ma_hoc_sinh,ma_lop,dang_theo_hoc FROM hoc_sinh WHERE ma_hoc_sinh = ANY($1) ORDER BY ma_hoc_sinh",
      [students],
    );
    assert.deepEqual(
      legacy.rows.map((r) => [r.ma_lop, r.dang_theo_hoc]),
      [
        [target11a2, true],
        [target11a2, true],
        [target11a2, true],
        [target10a3, true],
        [a1, false],
      ],
    );
    const closed = await f.owner.query(
      "SELECT trang_thai,den_ngay::text FROM hoc_sinh_lop WHERE ma_hoc_sinh=$1 AND ma_lop=$2",
      [s5, a1],
    );
    assert.deepEqual(closed.rows[0], {
      trang_thai: "NGHI_HOC",
      den_ngay: "2027-06-01",
    });

    // Há»c sinh tháº¥y hai nÄƒm.
    const bookY = await f.book(target11a2, subject.id, termY);
    await f.finish(bookY.id, subject.component, 9);
    const account = await f.actor("HOC_SINH", "s");
    await f.owner.query(
      "UPDATE hoc_sinh SET ma_nguoi_dung=$1 WHERE ma_hoc_sinh=$2",
      [account.id, s1],
    );
    const all = await f.finalResults.myOverview(account);
    assert.deepEqual(
      all.years.map((i) => [i.id, i.className.slice(0, 4)]),
      [
        [y, "11A2"],
        [x, "10A1"],
      ],
    );
    assert.deepEqual(
      all.items.map((i) => [i.yearId, i.className.slice(0, 4)]).sort(),
      [
        [x, "10A1"],
        [y, "11A2"],
      ].sort(),
    );
    assert.equal(
      all.items.every((i) => i.yearName.length > 0),
      true,
    );
    const onlyX = await f.finalResults.myOverview(
      account,
      undefined,
      String(x),
    );
    assert.deepEqual(
      onlyX.items.map((i) => i.gradebookId),
      [bookX.id],
    );
    assert.equal(onlyX.years.length, 2);
    assert.equal(onlyX.summary.yearId, x);
    assert.equal(onlyX.summary.className.slice(0, 4), "10A1");

    // Lá»‹ch sá»­ ghi danh: QTV vÃ  giÃ¡o viÃªn chá»§ nhiá»‡m xem Ä‘Æ°á»£c, má»›i nháº¥t trÆ°á»›c.
    const history = (await f.enrollments.list(f.teacher, s1)).items;
    assert.deepEqual(
      history.map((h) => [
        h.status,
        h.className.slice(0, 4),
        h.fromDate,
        h.toDate,
      ]),
      [
        ["DANG_HOC", "11A2", "2027-09-01", null],
        ["LEN_LOP", "10A1", "2026-09-01", "2027-06-01"],
      ],
    );
    assert.equal(history[0]!.actorName !== null, true);
  } finally {
    await f.done();
  }
});

test("promotion batches with any invalid row are rejected as a whole", async () => {
  const f = await fixture();
  try {
    const x = await f.year("NÄƒm X", "2026-09-01", "2027-06-01");
    const y = await f.year("NÄƒm Y", "2027-09-01", "2028-06-01");
    const z = await f.year("NÄƒm Z", "2028-09-01", "2029-06-01");
    const src = await f.klass(x, "10B", 10);
    const other = await f.klass(x, "10C", 10);
    const t11 = await f.klass(y, "11B", 11);
    const t10 = await f.klass(y, "10B", 10);
    const t12 = await f.klass(y, "12B", 12);
    const wrongYear = await f.klass(z, "11Z", 11);
    const [a, b, c, d] = [
      await f.student(src, "Há»c sinh a"),
      await f.student(src, "Há»c sinh b"),
      await f.student(src, "Há»c sinh c"),
      await f.student(src, "Há»c sinh d"),
    ] as [number, number, number, number];
    const stranger = await f.student(other, "Há»c sinh ngoÃ i lá»›p");
    // d Ä‘Ã£ cÃ³ ghi danh nÄƒm Ä‘Ã­ch.
    await f.owner.query(
      "INSERT INTO hoc_sinh_lop(ma_hoc_sinh,ma_lop,tu_ngay,trang_thai) VALUES($1,$2,'2027-09-01','DANG_HOC')",
      [d, t11],
    );
    // d vá»«a cÃ³ ghi danh DANG_HOC nÄƒm Y nÃªn "lá»›p hiá»‡n táº¡i" Ä‘Ã£ sang 11B; há»“ sÆ¡ khÃ¡c dÃ¹ng lÃ m nguá»“n lÃªn lá»›p.
    const ids = [a, b, c, d, stranger];
    const before = await snapshot(f, ids);
    const good = { studentId: a, action: "LEN_LOP", targetClassId: t11 };
    const run = (year: number, items: unknown[], k = uniqueKey("p")) =>
      f.enrollments.promote(f.admin, src, k, { targetYearId: year, items });
    const rejects = async (
      year: number,
      items: unknown[],
      code: string,
      studentId?: number,
    ) => {
      await assert.rejects(run(year, items), failsWith(code, studentId));
      assert.deepEqual(await snapshot(f, ids), before, code);
    };
    await rejects(
      y,
      [good, { studentId: b, action: "LEN_LOP", targetClassId: t10 }],
      "PROMOTION_GRADE_MISMATCH",
      b,
    );
    await rejects(
      y,
      [good, { studentId: b, action: "LUU_BAN", targetClassId: t11 }],
      "PROMOTION_GRADE_MISMATCH",
      b,
    );
    await rejects(x, [good], "TARGET_YEAR_NOT_AFTER");
    await rejects(
      y,
      [good, { studentId: b, action: "TOT_NGHIEP" }],
      "GRADUATION_ONLY_GRADE_12",
      b,
    );
    await rejects(
      y,
      [good, { studentId: d, action: "LEN_LOP", targetClassId: t11 }],
      "STUDENT_ALREADY_ENROLLED",
      d,
    );
    await rejects(
      y,
      [good, { studentId: a, action: "LUU_BAN", targetClassId: t10 }],
      "DUPLICATE_STUDENT",
      a,
    );
    await rejects(
      y,
      [good, { studentId: b, action: "LEN_LOP" }],
      "TARGET_CLASS_REQUIRED",
      b,
    );
    await rejects(
      y,
      [good, { studentId: b, action: "NGHI_HOC", targetClassId: t11 }],
      "TARGET_CLASS_NOT_ALLOWED",
      b,
    );
    await rejects(
      y,
      [good, { studentId: b, action: "LEN_LOP", targetClassId: wrongYear }],
      "TARGET_CLASS_WRONG_YEAR",
      b,
    );
    await rejects(
      y,
      [good, { studentId: stranger, action: "LEN_LOP", targetClassId: t11 }],
      "ENROLLMENT_NOT_ACTIVE",
      stranger,
    );
    // Khá»‘i 12 tá»‘t nghiá»‡p Ä‘Æ°á»£c, vÃ  lÃ´ sai Ä‘áº§u vÃ o bá»‹ tá»« chá»‘i á»Ÿ API (400).
    const senior = await f.klass(x, "12B", 12);
    const grad = await f.student(senior, "Há»c sinh cuá»‘i cáº¥p");
    const graduated = await f.enrollments.promote(
      f.admin,
      senior,
      uniqueKey("g"),
      {
        targetYearId: y,
        items: [{ studentId: grad, action: "TOT_NGHIEP" }],
      },
    );
    assert.equal(graduated.graduated, 1);
    assert.equal(
      (
        await f.owner.query(
          "SELECT trang_thai FROM hoc_sinh_lop WHERE ma_hoc_sinh=$1",
          [grad],
        )
      ).rows[0].trang_thai,
      "TOT_NGHIEP",
    );
    assert.throws(() => run(y, []), BadRequestException);
    assert.throws(
      () => run(y, [{ studentId: a, action: "XOA" }]),
      BadRequestException,
    );
    assert.ok(t12);
  } finally {
    await f.done();
  }
});

test("mid-year transfer keeps the old class's grades and blocks invalid moves", async () => {
  const f = await fixture();
  try {
    const x = await f.year("NÄƒm chuyá»ƒn", "2026-09-01", "2027-06-01");
    const z = await f.year("NÄƒm khÃ¡c", "2027-09-01", "2028-06-01");
    const term1 = await f.term(x, "2026-09-05", "2027-01-10", 1);
    const term2 = await f.term(x, "2027-01-15", "2027-05-31", 2);
    const c1 = await f.klass(x, "10C1", 10);
    const c2 = await f.klass(x, "10C2", 10);
    const c3 = await f.klass(x, "11C3", 11);
    const other = await f.klass(z, "10Z", 10);
    const stay = await f.student(c1, "Há»c sinh á»Ÿ láº¡i");
    const mover = await f.student(c1, "Há»c sinh chuyá»ƒn");
    await f.student(c2, "Há»c sinh lá»›p má»›i");
    const subject = await f.subject();
    const book1 = await f.book(c1, subject.id, term1);
    const book2 = await f.book(c1, subject.id, term2);
    const bookNew = await f.book(c2, subject.id, term1);
    const moverCell = (
      await f.owner.query(
        "SELECT ma_diem FROM diem_thanh_phan WHERE ma_bang_diem=$1 AND ma_hoc_sinh=$2",
        [book2.id, mover],
      )
    ).rows[0].ma_diem;
    await f.owner.query(
      "UPDATE diem_thanh_phan SET gia_tri=5,trang_thai='DA_DUYET' WHERE ma_diem=$1",
      [moverCell],
    );
    const move = (
      target: number,
      date: string,
      k = uniqueKey("t"),
      reason = "Chuyá»ƒn lá»›p",
    ) =>
      f.enrollments.transfer(f.admin, mover, k, {
        targetClassId: target,
        effectiveDate: date,
        reason,
      });
    const before = await snapshot(f, [mover]);
    await assert.rejects(
      move(c2, "2026-11-15"),
      failsWith("TRANSFER_HAS_LATER_GRADES", mover),
    );
    await assert.rejects(
      move(c3, "2026-11-15"),
      failsWith("TRANSFER_GRADE_MISMATCH", mover),
    );
    await assert.rejects(
      move(other, "2026-11-15"),
      failsWith("TARGET_CLASS_WRONG_YEAR", mover),
    );
    await assert.rejects(
      move(c1, "2026-11-15"),
      failsWith("TRANSFER_SAME_CLASS", mover),
    );
    for (const date of ["2026-08-01", "2027-07-01", "2026-09-01"])
      await assert.rejects(
        move(c2, date),
        failsWith("EFFECTIVE_DATE_OUT_OF_RANGE", mover),
      );
    assert.deepEqual(await snapshot(f, [mover]), before);

    // XÃ³a Ä‘iá»ƒm há»c ká»³ sau (cá»™t chÆ°a chá»‘t) â†’ chuyá»ƒn Ä‘Æ°á»£c; lá»›p má»›i cÃ³ báº£ng Ä‘iá»ƒm nhÆ°ng khÃ´ng tá»± táº¡o Ã´.
    await f.owner.query(
      "UPDATE diem_thanh_phan SET gia_tri=NULL,trang_thai='CHUA_CO' WHERE ma_diem=$1",
      [moverCell],
    );
    const key = uniqueKey("t");
    const moved = await move(c2, "2026-11-15", key);
    assert.equal(moved.enrollment.status, "DANG_HOC");
    assert.equal(moved.enrollment.className.slice(0, 5), "10C2 ");
    assert.equal(moved.enrollment.fromDate, "2026-11-15");
    assert.deepEqual(
      moved.affectedGradebooks.map((g) => g.id),
      [bookNew.id],
    );
    assert.deepEqual(await move(c2, "2026-11-15", key), moved);
    const old = await f.enrollments.list(f.admin, mover);
    assert.deepEqual(
      old.items.map((h) => [h.status, h.className.slice(0, 5), h.toDate]),
      [
        ["DANG_HOC", "10C2 ", null],
        ["DA_CHUYEN_LOP", "10C1 ", "2026-11-14"],
      ],
    );
    assert.deepEqual(
      (await f.gradebooks.missingStudents(f.admin, bookNew.id)).items.map(
        (s) => s.studentId,
      ),
      [mover],
    );

    // Lá»›p cÅ©: em khÃ´ng cÃ²n tÃ­nh â€” khÃ´ng bá»‹ ghi 0 khi háº¿t háº¡n, khÃ´ng bá»‹ Ä‘Ã²i káº¿t quáº£.
    const view = await f.gradebooks.cells(f.teacher, book1.id);
    assert.equal(view.items.find((c) => c.studentId === mover)!.active, false);
    await f.owner.query(
      "UPDATE diem_thanh_phan SET gia_tri=8,trang_thai='DA_DUYET' WHERE ma_bang_diem=$1 AND ma_hoc_sinh=$2",
      [book1.id, stay],
    );
    await f.owner.query(
      "INSERT INTO lich_nhap_diem(ma_bang_diem,ma_thanh_phan,mo_luc,dong_luc,nguoi_dat) VALUES($1,$2,now()-interval '2 hours',now()-interval '1 hour',$3)",
      [book1.id, subject.component, f.admin.id],
    );
    await f.gradebooks.processDue();
    const locked = await f.gradebooks.cells(f.teacher, book1.id);
    assert.equal(locked.items.find((c) => c.studentId === mover)!.value, null);
    const result = await f.finalResults.calculate(
      f.teacher,
      book1.id,
      uniqueKey("c"),
      {
        expectedVersion: locked.book.version,
        reason: "TÃ­nh káº¿t quáº£",
      },
    );
    assert.deepEqual(
      result.results.map((r) => r.studentId),
      [stay],
    );
    assert.deepEqual(result.skipped, []);
    assert.deepEqual(result.exempted, []);
    void book2;
  } finally {
    await f.done();
  }
});

test("withdraw then reenroll: same class reopens the old enrollment, another class creates a new one", async () => {
  const f = await fixture();
  try {
    const x = await f.year("NÄƒm nghá»‰", "2026-09-01", "2027-06-01");
    const c1 = await f.klass(x, "10D1", 10);
    const c2 = await f.klass(x, "10D2", 10);
    const s = await f.student(c1, "Há»c sinh nghá»‰ há»c");
    const account = await f.actor("HOC_SINH", "s");
    await f.owner.query(
      "UPDATE hoc_sinh SET ma_nguoi_dung=$1 WHERE ma_hoc_sinh=$2",
      [account.id, s],
    );
    const withdraw = (
      date: string,
      reason = "á»m dÃ i ngÃ y",
      k = uniqueKey("w"),
    ) => f.enrollments.withdraw(f.admin, s, k, { effectiveDate: date, reason });
    const reenroll = (cls: number, date: string, reason = "Quay láº¡i há»c") =>
      f.enrollments.reenroll(f.admin, s, uniqueKey("r"), {
        classId: cls,
        effectiveDate: date,
        reason,
      });

    await assert.rejects(
      withdraw("2026-08-01"),
      failsWith("EFFECTIVE_DATE_OUT_OF_RANGE", s),
    );
    await assert.rejects(
      reenroll(c1, "2026-12-01"),
      failsWith("STUDENT_ALREADY_ENROLLED", s),
    );
    const out = await withdraw("2026-11-01");
    assert.equal(out.enrollment.status, "NGHI_HOC");
    assert.equal(out.enrollment.toDate, "2026-10-31");
    assert.equal(
      (
        await f.owner.query(
          "SELECT trang_thai FROM nguoi_dung WHERE ma_nguoi_dung=$1",
          [account.id],
        )
      ).rows[0].trang_thai,
      true,
    );
    await assert.rejects(
      withdraw("2026-12-01"),
      failsWith("ENROLLMENT_NOT_ACTIVE", s),
    );
    await assert.rejects(
      reenroll(c1, "2027-07-01"),
      failsWith("TARGET_CLASS_WRONG_YEAR", s),
    );

    const back = await reenroll(c1, "2026-12-01");
    assert.equal(back.enrollment.id, out.enrollment.id);
    assert.equal(back.enrollment.status, "DANG_HOC");
    assert.equal(back.enrollment.toDate, null);
    assert.equal(back.enrollment.reason, "Quay láº¡i há»c");
    assert.equal((await f.enrollments.list(f.admin, s)).items.length, 1);
    const audit = await f.owner.query(
      "SELECT doi_tuong FROM nhat_ky_bao_mat WHERE hanh_dong='ENROLLMENT_REOPENED' AND doi_tuong LIKE $1",
      [`hoc_sinh_lop:${out.enrollment.id}:%`],
    );
    assert.equal(audit.rowCount, 1);
    assert.match(audit.rows[0].doi_tuong, /nghi=2026-10-31/);

    await withdraw("2027-01-05", "Nghá»‰ láº§n hai");
    const other = await reenroll(c2, "2027-02-01", "Há»c lá»›p khÃ¡c");
    assert.notEqual(other.enrollment.id, out.enrollment.id);
    assert.equal(other.enrollment.className.slice(0, 5), "10D2 ");
    assert.equal(other.enrollment.fromDate, "2027-02-01");
    const list = (await f.enrollments.list(f.admin, s)).items;
    assert.deepEqual(
      list.map((h) => h.status),
      ["DANG_HOC", "NGHI_HOC"],
    );
    const legacy = await f.owner.query(
      "SELECT ma_lop,dang_theo_hoc FROM hoc_sinh WHERE ma_hoc_sinh=$1",
      [s],
    );
    assert.deepEqual(legacy.rows[0], { ma_lop: c2, dang_theo_hoc: true });
  } finally {
    await f.done();
  }
});

test("only admins run enrollment actions; history is visible to related teachers; keys are idempotent", async () => {
  const f = await fixture();
  try {
    const x = await f.year("NÄƒm quyá»n", "2026-09-01", "2027-06-01");
    const y = await f.year("NÄƒm sau", "2027-09-01", "2028-06-01");
    const c1 = await f.klass(x, "10E1", 10);
    const c2 = await f.klass(x, "10E2", 10);
    const t11 = await f.klass(y, "11E1", 11);
    const s = await f.student(c1, "Há»c sinh quyá»n");
    const stranger = await f.actor("GIAO_VIEN", "u");
    const student = await f.actor("HOC_SINH", "h");
    for (const who of [f.teacher, student]) {
      await assert.rejects(
        f.enrollments.preview(who, c1, String(y)),
        ForbiddenException,
      );
      await assert.rejects(
        f.enrollments.promote(who, c1, uniqueKey("k"), {
          targetYearId: y,
          items: [{ studentId: s, action: "LEN_LOP", targetClassId: t11 }],
        }),
        ForbiddenException,
      );
      await assert.rejects(
        f.enrollments.transfer(who, s, uniqueKey("k"), {
          targetClassId: c2,
          effectiveDate: "2026-11-15",
          reason: "x",
        }),
        ForbiddenException,
      );
      await assert.rejects(
        f.enrollments.withdraw(who, s, uniqueKey("k"), {
          effectiveDate: "2026-11-15",
          reason: "x",
        }),
        ForbiddenException,
      );
      await assert.rejects(
        f.enrollments.reenroll(who, s, uniqueKey("k"), {
          classId: c1,
          effectiveDate: "2026-11-15",
          reason: "x",
        }),
        ForbiddenException,
      );
    }
    // SQL cÅ©ng tá»« chá»‘i khi gá»i tháº³ng vá»›i phiÃªn giÃ¡o viÃªn (kiá»ƒm quyá»n á»Ÿ cáº£ hai táº§ng).
    const client = await f.runtimePool.connect();
    try {
      await client.query("BEGIN ISOLATION LEVEL SERIALIZABLE");
      await assert.rejects(
        client.query(
          "SELECT public.cho_nghi_hoc($1,$2,DATE '2026-11-15','x',$3,$4)",
          [f.teacher.sessionHash, s, uniqueKey("k"), "0".repeat(64)],
        ),
        (e: { code?: string }) => e.code === "42501",
      );
      await client.query("ROLLBACK");
    } finally {
      client.release();
    }
    assert.equal((await snapshot(f, [s])).length, 1);

    // Lá»‹ch sá»­: QTV vÃ  giÃ¡o viÃªn chá»§ nhiá»‡m xem Ä‘Æ°á»£c; giÃ¡o viÃªn khÃ´ng liÃªn quan vÃ  há»c sinh thÃ¬ khÃ´ng.
    assert.equal((await f.enrollments.list(f.admin, s)).items.length, 1);
    assert.equal((await f.enrollments.list(f.teacher, s)).items.length, 1);
    await assert.rejects(f.enrollments.list(stranger, s), ForbiddenException);
    await assert.rejects(f.enrollments.list(student, s), ForbiddenException);

    // Idempotency: cÃ¹ng khÃ³a + cÃ¹ng ná»™i dung â†’ cÃ¹ng káº¿t quáº£ (khÃ´ng táº¡o thÃªm); cÃ¹ng khÃ³a, ná»™i dung khÃ¡c â†’ lá»—i.
    const key = uniqueKey("w");
    const first = await f.enrollments.withdraw(f.admin, s, key, {
      effectiveDate: "2026-11-01",
      reason: "á»m",
    });
    const again = await f.enrollments.withdraw(f.admin, s, key, {
      effectiveDate: "2026-11-01",
      reason: "á»m",
    });
    assert.deepEqual(again, first);
    assert.equal((await f.enrollments.list(f.admin, s)).items.length, 1);
    await assert.rejects(
      f.enrollments.withdraw(f.admin, s, key, {
        effectiveDate: "2026-11-01",
        reason: "LÃ½ do khÃ¡c",
      }),
      ConflictException,
    );
    assert.throws(
      () =>
        f.enrollments.withdraw(f.admin, s, key, {
          effectiveDate: "01/11/2026",
          reason: "x",
        }),
      BadRequestException,
    );
  } finally {
    await f.done();
  }
});
