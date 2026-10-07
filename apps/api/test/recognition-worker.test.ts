import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import type {
  ObjectStorage,
  StoredObject,
} from "../src/modules/files/application/port.js";
import type { RecognitionRowResult } from "../src/modules/recognition/application/port.js";
import { RecognitionJobProcessor } from "../src/modules/recognition/application/worker.js";
import {
  HttpRecognitionModel,
  parseRecognitionResponse,
} from "../src/modules/recognition/infrastructure/http-model.js";

const pixel =
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=";
const row = (rowIndex: number): RecognitionRowResult => ({
  rowIndex,
  struck: false,
  stt: {
    raw: String(rowIndex),
    value: rowIndex,
    confidence: "0.97",
    isBlank: false,
  },
  name: { raw: `Học sinh ${rowIndex}`, confidence: "0.90", isBlank: false },
  numeric: {
    rawOutput: "0.0",
    value: "0.0",
    confidence: "0.95",
    isBlank: false,
  },
  written: {
    rawOutput: "không",
    value: "0.0",
    confidence: "0.94",
    isBlank: false,
  },
  numericCropBase64: pixel,
  writtenCropBase64: pixel,
  nameCropBase64: pixel,
  comparison: "KHOP",
  reviewLevel: "XANH",
});

const roster = (size: number) =>
  Array.from({ length: size }, (_, index) => ({
    stt: index + 1,
    studentId: 100 + index,
    fullName: `Học sinh ${index + 1}`,
  }));

class MemoryStorage implements ObjectStorage {
  readonly objects = new Map<string, StoredObject>();
  constructor() {
    this.objects.set("original.png", {
      key: "original.png",
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

function harness(
  rows: RecognitionRowResult[],
  entries = roster(2),
  status: "DANG_XU_LY" | "CHO_DOI_CHIEU" = "DANG_XU_LY",
) {
  const state = {
    completed: undefined as Array<Record<string, unknown>> | undefined,
    failed: undefined as string | undefined,
    recognized: 0,
  };
  const storage = new MemoryStorage();
  const processor = new RecognitionJobProcessor(
    {
      load: async () => ({ status, objectKey: "original.png" }),
      roster: async () => entries,
      complete: async (_id, _version, stored) =>
        void (state.completed = stored as Array<Record<string, unknown>>),
      fail: async (_id, code) => void (state.failed = code),
    },
    storage,
    {
      recognize: async () => {
        state.recognized += 1;
        return { modelVersion: "fake-dev-v1", pageStartStt: 1, rows };
      },
    },
  );
  return { state, storage, processor };
}

test("worker preserves two channels, matches students and never writes an official grade", async () => {
  const { state, storage, processor } = harness([row(1), row(2)]);
  await processor.process("42");
  assert.equal(state.failed, undefined);
  assert.equal(state.completed?.length, 2);
  const first = state.completed![0]!;
  assert.equal((first.numeric as { value: string }).value, "0.0");
  assert.equal("officialGrade" in first, false);
  assert.equal(first.stt, 1);
  assert.equal(first.order, 1);
  assert.equal(first.sttOnPaper, 1);
  assert.equal(first.nameRead, "Học sinh 1");
  assert.equal(first.nameCropKey, "recognition/crops/42/1-name.png");
  assert.equal(first.reviewLevel, "XANH");
  assert.match(String(first.matchNote), /Khớp họ tên và STT/);
  // original + 3 crops per row.
  assert.equal(storage.objects.size, 7);
});

test("struck rows are dropped and their crops are never stored", async () => {
  const struck: RecognitionRowResult = {
    ...row(2),
    struck: true,
    numeric: { rawOutput: null, value: null, confidence: null, isBlank: true },
    written: { rawOutput: null, value: null, confidence: null, isBlank: true },
    comparison: "KHONG_DOC_DUOC",
    reviewLevel: "DO",
  };
  const { state, storage, processor } = harness(
    [row(1), struck, row(3)],
    roster(3),
  );
  await processor.process("7");
  assert.deepEqual(
    state.completed!.map((item) => [item.order, item.stt]),
    [
      [1, 1],
      [3, 3],
    ],
  );
  assert.equal(storage.objects.has("recognition/crops/7/2-numeric.png"), false);
  assert.equal(storage.objects.size, 7);
});

test("rows are mapped by STT and name, not by position on the paper", async () => {
  // Trang chỉ chứa STT 3–4 của lớp 4 người: dòng 1 trên ảnh là học sinh STT 3.
  const onPaper = (rowIndex: number, stt: number): RecognitionRowResult => ({
    ...row(rowIndex),
    stt: { ...row(rowIndex).stt, value: stt, raw: String(stt) },
    name: { ...row(rowIndex).name, raw: `Học sinh ${stt}` },
  });
  const { state, processor } = harness(
    [onPaper(1, 3), onPaper(2, 4)],
    roster(4),
  );
  await processor.process("8");
  assert.deepEqual(
    state.completed!.map((item) => [item.order, item.stt]),
    [
      [1, 3],
      [2, 4],
    ],
  );
});

test("rows without any STT reading (project decision: STT is not recognised) are matched by name and order", async () => {
  const noStt = (rowIndex: number, name: string): RecognitionRowResult => ({
    ...row(rowIndex),
    stt: { raw: null, value: null, confidence: "0", isBlank: true },
    name: { raw: name, confidence: "0.90", isBlank: false },
  });
  // The page holds students 3–5 of a class of 6; names alone locate the segment.
  const { state, processor } = harness(
    [noStt(1, "Học sinh 3"), noStt(2, "Học sinh 4"), noStt(3, "Học sinh 5")],
    roster(6),
  );
  await processor.process("21");
  assert.equal(state.failed, undefined);
  assert.deepEqual(
    state.completed!.map((item) => [item.order, item.stt, item.sttOnPaper]),
    [
      [1, 3, null],
      [2, 4, null],
      [3, 5, null],
    ],
  );
  assert.ok(state.completed!.every((item) => item.reviewLevel === "XANH"));
  // A row whose name cannot be read is never green when there is no STT either (red, 1 of 5 stays within the red ratio).
  const unreadable = harness(
    [
      noStt(1, "Học sinh 1"),
      noStt(2, "Học sinh 2"),
      {
        ...noStt(3, ""),
        name: { raw: null, confidence: null, isBlank: false },
      },
      noStt(4, "Học sinh 4"),
      noStt(5, "Học sinh 5"),
    ],
    roster(5),
  );
  await unreadable.processor.process("22");
  assert.deepEqual(
    unreadable.state.completed!.map((item) => [item.stt, item.reviewLevel]),
    [
      [1, "XANH"],
      [2, "XANH"],
      [3, "DO"],
      [4, "XANH"],
      [5, "XANH"],
    ],
  );
});

test("final level is the lower of the grade level and the match level", async () => {
  const yellowGrade: RecognitionRowResult = {
    ...row(1),
    comparison: "LECH",
    reviewLevel: "VANG",
    written: { ...row(1).written, value: "5.0" },
  };
  const redMatch: RecognitionRowResult = {
    ...row(2),
    // STT in trên giấy mâu thuẫn học sinh được ghép → Đỏ do ghép dù hai kênh khớp.
    stt: { ...row(2).stt, value: 9, raw: "9" },
  };
  const { state, processor } = harness(
    [yellowGrade, redMatch, row(3), row(4), row(5), row(6)],
    roster(6),
  );
  await processor.process("9");
  assert.deepEqual(
    state.completed!.map((item) => item.reviewLevel),
    ["VANG", "DO", "XANH", "XANH", "XANH", "XANH"],
  );
  // Mức điểm gốc của dịch vụ vẫn được giữ trong comparison.
  assert.equal(state.completed![0]!.comparison, "LECH");
});

test("rows that cannot be matched mark the ticket ROW_MATCH_FAILED and store nothing", async () => {
  const foreign = [1, 2, 3, 4].map((index) => ({
    ...row(index),
    stt: { ...row(index).stt, value: null, raw: null, isBlank: true },
    name: { ...row(index).name, raw: `Trương Ghi ${index}${index}${index}` },
  }));
  const { state, storage, processor } = harness(foreign, roster(4));
  await processor.process("11");
  assert.equal(state.failed, "ROW_MATCH_FAILED");
  assert.equal(state.completed, undefined);
  assert.equal(storage.objects.size, 1);
  // Nhiều dòng có điểm hơn sĩ số snapshot cũng không đoán.
  const tooMany = harness([row(1), row(2), row(3)], roster(2));
  await tooMany.processor.process("12");
  assert.equal(tooMany.state.failed, "ROW_MATCH_FAILED");
});

test("a ticket without a roster snapshot fails instead of guessing", async () => {
  const { state, processor } = harness([row(1)], []);
  await processor.process("13");
  assert.equal(state.failed, "ROW_MATCH_FAILED");
  assert.equal(state.recognized, 0);
});

test("finished tickets are not recognised again", async () => {
  const done = harness([row(1)], roster(1), "CHO_DOI_CHIEU");
  await done.processor.process("14");
  assert.equal(done.state.recognized, 0);
  assert.equal(done.state.completed, undefined);
});

test("storage failure removes the crops that were written and rethrows", async () => {
  const storage = new MemoryStorage();
  let puts = 0;
  const failing: ObjectStorage = {
    put: async (value) => {
      puts += 1;
      if (puts === 4) throw new Error("storage down");
      await storage.put(value);
    },
    get: storage.get,
    signedGetUrl: storage.signedGetUrl,
    remove: storage.remove,
  };
  const processor = new RecognitionJobProcessor(
    {
      load: async () => ({ status: "DANG_XU_LY", objectKey: "original.png" }),
      roster: async () => roster(2),
      complete: async () => assert.fail("must not complete"),
      fail: async () => assert.fail("a retryable storage error is not final"),
    },
    failing,
    {
      recognize: async () => ({
        modelVersion: "v",
        pageStartStt: 1,
        rows: [row(1), row(2)],
      }),
    },
  );
  await assert.rejects(processor.process("15"), /storage down/);
  assert.deepEqual([...storage.objects.keys()], ["original.png"]);
});

test("corrupt crop data is rejected before it reaches storage", async () => {
  const { storage, processor } = harness(
    [{ ...row(1), nameCropBase64: "@@@" }, row(2)],
    roster(2),
  );
  await assert.rejects(processor.process("16"), /MALFORMED_RESPONSE/);
  assert.equal(storage.objects.size, 1);
});

const respond = (body: unknown, status = 200) =>
  new HttpRecognitionModel(
    "http://ocr",
    async () =>
      new Response(typeof body === "string" ? body : JSON.stringify(body), {
        status,
      }),
    100,
  );
const page = (rows: unknown[] = [row(1)]) => ({
  modelVersion: "fake-dev-v1",
  pageStartStt: 1,
  rows,
});
const image = new Uint8Array([1]);

test("HTTP model accepts the full contract and sends only the image", async () => {
  let sent: FormData | undefined;
  const model = new HttpRecognitionModel(
    "http://ocr",
    async (_url, init) => {
      sent = init?.body as FormData;
      return new Response(JSON.stringify(page([row(1), row(2)])), {
        status: 200,
      });
    },
    100,
  );
  const result = await model.recognize(image);
  assert.equal(result.modelVersion, "fake-dev-v1");
  assert.equal(result.pageStartStt, 1);
  assert.deepEqual(
    result.rows.map((item) => item.rowIndex),
    [1, 2],
  );
  assert.deepEqual([...sent!.keys()], ["image"]);
  assert.equal(
    (await respond(page([row(1)])).recognize(image)).rows[0]!.name.raw,
    "Học sinh 1",
  );
  // pageStartStt may be null; struck/blank rows with null values are valid.
  const struck = {
    ...row(2),
    struck: true,
    stt: { raw: null, value: null, confidence: null, isBlank: true },
    numeric: { rawOutput: null, value: null, confidence: null, isBlank: true },
    written: { rawOutput: null, value: null, confidence: null, isBlank: true },
    comparison: "KHONG_DOC_DUOC",
    reviewLevel: "DO",
  };
  const parsed = await respond({
    ...page([row(1), struck]),
    pageStartStt: null,
  }).recognize(image);
  assert.equal(parsed.pageStartStt, null);
  assert.equal(parsed.rows[1]!.struck, true);
});

test("HTTP model rejects malformed output and maps unavailable model", async () => {
  await assert.rejects(
    respond({ rows: [] }).recognize(image),
    /MALFORMED_RESPONSE/,
  );
  await assert.rejects(
    respond("not json").recognize(image),
    /MALFORMED_RESPONSE/,
  );
  await assert.rejects(respond("", 503).recognize(image), /MODEL_UNAVAILABLE/);
  await assert.rejects(
    respond("", 500).recognize(image),
    /RECOGNITION_SERVICE_ERROR/,
  );
  const timedOut = new HttpRecognitionModel(
    "http://ocr",
    async () => {
      throw new Error("timeout");
    },
    1,
  );
  await assert.rejects(timedOut.recognize(image), /RECOGNITION_TIMEOUT/);
  // A real timeout from the abort signal also maps to RECOGNITION_TIMEOUT.
  const aborted = new HttpRecognitionModel(
    "http://ocr",
    (_url, init) =>
      new Promise<Response>((_resolve, reject) =>
        init?.signal?.addEventListener("abort", () =>
          reject(init.signal!.reason),
        ),
      ),
    5,
  );
  await assert.rejects(aborted.recognize(image), /RECOGNITION_TIMEOUT/);
});

test("HTTP model rejects every missing field, wrong type and corrupt crop", async () => {
  const cases: Array<[string, unknown]> = [
    ["no rows array", { modelVersion: "v", pageStartStt: 1, rows: {} }],
    ["no modelVersion", { pageStartStt: 1, rows: [row(1)] }],
    ["empty modelVersion", { ...page(), modelVersion: "" }],
    ["long modelVersion", { ...page(), modelVersion: "x".repeat(81) }],
    ["missing pageStartStt", { modelVersion: "v", rows: [row(1)] }],
    ["bad pageStartStt", { ...page(), pageStartStt: 0 }],
    ["fractional pageStartStt", { ...page(), pageStartStt: 1.5 }],
    ["legacy order only", page([{ ...row(1), rowIndex: undefined, order: 1 }])],
    ["rowIndex zero", page([{ ...row(1), rowIndex: 0 }])],
    ["rowIndex string", page([{ ...row(1), rowIndex: "1" }])],
    ["duplicate rowIndex", page([row(1), row(1)])],
    ["struck missing", page([{ ...row(1), struck: undefined }])],
    ["struck as string", page([{ ...row(1), struck: "false" }])],
    ["stt missing", page([{ ...row(1), stt: undefined }])],
    [
      "stt value string",
      page([{ ...row(1), stt: { ...row(1).stt, value: "1" } }]),
    ],
    [
      "stt blank with value",
      page([{ ...row(1), stt: { ...row(1).stt, isBlank: true } }]),
    ],
    [
      "stt confidence above 1",
      page([{ ...row(1), stt: { ...row(1).stt, confidence: "1.5" } }]),
    ],
    ["name missing", page([{ ...row(1), name: undefined }])],
    [
      "name raw wrong type",
      page([{ ...row(1), name: { ...row(1).name, raw: 5 } }]),
    ],
    [
      "name raw too long",
      page([{ ...row(1), name: { ...row(1).name, raw: "x".repeat(151) } }]),
    ],
    [
      "name confidence malformed",
      page([{ ...row(1), name: { ...row(1).name, confidence: "high" } }]),
    ],
    [
      "numeric value out of range",
      page([{ ...row(1), numeric: { ...row(1).numeric, value: "10.5" } }]),
    ],
    [
      "numeric value too precise",
      page([{ ...row(1), numeric: { ...row(1).numeric, value: "8.55" } }]),
    ],
    [
      "numeric confidence above 1",
      page([{ ...row(1), numeric: { ...row(1).numeric, confidence: "1.2" } }]),
    ],
    [
      "numeric blank with value",
      page([{ ...row(1), numeric: { ...row(1).numeric, isBlank: true } }]),
    ],
    ["written missing", page([{ ...row(1), written: undefined }])],
    [
      "numeric crop missing",
      page([{ ...row(1), numericCropBase64: undefined }]),
    ],
    ["name crop missing", page([{ ...row(1), nameCropBase64: undefined }])],
    ["crop empty", page([{ ...row(1), writtenCropBase64: "" }])],
    ["crop not base64", page([{ ...row(1), numericCropBase64: "@@@@" }])],
    ["crop bad padding", page([{ ...row(1), nameCropBase64: "abc" }])],
    [
      "crop too large",
      page([{ ...row(1), nameCropBase64: "A".repeat(3 * 1024 * 1024) }]),
    ],
    ["comparison unknown", page([{ ...row(1), comparison: "MAYBE" }])],
    [
      "unreadable but green",
      page([{ ...row(1), comparison: "KHONG_DOC_DUOC", reviewLevel: "XANH" }]),
    ],
    [
      "mismatch but green",
      page([
        {
          ...row(1),
          numeric: { ...row(1).numeric, value: "1.0" },
          comparison: "LECH",
          reviewLevel: "XANH",
        },
      ]),
    ],
  ];
  for (const [label, body] of cases)
    await assert.rejects(
      respond(body).recognize(image),
      /MALFORMED_RESPONSE/,
      label,
    );
});

test("API parser accepts the response produced by the real FastAPI service", () => {
  // Golden file written by apps/recognition-service (tests/test_api.py keeps it in sync).
  const body = JSON.parse(
    readFileSync(
      new URL("./fixtures/recognition-fake-response.json", import.meta.url),
      "utf8",
    ),
  );
  const parsed = parseRecognitionResponse(body);
  assert.equal(parsed.pageStartStt, 39);
  assert.deepEqual(
    parsed.rows.map((item) => [item.rowIndex, item.struck, item.stt.value]),
    [
      [1, false, 39],
      [2, true, 40],
      [3, false, 41],
    ],
  );
  assert.equal(parsed.rows[1]!.reviewLevel, "DO");
  assert.equal(parsed.rows[0]!.name.raw, "Học sinh 39");
});

test("HTTP 422 from the service keeps its stable pipeline code", async () => {
  const reject = (body: unknown, status = 422) =>
    new HttpRecognitionModel(
      "http://ocr",
      async () =>
        new Response(typeof body === "string" ? body : JSON.stringify(body), {
          status,
        }),
      100,
    );
  for (const code of [
    "IMAGE_UNREADABLE",
    "IMAGE_QUALITY_LOW",
    "GRID_NOT_FOUND",
    "NOT_A_GRADEBOOK",
    "SCORE_COLUMN_NOT_FOUND",
  ])
    await assert.rejects(
      reject({ detail: { code, message: "chi tiết" } }).recognize(image),
      new RegExp(`^Error: ${code}$`),
      code,
    );
  // Unknown or malformed 422 bodies (e.g. FastAPI validation errors) are generic service errors.
  for (const body of [
    { detail: { code: "SOMETHING_ELSE" } },
    { detail: [{ loc: ["body", "image"], msg: "field required" }] },
    { detail: "INVALID_IMAGE" },
    "not json",
    {},
  ])
    await assert.rejects(
      reject(body).recognize(image),
      /RECOGNITION_SERVICE_ERROR/,
    );
});

test("worker marks the ticket LOI with the pipeline code and does not retry", async () => {
  for (const code of [
    "IMAGE_QUALITY_LOW",
    "GRID_NOT_FOUND",
    "NOT_A_GRADEBOOK",
    "SCORE_COLUMN_NOT_FOUND",
    "IMAGE_UNREADABLE",
  ]) {
    const failures: string[] = [];
    const storage = new MemoryStorage();
    const processor = new RecognitionJobProcessor(
      {
        load: async () => ({ status: "DANG_XU_LY", objectKey: "original.png" }),
        roster: async () => roster(2),
        complete: async () => assert.fail("must not complete"),
        fail: async (_id, value) => void failures.push(value),
      },
      storage,
      {
        recognize: async () => {
          throw new Error(code);
        },
      },
    );
    await processor.process("77"); // resolves: BullMQ sees success and will not retry
    assert.deepEqual(failures, [code]);
    assert.equal(storage.objects.size, 1);
  }
});

test("infrastructure errors are still thrown so the queue can retry them", async () => {
  for (const code of [
    "MODEL_UNAVAILABLE",
    "RECOGNITION_TIMEOUT",
    "RECOGNITION_SERVICE_ERROR",
  ]) {
    const processor = new RecognitionJobProcessor(
      {
        load: async () => ({ status: "DANG_XU_LY", objectKey: "original.png" }),
        roster: async () => roster(2),
        complete: async () => assert.fail("must not complete"),
        fail: async () => assert.fail("not a final failure of the photo"),
      },
      new MemoryStorage(),
      {
        recognize: async () => {
          throw new Error(code);
        },
      },
    );
    await assert.rejects(processor.process("78"), new RegExp(code));
  }
});
