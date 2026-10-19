import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import { test } from "node:test";
import { BadRequestException, NotFoundException } from "@nestjs/common";
import type { Actor } from "../src/modules/authorization/application/policy.js";
import type {
  ObjectStorage,
  StoredObject,
} from "../src/modules/files/application/port.js";
import { BatchException } from "../src/modules/recognition/application/batch-errors.js";
import type {
  CancelRecognitionBatch,
  CreateRecognitionBatch,
  RecognitionBatchStore,
  RecognitionBatchView,
  StoredBatchReceipt,
} from "../src/modules/recognition/application/batch-port.js";
import {
  RecognitionBatchService,
  parseComponentChoices,
} from "../src/modules/recognition/application/batch-service.js";

// Dịch vụ lô (ADR-0016 mục 3, 4) với kho lưu trữ và store giả: kiểm ảnh từng trang, tối đa 4 trang, dọn object khi lỗi,
// phát lại idempotent. Không có DB; dữ liệu hoàn toàn giả.
const actor: Actor = {
  id: 7,
  username: "giaovien_gia",
  role: "GIAO_VIEN",
  sessionHash: "a".repeat(64),
};

function png(seed: Uint8Array = randomBytes(8)): Uint8Array {
  const bytes = new Uint8Array(24 + seed.byteLength);
  bytes.set([137, 80, 78, 71, 13, 10, 26, 10]);
  bytes.set([73, 72, 68, 82], 12);
  new DataView(bytes.buffer).setUint32(16, 100);
  new DataView(bytes.buffer).setUint32(20, 100);
  bytes.set(seed, 24);
  return bytes;
}

const page = (seed?: Uint8Array) => ({
  bytes: png(seed),
  claimedType: "image/png",
});

class MemoryStorage implements ObjectStorage {
  readonly objects = new Map<string, StoredObject>();
  failOnPut: number | null = null;
  puts = 0;
  async put(value: StoredObject) {
    this.puts += 1;
    if (this.failOnPut === this.puts) throw new Error("STORAGE_DOWN");
    this.objects.set(value.key, value);
  }
  get = async (key: string) => this.objects.get(key)!.bytes;
  signedGetUrl = async (key: string) => `https://storage.test/${key}`;
  remove = async (key: string) => void this.objects.delete(key);
}

const choices = [
  { templateColumnIndex: 2, componentId: 11 },
  { templateColumnIndex: 4, componentId: 12 },
];

function setup() {
  const storage = new MemoryStorage();
  const calls = {
    authorized: 0,
    created: [] as CreateRecognitionBatch[],
    cancelled: [] as CancelRecognitionBatch[],
  };
  const state = {
    createError: null as Error | null,
    /** Khóa object mà store trả về; null = đúng ảnh vừa tải (lần tạo đầu). */
    replayKeys: null as string[] | null,
    detail: null as RecognitionBatchView | null,
    cancelKeys: [] as string[],
  };
  const store: RecognitionBatchStore = {
    authorizeUpload: async () => void (calls.authorized += 1),
    create: async (input): Promise<StoredBatchReceipt> => {
      calls.created.push(input);
      if (state.createError) throw state.createError;
      return {
        batchId: "5",
        jobId: "recognition-batch-5",
        status: "DANG_XU_LY",
        storedObjectKeys:
          state.replayKeys ?? input.pages.map((item) => item.objectKey),
        tickets: input.components.map((item, index) => ({
          ticketId: String(100 + index),
          componentId: item.componentId,
          templateColumnIndex: item.templateColumnIndex,
        })),
      };
    },
    detail: async () => state.detail,
    cancel: async (input) => {
      calls.cancelled.push(input);
      return { objectKeys: state.cancelKeys };
    },
  };
  const service = new RecognitionBatchService(store, storage);
  return { service, storage, calls, state };
}

const upload = (pages: Array<ReturnType<typeof page>>) => ({
  templateId: "3",
  components: JSON.stringify(choices),
  pages,
});

async function codeOf(work: Promise<unknown>): Promise<string> {
  try {
    await work;
  } catch (error) {
    if (error instanceof BatchException) return error.code;
    if (error instanceof BadRequestException) return "BAD_REQUEST";
    if (error instanceof NotFoundException) return "NOT_FOUND";
    throw error;
  }
  return "OK";
}

test("more than four pages is TOO_MANY_PAGES and nothing is uploaded or created", async () => {
  const { service, storage, calls } = setup();
  const pages = Array.from({ length: 5 }, () => page());
  assert.equal(
    await codeOf(service.upload(actor, 1, "key-1", upload(pages))),
    "TOO_MANY_PAGES",
  );
  assert.equal(storage.objects.size, 0);
  assert.equal(calls.created.length, 0);
  assert.equal(calls.authorized, 0);
});

test("a page that is not an image, no page, or the same image twice is rejected before any upload", async () => {
  const { service, storage, calls } = setup();
  assert.equal(
    await codeOf(service.upload(actor, 1, "key-1", upload([]))),
    "BAD_REQUEST",
  );
  assert.equal(
    await codeOf(
      service.upload(
        actor,
        1,
        "key-1",
        upload([
          page(),
          { bytes: new Uint8Array([1, 2, 3]), claimedType: "image/png" },
        ]),
      ),
    ),
    "BAD_REQUEST",
  );
  // Khai báo loại tệp sai so với nội dung thật.
  assert.equal(
    await codeOf(
      service.upload(actor, 1, "key-1", {
        ...upload([]),
        pages: [{ bytes: png(), claimedType: "image/jpeg" }],
      }),
    ),
    "BAD_REQUEST",
  );
  const seed = randomBytes(8);
  assert.equal(
    await codeOf(
      service.upload(actor, 1, "key-1", upload([page(seed), page(seed)])),
    ),
    "DUPLICATE_FILE",
  );
  assert.equal(storage.puts, 0);
  assert.equal(calls.created.length, 0);
});

test("request fields are validated strictly", async () => {
  const { service, calls } = setup();
  const good = [page(), page()];
  for (const key of [undefined, "", "bad key!", "x".repeat(65)])
    assert.equal(
      await codeOf(service.upload(actor, 1, key, upload(good))),
      "BAD_REQUEST",
      String(key),
    );
  for (const gradebook of ["0", "abc", -1, 1.5])
    assert.equal(
      await codeOf(service.upload(actor, gradebook, "key-1", upload(good))),
      "BAD_REQUEST",
      String(gradebook),
    );
  for (const templateId of [undefined, "0", "x", 2 ** 40])
    assert.equal(
      await codeOf(
        service.upload(actor, 1, "key-1", { ...upload(good), templateId }),
      ),
      "BAD_REQUEST",
      String(templateId),
    );
  assert.equal(calls.created.length, 0);
});

test("component choices: 1..20 distinct columns and components, exact keys, sorted by column", () => {
  assert.deepEqual(
    parseComponentChoices(
      JSON.stringify([
        { templateColumnIndex: 4, componentId: 12 },
        { templateColumnIndex: 2, componentId: 11 },
      ]),
    ),
    choices,
  );
  const bad: unknown[] = [
    undefined,
    "",
    "not json",
    "{}",
    "[]",
    JSON.stringify(
      Array.from({ length: 21 }, (_, i) => ({
        templateColumnIndex: i,
        componentId: i + 1,
      })),
    ),
    JSON.stringify([{ templateColumnIndex: 2 }]),
    JSON.stringify([{ templateColumnIndex: 2, componentId: 11, extra: 1 }]),
    JSON.stringify([{ templateColumnIndex: "2", componentId: 11 }]),
    JSON.stringify([{ templateColumnIndex: -1, componentId: 11 }]),
    JSON.stringify([{ templateColumnIndex: 64, componentId: 11 }]),
    JSON.stringify([{ templateColumnIndex: 2.5, componentId: 11 }]),
    JSON.stringify([{ templateColumnIndex: 2, componentId: 0 }]),
    JSON.stringify([{ templateColumnIndex: 2, componentId: "11" }]),
    JSON.stringify([
      { templateColumnIndex: 2, componentId: 11 },
      { templateColumnIndex: 2, componentId: 12 },
    ]),
    JSON.stringify([
      { templateColumnIndex: 2, componentId: 11 },
      { templateColumnIndex: 4, componentId: 11 },
    ]),
    "[" + "0,".repeat(3000) + "0]",
  ];
  for (const value of bad)
    assert.throws(
      () => parseComponentChoices(value),
      BadRequestException,
      String(value).slice(0, 40),
    );
});

test("a good upload stores every page before one create call and returns one ticket per component", async () => {
  const { service, storage, calls } = setup();
  const first = page();
  const second = page();
  const receipt = await service.upload(
    actor,
    9,
    "key-1",
    upload([first, second]),
  );
  assert.equal(calls.authorized, 1);
  assert.equal(calls.created.length, 1);
  const input = calls.created[0]!;
  assert.equal(input.gradebookId, 9);
  assert.equal(input.templateId, 3);
  assert.deepEqual(input.components, choices);
  assert.deepEqual(
    input.pages.map((item) => item.page),
    [1, 2],
  );
  assert.deepEqual(
    input.pages.map((item) => item.checksum),
    [first, second].map((item) =>
      createHash("sha256").update(item.bytes).digest("hex"),
    ),
  );
  for (const item of input.pages) {
    assert.match(item.objectKey, /^recognition\/original\/[0-9a-f-]{36}\.png$/);
    assert.equal(storage.objects.get(item.objectKey)?.checksum, item.checksum);
  }
  assert.equal(storage.objects.size, 2);
  assert.match(input.requestHash, /^[0-9a-f]{64}$/);
  assert.deepEqual(receipt, {
    batchId: "5",
    jobId: "recognition-batch-5",
    status: "DANG_XU_LY",
    tickets: [
      { ticketId: "100", componentId: 11 },
      { ticketId: "101", componentId: 12 },
    ],
  });
});

test("the request hash depends on the pages, the template and the mapping but not on the object keys", async () => {
  const { service, calls } = setup();
  const first = page();
  const second = page();
  await service.upload(actor, 9, "key-1", upload([first, second]));
  await service.upload(actor, 9, "key-1", upload([first, second]));
  await service.upload(actor, 9, "key-1", upload([second, first]));
  await service.upload(actor, 9, "key-1", {
    ...upload([first, second]),
    templateId: "4",
  });
  const hashes = calls.created.map((item) => item.requestHash);
  assert.equal(hashes[0], hashes[1]);
  assert.notEqual(hashes[0], hashes[2]);
  assert.notEqual(hashes[0], hashes[3]);
});

test("a failed create removes every uploaded page and rethrows the original error", async () => {
  const { service, storage, state } = setup();
  state.createError = new BatchException("RECOGNITION_ALREADY_PENDING");
  assert.equal(
    await codeOf(service.upload(actor, 9, "key-1", upload([page(), page()]))),
    "RECOGNITION_ALREADY_PENDING",
  );
  assert.equal(storage.objects.size, 0);
});

test("a storage failure on the second page removes the first and never creates the batch", async () => {
  const { service, storage, calls } = setup();
  storage.failOnPut = 2;
  await assert.rejects(
    service.upload(actor, 9, "key-1", upload([page(), page()])),
    /STORAGE_DOWN/,
  );
  assert.equal(storage.objects.size, 0);
  assert.equal(calls.created.length, 0);
});

test("a replay keeps the first upload's pages and discards the freshly uploaded ones", async () => {
  const { service, storage, state } = setup();
  state.replayKeys = [
    "recognition/original/11111111-1111-1111-1111-111111111111.png",
    "recognition/original/22222222-2222-2222-2222-222222222222.png",
  ];
  const receipt = await service.upload(
    actor,
    9,
    "key-1",
    upload([page(), page()]),
  );
  assert.equal(receipt.batchId, "5");
  assert.equal(storage.objects.size, 0);
});

const view = (statuses: string[]): RecognitionBatchView => ({
  batchId: "5",
  gradebookId: 9,
  templateId: 3,
  pageCount: 2,
  status: "DANG_XU_LY",
  errorCode: null,
  errorPage: null,
  modelVersion: null,
  version: 0,
  createdAt: "2026-10-19T00:00:00.000Z",
  cancelReason: null,
  cancelledAt: null,
  pages: [
    { page: 1, objectKey: "recognition/original/p1.png" },
    { page: 2, objectKey: "recognition/original/p2.png" },
  ],
  tickets: statuses.map((status, index) => ({
    ticketId: String(100 + index),
    componentId: 11 + index,
    componentName: `Thành phần ${index + 1}`,
    templateColumnIndex: 2 + index,
    status: status as RecognitionBatchView["tickets"][number]["status"],
    errorCode: null,
    version: 0,
    greenRows: 0,
    yellowRows: 0,
    redRows: 0,
  })),
});

test("detail signs short-lived page URLs, never exposes object keys, and 404s an unknown batch", async () => {
  const { service, state } = setup();
  assert.equal(await codeOf(service.detail(actor, 9, "5")), "NOT_FOUND");
  assert.equal(await codeOf(service.detail(actor, 9, "abc")), "BAD_REQUEST");
  assert.equal(await codeOf(service.detail(actor, 9, "0")), "BAD_REQUEST");
  state.detail = view(["DANG_XU_LY", "CHO_DOI_CHIEU"]);
  const detail = await service.detail(actor, 9, "5");
  assert.equal(detail.imageUrlExpiresInSeconds, 300);
  assert.deepEqual(detail.pages, [
    { page: 1, imageUrl: "https://storage.test/recognition/original/p1.png" },
    { page: 2, imageUrl: "https://storage.test/recognition/original/p2.png" },
  ]);
  assert.equal(JSON.stringify(detail).includes("objectKey"), false);
});

test("a batch whose tickets are all cancelled has no page URLs because the images are gone", async () => {
  const { service, state } = setup();
  state.detail = view(["DA_HUY", "DA_HUY"]);
  assert.deepEqual(
    (await service.detail(actor, 9, "5")).pages.map((item) => item.imageUrl),
    ["", ""],
  );
  // Còn một phiếu đã duyệt: ảnh trang là bằng chứng nên vẫn còn.
  state.detail = view(["DA_HUY", "DA_DUYET"]);
  assert.equal(
    (await service.detail(actor, 9, "5")).pages[0]!.imageUrl.startsWith(
      "https://",
    ),
    true,
  );
});

test("cancel needs a key and exactly one non-empty reason, then deletes the freed objects", async () => {
  const { service, storage, calls, state } = setup();
  state.detail = view(["DA_HUY", "DA_HUY"]);
  state.cancelKeys = ["recognition/crops/100/1-numeric.png"];
  storage.objects.set(state.cancelKeys[0]!, {
    key: state.cancelKeys[0]!,
    bytes: new Uint8Array([1]),
    contentType: "image/png",
    checksum: "b".repeat(64),
  });
  for (const body of [
    undefined,
    null,
    [],
    {},
    { reason: "" },
    { reason: "   " },
    { reason: 5 },
    { reason: "y".repeat(201) },
    { reason: "x", extra: 1 },
  ])
    assert.equal(
      await codeOf(service.cancel(actor, 9, "5", "cancel-1", body)),
      "BAD_REQUEST",
      JSON.stringify(body),
    );
  assert.equal(
    await codeOf(service.cancel(actor, 9, "5", undefined, { reason: "x" })),
    "BAD_REQUEST",
  );
  assert.equal(calls.cancelled.length, 0);
  assert.equal(storage.objects.size, 1);

  const result = await service.cancel(actor, 9, "5", "cancel-1", {
    reason: "  Chụp nhầm bảng  ",
  });
  assert.equal(calls.cancelled[0]!.reason, "Chụp nhầm bảng");
  assert.equal(calls.cancelled[0]!.batchId, "5");
  assert.match(calls.cancelled[0]!.requestHash, /^[0-9a-f]{64}$/);
  assert.equal(storage.objects.size, 0);
  assert.equal(result.batchId, "5");
});

test("a cleanup failure after cancel does not turn the committed cancel into an error", async () => {
  const { service, storage, state } = setup();
  state.detail = view(["DA_HUY"]);
  state.cancelKeys = ["recognition/crops/100/1-numeric.png"];
  storage.remove = async () => {
    throw new Error("STORAGE_DOWN");
  };
  const result = await service.cancel(actor, 9, "5", "cancel-1", {
    reason: "Chụp nhầm",
  });
  assert.equal(result.batchId, "5");
});
