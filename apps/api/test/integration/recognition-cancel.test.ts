import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import { test } from "node:test";
import { Pool } from "pg";
import { createApp } from "../../src/app.js";
import type {
  ObjectStorage,
  StoredObject,
} from "../../src/modules/files/application/port.js";
import type { Actor } from "../../src/modules/authorization/application/policy.js";
import { GradebooksService } from "../../src/modules/gradebooks/application/service.js";
import { RecognitionDispatcher } from "../../src/modules/recognition/application/outbox.js";
import { RecognitionJobProcessor } from "../../src/modules/recognition/application/worker.js";
import { PrismaRecognitionOutbox } from "../../src/modules/recognition/infrastructure/prisma-outbox.js";
import { PrismaRecognitionWorkerStore } from "../../src/modules/recognition/infrastructure/prisma-worker-store.js";
import type { PrismaClient } from "../../src/generated/prisma/client.js";

function png(seed: Uint8Array): Uint8Array {
  const bytes = new Uint8Array(24 + seed.byteLength);
  bytes.set([137, 80, 78, 71, 13, 10, 26, 10]);
  bytes.set([73, 72, 68, 82], 12);
  new DataView(bytes.buffer).setUint32(16, 100);
  new DataView(bytes.buffer).setUint32(20, 100);
  bytes.set(seed, 24);
  return bytes;
}

const pixel =
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=";

const modelRow = (rowIndex: number, name: string) => ({
  rowIndex,
  struck: false,
  stt: {
    raw: String(rowIndex),
    value: rowIndex,
    confidence: "0.97",
    isBlank: false,
  },
  name: { raw: name, confidence: "0.90", isBlank: false },
  numeric: {
    rawOutput: "8.0",
    value: "8.0",
    confidence: "0.95",
    isBlank: false,
  },
  written: {
    rawOutput: "tám",
    value: "8.0",
    confidence: "0.93",
    isBlank: false,
  },
  numericCropBase64: pixel,
  writtenCropBase64: pixel,
  nameCropBase64: pixel,
  comparison: "KHOP" as const,
  reviewLevel: "XANH" as const,
  suggestedSource: "SO" as const,
});

test("cancelling a ticket is a soft, idempotent, authorised operation that stops the pipeline for it", async () => {
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
  const objects = new Map<string, StoredObject>();
  const storage: ObjectStorage = {
    put: async (object) => void objects.set(object.key, object),
    get: async (key) => objects.get(key)!.bytes,
    signedGetUrl: async (key) => `https://storage.test/${key}`,
    remove: async (key) => void objects.delete(key),
  };
  const app = await createApp(
    {
      environment: "development",
      origins: ["http://localhost:8080"],
      databaseUrl: runtimeUrl,
      uploadRateLimitPerMinute: 30,
    },
    { check: async () => true, close: async () => {} },
    { objectStorage: storage },
  );
  await app.listen(0, "127.0.0.1");
  const baseUrl = await app.getUrl();
  const gradebooks = app.get(GradebooksService);
  const suffix = randomBytes(5).toString("hex");
  const makeActor = async (): Promise<Actor & { token: string }> => {
    const row = (
      await owner.query(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'test-only','GIAO_VIEN') RETURNING ma_nguoi_dung",
        ["cancel_" + randomBytes(5).toString("hex")],
      )
    ).rows[0];
    const token = randomBytes(32).toString("hex");
    const sessionHash = createHash("sha256").update(token).digest("hex");
    await owner.query(
      "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
      [sessionHash, row.ma_nguoi_dung, randomBytes(32).toString("hex")],
    );
    await owner.query(
      "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'GV hủy phiếu giả')",
      [row.ma_nguoi_dung],
    );
    return {
      id: row.ma_nguoi_dung,
      username: "cancel_" + suffix,
      role: "GIAO_VIEN",
      sessionHash,
      token,
    };
  };
  try {
    const teacher = await makeActor();
    const intruder = await makeActor();
    const year = (
      await owner.query(
        "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2026-09-01','2027-06-01') RETURNING ma_nam_hoc",
        ["C-" + suffix],
      )
    ).rows[0].ma_nam_hoc;
    const term = (
      await owner.query(
        "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'Kỳ hủy',1,'2026-09-01','2027-01-01') RETURNING ma_hoc_ky",
        [year],
      )
    ).rows[0].ma_hoc_ky;
    const cls = (
      await owner.query(
        "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,10) RETURNING ma_lop",
        [year, teacher.id, "C-" + suffix],
      )
    ).rows[0].ma_lop;
    await owner.query(
      "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,'Trần Văn Bình','2010-01-01'),($1,'Lê Thị An','2010-01-01')",
      [cls],
    );
    const subject = (
      await owner.query(
        "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,2) RETURNING ma_mon",
        ["HUY-" + suffix],
      )
    ).rows[0].ma_mon;
    const component = (
      await owner.query(
        "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,he_so,thu_tu_hien_thi) VALUES($1,'Ảnh hủy',1,1) RETURNING ma_thanh_phan",
        [subject],
      )
    ).rows[0].ma_thanh_phan;
    await owner.query(
      "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,CURRENT_DATE)",
      [teacher.id, cls, subject, term],
    );
    const book = await gradebooks.create(teacher, {
      classId: cls,
      subjectId: subject,
      termId: term,
    });
    const api = `${baseUrl}/api/v1/gradebooks/${book.id}/recognition-tickets`;
    const auth = (actor: { token: string }) => ({
      authorization: `Bearer ${actor.token}`,
    });
    const upload = async (bytes: Uint8Array, key: string) => {
      const form = new FormData();
      form.set("componentId", String(component));
      form.set(
        "image",
        new Blob([bytes.buffer as ArrayBuffer], { type: "image/png" }),
        "grades.png",
      );
      return fetch(api, {
        method: "POST",
        headers: { ...auth(teacher), "x-idempotency-key": key },
        body: form,
      });
    };
    const cancel = (
      ticketId: string,
      body: unknown,
      options: { key?: string | null; actor?: { token: string } } = {},
    ) =>
      fetch(`${api}/${ticketId}/cancel`, {
        method: "POST",
        headers: {
          ...auth(options.actor ?? teacher),
          "content-type": "application/json",
          ...(options.key === null
            ? {}
            : { "x-idempotency-key": options.key ?? "cancel-1" }),
        },
        body: JSON.stringify(body),
      });
    const listIds = async (query = "") =>
      (
        (await (
          await fetch(api + query, { headers: auth(teacher) })
        ).json()) as Array<{ ticketId: string; status: string }>
      ).map((item) => `${item.ticketId}:${item.status}`);

    // --- Tải ảnh lên, rồi hủy khi phiếu còn DANG_XU_LY ---
    const bytes = png(randomBytes(8));
    const uploaded = await upload(bytes, "up-1");
    assert.equal(uploaded.status, 202);
    const receipt = (await uploaded.json()) as { ticketId: string };
    const ticketId = receipt.ticketId;
    assert.equal(objects.size, 1);

    // Bị từ chối trước khi đụng tới dữ liệu: thiếu khóa idempotency, thân sai, lý do sai, giáo viên không được phân công.
    assert.equal(
      (
        await cancel(
          ticketId,
          { expectedVersion: 0, reason: "x" },
          { key: null },
        )
      ).status,
      400,
    );
    for (const body of [
      {},
      { expectedVersion: 0 },
      { reason: "x" },
      { expectedVersion: -1, reason: "x" },
      { expectedVersion: 0, reason: "   " },
      { expectedVersion: 0, reason: "y".repeat(201) },
      { expectedVersion: 0, reason: "x", extra: true },
    ])
      assert.equal((await cancel(ticketId, body)).status, 400);
    assert.equal(
      (
        await cancel(
          ticketId,
          { expectedVersion: 0, reason: "x" },
          { actor: intruder },
        )
      ).status,
      403,
    );
    assert.equal(
      (
        await fetch(`${api}/${ticketId}/cancel`, {
          method: "POST",
          headers: {
            "content-type": "application/json",
            "x-idempotency-key": "anon",
          },
          body: JSON.stringify({ expectedVersion: 0, reason: "x" }),
        })
      ).status,
      401,
    );
    assert.equal(
      (
        await fetch(
          `${baseUrl}/api/v1/gradebooks/2000000000/recognition-tickets/${ticketId}/cancel`,
          {
            method: "POST",
            headers: {
              ...auth(teacher),
              "content-type": "application/json",
              "x-idempotency-key": "nobook",
            },
            body: JSON.stringify({ expectedVersion: 0, reason: "x" }),
          },
        )
      ).status,
      404,
    );
    assert.equal(
      (await cancel("9000000000000000000", { expectedVersion: 0, reason: "x" }))
        .status,
      404,
    );
    // Phiếu vẫn nguyên và chưa mất ảnh.
    assert.deepEqual(await listIds(), [`${ticketId}:DANG_XU_LY`]);
    assert.equal(objects.size, 1);

    // Sai version → 409 với thông báo tiếng Việt, phiếu không đổi.
    const stale = await cancel(ticketId, { expectedVersion: 5, reason: "x" });
    assert.equal(stale.status, 409);
    assert.match(
      JSON.stringify(await stale.json()),
      /Phiếu vừa thay đổi, tải lại rồi thử lại\./,
    );
    assert.equal(objects.size, 1);

    const cancelled = await cancel(ticketId, {
      expectedVersion: 0,
      reason: "  Chụp nhầm bảng  ",
    });
    assert.equal(cancelled.status, 200);
    const detail = (await cancelled.json()) as Record<string, unknown>;
    assert.equal(detail.ticketId, ticketId);
    assert.equal(detail.status, "DA_HUY");
    assert.equal(detail.version, 1);
    assert.equal(detail.cancelReason, "Chụp nhầm bảng");
    assert.equal(typeof detail.cancelledAt, "string");
    assert.equal(Number.isNaN(Date.parse(String(detail.cancelledAt))), false);
    // Ảnh gốc đã bị xóa khỏi kho; chi tiết vẫn trả được nhưng không còn URL ảnh.
    assert.equal(detail.sourceImageUrl, "");
    assert.equal(objects.size, 0);
    const row = (
      await owner.query(
        "SELECT trang_thai::text AS status, ly_do_huy, nguoi_huy, thoi_diem_huy IS NOT NULL AS has_time FROM phieu_nhan_dien WHERE ma_phieu=$1",
        [ticketId],
      )
    ).rows[0];
    assert.deepEqual(row, {
      status: "DA_HUY",
      ly_do_huy: "Chụp nhầm bảng",
      nguoi_huy: teacher.id,
      has_time: true,
    });

    // Cùng khóa → cùng kết quả; khóa khác → vẫn là phiếu đã hủy, không đổi lý do/version.
    const replay = await cancel(ticketId, {
      expectedVersion: 0,
      reason: "Chụp nhầm bảng",
    });
    assert.equal(replay.status, 200);
    assert.equal(((await replay.json()) as { version: number }).version, 1);
    const again = await cancel(
      ticketId,
      { expectedVersion: 0, reason: "Lý do khác" },
      { key: "cancel-2" },
    );
    assert.equal(again.status, 200);
    const againBody = (await again.json()) as {
      version: number;
      cancelReason: string;
    };
    assert.equal(againBody.version, 1);
    assert.equal(againBody.cancelReason, "Chụp nhầm bảng");
    // Cùng khóa nhưng nội dung khác bị từ chối.
    assert.equal(
      (await cancel(ticketId, { expectedVersion: 0, reason: "Nội dung khác" }))
        .status,
      409,
    );

    // Danh sách: mặc định ẩn DA_HUY; includeCancelled=true hiện; giá trị lạ → 400. Chi tiết vẫn đọc được.
    assert.deepEqual(await listIds(), []);
    assert.deepEqual(await listIds("?includeCancelled=false"), []);
    assert.deepEqual(await listIds("?includeCancelled=true"), [
      `${ticketId}:DA_HUY`,
    ]);
    assert.equal(
      (await fetch(api + "?includeCancelled=maybe", { headers: auth(teacher) }))
        .status,
      400,
    );
    const read = await fetch(`${api}/${ticketId}`, { headers: auth(teacher) });
    assert.equal(read.status, 200);
    const readBody = (await read.json()) as Record<string, unknown>;
    assert.equal(readBody.status, "DA_HUY");
    assert.equal(readBody.cancelReason, "Chụp nhầm bảng");
    assert.equal(readBody.sourceImageUrl, "");

    // Dispatcher không gửi sự kiện của phiếu đã hủy.
    const database = app.get<PrismaClient>("DATABASE");
    const queued: string[] = [];
    const dispatcher = new RecognitionDispatcher(
      new PrismaRecognitionOutbox(database),
      {
        enqueue: async (event) => void queued.push(event.ticketId),
        close: async () => {},
      },
    );
    await dispatcher.dispatchOnce();
    assert.equal(queued.includes(ticketId), false);

    // Worker nhận job của phiếu đã hủy: kết thúc thành công, không gọi mô hình, không ghi kết quả.
    let modelCalls = 0;
    const worker = (
      rows = [modelRow(1, "Lê Thị An"), modelRow(2, "Trần Văn Bình")],
    ) =>
      new RecognitionJobProcessor(
        new PrismaRecognitionWorkerStore(database),
        storage,
        {
          recognize: async () => {
            modelCalls += 1;
            return { modelVersion: "fake-dev-v1", pageStartStt: 1, rows };
          },
        },
      );
    const logs: string[] = [];
    const originalLog = console.log;
    console.log = (line: unknown) => void logs.push(String(line));
    try {
      await worker().process(ticketId);
    } finally {
      console.log = originalLog;
    }
    assert.equal(modelCalls, 0);
    assert.deepEqual(
      logs.map((line) => JSON.parse(line)),
      [{ event: "recognition_ticket_cancelled", ticketId }],
    );
    assert.equal(
      Number(
        (
          await owner.query(
            "SELECT count(*) FROM ket_qua_dong WHERE ma_phieu=$1",
            [ticketId],
          )
        ).rows[0].count,
      ),
      0,
    );
    assert.equal(
      (
        await owner.query(
          "SELECT trang_thai::text AS status FROM phieu_nhan_dien WHERE ma_phieu=$1",
          [ticketId],
        )
      ).rows[0].status,
      "DA_HUY",
    );
    assert.equal(objects.size, 0);

    // Hủy xong tải lại đúng ảnh đó được (không còn DUPLICATE_FILE) và không bị coi là có phiếu chờ.
    const second = await upload(bytes, "up-2");
    assert.equal(second.status, 202);
    const secondTicket = ((await second.json()) as { ticketId: string })
      .ticketId;
    assert.notEqual(secondTicket, ticketId);
    assert.equal(objects.size, 1);
    // Khi đang có phiếu chưa hủy cùng ảnh / cùng thành phần: thông báo tiếng Việt rõ ràng.
    const duplicate = await upload(bytes, "up-3");
    assert.equal(duplicate.status, 409);
    assert.match(
      JSON.stringify(await duplicate.json()),
      /Ảnh này đã được tải lên ở một phiếu khác\./,
    );
    const pending = await upload(png(randomBytes(8)), "up-4");
    assert.equal(pending.status, 409);
    assert.match(
      JSON.stringify(await pending.json()),
      /đang có phiếu chờ xử lý\/đối chiếu; duyệt hoặc hủy phiếu đó trước\./,
    );
    assert.equal(objects.size, 1);

    // Hủy giữa lúc worker đang nhận dạng: kết quả bị bỏ qua, ảnh ô vừa tải lên được dọn, không có dòng nào được ghi.
    let cancelDuringModel: Response | undefined;
    const racing = new RecognitionJobProcessor(
      new PrismaRecognitionWorkerStore(database),
      storage,
      {
        recognize: async () => {
          cancelDuringModel = await cancel(
            secondTicket,
            { expectedVersion: 0, reason: "Hủy khi đang nhận dạng" },
            { key: "cancel-race" },
          );
          return {
            modelVersion: "fake-dev-v1",
            pageStartStt: 1,
            rows: [modelRow(1, "Lê Thị An"), modelRow(2, "Trần Văn Bình")],
          };
        },
      },
    );
    console.log = (line: unknown) => void logs.push(String(line));
    try {
      await racing.process(secondTicket);
    } finally {
      console.log = originalLog;
    }
    assert.equal(cancelDuringModel?.status, 200);
    assert.equal(
      Number(
        (
          await owner.query(
            "SELECT count(*) FROM ket_qua_dong WHERE ma_phieu=$1",
            [secondTicket],
          )
        ).rows[0].count,
      ),
      0,
    );
    assert.equal(
      (
        await owner.query(
          "SELECT trang_thai::text AS status FROM phieu_nhan_dien WHERE ma_phieu=$1",
          [secondTicket],
        )
      ).rows[0].status,
      "DA_HUY",
    );
    assert.deepEqual([...objects.keys()], []);
    assert.deepEqual(await listIds("?includeCancelled=true"), [
      `${secondTicket}:DA_HUY`,
      `${ticketId}:DA_HUY`,
    ]);

    // Phiếu đã duyệt không hủy được (409, thông báo tiếng Việt) và không bị đổi.
    const third = await upload(png(randomBytes(8)), "up-5");
    assert.equal(third.status, 202);
    const thirdTicket = ((await third.json()) as { ticketId: string }).ticketId;
    await owner.query(
      "UPDATE phieu_nhan_dien SET trang_thai='DA_DUYET', so_dong_nhan_dien=1 WHERE ma_phieu=$1",
      [thirdTicket],
    );
    const approved = await cancel(
      thirdTicket,
      { expectedVersion: 0, reason: "Muộn rồi" },
      { key: "cancel-approved" },
    );
    assert.equal(approved.status, 409);
    assert.match(
      JSON.stringify(await approved.json()),
      /Phiếu đã duyệt, không thể hủy\./,
    );
    assert.equal(
      (
        await owner.query(
          "SELECT trang_thai::text AS status, ly_do_huy FROM phieu_nhan_dien WHERE ma_phieu=$1",
          [thirdTicket],
        )
      ).rows[0].status,
      "DA_DUYET",
    );
    // Dọn: không để sự kiện outbox chưa gửi cho test khác.
    await owner.query(
      "UPDATE recognition_outbox SET da_gui_luc=now() WHERE da_gui_luc IS NULL AND ma_phieu IN (SELECT ma_phieu FROM phieu_nhan_dien WHERE ma_bang_diem=$1)",
      [book.id],
    );
  } finally {
    await app.close();
    await owner.end();
  }
});
