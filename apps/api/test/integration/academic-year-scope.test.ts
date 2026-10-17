import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import { test } from "node:test";
import { Pool } from "pg";
import { createApp } from "../../src/app.js";
import type { ObjectStorage } from "../../src/modules/files/application/port.js";
import { createRosterFixture } from "./roster-fixture.js";

// Năm học hiện hành làm phạm vi mặc định: lọc ở server theo yearId trước khi phân trang, chuyển năm hiện hành trong một giao dịch,
// tóm tắt việc còn dang dở của năm và học kỳ mặc định của thời khóa biểu. Dữ liệu hoàn toàn giả, chỉ trên DB *_test.

interface Page<T> {
  items: T[];
  nextCursor: string | null;
}

test("year scoped lists, current-year switching and pending summary", async () => {
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
  const storage: ObjectStorage = {
    put: async () => {},
    get: async () => new Uint8Array(),
    signedGetUrl: async (key) => `https://storage.test/${key}`,
    remove: async () => {},
  };
  const app = await createApp(
    {
      environment: "development",
      origins: ["http://localhost:8080"],
      databaseUrl: runtimeUrl,
    },
    { check: async () => true, close: async () => {} },
    { objectStorage: storage },
  );
  await app.listen(0, "127.0.0.1");
  const base = `${await app.getUrl()}/api/v1`;
  const suffix = randomBytes(4).toString("hex");
  const originalCurrent: number[] = (
    await owner.query("SELECT ma_nam_hoc FROM nam_hoc WHERE hien_hanh")
  ).rows.map((row) => row.ma_nam_hoc);

  const makeUser = async (role: "QUAN_TRI_VIEN" | "GIAO_VIEN") => {
    const id: number = (
      await owner.query(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'test-only',$2) RETURNING ma_nguoi_dung",
        [`ys_${role.slice(0, 2)}_${randomBytes(4).toString("hex")}`, role],
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
        "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'GV năm học giả')",
        [id],
      );
    return { id, token };
  };
  const call = (
    token: string | null,
    method: string,
    path: string,
    body?: unknown,
  ) =>
    fetch(base + path, {
      method,
      headers: {
        ...(token ? { authorization: `Bearer ${token}` } : {}),
        ...(body === undefined ? {} : { "content-type": "application/json" }),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  const get = async <T>(token: string, path: string): Promise<T> => {
    const response = await call(token, "GET", path);
    assert.equal(response.status, 200, path);
    return (await response.json()) as T;
  };
  const currentYears = async () =>
    (
      await owner.query(
        "SELECT ma_nam_hoc FROM nam_hoc WHERE hien_hanh ORDER BY 1",
      )
    ).rows.map((row) => row.ma_nam_hoc as number);

  try {
    const admin = await makeUser("QUAN_TRI_VIEN");
    const teacherOne = await makeUser("GIAO_VIEN");
    const teacherTwo = await makeUser("GIAO_VIEN");

    // --- Hai năm học tạo qua API, đều không hiện hành ---
    const makeYear = async (name: string, from: string, to: string) => {
      const response = await call(admin.token, "POST", "/catalog/years", {
        ten: `${name}-${suffix}`,
        ngay_bat_dau: from,
        ngay_ket_thuc: to,
        hien_hanh: false,
      });
      assert.equal(response.status, 200);
      return ((await response.json()) as { ma_nam_hoc: number }).ma_nam_hoc;
    };
    const y1 = await makeYear("Y1", "2026-09-01", "2027-06-01");
    const y2 = await makeYear("Y2", "2027-09-01", "2028-06-01");

    // Dữ liệu: năm 2 chèn trước nên danh sách không lọc (bắt đầu từ mã đầu tiên của bài test) có đủ cả hai năm.
    const semester = async (
      year: number,
      name: string,
      order: number,
      from: string,
      to: string,
    ) =>
      (
        await owner.query(
          "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,$2,$3,$4,$5) RETURNING ma_hoc_ky",
          [year, name, order, from, to],
        )
      ).rows[0].ma_hoc_ky as number;
    const s2 = await semester(y2, "HK1-Y2", 1, "2027-09-05", "2028-01-10");
    const s1a = await semester(y1, "HK1-Y1", 1, "2026-09-05", "2027-01-10");
    const s1b = await semester(y1, "HK2-Y1", 2, "2027-01-15", "2027-05-31");
    const classesOf = async (year: number, count: number) =>
      (
        await owner.query(
          "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) SELECT $1,$2,'c'||n,10 FROM generate_series(1,$3::int) n RETURNING ma_lop",
          [year, teacherOne.id, count],
        )
      ).rows
        .map((row) => row.ma_lop as number)
        .sort((a, b) => a - b);
    const y2Classes = await classesOf(y2, 3);
    const y1Classes = await classesOf(y1, 55);
    const firstClass = y2Classes[0]!;
    await owner.query(
      "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,'Học sinh Y1 một','2010-01-01'),($1,'Học sinh Y1 hai','2010-01-01'),($2,'Học sinh Y2 một','2010-01-01')",
      [y1Classes[0], y2Classes[0]],
    );
    const subject = (
      await owner.query(
        "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,2) RETURNING ma_mon",
        [`YS-${suffix}`],
      )
    ).rows[0].ma_mon as number;
    const assign = (teacher: number, cls: number, term: number) =>
      owner.query(
        "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,CURRENT_DATE)",
        [teacher, cls, subject, term],
      );
    await assign(teacherOne.id, y1Classes[0]!, s1a);
    await assign(teacherOne.id, y2Classes[0]!, s2);
    await assign(teacherTwo.id, y2Classes[1]!, s2);
    await owner.query(
      "INSERT INTO he_so_hoc_ky_chung(ma_hoc_ky,loai_he_so,he_so) VALUES($1,'TX',1.00),($2,'TX',1.00)",
      [s1a, s2],
    );
    await owner.query(
      "INSERT INTO bang_diem(ma_lop,ma_mon,ma_hoc_ky) VALUES($1,$2,$3),($4,$2,$3),($5,$2,$6)",
      [y1Classes[0], subject, s1a, y1Classes[1], y2Classes[0], s2],
    );

    // --- Lọc theo yearId, trước khi phân trang ---
    const idsOf = <T extends Record<string, unknown>>(
      page: Page<T>,
      key: string,
    ) => page.items.map((item) => item[key] as number);
    const path = (list: string, params: Record<string, string | number>) =>
      `${list}?${new URLSearchParams(Object.entries(params).map(([k, v]) => [k, String(v)]))}`;
    const fromMine = firstClass - 1;

    const classesPage1 = await get<Page<Record<string, unknown>>>(
      admin.token,
      path("/catalog/classes", { yearId: y1 }),
    );
    // Cùng một năm: phân trang đúng (50 + 5), không lẫn lớp của năm khác dù mã nhỏ hơn.
    const collected: number[] = [];
    let page = await get<Page<Record<string, unknown>>>(
      admin.token,
      path("/catalog/classes", { yearId: y1, cursor: fromMine }),
    );
    assert.equal(page.items.length, 50);
    assert.ok(page.nextCursor);
    collected.push(...idsOf(page, "ma_lop"));
    page = await get(
      admin.token,
      path("/catalog/classes", {
        yearId: y1,
        cursor: page.nextCursor!,
      }),
    );
    assert.equal(page.items.length, 5);
    assert.equal(page.nextCursor, null);
    collected.push(...idsOf(page, "ma_lop"));
    assert.deepEqual(collected, y1Classes);
    assert.ok(
      classesPage1.items.every((item) => item.ma_nam_hoc === y1),
      "trang đầu chỉ có lớp của năm 1",
    );
    assert.deepEqual(
      idsOf(
        await get<Page<Record<string, unknown>>>(
          admin.token,
          path("/catalog/classes", { yearId: y2 }),
        ),
        "ma_lop",
      ),
      y2Classes,
    );
    // Không truyền yearId: như cũ, thấy lớp của mọi năm.
    const unfiltered = await get<Page<Record<string, unknown>>>(
      admin.token,
      path("/catalog/classes", { cursor: fromMine }),
    );
    assert.deepEqual(
      [...new Set(unfiltered.items.map((item) => item.ma_nam_hoc))].sort(),
      [y1, y2].sort(),
    );

    const semesters = (year: number) =>
      get<Page<Record<string, unknown>>>(
        admin.token,
        path("/catalog/semesters", { yearId: year }),
      );
    assert.deepEqual(idsOf(await semesters(y1), "ma_hoc_ky"), [s1a, s1b]);
    assert.deepEqual(idsOf(await semesters(y2), "ma_hoc_ky"), [s2]);

    const students = async (year?: number) =>
      (
        await get<Page<Record<string, unknown>>>(
          admin.token,
          path("/catalog/students", {
            ...(year ? { yearId: year } : {}),
            q: "Học sinh Y",
          }),
        )
      ).items.map((item) => item.ho_ten as string);
    assert.deepEqual((await students(y1)).sort(), [
      "Học sinh Y1 hai",
      "Học sinh Y1 một",
    ]);
    assert.deepEqual(await students(y2), ["Học sinh Y2 một"]);
    assert.equal((await students()).length >= 3, true);

    const assignmentsIn = async (year: number) =>
      idsOf(
        await get<Page<Record<string, unknown>>>(
          admin.token,
          path("/catalog/assignments", { yearId: year }),
        ),
        "ma_hoc_ky",
      ).filter((term) => [s1a, s1b, s2].includes(term));
    assert.deepEqual(await assignmentsIn(y1), [s1a]);
    assert.deepEqual(await assignmentsIn(y2), [s2, s2]);

    const weightsIn = async (year: number) =>
      idsOf(
        await get<Page<Record<string, unknown>>>(
          admin.token,
          path("/catalog/semester-weights", { yearId: year }),
        ),
        "ma_hoc_ky",
      ).filter((term) => [s1a, s2].includes(term));
    assert.deepEqual(await weightsIn(y1), [s1a]);
    assert.deepEqual(await weightsIn(y2), [s2]);

    const gradebooksIn = async (year?: number) =>
      (
        await get<Page<Record<string, unknown>>>(
          admin.token,
          path("/gradebooks", { ...(year ? { yearId: year } : {}) }),
        )
      ).items.map((item) => item.termId) as number[];
    const inMine = (terms: number[]) =>
      terms.filter((term) => [s1a, s2].includes(term)).sort();
    // Phân trang của bảng điểm cũng theo năm: lọc rồi mới cắt trang nên không thiếu bảng của năm 1.
    assert.deepEqual(inMine(await gradebooksIn(y1)), [s1a, s1a]);
    assert.deepEqual(inMine(await gradebooksIn(y2)), [s2]);

    // Giáo viên: activeInYearId chỉ gồm người có phân công trong năm đó.
    const teachersIn = async (year?: number) =>
      idsOf(
        await get<Page<Record<string, unknown>>>(
          admin.token,
          path("/catalog/teachers", {
            ...(year ? { activeInYearId: year } : {}),
            cursor: Math.min(teacherOne.id, teacherTwo.id) - 1,
          }),
        ),
        "ma_giao_vien",
      ).filter((id) => [teacherOne.id, teacherTwo.id].includes(id));
    assert.deepEqual(await teachersIn(y1), [teacherOne.id]);
    assert.deepEqual(
      (await teachersIn(y2)).sort(),
      [teacherOne.id, teacherTwo.id].sort(),
    );
    assert.equal((await teachersIn()).length, 2);

    // Năm không tồn tại: danh sách rỗng. Tham số sai: 400. Giáo viên vẫn bị giới hạn theo phạm vi của mình.
    assert.deepEqual(
      (
        await get<Page<unknown>>(
          admin.token,
          path("/catalog/classes", { yearId: 2_000_000_000 }),
        )
      ).items,
      [],
    );
    for (const list of [
      "/catalog/classes",
      "/catalog/semesters",
      "/catalog/students",
      "/catalog/assignments",
      "/catalog/semester-weights",
      "/gradebooks",
    ])
      for (const bad of ["abc", "0", "-3", "1.5", "99999999999"])
        assert.equal(
          (await call(admin.token, "GET", path(list, { yearId: bad }))).status,
          400,
          `${list} ${bad}`,
        );
    for (const bad of ["abc", "0"])
      assert.equal(
        (
          await call(
            admin.token,
            "GET",
            path("/catalog/teachers", { activeInYearId: bad }),
          )
        ).status,
        400,
      );
    const teacherView = await get<Page<Record<string, unknown>>>(
      teacherTwo.token,
      path("/catalog/classes", { yearId: y2 }),
    );
    assert.deepEqual(idsOf(teacherView, "ma_lop"), [y2Classes[1]]);

    // --- Chuyển năm hiện hành ---
    const save = (
      method: "POST" | "PUT",
      year: number | null,
      current: boolean,
    ) =>
      call(
        admin.token,
        method,
        year ? `/catalog/years/${year}` : "/catalog/years",
        {
          ten: year === y2 ? `Y2-${suffix}` : `Y1-${suffix}`,
          ngay_bat_dau: year === y2 ? "2027-09-01" : "2026-09-01",
          ngay_ket_thuc: year === y2 ? "2028-06-01" : "2027-06-01",
          hien_hanh: current,
        },
      );
    assert.equal((await save("PUT", y1, true)).status, 200);
    assert.deepEqual(await currentYears(), [y1]);
    // Bật năm khác: năm cũ tự tắt trong cùng giao dịch, luôn đúng một năm hiện hành.
    assert.equal((await save("PUT", y2, true)).status, 200);
    assert.deepEqual(await currentYears(), [y2]);
    // Tạo mới một năm hiện hành cũng chuyển.
    const created = await call(admin.token, "POST", "/catalog/years", {
      ten: `Y3-${suffix}`,
      ngay_bat_dau: "2028-09-01",
      ngay_ket_thuc: "2029-06-01",
      hien_hanh: true,
    });
    assert.equal(created.status, 200);
    const y3 = ((await created.json()) as { ma_nam_hoc: number }).ma_nam_hoc;
    assert.deepEqual(await currentYears(), [y3]);
    // Hai yêu cầu chuyển song song: không bao giờ có hai năm hiện hành (chỉ mục duy nhất một phần sẽ lộ ra nếu không nguyên tử).
    const race = await Promise.all([
      save("PUT", y1, true),
      save("PUT", y2, true),
    ]);
    assert.ok(race.some((response) => response.status === 200));
    assert.equal((await currentYears()).length, 1);
    assert.equal(
      Number(
        (
          await owner.query(
            "SELECT count(*) FROM nhat_ky_bao_mat WHERE hanh_dong='ACADEMIC_YEAR_SWITCHED' AND doi_tuong=$1",
            [`nam_hoc:${y2}`],
          )
        ).rows[0].count,
      ) >= 1,
      true,
    );
    // Tắt năm hiện hành duy nhất: 409 với thông báo tiếng Việt, không đổi gì.
    const [onlyCurrent] = await currentYears();
    const refused = await save("PUT", onlyCurrent === y2 ? y2 : y1, false);
    assert.equal(refused.status, 409);
    assert.match(
      JSON.stringify(await refused.json()),
      /Phải có một năm học hiện hành; hãy bật năm khác để chuyển\./,
    );
    assert.deepEqual(await currentYears(), [onlyCurrent]);
    // Không xóa được năm đang hiện hành (409 tiếng Việt, năm vẫn còn); năm không hiện hành và chưa dùng thì xóa được.
    const deleteCurrent = await call(
      admin.token,
      "DELETE",
      `/catalog/years/${onlyCurrent}`,
    );
    assert.equal(deleteCurrent.status, 409);
    assert.match(
      JSON.stringify(await deleteCurrent.json()),
      /Không thể xóa năm học hiện hành; hãy chuyển năm hiện hành sang năm khác trước\./,
    );
    assert.deepEqual(await currentYears(), [onlyCurrent]);
    assert.equal(
      (await call(teacherOne.token, "DELETE", `/catalog/years/${y3}`)).status,
      403,
    );
    assert.equal(
      (await call(admin.token, "DELETE", `/catalog/years/${y3}`)).status,
      204,
    );
    assert.equal(
      Number(
        (
          await owner.query(
            "SELECT count(*) FROM nam_hoc WHERE ma_nam_hoc=$1",
            [y3],
          )
        ).rows[0].count,
      ),
      0,
    );
    assert.deepEqual(await currentYears(), [onlyCurrent]);

    // --- Tóm tắt việc còn dang dở ---
    assert.equal(
      (await call(admin.token, "GET", `/catalog/years/${y1}/pending-summary`))
        .status,
      200,
    );
    assert.deepEqual(
      await get(admin.token, `/catalog/years/${y1}/pending-summary`),
      {
        openGradebooks: 2,
        pendingRecognitionTickets: 0,
        unpublishedSemesters: 2,
      },
    );
    assert.equal(
      (
        await call(
          admin.token,
          "GET",
          "/catalog/years/2000000000/pending-summary",
        )
      ).status,
      404,
    );
    assert.equal(
      (
        await call(
          teacherOne.token,
          "GET",
          `/catalog/years/${y1}/pending-summary`,
        )
      ).status,
      403,
    );
    assert.equal(
      (await call(null, "GET", `/catalog/years/${y1}/pending-summary`)).status,
      401,
    );
    assert.equal(
      (await call(admin.token, "GET", "/catalog/years/abc/pending-summary"))
        .status,
      400,
    );

    const fixture = await createRosterFixture();
    try {
      const fixtureYear: number = (
        await fixture.owner.query(
          "SELECT ma_nam_hoc FROM lop WHERE ma_lop=$1",
          [fixture.cls],
        )
      ).rows[0].ma_nam_hoc;
      const summary = () =>
        get(admin.token, `/catalog/years/${fixtureYear}/pending-summary`);
      assert.deepEqual(await summary(), {
        openGradebooks: 1,
        pendingRecognitionTickets: 0,
        unpublishedSemesters: 1,
      });
      const ticket = await fixture.createTicket(fixture.valid, "pending-1");
      assert.equal(
        ((await summary()) as { pendingRecognitionTickets: number })
          .pendingRecognitionTickets,
        1,
      );
      await fixture.owner.query(
        "UPDATE phieu_nhan_dien SET trang_thai='CHO_DOI_CHIEU', so_dong_nhan_dien=1 WHERE ma_phieu=$1",
        [ticket.ticketId],
      );
      assert.equal(
        ((await summary()) as { pendingRecognitionTickets: number })
          .pendingRecognitionTickets,
        1,
      );
      // Phiếu đã hủy hoặc đã duyệt không còn là việc dang dở.
      await fixture.owner.query(
        "UPDATE phieu_nhan_dien SET trang_thai='DA_HUY', ly_do_huy='x', nguoi_huy=$2, thoi_diem_huy=now() WHERE ma_phieu=$1",
        [ticket.ticketId, fixture.teacherId],
      );
      assert.equal(
        ((await summary()) as { pendingRecognitionTickets: number })
          .pendingRecognitionTickets,
        0,
      );
      // Công bố học kỳ cần đủ kết quả tổng kết (trigger kiem_cong_bo) nên ở đây chỉ chốt bảng điểm.
      await fixture.owner.query(
        "UPDATE bang_diem SET trang_thai='DA_CHOT' WHERE ma_bang_diem=$1",
        [fixture.book],
      );
      assert.deepEqual(await summary(), {
        openGradebooks: 0,
        pendingRecognitionTickets: 0,
        unpublishedSemesters: 1,
      });
    } finally {
      await fixture.close();
    }
  } finally {
    // Trả năm hiện hành về như trước khi chạy test (DB *_test dùng chung với các test khác).
    await owner.query("UPDATE nam_hoc SET hien_hanh=false WHERE hien_hanh");
    if (originalCurrent.length)
      await owner.query(
        "UPDATE nam_hoc SET hien_hanh=true WHERE ma_nam_hoc=$1",
        [originalCurrent[0]],
      );
    await app.close();
    await owner.end();
  }
});

test("timetable without semesterId shows the semester running today in the current year", async () => {
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
  const originalCurrent: number[] = (
    await owner.query("SELECT ma_nam_hoc FROM nam_hoc WHERE hien_hanh")
  ).rows.map((row) => row.ma_nam_hoc);
  try {
    const adminId: number = (
      await owner.query(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'test-only','QUAN_TRI_VIEN') RETURNING ma_nguoi_dung",
        [`tt_${suffix}`],
      )
    ).rows[0].ma_nguoi_dung;
    const token = randomBytes(32).toString("hex");
    await owner.query(
      "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
      [
        createHash("sha256").update(token).digest("hex"),
        adminId,
        randomBytes(32).toString("hex"),
      ],
    );
    await owner.query(
      "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'GV TKB giả')",
      [adminId],
    );
    // Ngày theo giờ Việt Nam như service dùng; học kỳ 1 đã qua, học kỳ 2 đang chạy: mặc định phải là học kỳ 2, không phải học kỳ đầu.
    const day = (offset: number) =>
      new Date(Date.now() + 7 * 3_600_000 + offset * 86_400_000)
        .toISOString()
        .slice(0, 10);
    await owner.query("UPDATE nam_hoc SET hien_hanh=false WHERE hien_hanh");
    const year: number = (
      await owner.query(
        "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc,hien_hanh) VALUES($1,$2,$3,true) RETURNING ma_nam_hoc",
        [`TT-${suffix}`, day(-200), day(200)],
      )
    ).rows[0].ma_nam_hoc;
    const term = async (
      name: string,
      order: number,
      from: string,
      to: string,
    ) =>
      (
        await owner.query(
          "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,$2,$3,$4,$5) RETURNING ma_hoc_ky",
          [year, name, order, from, to],
        )
      ).rows[0].ma_hoc_ky as number;
    const past = await term("HK1", 1, day(-190), day(-10));
    const running = await term("HK2", 2, day(-9), day(190));
    const cls: number = (
      await owner.query(
        "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,'tkb',10) RETURNING ma_lop",
        [year, adminId],
      )
    ).rows[0].ma_lop;
    const subject: number = (
      await owner.query(
        "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,2) RETURNING ma_mon",
        [`TKB-${suffix}`],
      )
    ).rows[0].ma_mon;
    for (const [termId, tiet] of [
      [past, 1],
      [running, 2],
    ] as const)
      await owner.query(
        "INSERT INTO thoi_khoa_bieu(ma_lop,ma_mon,ma_giao_vien,ma_hoc_ky,thu,tiet) VALUES($1,$2,$3,$4,2,$5)",
        [cls, subject, adminId, termId, tiet],
      );
    const list = async (query = "") => {
      const response = await fetch(`${base}/timetable?classId=${cls}${query}`, {
        headers: { authorization: `Bearer ${token}` },
      });
      assert.equal(response.status, 200);
      return (
        (await response.json()) as { items: Array<{ ma_hoc_ky: number }> }
      ).items.map((item) => item.ma_hoc_ky);
    };
    assert.deepEqual(await list(), [running]);
    // Truyền semesterId rõ ràng thì giữ nguyên như cũ.
    assert.deepEqual(await list(`&semesterId=${past}`), [past]);
    // Hôm nay nằm giữa hai học kỳ → học kỳ đầu như cũ.
    await owner.query("UPDATE hoc_ky SET ngay_ket_thuc=$2 WHERE ma_hoc_ky=$1", [
      past,
      day(-20),
    ]);
    await owner.query("UPDATE hoc_ky SET ngay_bat_dau=$2 WHERE ma_hoc_ky=$1", [
      running,
      day(5),
    ]);
    assert.deepEqual(await list(), [past]);
  } finally {
    await owner.query("UPDATE nam_hoc SET hien_hanh=false WHERE hien_hanh");
    if (originalCurrent.length)
      await owner.query(
        "UPDATE nam_hoc SET hien_hanh=true WHERE ma_nam_hoc=$1",
        [originalCurrent[0]],
      );
    await app.close();
    await owner.end();
  }
});
