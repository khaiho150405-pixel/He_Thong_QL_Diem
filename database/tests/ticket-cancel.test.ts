import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import { test } from "node:test";
import { createRosterFixture } from "../../apps/api/test/integration/roster-fixture.js";

// Hủy mềm phiếu nhận dạng (ADR-0015): hàm huy_phieu_nhan_dien, ràng buộc cột hủy, chỉ mục duy nhất một phần theo checksum.
// Dữ liệu hoàn toàn giả; chỉ chạy trên DB có tên kết thúc _test (fixture tự kiểm).

type Fixture = Awaited<ReturnType<typeof createRosterFixture>>;
type Failure = { code?: string; message?: string };

const hash = (n: number) => String(n).repeat(64).slice(0, 64);
const failsWith = (code: string, text: string) => (error: Failure) =>
  error.code === code && String(error.message).includes(text);

async function stateOf(f: Fixture, ticket: string) {
  return (
    await f.owner.query(
      `SELECT trang_thai::text AS status, version, ly_do_huy, nguoi_huy, thoi_diem_huy
       FROM phieu_nhan_dien WHERE ma_phieu=$1`,
      [ticket],
    )
  ).rows[0];
}

function cancel(
  f: Fixture,
  ticket: string,
  version: number,
  options: {
    reason?: string;
    key?: string;
    requestHash?: string;
    session?: string;
    book?: number;
  } = {},
) {
  return f.serializable(
    async (query) =>
      (
        await query(
          "SELECT public.huy_phieu_nhan_dien($1,$2,$3,$4,$5,$6,$7) AS result",
          [
            options.session ?? f.session,
            options.book ?? f.book,
            ticket,
            version,
            options.reason ?? "Chụp nhầm bảng điểm",
            options.key ?? `cancel-${randomBytes(6).toString("hex")}`,
            options.requestHash ?? hash(1),
          ],
        )
      ).rows[0].result,
  );
}

const channel = (value: string) => ({
  rawOutput: value,
  value,
  confidence: "0.95",
  isBlank: false,
});

// Kết quả nhận dạng giả cho các dòng 1..count (thứ tự STT hệ thống).
const recognitionRows = (ticket: string, count: number) =>
  Array.from({ length: count }, (_, index) => ({
    order: index + 1,
    stt: index + 1,
    sttOnPaper: null,
    nameRead: "Họ tên đọc được giả",
    matchConfidence: 0.97,
    matchNote: "Khớp họ tên",
    numeric: channel("8.0"),
    written: channel("8.0"),
    numericCropKey: `recognition/crops/${ticket}/${index + 1}-numeric.png`,
    writtenCropKey: `recognition/crops/${ticket}/${index + 1}-written.png`,
    nameCropKey: `recognition/crops/${ticket}/${index + 1}-name.png`,
    comparison: "KHOP",
    reviewLevel: "XANH",
    suggestedSource: "SO",
    matchLevel: "XANH",
  }));

const saveResults = (f: Fixture, ticket: string, count = 3) =>
  f.serializable((query) =>
    query("SELECT public.luu_ket_qua_nhan_dien($1,$2,$3::jsonb)", [
      ticket,
      "fake-test-v1",
      JSON.stringify(recognitionRows(ticket, count)),
    ]),
  );

async function approve(f: Fixture, ticket: string) {
  const evidence = (
    await f.owner.query(
      "SELECT ma_dong FROM ket_qua_dong WHERE ma_phieu=$1 ORDER BY thu_tu_dong",
      [ticket],
    )
  ).rows;
  const versions = (
    await f.owner.query(
      "SELECT t.version AS ticket_version,b.version AS book_version FROM phieu_nhan_dien t JOIN bang_diem b USING(ma_bang_diem) WHERE t.ma_phieu=$1",
      [ticket],
    )
  ).rows[0];
  await f.serializable((query) =>
    query(
      "SELECT public.duyet_phieu_nhan_dien($1,$2,$3,$4,$5,$6::jsonb,$7,$8)",
      [
        f.session,
        f.book,
        ticket,
        versions.ticket_version,
        versions.book_version,
        JSON.stringify(
          evidence.map((row) => ({
            rowId: String(row.ma_dong),
            value: "8.0",
            reason: "Đối chiếu ảnh giả",
          })),
        ),
        `approve-${randomBytes(6).toString("hex")}`,
        hash(2),
      ],
    ),
  );
}

async function otherTeacher(f: Fixture) {
  const id: number = (
    await f.owner.query(
      "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'test-only','GIAO_VIEN') RETURNING ma_nguoi_dung",
      [`other_${randomBytes(5).toString("hex")}`],
    )
  ).rows[0].ma_nguoi_dung;
  const session = createHash("sha256").update(randomBytes(32)).digest("hex");
  await f.owner.query(
    "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
    [session, id, randomBytes(32).toString("hex")],
  );
  await f.owner.query(
    "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'GV khác giả')",
    [id],
  );
  return { id, session };
}

const countOf = async (f: Fixture, table: string, ticket: string) =>
  Number(
    (
      await f.owner.query(`SELECT count(*) FROM ${table} WHERE ma_phieu=$1`, [
        ticket,
      ])
    ).rows[0].count,
  );

test("cancel works from DANG_XU_LY, keeps every row of evidence and stops the outbox", async () => {
  const f = await createRosterFixture();
  try {
    const { ticketId } = await f.createTicket(f.valid, "cancel-processing");
    const before = await stateOf(f, ticketId);
    assert.equal(before.status, "DANG_XU_LY");
    const result = await cancel(f, ticketId, before.version, {
      reason: "  Chụp nhầm bảng điểm  ",
    });
    assert.deepEqual(result, {
      ticketId,
      ticketVersion: before.version + 1,
      gradebookId: f.book,
      status: "DA_HUY",
    });
    const after = await stateOf(f, ticketId);
    assert.equal(after.status, "DA_HUY");
    assert.equal(after.version, before.version + 1);
    assert.equal(after.ly_do_huy, "Chụp nhầm bảng điểm");
    assert.equal(after.nguoi_huy, f.teacherId);
    assert.ok(after.thoi_diem_huy instanceof Date);
    // Không xóa cứng: danh sách lớp đã chốt vẫn còn đủ 4 học sinh.
    assert.equal(await countOf(f, "danh_sach_phieu", ticketId), 4);
    // Dispatcher không gửi lại sự kiện của phiếu đã hủy.
    const outbox = (
      await f.owner.query(
        "SELECT da_gui_luc IS NOT NULL AS sent, loi_cuoi FROM recognition_outbox WHERE ma_phieu=$1",
        [ticketId],
      )
    ).rows[0];
    assert.deepEqual(outbox, { sent: true, loi_cuoi: "TICKET_CANCELLED" });
    const audit = (
      await f.owner.query(
        "SELECT ma_tac_nhan FROM nhat_ky_bao_mat WHERE hanh_dong='RECOGNITION_CANCELLED' AND doi_tuong=$1",
        [`phieu_nhan_dien:${ticketId}`],
      )
    ).rows;
    assert.deepEqual(
      audit.map((row) => row.ma_tac_nhan),
      [f.teacherId],
    );
  } finally {
    await f.close();
  }
});

test("cancel works from CHO_DOI_CHIEU without touching rows or official grades", async () => {
  const f = await createRosterFixture();
  try {
    const { ticketId } = await f.createTicket(f.valid, "cancel-review");
    await saveResults(f, ticketId, 3);
    const before = await stateOf(f, ticketId);
    assert.equal(before.status, "CHO_DOI_CHIEU");
    const gradesBefore = (
      await f.owner.query(
        "SELECT count(*) FROM diem_thanh_phan WHERE ma_bang_diem=$1 AND gia_tri IS NOT NULL",
        [f.book],
      )
    ).rows[0].count;
    await cancel(f, ticketId, before.version);
    assert.equal((await stateOf(f, ticketId)).status, "DA_HUY");
    assert.equal(await countOf(f, "ket_qua_dong", ticketId), 3);
    assert.equal(await countOf(f, "danh_sach_phieu", ticketId), 4);
    // Máy chỉ đề xuất: hủy không ghi điểm, không tạo lịch sử.
    assert.equal(
      (
        await f.owner.query(
          "SELECT count(*) FROM diem_thanh_phan WHERE ma_bang_diem=$1 AND gia_tri IS NOT NULL",
          [f.book],
        )
      ).rows[0].count,
      gradesBefore,
    );
    // Phiếu đã hủy không còn duyệt được.
    await assert.rejects(
      approve(f, ticketId),
      failsWith("23514", "TICKET_VERSION_OR_STATE_CONFLICT"),
    );
  } finally {
    await f.close();
  }
});

test("cancel works from LOI", async () => {
  const f = await createRosterFixture();
  try {
    const { ticketId } = await f.createTicket(f.valid, "cancel-error");
    await f.serializable((query) =>
      query("SELECT public.danh_dau_phieu_nhan_dien_loi($1,$2)", [
        ticketId,
        "IMAGE_QUALITY_LOW",
      ]),
    );
    const before = await stateOf(f, ticketId);
    assert.equal(before.status, "LOI");
    await cancel(f, ticketId, before.version);
    const after = await stateOf(f, ticketId);
    assert.equal(after.status, "DA_HUY");
    assert.equal(after.version, before.version + 1);
  } finally {
    await f.close();
  }
});

test("an approved ticket cannot be cancelled and stays untouched", async () => {
  const f = await createRosterFixture();
  try {
    const { ticketId } = await f.createTicket(f.valid, "cancel-approved");
    await saveResults(f, ticketId, 3);
    await approve(f, ticketId);
    const before = await stateOf(f, ticketId);
    assert.equal(before.status, "DA_DUYET");
    await assert.rejects(
      cancel(f, ticketId, before.version),
      failsWith("23514", "TICKET_ALREADY_APPROVED"),
    );
    // Cả khi gửi sai version: trạng thái đã duyệt được báo trước.
    await assert.rejects(
      cancel(f, ticketId, before.version + 7),
      failsWith("23514", "TICKET_ALREADY_APPROVED"),
    );
    assert.deepEqual(await stateOf(f, ticketId), before);
  } finally {
    await f.close();
  }
});

test("cancelling twice is idempotent: the first reason, actor and time are kept", async () => {
  const f = await createRosterFixture();
  try {
    const { ticketId } = await f.createTicket(f.valid, "cancel-twice");
    const version = (await stateOf(f, ticketId)).version;
    const first = await cancel(f, ticketId, version, {
      key: "same-key",
      requestHash: hash(3),
      reason: "Lý do đầu tiên",
    });
    const cancelled = await stateOf(f, ticketId);
    // Cùng khóa + cùng yêu cầu: trả đúng kết quả đã lưu.
    assert.deepEqual(
      await cancel(f, ticketId, version, {
        key: "same-key",
        requestHash: hash(3),
        reason: "Lý do đầu tiên",
      }),
      first,
    );
    // Cùng khóa nhưng nội dung khác: từ chối.
    await assert.rejects(
      cancel(f, ticketId, version, {
        key: "same-key",
        requestHash: hash(4),
        reason: "Lý do khác",
      }),
      failsWith("23505", "IDEMPOTENCY_MISMATCH"),
    );
    // Khóa mới, version cũ lẫn mới, lý do khác: phiếu đã hủy được trả lại nguyên trạng.
    for (const staleVersion of [version, version + 1, version + 9]) {
      const again = await cancel(f, ticketId, staleVersion, {
        reason: "Lý do thứ hai",
      });
      assert.equal(again.status, "DA_HUY");
      assert.equal(again.ticketVersion, cancelled.version);
    }
    assert.deepEqual(await stateOf(f, ticketId), cancelled);
    assert.equal(
      Number(
        (
          await f.owner.query(
            "SELECT count(*) FROM nhat_ky_bao_mat WHERE hanh_dong='RECOGNITION_CANCELLED' AND doi_tuong=$1",
            [`phieu_nhan_dien:${ticketId}`],
          )
        ).rows[0].count,
      ),
      1,
    );
  } finally {
    await f.close();
  }
});

test("a stale version is rejected without changing the ticket", async () => {
  const f = await createRosterFixture();
  try {
    const { ticketId } = await f.createTicket(f.valid, "cancel-version");
    const before = await stateOf(f, ticketId);
    for (const wrong of [before.version + 1, before.version + 100])
      await assert.rejects(
        cancel(f, ticketId, wrong),
        failsWith("23514", "VERSION_CONFLICT"),
      );
    assert.deepEqual(await stateOf(f, ticketId), before);
  } finally {
    await f.close();
  }
});

test("the reason must have 1 to 200 characters after trimming", async () => {
  const f = await createRosterFixture();
  try {
    const { ticketId } = await f.createTicket(f.valid, "cancel-reason");
    const version = (await stateOf(f, ticketId)).version;
    for (const bad of ["", "   ", "x".repeat(201)])
      await assert.rejects(
        cancel(f, ticketId, version, { reason: bad }),
        failsWith("23514", "INVALID_CANCEL_REQUEST"),
      );
    for (const badVersion of [-1])
      await assert.rejects(
        cancel(f, ticketId, badVersion),
        failsWith("23514", "INVALID_CANCEL_REQUEST"),
      );
    for (const badKey of ["", "có dấu", "a".repeat(65)])
      await assert.rejects(
        cancel(f, ticketId, version, { key: badKey }),
        failsWith("23514", "INVALID_CANCEL_REQUEST"),
      );
    assert.equal((await stateOf(f, ticketId)).status, "DANG_XU_LY");
    await cancel(f, ticketId, version, { reason: "y".repeat(200) });
    assert.equal((await stateOf(f, ticketId)).ly_do_huy?.length, 200);
  } finally {
    await f.close();
  }
});

test("after a cancel the same image can be uploaded again and cancelled repeatedly, but never twice at once", async () => {
  const f = await createRosterFixture();
  try {
    const checksum = randomBytes(32).toString("hex");
    const first = await f.createTicket(f.valid, "again-1", hash(5), checksum);
    // Đang có phiếu chưa hủy cùng ảnh: DUPLICATE_FILE.
    await assert.rejects(
      f.createTicket(f.valid, "again-dup", hash(6), checksum),
      failsWith("23505", "DUPLICATE_FILE"),
    );
    await cancel(f, first.ticketId, (await stateOf(f, first.ticketId)).version);
    // Phiếu DA_HUY không gây DUPLICATE_FILE lẫn RECOGNITION_ALREADY_PENDING.
    const second = await f.createTicket(f.valid, "again-2", hash(7), checksum);
    assert.notEqual(second.ticketId, first.ticketId);
    await cancel(
      f,
      second.ticketId,
      (await stateOf(f, second.ticketId)).version,
    );
    const third = await f.createTicket(f.valid, "again-3", hash(8), checksum);
    const sameChecksum = (
      await f.owner.query(
        "SELECT trang_thai::text AS status FROM phieu_nhan_dien WHERE ma_bam_tep=$1 ORDER BY ma_phieu",
        [checksum],
      )
    ).rows.map((row) => row.status);
    assert.deepEqual(sameChecksum, ["DA_HUY", "DA_HUY", "DANG_XU_LY"]);
    // Chỉ mục duy nhất một phần chặn cả ghi trực tiếp một phiếu chưa hủy thứ hai.
    await assert.rejects(
      f.owner.query(
        `INSERT INTO phieu_nhan_dien(ma_bang_diem,ma_thanh_phan,nguoi_tai,ma_bam_tep,duong_dan_anh_goc,so_dong_khai_bao)
         VALUES($1,$2,$3,$4,'recognition/original/x.png',4)`,
        [f.book, f.component, f.teacherId, checksum],
      ),
      (error: Failure) => error.code === "23505",
    );
    await cancel(f, third.ticketId, (await stateOf(f, third.ticketId)).version);
  } finally {
    await f.close();
  }
});

test("a cancelled ticket is not a pending ticket: a new upload for the same component is allowed, a pending one still blocks", async () => {
  const f = await createRosterFixture();
  try {
    const first = await f.createTicket(f.valid, "pending-1");
    await assert.rejects(
      f.createTicket(f.valid, "pending-2"),
      failsWith("23514", "RECOGNITION_ALREADY_PENDING"),
    );
    await cancel(f, first.ticketId, (await stateOf(f, first.ticketId)).version);
    const second = await f.createTicket(f.valid, "pending-3");
    assert.equal(second.status, "DANG_XU_LY");
    await assert.rejects(
      f.createTicket(f.valid, "pending-4"),
      failsWith("23514", "RECOGNITION_ALREADY_PENDING"),
    );
  } finally {
    await f.close();
  }
});

test("a cancelled ticket does not block manual grade entry on its component", async () => {
  const f = await createRosterFixture();
  try {
    const edit = async () => {
      const cell = (
        await f.owner.query(
          "SELECT ma_diem FROM diem_thanh_phan WHERE ma_bang_diem=$1 AND ma_hoc_sinh=$2",
          [f.book, f.students.an],
        )
      ).rows[0].ma_diem;
      const version = (
        await f.owner.query(
          "SELECT version FROM bang_diem WHERE ma_bang_diem=$1",
          [f.book],
        )
      ).rows[0].version;
      return f.serializable((query) =>
        query("SELECT public.cap_nhat_diem($1,$2,$3,$4::jsonb)", [
          f.session,
          f.book,
          version,
          JSON.stringify([
            { cellId: String(cell), value: "7.5", reason: "Nhập tay giả" },
          ]),
        ]),
      );
    };
    const { ticketId } = await f.createTicket(f.valid, "manual-entry");
    await assert.rejects(edit(), failsWith("23514", "CELL_NOT_EDITABLE"));
    await cancel(f, ticketId, (await stateOf(f, ticketId)).version);
    await edit();
    assert.equal(
      (
        await f.owner.query(
          "SELECT gia_tri::text AS value FROM diem_thanh_phan WHERE ma_bang_diem=$1 AND ma_hoc_sinh=$2",
          [f.book, f.students.an],
        )
      ).rows[0].value,
      "7.5",
    );
  } finally {
    await f.close();
  }
});

test("saving worker results for a cancelled ticket is a silent no-op", async () => {
  const f = await createRosterFixture();
  try {
    const { ticketId } = await f.createTicket(f.valid, "late-result");
    await cancel(f, ticketId, (await stateOf(f, ticketId)).version);
    const before = await stateOf(f, ticketId);
    await saveResults(f, ticketId, 3);
    assert.equal(await countOf(f, "ket_qua_dong", ticketId), 0);
    assert.deepEqual(await stateOf(f, ticketId), before);
    // Dù kết quả sai hình dạng nhưng đã qua kiểm tra chung thì vẫn không ghi gì (không raise TICKET_NOT_PROCESSING).
    await f.serializable((query) =>
      query("SELECT public.luu_ket_qua_nhan_dien($1,$2,$3::jsonb)", [
        ticketId,
        "fake-test-v1",
        JSON.stringify([]),
      ]),
    );
    assert.equal(await countOf(f, "ket_qua_dong", ticketId), 0);
    // Đánh dấu lỗi sau khi hủy cũng không đổi trạng thái.
    await f.serializable((query) =>
      query("SELECT public.danh_dau_phieu_nhan_dien_loi($1,$2)", [
        ticketId,
        "IMAGE_QUALITY_LOW",
      ]),
    );
    assert.equal((await stateOf(f, ticketId)).status, "DA_HUY");
  } finally {
    await f.close();
  }
});

test("only the assigned teacher or the uploader may cancel; others get 42501, unknown book or ticket gets not found", async () => {
  const f = await createRosterFixture();
  try {
    const { ticketId } = await f.createTicket(f.valid, "cancel-authz");
    const version = (await stateOf(f, ticketId)).version;
    const stranger = await otherTeacher(f);
    await assert.rejects(
      cancel(f, ticketId, version, { session: stranger.session }),
      (error: Failure) => error.code === "42501",
    );
    // Phiên hết hạn hoặc không tồn tại.
    await assert.rejects(
      cancel(f, ticketId, version, { session: hash(9) }),
      (error: Failure) => error.code === "42501",
    );
    // Bảng điểm không tồn tại / phiếu không thuộc bảng điểm.
    await assert.rejects(
      cancel(f, ticketId, version, { book: 2_000_000_000 }),
      (error: Failure) => error.code === "P0002",
    );
    await assert.rejects(
      cancel(f, "9000000000000000000", version),
      (error: Failure) => error.code === "P0002",
    );
    assert.equal((await stateOf(f, ticketId)).status, "DANG_XU_LY");
  } finally {
    await f.close();
  }
});

test("the uploader may cancel even after the assignment was removed", async () => {
  const f = await createRosterFixture();
  try {
    const { ticketId } = await f.createTicket(f.valid, "cancel-uploader");
    const version = (await stateOf(f, ticketId)).version;
    await f.owner.query(
      "DELETE FROM phan_cong_giang_day WHERE ma_giao_vien=$1",
      [f.teacherId],
    );
    await cancel(f, ticketId, version);
    assert.equal((await stateOf(f, ticketId)).status, "DA_HUY");
  } finally {
    await f.close();
  }
});

test("cancel columns are all-or-nothing and tied to DA_HUY by a CHECK constraint", async () => {
  const f = await createRosterFixture();
  try {
    const { ticketId } = await f.createTicket(f.valid, "cancel-check");
    const attempt = (sql: string) =>
      assert.rejects(
        f.owner.query(
          sql,
          sql.includes("$2") ? [ticketId, f.teacherId] : [ticketId],
        ),
        (error: Failure) => error.code === "23514",
      );
    // DA_HUY thiếu một trong ba cột.
    await attempt(
      "UPDATE phieu_nhan_dien SET trang_thai='DA_HUY' WHERE ma_phieu=$1",
    );
    await attempt(
      "UPDATE phieu_nhan_dien SET trang_thai='DA_HUY', ly_do_huy='x', nguoi_huy=$2 WHERE ma_phieu=$1",
    );
    // Có cột hủy nhưng không ở DA_HUY.
    await attempt(
      "UPDATE phieu_nhan_dien SET ly_do_huy='x', nguoi_huy=$2, thoi_diem_huy=now() WHERE ma_phieu=$1",
    );
    // Lý do chỉ gồm khoảng trắng.
    await attempt(
      "UPDATE phieu_nhan_dien SET trang_thai='DA_HUY', ly_do_huy='   ', nguoi_huy=$2, thoi_diem_huy=now() WHERE ma_phieu=$1",
    );
    assert.equal((await stateOf(f, ticketId)).status, "DANG_XU_LY");
    // Người hủy phải là người dùng có thật.
    await assert.rejects(
      f.owner.query(
        "UPDATE phieu_nhan_dien SET trang_thai='DA_HUY', ly_do_huy='x', nguoi_huy=2000000000, thoi_diem_huy=now() WHERE ma_phieu=$1",
        [ticketId],
      ),
      (error: Failure) => error.code === "23503",
    );
  } finally {
    await f.close();
  }
});

test("the application role cannot delete tickets, rows or rosters (soft cancel only)", async () => {
  const f = await createRosterFixture();
  try {
    const { ticketId } = await f.createTicket(f.valid, "cancel-nodelete");
    await saveResults(f, ticketId, 3);
    for (const sql of [
      "DELETE FROM phieu_nhan_dien WHERE ma_phieu=$1",
      "DELETE FROM ket_qua_dong WHERE ma_phieu=$1",
      "DELETE FROM danh_sach_phieu WHERE ma_phieu=$1",
      "UPDATE phieu_nhan_dien SET trang_thai='DA_HUY' WHERE ma_phieu=$1",
    ])
      await assert.rejects(
        f.runtime.query(sql, [ticketId]),
        (error: Failure) => error.code === "42501",
        sql,
      );
  } finally {
    await f.close();
  }
});
