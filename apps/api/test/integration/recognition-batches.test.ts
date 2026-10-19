import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import { test } from "node:test";
import { Pool } from "pg";
import { createApp } from "../../src/app.js";
import type { Actor } from "../../src/modules/authorization/application/policy.js";
import type {
  ObjectStorage,
  StoredObject,
} from "../../src/modules/files/application/port.js";
import { GradebooksService } from "../../src/modules/gradebooks/application/service.js";
import { RecognitionBatchProcessor } from "../../src/modules/recognition/application/batch-worker.js";
import {
  RecognitionDispatcher,
  type RecognitionOutboxEvent,
} from "../../src/modules/recognition/application/outbox.js";
import type { ChannelResult } from "../../src/modules/recognition/application/port.js";
import { PrismaRecognitionBatchWorkerStore } from "../../src/modules/recognition/infrastructure/prisma-batch-worker-store.js";
import { PrismaRecognitionOutbox } from "../../src/modules/recognition/infrastructure/prisma-outbox.js";
import {
  RecognitionV2Error,
  type RecognitionV2Client,
  type V2Grade,
  type V2Result,
  type V2Row,
} from "../../src/modules/recognition/public.js";
import type { PrismaClient } from "../../src/generated/prisma/client.js";
import { createTemplate } from "./batch-fixture.js";

// Lô nhận dạng nhiều trang, nhiều thành phần (ADR-0016 mục 3, 4) qua HTTP + worker thật + PostgreSQL thật.
// Họ tên, ảnh và điểm hoàn toàn giả. Mô hình nhận dạng là bản giả đặt trong test; ảnh nằm trong kho lưu trữ trong bộ nhớ.
function png(seed: Uint8Array = randomBytes(8)): Uint8Array {
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

const channel = (value: string | null): ChannelResult => ({
  rawOutput: value,
  value,
  confidence: value === null ? null : "0.95",
  isBlank: value === null,
});
const twoChannel = (key: string, value: string): V2Grade => ({
  key,
  numeric: channel(value),
  written: channel(value),
  numericCropBase64: pixel,
  writtenCropBase64: pixel,
  comparison: "KHOP",
  reviewLevel: "XANH",
  suggestedSource: "SO",
});
const oneChannel = (key: string, value: string): V2Grade => ({
  key,
  numeric: channel(value),
  written: null,
  numericCropBase64: pixel,
  writtenCropBase64: null,
  comparison: "MOT_KENH",
  reviewLevel: "VANG",
  suggestedSource: "SO",
});
const v2Row = (
  rowIndex: number,
  stt: number,
  name: string,
  grades: V2Grade[],
): V2Row => ({
  rowIndex,
  struck: false,
  stt: {
    raw: String(stt),
    value: stt,
    confidence: "0.97",
    isBlank: false,
  },
  name: { raw: name, confidence: "0.90", isBlank: false },
  nameCropBase64: pixel,
  sttRead: stt,
  sttFromPosition: stt,
  grades,
});
const pageResult = (rows: V2Row[]): V2Result => ({
  modelVersion: "fake-v2",
  pageStartStt: 1,
  templateMatch: {
    score: 0.97,
    columnMap: { 0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5 },
  },
  rows,
});

// Giá trị KHÁC NHAU giữa hai cột của cùng một học sinh để bắt nhầm cột (AC-4).
const TX1 = ["6.0", "7.0", "8.0", "9.0"];
const TX2 = ["1.0", "2.0", "3.0", "4.0"];

test("recognition batches: mapping, upload, worker, per-ticket approval, cancel and isolation over HTTP", async () => {
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
      uploadRateLimitPerMinute: 60,
    },
    { check: async () => true, close: async () => {} },
    { objectStorage: storage },
  );
  await app.listen(0, "127.0.0.1");
  const baseUrl = await app.getUrl();
  const gradebooks = app.get(GradebooksService);
  const database = app.get<PrismaClient>("DATABASE");
  const suffix = randomBytes(5).toString("hex");
  const count = async (sql: string, params: unknown[] = []) =>
    Number((await owner.query(sql, params)).rows[0].count);

  const makeActor = async (
    role: "GIAO_VIEN" | "HOC_SINH",
  ): Promise<Actor & { token: string }> => {
    const username = `batch_${role === "GIAO_VIEN" ? "gv" : "hs"}_${randomBytes(5).toString("hex")}`;
    const row = (
      await owner.query(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'test-only',$2::\"VaiTro\") RETURNING ma_nguoi_dung",
        [username, role],
      )
    ).rows[0];
    const token = randomBytes(32).toString("hex");
    const sessionHash = createHash("sha256").update(token).digest("hex");
    await owner.query(
      "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
      [sessionHash, row.ma_nguoi_dung, randomBytes(32).toString("hex")],
    );
    if (role === "GIAO_VIEN")
      await owner.query(
        "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'GV lô giả')",
        [row.ma_nguoi_dung],
      );
    return { id: row.ma_nguoi_dung, username, role, sessionHash, token };
  };

  try {
    const teacher = await makeActor("GIAO_VIEN");
    const intruder = await makeActor("GIAO_VIEN");
    const student = await makeActor("HOC_SINH");
    const year = (
      await owner.query(
        "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2026-09-01','2027-06-01') RETURNING ma_nam_hoc",
        [`LO-${suffix}`],
      )
    ).rows[0].ma_nam_hoc;
    const term = (
      await owner.query(
        "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'Kỳ lô',1,'2026-09-01','2027-01-01') RETURNING ma_hoc_ky",
        [year],
      )
    ).rows[0].ma_hoc_ky;
    const makeClass = async (homeroom: Actor, name: string) =>
      (
        await owner.query(
          "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,10) RETURNING ma_lop",
          [year, homeroom.id, `${name}-${suffix}`],
        )
      ).rows[0].ma_lop as number;
    const cls = await makeClass(teacher, "A");
    const otherCls = await makeClass(intruder, "B");
    for (const name of [
      "Lê Thị An",
      "Trần Văn Bình",
      "Hoàng Minh Châu",
      "Phạm Quốc Dũng",
    ])
      await owner.query(
        "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,$2,'2010-01-01')",
        [cls, name],
      );
    await owner.query(
      "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,'Vũ Thị Khác','2010-01-01')",
      [otherCls],
    );
    const makeSubject = async (label: string) =>
      (
        await owner.query(
          "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,2) RETURNING ma_mon",
          [`${label}-${suffix}`],
        )
      ).rows[0].ma_mon as number;
    const makeComponent = async (
      subject: number,
      name: string,
      order: number,
    ) =>
      (
        await owner.query(
          "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,he_so,thu_tu_hien_thi) VALUES($1,$2,1,$3) RETURNING ma_thanh_phan",
          [subject, name, order],
        )
      ).rows[0].ma_thanh_phan as number;
    const subject = await makeSubject("LO");
    const comp1 = await makeComponent(subject, "Thường xuyên 1", 1);
    const comp2 = await makeComponent(subject, "Thường xuyên 2", 2);
    const otherSubject = await makeSubject("LK");
    await makeComponent(otherSubject, "Khác 1", 1);
    await makeComponent(otherSubject, "Khác 2", 2);
    const assign = (actor: Actor, classId: number, subjectId: number) =>
      owner.query(
        "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,CURRENT_DATE)",
        [actor.id, classId, subjectId, term],
      );
    await assign(teacher, cls, subject);
    await assign(intruder, otherCls, otherSubject);
    const book = await gradebooks.create(teacher, {
      classId: cls,
      subjectId: subject,
      termId: term,
    });
    const otherBook = await gradebooks.create(intruder, {
      classId: otherCls,
      subjectId: otherSubject,
      termId: term,
    });
    const template = await createTemplate(owner, runtime, true);
    const draftTemplate = await createTemplate(owner, runtime, false);

    const api = `${baseUrl}/api/v1/gradebooks/${book.id}`;
    const auth = (actor: { token: string }) => ({
      authorization: `Bearer ${actor.token}`,
    });
    const choice = (index: number, componentId: number) => ({
      templateColumnIndex: index,
      componentId,
    });
    const both = [choice(2, comp1), choice(4, comp2)];
    const postBatch = (
      images: Uint8Array[],
      options: {
        actor?: { token: string } | null;
        key?: string | null;
        templateId?: unknown;
        components?: unknown;
        gradebookId?: number;
      } = {},
    ) => {
      const form = new FormData();
      for (const [index, bytes] of images.entries())
        form.append(
          "images",
          new Blob([bytes.buffer as ArrayBuffer], { type: "image/png" }),
          `page-${index + 1}.png`,
        );
      form.set("templateId", String(options.templateId ?? template));
      form.set(
        "components",
        typeof options.components === "string"
          ? options.components
          : JSON.stringify(options.components ?? both),
      );
      return fetch(
        `${baseUrl}/api/v1/gradebooks/${options.gradebookId ?? book.id}/recognition-batches`,
        {
          method: "POST",
          headers: {
            ...(options.actor === null ? {} : auth(options.actor ?? teacher)),
            ...(options.key === null
              ? {}
              : {
                  "x-idempotency-key":
                    options.key ?? `key-${randomBytes(4).toString("hex")}`,
                }),
          },
          body: form,
        },
      );
    };
    const getBatch = (
      batchId: string,
      actor: { token: string } | null = teacher,
      gradebookId = book.id,
    ) =>
      fetch(
        `${baseUrl}/api/v1/gradebooks/${gradebookId}/recognition-batches/${batchId}`,
        { headers: actor ? auth(actor) : {} },
      );
    const cancelBatch = (
      batchId: string,
      options: {
        actor?: { token: string };
        key?: string;
        body?: unknown;
        gradebookId?: number;
      } = {},
    ) =>
      fetch(
        `${baseUrl}/api/v1/gradebooks/${options.gradebookId ?? book.id}/recognition-batches/${batchId}/cancel`,
        {
          method: "POST",
          headers: {
            ...auth(options.actor ?? teacher),
            "content-type": "application/json",
            "x-idempotency-key": options.key ?? "cancel-1",
          },
          body: JSON.stringify(options.body ?? { reason: "Chụp nhầm bảng" }),
        },
      );
    const batchCount = () =>
      count("SELECT count(*) FROM lo_nhan_dien WHERE ma_bang_diem=$1", [
        book.id,
      ]);
    const ticketCount = () =>
      count("SELECT count(*) FROM phieu_nhan_dien WHERE ma_bang_diem=$1", [
        book.id,
      ]);

    // --- Gợi ý ánh xạ cột -> thành phần ---
    const mappingUrl = (templateId: number, gradebookId = book.id) =>
      `${baseUrl}/api/v1/gradebooks/${gradebookId}/form-templates/${templateId}/mapping`;
    const mapping = await fetch(mappingUrl(template), {
      headers: auth(teacher),
    });
    assert.equal(mapping.status, 200);
    assert.deepEqual(await mapping.json(), {
      gradebookId: book.id,
      templateId: template,
      items: [
        {
          templateColumnIndex: 2,
          key: "TX1",
          group: "TX",
          order: 1,
          channels: "SO_CHU",
          componentId: comp1,
          componentName: "Thường xuyên 1",
          locked: false,
          pending: false,
        },
        {
          templateColumnIndex: 4,
          key: "TX2",
          group: "TX",
          order: 2,
          channels: "SO",
          componentId: comp2,
          componentName: "Thường xuyên 2",
          locked: false,
          pending: false,
        },
      ],
    });
    assert.equal(
      (await fetch(mappingUrl(template), { headers: auth(student) })).status,
      403,
    );
    assert.equal(
      (await fetch(mappingUrl(template), { headers: auth(intruder) })).status,
      403,
    );
    assert.equal((await fetch(mappingUrl(template))).status, 401);
    const inactiveMapping = await fetch(mappingUrl(draftTemplate), {
      headers: auth(teacher),
    });
    assert.equal(inactiveMapping.status, 409);
    assert.equal(
      ((await inactiveMapping.json()) as { code: string }).code,
      "TEMPLATE_INACTIVE",
    );
    assert.equal(
      (await fetch(mappingUrl(2_000_000_000), { headers: auth(teacher) }))
        .status,
      404,
    );

    // --- Từ chối trước khi đụng tới dữ liệu: không lô, không phiếu, không ảnh ---
    const pages = [png(), png()];
    const codeOf = async (response: Response) =>
      ((await response.json()) as { code?: string }).code;
    assert.equal((await postBatch(pages, { key: null })).status, 400);
    assert.equal((await postBatch([])).status, 400);
    const tooMany = await postBatch([png(), png(), png(), png(), png()]);
    assert.equal(tooMany.status, 400);
    assert.equal(await codeOf(tooMany), "TOO_MANY_PAGES");
    assert.equal(
      (await postBatch(pages, { components: "không phải JSON" })).status,
      400,
    );
    assert.equal((await postBatch([new Uint8Array([1, 2, 3])])).status, 400);
    const swapped = await postBatch(pages, {
      components: [choice(2, comp2), choice(4, comp1)],
    });
    assert.equal(swapped.status, 400);
    assert.equal(await codeOf(swapped), "COMPONENT_NOT_MAPPABLE");
    const notGrade = await postBatch(pages, { components: [choice(3, comp1)] });
    assert.equal(notGrade.status, 400);
    assert.equal(await codeOf(notGrade), "COMPONENT_NOT_MAPPABLE");
    const inactive = await postBatch(pages, { templateId: draftTemplate });
    assert.equal(inactive.status, 409);
    assert.equal(await codeOf(inactive), "TEMPLATE_INACTIVE");
    const unknown = await postBatch(pages, { templateId: 2_000_000_000 });
    assert.equal(unknown.status, 404);
    assert.equal(await codeOf(unknown), "TEMPLATE_NOT_FOUND");
    // AC-8: giáo viên không được phân công, học sinh và người chưa đăng nhập.
    assert.equal((await postBatch(pages, { actor: intruder })).status, 403);
    assert.equal((await postBatch(pages, { actor: student })).status, 403);
    assert.equal((await postBatch(pages, { actor: null })).status, 401);
    assert.equal(
      (await postBatch(pages, { gradebookId: 2_000_000_000 })).status,
      404,
    );
    assert.equal(await batchCount(), 0);
    assert.equal(await ticketCount(), 0);
    assert.equal(objects.size, 0);

    // --- AC-2: lỗi ở thành phần thứ hai thì rollback cả lô và dọn ảnh đã tải ---
    const lone = await postBatch([png()], { components: [choice(4, comp2)] });
    assert.equal(lone.status, 202);
    const loneBatch = ((await lone.json()) as { batchId: string }).batchId;
    assert.equal(objects.size, 1);
    assert.equal(await batchCount(), 1);
    assert.equal(await ticketCount(), 1);
    const midway = await postBatch([png(), png()]);
    assert.equal(midway.status, 409);
    assert.equal(await codeOf(midway), "RECOGNITION_ALREADY_PENDING");
    assert.equal(await batchCount(), 1);
    assert.equal(await ticketCount(), 1);
    assert.equal(objects.size, 1);
    assert.equal(
      await count(
        "SELECT count(*) FROM danh_sach_phieu WHERE ma_phieu IN (SELECT ma_phieu FROM phieu_nhan_dien WHERE ma_bang_diem=$1)",
        [book.id],
      ),
      4,
    );
    // Hủy lô một thành phần: ảnh trang được xóa vì mọi phiếu của lô đã hủy.
    const cancelledLone = await cancelBatch(loneBatch);
    assert.equal(cancelledLone.status, 200);
    assert.equal(
      ((await cancelledLone.json()) as { status: string }).status,
      "DA_HUY",
    );
    assert.equal(objects.size, 0);

    // --- Tạo lô 2 trang, 2 thành phần: 202 và đúng 2 phiếu trong một giao dịch ---
    const created = await postBatch(pages, { key: "batch-1" });
    assert.equal(created.status, 202);
    const receipt = (await created.json()) as {
      batchId: string;
      jobId: string;
      status: string;
      tickets: Array<{ ticketId: string; componentId: number }>;
    };
    assert.equal(receipt.status, "DANG_XU_LY");
    assert.equal(receipt.jobId, `recognition-batch-${receipt.batchId}`);
    assert.deepEqual(
      receipt.tickets.map((ticket) => ticket.componentId).sort(),
      [comp1, comp2].sort(),
    );
    assert.equal(objects.size, 2);
    const ticketOf = (component: number) =>
      receipt.tickets.find((ticket) => ticket.componentId === component)!
        .ticketId;
    const tx1Ticket = ticketOf(comp1);
    const tx2Ticket = ticketOf(comp2);
    const stored = (
      await owner.query(
        "SELECT so_trang, duong_dan_anh FROM trang_lo_nhan_dien WHERE ma_lo=$1 ORDER BY so_trang",
        [receipt.batchId],
      )
    ).rows;
    assert.equal(stored.length, 2);
    assert.deepEqual(
      stored.map((row) => objects.has(row.duong_dan_anh)),
      [true, true],
    );
    assert.equal(
      await count("SELECT count(*) FROM phieu_nhan_dien WHERE ma_lo=$1", [
        receipt.batchId,
      ]),
      2,
    );
    // Một sự kiện outbox cho cả lô.
    assert.equal(
      await count(
        "SELECT count(*) FROM recognition_outbox WHERE ma_lo=$1 AND loai_su_kien='RECOGNITION_BATCH_REQUESTED'",
        [receipt.batchId],
      ),
      1,
    );

    // Phát lại cùng khóa và cùng nội dung: cùng kết quả, không thêm lô/phiếu/ảnh.
    const replay = await postBatch(pages, { key: "batch-1" });
    assert.equal(replay.status, 202);
    assert.deepEqual(await replay.json(), receipt);
    assert.equal(objects.size, 2);
    assert.equal(
      await count("SELECT count(*) FROM lo_nhan_dien WHERE ma_lo=$1", [
        receipt.batchId,
      ]),
      1,
    );
    assert.equal(await ticketCount(), 3);
    // Cùng khóa nhưng ảnh khác; khóa khác nhưng cùng ảnh; thành phần đang chờ.
    const mismatch = await postBatch([png(), png()], { key: "batch-1" });
    assert.equal(mismatch.status, 409);
    assert.equal(await codeOf(mismatch), "IDEMPOTENCY_MISMATCH");
    const duplicate = await postBatch(pages, { key: "batch-dup" });
    assert.equal(duplicate.status, 409);
    assert.equal(await codeOf(duplicate), "DUPLICATE_FILE");
    const pending = await postBatch([png(), png()], { key: "batch-pending" });
    assert.equal(pending.status, 409);
    assert.equal(await codeOf(pending), "RECOGNITION_ALREADY_PENDING");
    assert.equal(objects.size, 2);
    assert.equal(await ticketCount(), 3);

    // Gợi ý ánh xạ giờ đánh dấu hai thành phần đang chờ.
    const pendingMapping = (await (
      await fetch(mappingUrl(template), { headers: auth(teacher) })
    ).json()) as { items: Array<{ pending: boolean; locked: boolean }> };
    assert.deepEqual(
      pendingMapping.items.map((item) => [item.pending, item.locked]),
      [
        [true, false],
        [true, false],
      ],
    );

    // Dispatcher đưa MỘT job cho cả lô (batchId), không có job theo phiếu của lô.
    const queued: RecognitionOutboxEvent[] = [];
    const dispatcher = new RecognitionDispatcher(
      new PrismaRecognitionOutbox(database),
      {
        enqueue: async (event) => void queued.push(event),
        close: async () => {},
      },
    );
    for (let round = 0; round < 5; round++) {
      if (queued.some((event) => event.batchId === receipt.batchId)) break;
      await dispatcher.dispatchOnce();
    }
    const events = queued.filter((event) => event.batchId === receipt.batchId);
    assert.equal(events.length, 1);
    assert.equal(events[0]!.jobId, receipt.jobId);
    assert.equal(
      queued.some(
        (event) =>
          !event.batchId &&
          receipt.tickets.some((ticket) => ticket.ticketId === event.ticketId),
      ),
      false,
    );

    // --- Worker thật trên DB thật: ghép học sinh MỘT lần, mỗi phiếu chỉ giá trị của đúng cột ---
    const roster = (
      await owner.query(
        "SELECT stt, ho_ten FROM danh_sach_phieu WHERE ma_phieu=$1 ORDER BY stt",
        [tx1Ticket],
      )
    ).rows as Array<{ stt: number; ho_ten: string }>;
    assert.equal(roster.length, 4);
    const rowsOf = (sttList: number[]) =>
      sttList.map((stt, position) =>
        v2Row(position + 1, stt, roster[stt - 1]!.ho_ten, [
          twoChannel("TX1", TX1[stt - 1]!),
          oneChannel("TX2", TX2[stt - 1]!),
        ]),
      );
    class FakeModel implements RecognitionV2Client {
      calls = 0;
      constructor(private readonly results: Array<V2Result | Error>) {}
      async analyzeLayout(): Promise<never> {
        throw new Error("not used");
      }
      async recognize(): Promise<V2Result> {
        const next = this.results[this.calls]!;
        this.calls += 1;
        if (next instanceof Error) throw next;
        return next;
      }
    }
    const modelFor = (results: Array<V2Result | Error>) =>
      new FakeModel(results);
    const processorFor = (model: RecognitionV2Client) =>
      new RecognitionBatchProcessor(
        new PrismaRecognitionBatchWorkerStore(database),
        storage,
        model,
        { sttCheck: false },
      );
    const model = modelFor([
      pageResult(rowsOf([1, 2])),
      pageResult(rowsOf([3, 4])),
    ]);
    await processorFor(model).process(receipt.batchId);
    assert.equal(model.calls, 2);

    const done = (await (await getBatch(receipt.batchId)).json()) as {
      status: string;
      errorCode: string | null;
      pageCount: number;
      pages: Array<{ page: number; imageUrl: string }>;
      tickets: Array<{
        ticketId: string;
        componentId: number;
        status: string;
        version: number;
        greenRows: number;
        yellowRows: number;
        redRows: number;
      }>;
    };
    assert.equal(done.status, "XONG");
    assert.equal(done.errorCode, null);
    assert.equal(done.pageCount, 2);
    assert.deepEqual(
      done.pages.map((page) => page.page),
      [1, 2],
    );
    assert.ok(done.pages.every((page) => page.imageUrl.startsWith("https://")));
    assert.ok(
      done.tickets.every((ticket) => ticket.status === "CHO_DOI_CHIEU"),
    );
    const tx1View = done.tickets.find((t) => t.ticketId === tx1Ticket)!;
    const tx2View = done.tickets.find((t) => t.ticketId === tx2Ticket)!;
    assert.deepEqual(
      [tx1View.greenRows, tx1View.yellowRows, tx1View.redRows],
      [4, 0, 0],
    );
    // AC-5: cột một kênh không có dòng Xanh (tối đa Vàng).
    assert.deepEqual(
      [tx2View.greenRows, tx2View.yellowRows, tx2View.redRows],
      [0, 4, 0],
    );
    assert.equal(
      await count(
        "SELECT count(*) FROM ket_qua_dong WHERE ma_phieu=$1 AND muc_phan_loai='XANH'",
        [tx2Ticket],
      ),
      0,
    );

    const evidence = async (ticket: string) =>
      (
        await owner.query(
          "SELECT thu_tu_dong, so_trang, ma_hoc_sinh, gia_tri_kenh_a::text AS a, gia_tri_kenh_b::text AS b, duong_dan_anh_o_chu FROM ket_qua_dong WHERE ma_phieu=$1 ORDER BY thu_tu_dong",
          [ticket],
        )
      ).rows;
    const first = await evidence(tx1Ticket);
    const second = await evidence(tx2Ticket);
    assert.deepEqual(
      first.map((row) => [row.thu_tu_dong, row.so_trang]),
      [
        [1, 1],
        [2, 1],
        [1001, 2],
        [1002, 2],
      ],
    );
    // AC-4: mỗi phiếu chỉ chứa giá trị của đúng cột của nó.
    assert.deepEqual(
      first.map((row) => row.a),
      TX1,
    );
    assert.deepEqual(
      second.map((row) => row.a),
      TX2,
    );
    assert.ok(
      second.every((row) => row.b === null && row.duong_dan_anh_o_chu === null),
    );
    // Cùng bốn học sinh ở cả hai phiếu: ghép một lần cho cả lô.
    assert.deepEqual(
      first.map((row) => row.ma_hoc_sinh),
      second.map((row) => row.ma_hoc_sinh),
    );
    assert.equal(new Set(first.map((row) => row.ma_hoc_sinh)).size, 4);
    // Máy chỉ đề xuất: chưa có điểm chính thức.
    assert.equal(
      await count(
        "SELECT count(*) FROM diem_thanh_phan WHERE ma_bang_diem=$1 AND gia_tri IS NOT NULL",
        [book.id],
      ),
      0,
    );
    // Job bị gửi lại sau khi xong: không đọc lại, không ghi trùng.
    const retry = modelFor([]);
    await processorFor(retry).process(receipt.batchId);
    assert.equal(retry.calls, 0);
    assert.equal((await evidence(tx1Ticket)).length, 4);

    // --- AC-8: IDOR theo batchId ---
    assert.equal((await getBatch(receipt.batchId, intruder)).status, 403);
    assert.equal((await getBatch(receipt.batchId, student)).status, 403);
    assert.equal((await getBatch(receipt.batchId, null)).status, 401);
    // Lô của bảng điểm này đọc qua bảng điểm khác (mà người dùng được phân công) là không tìm thấy.
    assert.equal(
      (await getBatch(receipt.batchId, intruder, otherBook.id)).status,
      404,
    );
    assert.equal((await getBatch("2000000000")).status, 404);
    assert.equal((await getBatch("abc")).status, 400);
    assert.equal(
      (await cancelBatch(receipt.batchId, { actor: intruder })).status,
      403,
    );
    assert.equal(
      (
        await cancelBatch(receipt.batchId, {
          actor: intruder,
          gradebookId: otherBook.id,
          key: "idor-cancel",
        })
      ).status,
      404,
    );
    assert.equal(
      (await cancelBatch(receipt.batchId, { actor: student })).status,
      403,
    );
    assert.equal(
      await count(
        "SELECT count(*) FROM phieu_nhan_dien WHERE ma_lo=$1 AND trang_thai='DA_HUY'",
        [receipt.batchId],
      ),
      0,
    );
    // Người đã tải lô nhưng mất phân công thì không hủy được (AGENTS 7.9): 403 và không gì thay đổi.
    const cancelAudit = () =>
      count(
        "SELECT count(*) FROM nhat_ky_bao_mat WHERE hanh_dong IN ('RECOGNITION_CANCELLED','RECOGNITION_BATCH_CANCELLED')",
        [],
      );
    const auditBefore = await cancelAudit();
    await owner.query(
      "DELETE FROM phan_cong_giang_day WHERE ma_giao_vien=$1 AND ma_lop=$2 AND ma_mon=$3 AND ma_hoc_ky=$4",
      [teacher.id, cls, subject, term],
    );
    try {
      assert.equal(
        (
          await cancelBatch(receipt.batchId, {
            actor: teacher,
            key: "lost-assignment-cancel",
          })
        ).status,
        403,
      );
    } finally {
      await assign(teacher, cls, subject);
    }
    assert.equal(
      await count(
        "SELECT count(*) FROM phieu_nhan_dien WHERE ma_lo=$1 AND trang_thai='DA_HUY'",
        [receipt.batchId],
      ),
      0,
    );
    assert.equal(
      await count(
        "SELECT count(*) FROM lo_nhan_dien WHERE ma_lo=$1 AND trang_thai='DA_HUY'",
        [receipt.batchId],
      ),
      0,
    );
    assert.equal(await cancelAudit(), auditBefore);
    assert.equal(
      await count(
        "SELECT count(*) FROM khoa_idempotency WHERE khoa='lost-assignment-cancel'",
        [],
      ),
      0,
    );

    // --- AC-7: duyệt TỪNG phiếu của lô bằng endpoint duyệt hiện có ---
    const approve = async (ticketId: string, values: string[], key: string) => {
      const detail = (await (
        await fetch(`${api}/recognition-tickets/${ticketId}`, {
          headers: auth(teacher),
        })
      ).json()) as {
        version: number;
        rows: Array<{ rowId: string; order: number }>;
      };
      const rows = [...detail.rows].sort((a, b) => a.order - b.order);
      assert.equal(rows.length, 4);
      const gradebookVersion = (
        await owner.query(
          "SELECT version FROM bang_diem WHERE ma_bang_diem=$1",
          [book.id],
        )
      ).rows[0].version as number;
      return fetch(`${api}/recognition-tickets/${ticketId}/approve`, {
        method: "POST",
        headers: {
          ...auth(teacher),
          "content-type": "application/json",
          "x-idempotency-key": key,
        },
        body: JSON.stringify({
          expectedTicketVersion: detail.version,
          expectedGradebookVersion: gradebookVersion,
          decisions: rows.map((row, index) => ({
            rowId: row.rowId,
            value: values[index],
            reason: "Đối chiếu ảnh giả",
          })),
        }),
      });
    };
    const grades = async (component: number) =>
      (
        await owner.query(
          "SELECT gia_tri::text AS value, trang_thai::text AS status FROM diem_thanh_phan WHERE ma_bang_diem=$1 AND ma_thanh_phan=$2 ORDER BY ma_hoc_sinh",
          [book.id, component],
        )
      ).rows as Array<{ value: string | null; status: string }>;
    const approvedFirst = await approve(tx1Ticket, TX1, "batch-approve-1");
    assert.equal(approvedFirst.status, 200);
    assert.deepEqual(
      (await grades(comp1)).map((cell) => cell.value).sort(),
      [...TX1].sort(),
    );
    // Phiếu kia và thành phần kia chưa bị đụng tới (NULL, không phải 0.0).
    assert.deepEqual(await grades(comp2), [
      { value: null, status: "CHUA_CO" },
      { value: null, status: "CHUA_CO" },
      { value: null, status: "CHUA_CO" },
      { value: null, status: "CHUA_CO" },
    ]);
    assert.equal(
      (
        await owner.query(
          "SELECT trang_thai::text AS status FROM phieu_nhan_dien WHERE ma_phieu=$1",
          [tx2Ticket],
        )
      ).rows[0].status,
      "CHO_DOI_CHIEU",
    );
    const approvedSecond = await approve(tx2Ticket, TX2, "batch-approve-2");
    assert.equal(approvedSecond.status, 200);
    assert.deepEqual(
      (await grades(comp2)).map((cell) => cell.value).sort(),
      [...TX2].sort(),
    );
    assert.deepEqual(
      (await grades(comp1)).map((cell) => cell.value).sort(),
      [...TX1].sort(),
    );
    // Mọi phiếu của lô đã duyệt thì không hủy được.
    const lateCancel = await cancelBatch(receipt.batchId, {
      key: "late-cancel",
    });
    assert.equal(lateCancel.status, 409);
    assert.equal(await codeOf(lateCancel), "BATCH_ALREADY_APPROVED");

    // --- Hủy lô trước khi worker chạy: phiếu DA_HUY, ảnh bị xóa, sự kiện không gửi, worker bỏ qua ---
    const fresh = [png(), png()];
    const secondUpload = await postBatch(fresh, { key: "batch-2" });
    assert.equal(secondUpload.status, 202);
    const secondBatch = ((await secondUpload.json()) as { batchId: string })
      .batchId;
    const objectsBefore = objects.size;
    assert.ok(objectsBefore >= 2);
    assert.equal(
      (await cancelBatch(secondBatch, { body: { reason: "   " } })).status,
      400,
    );
    assert.equal(
      (await cancelBatch(secondBatch, { body: { reason: "x", extra: 1 } }))
        .status,
      400,
    );
    const cancelled = await cancelBatch(secondBatch, {
      body: { reason: "  Chụp nhầm bảng  " },
      key: "cancel-batch-2",
    });
    assert.equal(cancelled.status, 200);
    const cancelledBody = (await cancelled.json()) as {
      status: string;
      cancelReason: string;
      cancelledAt: string;
      version: number;
      pages: Array<{ imageUrl: string }>;
      tickets: Array<{ status: string }>;
    };
    assert.equal(cancelledBody.status, "DA_HUY");
    assert.equal(cancelledBody.cancelReason, "Chụp nhầm bảng");
    assert.equal(cancelledBody.version, 1);
    assert.equal(Number.isNaN(Date.parse(cancelledBody.cancelledAt)), false);
    assert.ok(
      cancelledBody.tickets.every((ticket) => ticket.status === "DA_HUY"),
    );
    assert.ok(cancelledBody.pages.every((page) => page.imageUrl === ""));
    assert.equal(objects.size, objectsBefore - 2);
    // Cùng khóa -> cùng kết quả; khóa khác -> vẫn là lô đã hủy với lý do ban đầu.
    const sameKey = await cancelBatch(secondBatch, {
      body: { reason: "Chụp nhầm bảng" },
      key: "cancel-batch-2",
    });
    assert.equal(sameKey.status, 200);
    const otherKey = await cancelBatch(secondBatch, {
      body: { reason: "Lý do khác" },
      key: "cancel-batch-2b",
    });
    assert.equal(otherKey.status, 200);
    const otherKeyBody = (await otherKey.json()) as {
      cancelReason: string;
      version: number;
    };
    assert.equal(otherKeyBody.cancelReason, "Chụp nhầm bảng");
    assert.equal(otherKeyBody.version, 1);
    // Sự kiện outbox chưa gửi của lô đã hủy không còn được gửi.
    assert.equal(
      await count(
        "SELECT count(*) FROM recognition_outbox WHERE ma_lo=$1 AND da_gui_luc IS NULL",
        [secondBatch],
      ),
      0,
    );
    const skipped = modelFor([]);
    const logs: string[] = [];
    const originalLog = console.log;
    console.log = (line: unknown) => void logs.push(String(line));
    try {
      await processorFor(skipped).process(secondBatch);
    } finally {
      console.log = originalLog;
    }
    assert.equal(skipped.calls, 0);
    assert.deepEqual(
      logs.map((line) => JSON.parse(line)),
      [{ event: "recognition_batch_cancelled", batchId: secondBatch }],
    );
    assert.equal(
      await count(
        "SELECT count(*) FROM ket_qua_dong WHERE ma_phieu IN (SELECT ma_phieu FROM phieu_nhan_dien WHERE ma_lo=$1)",
        [secondBatch],
      ),
      0,
    );

    // Hủy xong tải lại đúng ảnh đó được (không còn DUPLICATE_FILE) — lô thứ ba, sẽ lỗi ở trang 2.
    const third = await postBatch(fresh, { key: "batch-3" });
    assert.equal(third.status, 202);
    const thirdReceipt = (await third.json()) as {
      batchId: string;
      tickets: Array<{ ticketId: string }>;
    };

    // --- AC-6: trang lỗi TEMPLATE_MISMATCH -> mọi phiếu của lô LOI cùng mã, không có dòng kết quả ---
    const mismatchModel = modelFor([
      pageResult(rowsOf([1, 2])),
      new RecognitionV2Error("TEMPLATE_MISMATCH", { score: 0.4 }),
    ]);
    await processorFor(mismatchModel).process(thirdReceipt.batchId);
    const failed = (await (await getBatch(thirdReceipt.batchId)).json()) as {
      status: string;
      errorCode: string;
      errorPage: number;
      tickets: Array<{ status: string; errorCode: string }>;
    };
    assert.equal(failed.status, "LOI");
    assert.equal(failed.errorCode, "TEMPLATE_MISMATCH");
    assert.equal(failed.errorPage, 2);
    assert.equal(failed.tickets.length, 2);
    assert.ok(
      failed.tickets.every(
        (ticket) =>
          ticket.status === "LOI" && ticket.errorCode === "TEMPLATE_MISMATCH",
      ),
    );
    assert.equal(
      await count(
        "SELECT count(*) FROM ket_qua_dong WHERE ma_phieu IN (SELECT ma_phieu FROM phieu_nhan_dien WHERE ma_lo=$1)",
        [thirdReceipt.batchId],
      ),
      0,
    );

    // --- AC-3: một học sinh ở hai trang -> ROW_MATCH_FAILED, không ghi dòng ---
    const fourth = await postBatch([png(), png()], { key: "batch-4" });
    assert.equal(fourth.status, 202);
    const fourthBatch = ((await fourth.json()) as { batchId: string }).batchId;
    await processorFor(
      modelFor([pageResult(rowsOf([1, 2])), pageResult(rowsOf([2, 3]))]),
    ).process(fourthBatch);
    const duplicated = (await (await getBatch(fourthBatch)).json()) as {
      status: string;
      errorCode: string;
      errorPage: number | null;
      tickets: Array<{ status: string; errorCode: string }>;
    };
    assert.equal(duplicated.status, "LOI");
    assert.equal(duplicated.errorCode, "ROW_MATCH_FAILED");
    assert.equal(duplicated.errorPage, null);
    assert.ok(
      duplicated.tickets.every(
        (ticket) =>
          ticket.status === "LOI" && ticket.errorCode === "ROW_MATCH_FAILED",
      ),
    );
    assert.equal(
      await count(
        "SELECT count(*) FROM ket_qua_dong WHERE ma_phieu IN (SELECT ma_phieu FROM phieu_nhan_dien WHERE ma_lo=$1)",
        [fourthBatch],
      ),
      0,
    );

    // --- Trang 2 thiếu: học sinh của trang 2 bỏ trống, không lỗi ---
    const fifth = await postBatch([png(), png()], { key: "batch-5" });
    assert.equal(fifth.status, 202);
    const fifthBatch = ((await fifth.json()) as { batchId: string }).batchId;
    await processorFor(
      modelFor([pageResult(rowsOf([1, 2, 3])), pageResult([])]),
    ).process(fifthBatch);
    const partial = (await (await getBatch(fifthBatch)).json()) as {
      status: string;
      tickets: Array<{ status: string }>;
    };
    assert.equal(partial.status, "XONG");
    assert.ok(
      partial.tickets.every((ticket) => ticket.status === "CHO_DOI_CHIEU"),
    );
    assert.equal(
      await count(
        "SELECT count(*) FROM ket_qua_dong WHERE ma_phieu IN (SELECT ma_phieu FROM phieu_nhan_dien WHERE ma_lo=$1)",
        [fifthBatch],
      ),
      6,
    );
    // Dọn: không để sự kiện outbox chưa gửi cho test khác.
    await owner.query(
      "UPDATE recognition_outbox SET da_gui_luc=now() WHERE da_gui_luc IS NULL AND ma_lo IN (SELECT ma_lo FROM lo_nhan_dien WHERE ma_bang_diem=$1)",
      [book.id],
    );
  } finally {
    await app.close();
    await owner.end();
    await runtime.end();
  }
});
