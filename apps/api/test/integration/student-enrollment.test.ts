import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import { test } from "node:test";
import { Pool } from "pg";
import { createApp } from "../../src/app.js";
import type {
  Actor,
  Role,
} from "../../src/modules/authorization/application/policy.js";
import { FinalResultsService } from "../../src/modules/final-results/application/service.js";
import { GradebooksService } from "../../src/modules/gradebooks/application/service.js";
import { StudentsService } from "../../src/modules/students/application/students.js";

// Ghi danh học sinh theo lớp/năm học (migration 202610230001). Dữ liệu giả, chỉ chạy trên DB *_test.

const uniqueKey = (tag: string) => `${tag}-${randomBytes(4).toString("hex")}`;
const codeIs = (code: string) => (e: { code?: string }) => e.code === code;

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
        "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'Giáo viên giả')",
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
  const term = async (yearId: number, from: string, to: string) =>
    (
      await one(
        "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'Kỳ 1',1,$2,$3) RETURNING ma_hoc_ky",
        [yearId, from, to],
      )
    ).ma_hoc_ky!;
  const klass = async (yearId: number, name: string) =>
    (
      await one(
        "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,10) RETURNING ma_lop",
        [yearId, teacher.id, `${name} ${suffix}`.slice(0, 20)],
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
        [`Môn ${suffix}`],
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
  /** Điền điểm cho mọi ô còn trống, chốt cột bằng lịch đã hết hạn và tính tổng kết. */
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
      reason: "Tính kết quả kiểm thử",
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

test("every student has exactly one enrollment that mirrors the legacy class columns", async () => {
  const f = await fixture();
  try {
    // Mọi hồ sơ có ghi danh; cột lớp hiện tại khớp ghi danh (DANG_HOC ⇔ dang_theo_hoc; ma_lop thuộc các ghi danh của em).
    // Học sinh từng lên lớp/chuyển lớp ở các test khác có nhiều ghi danh nên không đòi "đúng một" cho mọi hồ sơ.
    const bad = await f.owner.query(`
      SELECT h.ma_hoc_sinh FROM hoc_sinh h
      WHERE NOT EXISTS (SELECT 1 FROM hoc_sinh_lop g WHERE g.ma_hoc_sinh=h.ma_hoc_sinh)
         OR NOT EXISTS (SELECT 1 FROM hoc_sinh_lop g WHERE g.ma_hoc_sinh=h.ma_hoc_sinh AND g.ma_lop=h.ma_lop)
         OR h.dang_theo_hoc <> EXISTS (SELECT 1 FROM hoc_sinh_lop g WHERE g.ma_hoc_sinh=h.ma_hoc_sinh AND g.trang_thai='DANG_HOC')`);
    assert.equal(bad.rowCount, 0);
    const single = await f.owner.query(`
      SELECT count(*)::int AS n FROM hoc_sinh h
      WHERE (SELECT count(*) FROM hoc_sinh_lop g WHERE g.ma_hoc_sinh=h.ma_hoc_sinh) = 1`);
    assert.ok(single.rows[0].n > 0);
    // Hồ sơ tạo mới (tương thích ngược) tự có ghi danh đầu tiên.
    const y = await f.year("Năm ghi danh", "2026-09-01", "2027-06-01");
    const cls = await f.klass(y, "gd");
    const id = await f.student(cls, "Học sinh mới");
    const rows = await f.owner.query(
      "SELECT trang_thai,den_ngay,tu_ngay::text FROM hoc_sinh_lop WHERE ma_hoc_sinh=$1",
      [id],
    );
    assert.equal(rows.rowCount, 1);
    assert.equal(rows.rows[0].trang_thai, "DANG_HOC");
    assert.equal(rows.rows[0].den_ngay, null);
    assert.equal(rows.rows[0].tu_ngay, "2026-09-01");
  } finally {
    await f.done();
  }
});

test("a promoted student stays in last year's gradebook, results and publication check, and has this year's gradebook", async () => {
  const f = await fixture();
  try {
    const x = await f.year("Năm X", "2026-09-01", "2027-06-01");
    const y = await f.year("Năm Y", "2027-09-01", "2028-06-01");
    const termX = await f.term(x, "2026-09-05", "2027-01-10");
    const termY = await f.term(y, "2027-09-05", "2028-01-10");
    const a10 = await f.klass(x, "10A");
    const b11 = await f.klass(y, "11B");
    const s1 = await f.student(a10, "Học sinh lên lớp");
    const s2 = await f.student(a10, "Học sinh ở lại");
    const subject = await f.subject();
    const bookX = await f.book(a10, subject.id, termX);
    const first = await f.finish(bookX.id, subject.component, 6);
    assert.equal(first.calculatedStudents, 2);

    // Lên lớp: đóng ghi danh 10A (LEN_LOP) và mở ghi danh 11B.
    await f.owner.query(
      "UPDATE hoc_sinh_lop SET trang_thai='LEN_LOP',den_ngay='2027-06-01' WHERE ma_hoc_sinh=$1 AND ma_lop=$2",
      [s1, a10],
    );
    await f.owner.query(
      "INSERT INTO hoc_sinh_lop(ma_hoc_sinh,ma_lop,tu_ngay,trang_thai) VALUES($1,$2,'2027-09-01','DANG_HOC')",
      [s1, b11],
    );
    const legacy = await f.owner.query(
      "SELECT ma_lop,dang_theo_hoc FROM hoc_sinh WHERE ma_hoc_sinh=$1",
      [s1],
    );
    assert.deepEqual(legacy.rows[0], { ma_lop: b11, dang_theo_hoc: true });

    // Bảng điểm năm cũ vẫn có em với điểm cũ, còn học, có STT.
    const oldView = await f.gradebooks.cells(f.teacher, bookX.id);
    const oldCell = oldView.items.find((c) => c.studentId === s1)!;
    assert.equal(oldCell.value, "6.0");
    assert.equal(oldCell.active, true);
    assert.equal(oldCell.stt !== null, true);
    assert.equal(oldView.items.length, 2);
    // Tổng kết lại vẫn có em; danh sách kết quả và nhóm thiếu/miễn không mất em.
    const again = await f.finalResults.calculate(
      f.teacher,
      bookX.id,
      uniqueKey("calc"),
      {
        expectedVersion: oldView.book.version,
        reason: "Tính lại sau khi lên lớp",
      },
    );
    assert.deepEqual(
      again.results.map((r) => r.studentId).sort(),
      [s1, s2].sort(),
    );
    const list = await f.finalResults.list(f.teacher, bookX.id);
    assert.deepEqual(
      list.items.map((r) => r.studentId).sort(),
      [s1, s2].sort(),
    );
    assert.deepEqual(list.skipped, []);
    // Công bố học kỳ năm X không báo thiếu học sinh đã lên lớp.
    assert.deepEqual(await f.gradebooks.publishReadiness(f.admin, termX), {
      ready: true,
      issues: [],
    });
    assert.deepEqual(
      (await f.gradebooks.missingStudents(f.admin, bookX.id)).items,
      [],
    );

    // Năm Y: bảng 11B có em.
    const bookY = await f.book(b11, subject.id, termY);
    const viewY = await f.gradebooks.cells(f.teacher, bookY.id);
    assert.deepEqual(
      viewY.items.map((c) => [c.studentId, c.active]),
      [[s1, true]],
    );
    await f.finish(bookY.id, subject.component, 9);

    // Em đăng nhập xem điểm cả hai năm; lọc theo năm học.
    const account = await f.actor("HOC_SINH", "s");
    await f.owner.query(
      "UPDATE hoc_sinh SET ma_nguoi_dung=$1 WHERE ma_hoc_sinh=$2",
      [account.id, s1],
    );
    const all = await f.finalResults.myOverview(account);
    assert.deepEqual(
      all.items.map((r) => r.gradebookId).sort(),
      [bookX.id, bookY.id].sort(),
    );
    const onlyX = await f.finalResults.myOverview(
      account,
      undefined,
      String(x),
    );
    assert.deepEqual(
      onlyX.items.map((r) => r.gradebookId),
      [bookX.id],
    );
    assert.equal(onlyX.summary.className.startsWith("10A"), true);
    const onlyY = await f.finalResults.myOverview(
      account,
      undefined,
      String(y),
    );
    assert.deepEqual(
      onlyY.items.map((r) => r.gradebookId),
      [bookY.id],
    );
    assert.equal(onlyY.summary.className.startsWith("11B"), true);
  } finally {
    await f.done();
  }
});

test("a student who transfers mid-term is no longer counted (no zero-fill, no result demanded) in the old class and appears in the new one", async () => {
  const f = await fixture();
  try {
    const x = await f.year("Năm chuyển", "2026-09-01", "2027-06-01");
    const termX = await f.term(x, "2026-09-05", "2027-01-10");
    const c1 = await f.klass(x, "C1");
    const c2 = await f.klass(x, "C2");
    const stay = await f.student(c1, "Học sinh ở lại C1");
    const mover = await f.student(c1, "Học sinh chuyển lớp");
    const subject = await f.subject();
    const book1 = await f.book(c1, subject.id, termX);
    await f.owner.query(
      "UPDATE hoc_sinh_lop SET trang_thai='DA_CHUYEN_LOP',den_ngay='2026-11-15' WHERE ma_hoc_sinh=$1 AND ma_lop=$2",
      [mover, c1],
    );
    await f.owner.query(
      "INSERT INTO hoc_sinh_lop(ma_hoc_sinh,ma_lop,tu_ngay,trang_thai) VALUES($1,$2,'2026-11-15','DANG_HOC')",
      [mover, c2],
    );
    const before = await f.gradebooks.cells(f.teacher, book1.id);
    assert.equal(
      before.items.find((c) => c.studentId === mover)!.active,
      false,
    );
    // Hết hạn: ô của học sinh còn học bị ghi 0, ô của em đã chuyển giữ NULL; tổng kết không đòi kết quả của em.
    await f.owner.query(
      "UPDATE diem_thanh_phan SET gia_tri=8,trang_thai='DA_DUYET' WHERE ma_bang_diem=$1 AND ma_hoc_sinh=$2",
      [book1.id, stay],
    );
    await f.owner.query(
      "INSERT INTO lich_nhap_diem(ma_bang_diem,ma_thanh_phan,mo_luc,dong_luc,nguoi_dat) VALUES($1,$2,now()-interval '2 hours',now()-interval '1 hour',$3)",
      [book1.id, subject.component, f.admin.id],
    );
    await f.gradebooks.processDue();
    const after = await f.gradebooks.cells(f.teacher, book1.id);
    assert.equal(after.items.find((c) => c.studentId === mover)!.value, null);
    const result = await f.finalResults.calculate(
      f.teacher,
      book1.id,
      uniqueKey("calc"),
      {
        expectedVersion: after.book.version,
        reason: "Tính kết quả",
      },
    );
    assert.deepEqual(
      result.results.map((r) => r.studentId),
      [stay],
    );
    assert.deepEqual(result.skipped, []);
    assert.deepEqual(result.exempted, []);
    const readiness = await f.gradebooks.publishReadiness(f.admin, termX);
    assert.deepEqual(
      readiness.issues.map((i) => i.code),
      [],
    );
    // Lớp mới có em.
    const book2 = await f.book(c2, subject.id, termX);
    const view2 = await f.gradebooks.cells(f.teacher, book2.id);
    assert.deepEqual(
      view2.items.map((c) => [c.studentId, c.active]),
      [[mover, true]],
    );
  } finally {
    await f.done();
  }
});

test("enrollment rules: one active enrollment per year, class changes only via enrollment, runtime is read-only", async () => {
  const f = await fixture();
  try {
    const x = await f.year("Năm luật", "2026-09-01", "2027-06-01");
    const c1 = await f.klass(x, "L1");
    const c2 = await f.klass(x, "L2");
    const id = await f.student(c1, "Học sinh luật");
    await assert.rejects(
      f.owner.query(
        "INSERT INTO hoc_sinh_lop(ma_hoc_sinh,ma_lop,tu_ngay,trang_thai) VALUES($1,$2,'2026-09-01','DANG_HOC')",
        [id, c2],
      ),
      (e: { code?: string }) => e.code === "23505",
    );
    await assert.rejects(
      f.owner.query("UPDATE hoc_sinh SET ma_lop=$2 WHERE ma_hoc_sinh=$1", [
        id,
        c2,
      ]),
      /STUDENT_CLASS_VIA_ENROLLMENT/,
    );
    await assert.rejects(
      f.owner.query(
        "UPDATE hoc_sinh SET dang_theo_hoc=false WHERE ma_hoc_sinh=$1",
        [id],
      ),
      /STUDENT_CLASS_VIA_ENROLLMENT/,
    );
    await assert.rejects(
      f.owner.query("DELETE FROM hoc_sinh_lop WHERE ma_hoc_sinh=$1", [id]),
      /ENROLLMENT_APPEND_ONLY/,
    );
    await assert.rejects(
      f.owner.query(
        "INSERT INTO hoc_sinh_lop(ma_hoc_sinh,ma_lop,ma_nam_hoc,tu_ngay,trang_thai) VALUES($1,$2,$3,'2026-09-01','NGHI_HOC')",
        [id, c2, x + 1000],
      ),
      (e: { code?: string }) => ["23514", "23503"].includes(e.code ?? ""),
    );
    // Runtime chỉ đọc.
    const denied = (e: { code?: string }) => e.code === "42501";
    await assert.rejects(
      f.runtimePool.query(
        "INSERT INTO hoc_sinh_lop(ma_hoc_sinh,ma_lop,tu_ngay,trang_thai) VALUES($1,$2,'2026-09-01','NGHI_HOC')",
        [id, c2],
      ),
      denied,
    );
    await assert.rejects(
      f.runtimePool.query(
        "UPDATE hoc_sinh_lop SET ly_do='x' WHERE ma_hoc_sinh=$1",
        [id],
      ),
      denied,
    );
    await assert.rejects(
      f.runtimePool.query("DELETE FROM hoc_sinh_lop WHERE ma_hoc_sinh=$1", [
        id,
      ]),
      denied,
    );
    assert.equal(
      (
        await f.runtimePool.query(
          "SELECT 1 FROM hoc_sinh_lop WHERE ma_hoc_sinh=$1",
          [id],
        )
      ).rowCount,
      1,
    );

    // Danh mục học sinh: đổi lớp / trạng thái bị từ chối, lưu không đổi vẫn được; DTO có lớp hiện tại.
    const students = f.app.get(StudentsService);
    const input = {
      ma_nguoi_dung: null,
      ma_lop: c1,
      ho_ten: "Học sinh luật",
      ngay_sinh: "2010-01-01",
      dang_theo_hoc: true,
    };
    await assert.rejects(
      students.save(f.admin, { ...input, ma_lop: c2 }, id),
      codeIs("STUDENT_CLASS_VIA_ENROLLMENT"),
    );
    await assert.rejects(
      students.save(f.admin, { ...input, dang_theo_hoc: false }, id),
      codeIs("STUDENT_CLASS_VIA_ENROLLMENT"),
    );
    const saved = (await students.save(
      f.admin,
      { ...input, ho_ten: "Học sinh luật (sửa)" },
      id,
    )) as Record<string, unknown>;
    assert.equal(saved.currentClassId, c1);
    assert.equal(saved.currentYearId, x);
    assert.match(String(saved.currentClassName), /^L1/);
    // Lọc danh mục theo năm học dùng ghi danh.
    const page = await students.list(f.admin, undefined, undefined, String(x));
    assert.ok(
      page.items.some(
        (s) => (s as unknown as { ma_hoc_sinh: number }).ma_hoc_sinh === id,
      ),
    );
  } finally {
    await f.done();
  }
});
