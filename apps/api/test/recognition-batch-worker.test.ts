import assert from "node:assert/strict";
import { test } from "node:test";
import type {
  ObjectStorage,
  StoredObject,
} from "../src/modules/files/application/port.js";
import {
  RecognitionBatchProcessor,
  type BatchWorkerJob,
  type BatchWorkerTicket,
  type RecognitionBatchWorkerStore,
} from "../src/modules/recognition/application/batch-worker.js";
import type { ChannelResult } from "../src/modules/recognition/application/port.js";
import {
  RecognitionV2Error,
  type RecognitionV2Client,
  type V2Grade,
  type V2Layout,
  type V2Result,
  type V2Row,
} from "../src/modules/recognition/public.js";
import type { RosterEntry } from "../src/modules/recognition/domain/row-matching.js";
import type { TemplateColumn } from "../src/modules/form-templates/public.js";

// Worker lô nhiều trang (ADR-0016 mục 3): dữ liệu và họ tên hoàn toàn giả, lưu trữ/mô hình/DB giả.
const pixel =
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=";

const signature = {
  version: 1 as const,
  columnWidths: [0.1, 0.3, 0.15, 0.15, 0.15, 0.15],
  headerTexts: ["", "", "", "", "", ""],
  headerRows: 1,
  rowHeightMm: 8,
  tableWidthMm: 180,
};

// STT | Họ tên | TX1 số | TX1 chữ | GK1 số (một kênh) | Ghi chú
const columns: TemplateColumn[] = [
  {
    index: 0,
    role: "STT",
    group: null,
    order: null,
    pairedWith: null,
    headerText: null,
  },
  {
    index: 1,
    role: "HO_TEN",
    group: null,
    order: null,
    pairedWith: null,
    headerText: null,
  },
  {
    index: 2,
    role: "DIEM",
    group: "TX",
    order: 1,
    pairedWith: null,
    headerText: null,
  },
  {
    index: 3,
    role: "DIEM_CHU",
    group: null,
    order: null,
    pairedWith: 2,
    headerText: null,
  },
  {
    index: 4,
    role: "DIEM",
    group: "GK",
    order: 1,
    pairedWith: null,
    headerText: null,
  },
  {
    index: 5,
    role: "BO_QUA",
    group: null,
    order: null,
    pairedWith: null,
    headerText: null,
  },
];

// Họ tên giả, khác nhau rõ rệt để ghép theo tên không nhầm.
const NAMES = [
  "Nguyễn Văn An",
  "Trần Thị Bình",
  "Lê Minh Châu",
  "Phạm Quốc Dũng",
];
const nameOf = (student: number) => NAMES[student - 1]!;

const roster = (size: number): RosterEntry[] =>
  Array.from({ length: size }, (_, index) => ({
    stt: index + 1,
    studentId: 100 + index,
    fullName: nameOf(index + 1),
  }));

class MemoryStorage implements ObjectStorage {
  readonly objects = new Map<string, StoredObject>();
  constructor() {
    for (const key of ["page-1.png", "page-2.png"])
      this.objects.set(key, {
        key,
        bytes: new Uint8Array([1]),
        contentType: "image/png",
        checksum: "a".repeat(64),
      });
  }
  put = async (value: StoredObject) => void this.objects.set(value.key, value);
  get = async (key: string) => this.objects.get(key)!.bytes;
  signedGetUrl = async (key: string) => `https://storage.test/${key}`;
  remove = async (key: string) => void this.objects.delete(key);
}

const channel = (value: string | null): ChannelResult => ({
  rawOutput: value,
  value,
  confidence: value === null ? null : "0.95",
  isBlank: value === null,
});

/** Ô hai kênh: hai kênh khớp → Xanh. */
const twoChannel = (key: string, value: string | null): V2Grade => ({
  key,
  numeric: channel(value),
  written: channel(value),
  numericCropBase64: pixel,
  writtenCropBase64: pixel,
  comparison: value === null ? "KHONG_DOC_DUOC" : "KHOP",
  reviewLevel: value === null ? "DO" : "XANH",
  suggestedSource: value === null ? null : "SO",
});

/** Ô một kênh: tối đa Vàng, gợi ý từ kênh số (D-01). */
const oneChannel = (key: string, value: string | null): V2Grade => ({
  key,
  numeric: channel(value),
  written: null,
  numericCropBase64: pixel,
  writtenCropBase64: null,
  comparison: value === null ? "KHONG_DOC_DUOC" : "MOT_KENH",
  reviewLevel: value === null ? "DO" : "VANG",
  suggestedSource: value === null ? null : "SO",
});

// Giá trị KHÁC NHAU giữa hai cột của cùng một học sinh để bắt nhầm cột.
const TX = ["6.0", "7.0", "8.0", "9.0"];
const GK = ["1.0", "2.0", "3.0", "4.0"];

function v2Row(rowIndex: number, student: number, grades: V2Grade[]): V2Row {
  return {
    rowIndex,
    struck: false,
    stt: {
      raw: String(student),
      value: student,
      confidence: "0.97",
      isBlank: false,
    },
    name: { raw: nameOf(student), confidence: "0.90", isBlank: false },
    nameCropBase64: pixel,
    sttRead: student,
    sttFromPosition: student,
    grades,
  };
}

const bothGrades = (student: number) => [
  twoChannel("TX1", TX[student - 1]!),
  oneChannel("GK1", GK[student - 1]!),
];

const pageResult = (rows: V2Row[]): V2Result => ({
  modelVersion: "fake-v2",
  pageStartStt: 1,
  templateMatch: {
    score: 0.97,
    columnMap: { 0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5 },
  },
  rows,
});

type Harness = ReturnType<typeof harness>;

function harness(options: {
  pages?: V2Result[];
  failures?: Array<Error | undefined>;
  tickets?: BatchWorkerTicket[];
  status?: BatchWorkerJob["status"];
  classSize?: number;
  sttCheck?: boolean;
  after?: Partial<BatchWorkerJob>;
}) {
  const tickets: BatchWorkerTicket[] = options.tickets ?? [
    { ticketId: "11", status: "DANG_XU_LY", templateColumnIndex: 2 },
    { ticketId: "12", status: "DANG_XU_LY", templateColumnIndex: 4 },
  ];
  const job: BatchWorkerJob = {
    status: options.status ?? "DANG_XU_LY",
    signature,
    columns,
    pages: [
      { page: 1, objectKey: "page-1.png" },
      { page: 2, objectKey: "page-2.png" },
    ],
    tickets,
  };
  const state = {
    completed: undefined as
      | Array<{ ticketId: string; rows: Array<Record<string, unknown>> }>
      | undefined,
    modelVersion: undefined as string | undefined,
    failed: undefined as { code: string; page: number | null } | undefined,
    layouts: [] as V2Layout[],
    loads: 0,
  };
  const storage = new MemoryStorage();
  const store: RecognitionBatchWorkerStore = {
    load: async () => {
      state.loads += 1;
      return state.loads > 1 && options.after
        ? { ...job, ...options.after }
        : job;
    },
    roster: async () => roster(options.classSize ?? 4),
    complete: async (_id, version, stored) => {
      state.modelVersion = version;
      state.completed = stored as typeof state.completed;
    },
    fail: async (_id, code, page) => void (state.failed = { code, page }),
  };
  const results = options.pages ?? [
    pageResult([v2Row(1, 1, bothGrades(1)), v2Row(2, 2, bothGrades(2))]),
    pageResult([v2Row(1, 3, bothGrades(3)), v2Row(2, 4, bothGrades(4))]),
  ];
  let call = 0;
  const model: RecognitionV2Client = {
    analyzeLayout: async () => {
      throw new Error("not used");
    },
    recognize: async (_image, layout) => {
      state.layouts.push(layout);
      const index = call;
      call += 1;
      const failure = options.failures?.[index];
      if (failure) throw failure;
      return results[index]!;
    },
  };
  const processor = new RecognitionBatchProcessor(store, storage, model, {
    sttCheck: options.sttCheck ?? false,
  });
  return { state, storage, processor, job };
}

const cropKeys = (storage: MemoryStorage) =>
  [...storage.objects.keys()].filter((key) =>
    key.startsWith("recognition/crops/"),
  );

test("one layout per page lists only the chosen grade columns and their written pair", async () => {
  const { state, processor } = harness({});
  await processor.process("7");
  assert.equal(state.layouts.length, 2);
  assert.deepEqual(state.layouts[0], state.layouts[1]);
  assert.deepEqual(
    state.layouts[0]!.columns.map((column) => [
      column.index,
      column.role,
      column.key ?? null,
    ]),
    [
      [0, "STT", null],
      [1, "HO_TEN", null],
      [2, "DIEM", "TX1"],
      [3, "DIEM_CHU", null],
      [4, "DIEM", "GK1"],
    ],
  );
  assert.deepEqual(state.layouts[0]!.signature, signature);
});

test("a ticket chosen for one column never reads the other column or an unchosen written pair", async () => {
  const { state, processor } = harness({
    tickets: [{ ticketId: "12", status: "DANG_XU_LY", templateColumnIndex: 4 }],
    pages: [
      pageResult([
        v2Row(1, 1, [oneChannel("GK1", GK[0]!)]),
        v2Row(2, 2, [oneChannel("GK1", GK[1]!)]),
      ]),
      pageResult([
        v2Row(1, 3, [oneChannel("GK1", GK[2]!)]),
        v2Row(2, 4, [oneChannel("GK1", GK[3]!)]),
      ]),
    ],
  });
  await processor.process("7");
  // Không chọn TX1 thì cả cột số lẫn cột chữ của TX1 không được gửi đi đọc.
  assert.deepEqual(
    state.layouts[0]!.columns.map((column) => column.index),
    [0, 1, 4],
  );
  assert.equal(state.completed?.length, 1);
});

test("each ticket stores only the values of its own key, with the page of every row (no column mix-up)", async () => {
  const { state, processor } = harness({});
  await processor.process("7");
  assert.equal(state.failed, undefined);
  assert.equal(state.completed?.length, 2);
  const [tx, gk] = state.completed!;
  assert.equal(tx!.ticketId, "11");
  assert.equal(gk!.ticketId, "12");
  const numericOf = (rows: Array<Record<string, unknown>>) =>
    rows.map((row) => (row.numeric as ChannelResult).value);
  assert.deepEqual(numericOf(tx!.rows), TX);
  assert.deepEqual(numericOf(gk!.rows), GK);
  // Hai tập giá trị khác nhau hoàn toàn: nếu worker lấy nhầm cột thì hai dãy trùng nhau.
  assert.notDeepEqual(numericOf(tx!.rows), numericOf(gk!.rows));
  assert.deepEqual(
    tx!.rows.map((row) => [row.page, row.order, row.stt]),
    [
      [1, 1, 1],
      [1, 2, 2],
      [2, 1001, 3],
      [2, 1002, 4],
    ],
  );
  assert.equal(state.modelVersion, "fake-v2");
  // Ảnh ô nằm dưới tiền tố đúng phiếu; ảnh ô số của hai phiếu là hai khóa khác nhau.
  assert.equal(
    tx!.rows[2]!.numericCropKey,
    "recognition/crops/11/1001-numeric.png",
  );
  assert.equal(
    gk!.rows[2]!.numericCropKey,
    "recognition/crops/12/1001-numeric.png",
  );
});

test("a one-channel column never produces a green row and keeps the written channel blank", async () => {
  const { state, processor } = harness({});
  await processor.process("7");
  const [tx, gk] = state.completed!;
  assert.ok(tx!.rows.every((row) => row.reviewLevel === "XANH"));
  for (const row of gk!.rows) {
    assert.notEqual(row.reviewLevel, "XANH");
    assert.equal(row.writtenCropKey, null);
    assert.deepEqual(row.written, {
      rawOutput: null,
      value: null,
      confidence: null,
      isBlank: true,
    });
    assert.equal(row.comparison, "MOT_KENH");
    assert.equal(row.suggestedSource, "SO");
  }
  // Cột hai kênh có ảnh ô chữ; cột một kênh thì không.
  assert.ok(tx!.rows.every((row) => typeof row.writtenCropKey === "string"));
});

test("a red row carries no suggestion and the final level is the lower of grade and match level", async () => {
  const { state, processor } = harness({
    pages: [
      pageResult([
        v2Row(1, 1, [twoChannel("TX1", null), oneChannel("GK1", null)]),
        v2Row(2, 2, bothGrades(2)),
      ]),
      pageResult([v2Row(1, 3, bothGrades(3)), v2Row(2, 4, bothGrades(4))]),
    ],
  });
  await processor.process("7");
  const [tx, gk] = state.completed!;
  for (const ticket of [tx!, gk!]) {
    const blank = ticket.rows[0]!;
    assert.equal(blank.reviewLevel, "DO");
    assert.equal(blank.suggestedSource, null);
    assert.equal(blank.comparison, "KHONG_DOC_DUOC");
  }
});

test("a rejected page marks the whole batch with the same code and page, and stores nothing", async () => {
  const { state, storage, processor } = harness({
    failures: [
      undefined,
      new RecognitionV2Error("TEMPLATE_MISMATCH", { score: 0.4 }),
    ],
  });
  await processor.process("7");
  assert.deepEqual(state.failed, { code: "TEMPLATE_MISMATCH", page: 2 });
  assert.equal(state.completed, undefined);
  // Không ảnh ô nào được lưu: chỉ còn hai ảnh trang gốc.
  assert.deepEqual(cropKeys(storage), []);
  assert.equal(storage.objects.size, 2);
});

test("every deterministic pipeline code fails the batch without retry", async () => {
  for (const code of [
    "GRID_NOT_FOUND",
    "IMAGE_QUALITY_LOW",
    "IMAGE_UNREADABLE",
    "NOT_A_GRADEBOOK",
    "SCORE_COLUMN_NOT_FOUND",
    "INVALID_LAYOUT",
  ]) {
    const { state, processor } = harness({
      failures: [new RecognitionV2Error(code)],
    });
    await processor.process("7");
    assert.deepEqual(state.failed, { code, page: 1 }, code);
    assert.equal(state.completed, undefined);
  }
});

test("infrastructure errors are thrown so the queue retries and nothing is written", async () => {
  for (const code of [
    "MODEL_UNAVAILABLE",
    "RECOGNITION_TIMEOUT",
    "RECOGNITION_SERVICE_ERROR",
  ]) {
    const { state, processor } = harness({
      failures: [undefined, new RecognitionV2Error(code)],
    });
    await assert.rejects(processor.process("7"), new RegExp(code));
    assert.equal(state.failed, undefined);
    assert.equal(state.completed, undefined);
  }
});

test("a student on two pages fails the batch with ROW_MATCH_FAILED and writes no row", async () => {
  const { state, storage, processor } = harness({
    classSize: 4,
    pages: [
      pageResult([v2Row(1, 1, bothGrades(1)), v2Row(2, 2, bothGrades(2))]),
      // Học sinh 2 xuất hiện lần nữa ở trang 2.
      pageResult([v2Row(1, 2, bothGrades(2)), v2Row(2, 3, bothGrades(3))]),
    ],
  });
  await processor.process("7");
  assert.deepEqual(state.failed, { code: "ROW_MATCH_FAILED", page: null });
  assert.equal(state.completed, undefined);
  assert.deepEqual(cropKeys(storage), []);
});

test("matching runs once over the whole batch: page 2 may be shorter and its students stay blank", async () => {
  const { state, processor } = harness({
    classSize: 4,
    pages: [
      pageResult([v2Row(1, 1, bothGrades(1)), v2Row(2, 2, bothGrades(2))]),
      pageResult([]),
    ],
  });
  await processor.process("7");
  assert.equal(state.failed, undefined);
  assert.deepEqual(
    state.completed![0]!.rows.map((row) => [row.page, row.stt]),
    [
      [1, 1],
      [1, 2],
    ],
  );
});

test("a response with keys that were not requested is rejected as malformed", async () => {
  for (const wrong of [
    [twoChannel("TX1", "6.0"), oneChannel("GK2", "1.0")],
    [twoChannel("TX1", "6.0")],
    [
      twoChannel("TX1", "6.0"),
      oneChannel("GK1", "1.0"),
      oneChannel("CK1", "2.0"),
    ],
  ]) {
    const { state, storage, processor } = harness({
      pages: [
        pageResult([v2Row(1, 1, wrong)]),
        pageResult([v2Row(1, 3, bothGrades(3))]),
      ],
    });
    await assert.rejects(processor.process("7"), /MALFORMED_RESPONSE/);
    assert.equal(state.completed, undefined);
    assert.deepEqual(cropKeys(storage), []);
  }
});

test("a row position that cannot be encoded in the page-qualified order is rejected", async () => {
  const { state, processor } = harness({
    pages: [
      pageResult([v2Row(1000, 1, bothGrades(1))]),
      pageResult([v2Row(1, 3, bothGrades(3))]),
    ],
  });
  await assert.rejects(processor.process("7"), /MALFORMED_RESPONSE/);
  assert.equal(state.completed, undefined);
});

test("a cancelled batch or a finished one is not recognised again", async () => {
  for (const status of ["DA_HUY", "XONG", "LOI"] as const) {
    const { state, processor } = harness({ status });
    await processor.process("7");
    assert.equal(state.layouts.length, 0, status);
    assert.equal(state.failed, undefined);
    assert.equal(state.completed, undefined);
  }
});

test("tickets cancelled one by one are skipped; all cancelled means nothing to read", async () => {
  const one = harness({
    tickets: [
      { ticketId: "11", status: "DA_HUY", templateColumnIndex: 2 },
      { ticketId: "12", status: "DANG_XU_LY", templateColumnIndex: 4 },
    ],
    pages: [
      pageResult([v2Row(1, 1, [oneChannel("GK1", GK[0]!)])]),
      pageResult([v2Row(1, 3, [oneChannel("GK1", GK[2]!)])]),
    ],
  });
  await one.processor.process("7");
  assert.deepEqual(
    one.state.completed!.map((ticket) => ticket.ticketId),
    ["12"],
  );
  const none = harness({
    tickets: [
      { ticketId: "11", status: "DA_HUY", templateColumnIndex: 2 },
      { ticketId: "12", status: "DA_HUY", templateColumnIndex: 4 },
    ],
  });
  await none.processor.process("7");
  assert.equal(none.state.layouts.length, 0);
});

test("a batch cancelled while the model runs: the result is ignored and the orphan crops are removed", async () => {
  const { state, storage, processor } = harness({
    after: { status: "DA_HUY" },
  });
  await processor.process("7");
  assert.equal(state.completed?.length, 2);
  assert.deepEqual(cropKeys(storage), []);
});

test("only the tickets cancelled meanwhile lose their crops", async () => {
  const { storage, processor } = harness({
    after: {
      tickets: [
        { ticketId: "11", status: "DA_HUY", templateColumnIndex: 2 },
        { ticketId: "12", status: "CHO_DOI_CHIEU", templateColumnIndex: 4 },
      ],
    },
  });
  await processor.process("7");
  const keys = cropKeys(storage);
  assert.ok(keys.length > 0);
  assert.ok(keys.every((key) => key.startsWith("recognition/crops/12/")));
});

test("a storage failure removes the crops already written and rethrows", async () => {
  const { storage, processor } = harness({});
  let writes = 0;
  const put = storage.put;
  storage.put = async (value) => {
    writes += 1;
    if (writes === 5) throw new Error("STORAGE_DOWN");
    await put(value);
  };
  await assert.rejects(processor.process("7"), /STORAGE_DOWN/);
  assert.deepEqual(cropKeys(storage), []);
});

test("an unknown batch is an error and a column that is not a grade column fails the batch", async () => {
  const missing = new RecognitionBatchProcessor(
    {
      load: async () => null,
      roster: async () => [],
      complete: async () => {},
      fail: async () => {},
    },
    new MemoryStorage(),
    {
      analyzeLayout: async () => {
        throw new Error("x");
      },
      recognize: async () => {
        throw new Error("x");
      },
    },
  );
  await assert.rejects(missing.process("9"), /BATCH_NOT_FOUND/);
  const { state, processor } = harness({
    tickets: [{ ticketId: "11", status: "DANG_XU_LY", templateColumnIndex: 5 }],
  });
  await processor.process("7");
  assert.deepEqual(state.failed, {
    code: "COMPONENT_NOT_MAPPABLE",
    page: null,
  });
});

test("logs never contain student names", async () => {
  const lines: string[] = [];
  const original = console.log;
  console.log = (...args: unknown[]) => void lines.push(args.join(" "));
  try {
    // Đường thành công (có log mô hình STT) và đường ghép thất bại (có log lý do).
    await harness({ sttCheck: true }).processor.process("7");
    await harness({
      pages: [
        pageResult([v2Row(1, 1, bothGrades(1))]),
        pageResult([v2Row(1, 1, bothGrades(1))]),
      ],
    }).processor.process("7");
  } finally {
    console.log = original;
  }
  assert.ok(lines.length >= 2);
  assert.ok(lines.every((line) => !NAMES.some((name) => line.includes(name))));
});

export type { Harness };
