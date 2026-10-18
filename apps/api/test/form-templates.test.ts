import assert from "node:assert/strict";
import { test } from "node:test";
import {
  ConflictException,
  ForbiddenException,
  HttpException,
  UnauthorizedException,
} from "@nestjs/common";
import type { Actor } from "../src/modules/authorization/application/policy.js";
import type {
  ObjectStorage,
  StoredObject,
} from "../src/modules/files/application/port.js";
import {
  TemplateException,
  type TemplateErrorCode,
} from "../src/modules/form-templates/application/errors.js";
import type {
  FormTemplateStore,
  SaveTemplate,
  TemplateDetail,
  TemplateForTry,
  TemplateStatus,
} from "../src/modules/form-templates/application/port.js";
import { FormTemplatesService } from "../src/modules/form-templates/application/service.js";
import type { TemplateColumn } from "../src/modules/form-templates/domain/definition.js";
import { PrismaFormTemplateStore } from "../src/modules/form-templates/infrastructure/prisma-store.js";
import { TemplateErrorFilter } from "../src/modules/form-templates/presentation/controller.js";
import {
  HttpRecognitionV2Client,
  RecognitionV2Error,
  type LayoutAnalysis,
  type RecognitionV2Client,
  type V2Layout,
  type V2Result,
} from "../src/modules/recognition/public.js";

// Dữ liệu hoàn toàn giả. Fake store/model/storage thay DB, dịch vụ nhận dạng và MinIO (giống recognition.test.ts).

function png(width = 2, height = 3): Uint8Array {
  const bytes = new Uint8Array(24);
  bytes.set([137, 80, 78, 71, 13, 10, 26, 10]);
  bytes.set([73, 72, 68, 82], 12);
  new DataView(bytes.buffer).setUint32(16, width);
  new DataView(bytes.buffer).setUint32(20, height);
  return bytes;
}

const admin: Actor = {
  id: 1,
  username: "admin_test",
  role: "QUAN_TRI_VIEN",
  sessionHash: "a".repeat(64),
};
const teacher: Actor = { ...admin, id: 7, role: "GIAO_VIEN", username: "gv" };
const student: Actor = { ...admin, id: 9, role: "HOC_SINH", username: "hs" };

const col = (
  index: number,
  role: TemplateColumn["role"],
  extra: Partial<TemplateColumn> = {},
): TemplateColumn => ({
  index,
  role,
  group: null,
  order: null,
  pairedWith: null,
  headerText: null,
  ...extra,
});

// STT | Họ tên | TX1 số | TX1 chữ | GK1 số | Ghi chú
const columns = (): TemplateColumn[] => [
  col(0, "STT"),
  col(1, "HO_TEN"),
  col(2, "DIEM", { group: "TX", order: 1 }),
  col(3, "DIEM_CHU", { pairedWith: 2 }),
  col(4, "DIEM", { group: "GK", order: 1 }),
  col(5, "BO_QUA"),
];

const definition = (overrides: Record<string, unknown> = {}) =>
  JSON.stringify({ name: "Mẫu thử", columns: columns(), ...overrides });

const signature = (count = 6) => ({
  version: 1 as const,
  columnWidths: Array.from({ length: count }, () => 1 / count),
  headerTexts: Array.from({ length: count }, () => ""),
  headerRows: 1,
  rowHeightMm: 8,
  tableWidthMm: 180,
});

const analysis = (count = 6): LayoutAnalysis => ({
  signature: signature(count),
  columns: Array.from({ length: count }, (_, index) => ({
    index,
    x0: index / count,
    x1: (index + 1) / count,
    widthMm: 30,
    headerText: "",
    suggestedRole: null,
    suggestedGroup: null,
    suggestedOrder: null,
  })),
  previewPngBase64: "AAAA",
});

const tryResult: V2Result = {
  modelVersion: "fake-v2",
  pageStartStt: 1,
  templateMatch: { score: 0.97, columnMap: { 0: 0, 1: 1 } },
  rows: [
    {
      rowIndex: 1,
      struck: false,
      stt: { raw: "1", value: 1, confidence: "0.9000", isBlank: false },
      name: { raw: "Họ tên giả", confidence: "0.9000", isBlank: false },
      nameCropBase64: "AAAA",
      sttRead: 1,
      sttFromPosition: 1,
      grades: [
        {
          key: "TX1",
          numeric: {
            rawOutput: "8",
            value: "8.0",
            confidence: "0.9500",
            isBlank: false,
          },
          written: {
            rawOutput: "tám",
            value: "8.0",
            confidence: "0.9000",
            isBlank: false,
          },
          numericCropBase64: "AAAA",
          writtenCropBase64: "AAAA",
          comparison: "KHOP",
          reviewLevel: "XANH",
          suggestedSource: "SO",
        },
        {
          key: "GK1",
          numeric: {
            rawOutput: "7",
            value: "7.0",
            confidence: "0.9500",
            isBlank: false,
          },
          written: null,
          numericCropBase64: "AAAA",
          writtenCropBase64: null,
          comparison: "MOT_KENH",
          reviewLevel: "VANG",
          suggestedSource: "SO",
        },
      ],
    },
  ],
};

class FakeStore implements FormTemplateStore {
  saves: SaveTemplate[] = [];
  statusChanges: Array<[number, number, string]> = [];
  audits: string[][] = [];
  rateLimits: string[] = [];
  allowRate = true;
  listCalls: Array<{ role: string; status: TemplateStatus | null }> = [];
  saveError: Error | null = null;
  rows = new Map<number, TemplateDetail>();

  constructor() {
    this.rows.set(1, this.detailRow(1, "DANG_DUNG"));
    this.rows.set(2, this.detailRow(2, "NHAP"));
  }

  private detailRow(id: number, status: TemplateStatus): TemplateDetail {
    return {
      id,
      name: `Mẫu ${id}`,
      description: null,
      status,
      revision: 1,
      rootTemplateId: null,
      columnCount: 6,
      gradeColumnCount: 2,
      version: 0,
      createdAt: "2026-10-19T00:00:00.000Z",
      columns: columns(),
      imageKey: `form-templates/${"0".repeat(8)}-0000-0000-0000-${String(id).padStart(12, "0")}.png`,
    };
  }

  async list(
    actor: Actor,
    _cursor: number | null,
    status: TemplateStatus | null,
  ) {
    this.listCalls.push({ role: actor.role, status });
    const visible = [...this.rows.values()].filter(
      (row) => actor.role !== "GIAO_VIEN" || row.status === "DANG_DUNG",
    );
    return { items: visible, nextCursor: null };
  }
  async detail(actor: Actor, id: number) {
    const row = this.rows.get(id);
    if (!row || (actor.role === "GIAO_VIEN" && row.status !== "DANG_DUNG"))
      return null;
    return row;
  }
  async forTry(_actor: Actor, id: number): Promise<TemplateForTry | null> {
    const row = this.rows.get(id);
    return row ? { id, signature: signature(), columns: row.columns } : null;
  }
  async save(input: SaveTemplate) {
    this.saves.push(input);
    if (this.saveError) throw this.saveError;
    // Tạo và tạo phiên bản sinh mẫu mới (id 3); sửa tại chỗ giữ id.
    const templateId = input.mode === "SUA" ? input.templateId! : 3;
    if (!this.rows.has(templateId))
      this.rows.set(templateId, this.detailRow(templateId, "NHAP"));
    return { templateId };
  }
  async setStatus(
    _actor: Actor,
    id: number,
    expectedVersion: number,
    status: "DANG_DUNG" | "NGUNG",
  ) {
    this.statusChanges.push([id, expectedVersion, status]);
  }
  async consumeRateLimit(_actor: Actor, operation: string) {
    this.rateLimits.push(operation);
    return this.allowRate;
  }
  async recordAudit(_actor: Actor, action: string, target: string) {
    this.audits.push([action, target]);
  }
}

class FakeRecognizer implements RecognitionV2Client {
  analyzeCalls = 0;
  recognizeCalls: V2Layout[] = [];
  failure: Error | null = null;
  analysisColumns = 6;
  async analyzeLayout() {
    this.analyzeCalls += 1;
    if (this.failure) throw this.failure;
    return analysis(this.analysisColumns);
  }
  async recognize(_image: Uint8Array, layout: V2Layout) {
    this.recognizeCalls.push(layout);
    if (this.failure) throw this.failure;
    return tryResult;
  }
}

function setup() {
  const objects = new Map<string, StoredObject>();
  const storage: ObjectStorage = {
    put: async (object) => void objects.set(object.key, object),
    get: async (key) => objects.get(key)!.bytes,
    signedGetUrl: async (key, seconds) =>
      `https://storage.test/${key}?ttl=${seconds}`,
    remove: async (key) => void objects.delete(key),
  };
  const store = new FakeStore();
  const recognizer = new FakeRecognizer();
  const service = new FormTemplatesService(store, recognizer, storage);
  return { objects, storage, store, recognizer, service };
}

const upload = { bytes: png(), claimedType: "image/png" };

async function codeOf(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (error) {
    if (error instanceof TemplateException) return error.code;
    throw error;
  }
  assert.fail("expected a TemplateException");
}

test("create re-analyses the image, stores it privately and saves a draft", async () => {
  const { service, store, recognizer, objects } = setup();
  const created = await service.create(admin, upload, definition());
  assert.equal(recognizer.analyzeCalls, 1);
  assert.equal(objects.size, 1);
  const [key] = [...objects.keys()];
  assert.match(key!, /^form-templates\/[0-9a-f-]{36}\.png$/);
  assert.equal(store.saves.length, 1);
  const saved = store.saves[0]!;
  assert.equal(saved.mode, "TAO");
  assert.equal(saved.templateId, null);
  // Chữ ký do server tính, không lấy từ client.
  assert.deepEqual(saved.image?.signature, signature());
  assert.equal(saved.image?.objectKey, key);
  assert.match(saved.image!.checksum, /^[0-9a-f]{64}$/);
  assert.deepEqual(store.rateLimits, ["FORM_TEMPLATE_ANALYZE"]);
  // Trả về chi tiết với URL ký ngắn hạn và không lộ khóa object.
  assert.equal(created.id, 3);
  assert.equal(created.status, "NHAP");
  assert.equal("imageKey" in created, false);
  assert.equal(created.imageUrlExpiresInSeconds, 300);
});

test("column count different from the analysed image is TEMPLATE_COLUMN_COUNT_MISMATCH", async () => {
  const { service, store, recognizer, objects } = setup();
  recognizer.analysisColumns = 7;
  assert.equal(
    await codeOf(service.create(admin, upload, definition())),
    "TEMPLATE_COLUMN_COUNT_MISMATCH",
  );
  assert.equal(store.saves.length, 0);
  assert.equal(objects.size, 0);
});

test("invalid definitions are rejected before any model call or storage", async () => {
  const { service, store, recognizer, objects } = setup();
  const base = columns();
  const variants: Record<string, TemplateColumn[]> = {
    "no HO_TEN": base.map((c) => (c.role === "HO_TEN" ? col(1, "BO_QUA") : c)),
    "two HO_TEN": base.map((c) => (c.index === 5 ? col(5, "HO_TEN") : c)),
    "no DIEM": [col(0, "STT"), col(1, "HO_TEN"), col(2, "BO_QUA")],
    "duplicate group/order": base.map((c) =>
      c.index === 4 ? col(4, "DIEM", { group: "TX", order: 1 }) : c,
    ),
    "written column pointing at a non-score column": base.map((c) =>
      c.index === 3 ? col(3, "DIEM_CHU", { pairedWith: 1 }) : c,
    ),
  };
  for (const [label, variant] of Object.entries(variants))
    assert.equal(
      await codeOf(
        service.create(admin, upload, definition({ columns: variant })),
      ),
      "INVALID_TEMPLATE_DEFINITION",
      label,
    );
  for (const broken of ["{", "[]", "null", '"x"', undefined])
    assert.equal(
      await codeOf(service.create(admin, upload, broken)),
      "INVALID_TEMPLATE_DEFINITION",
    );
  assert.equal(recognizer.analyzeCalls, 0);
  assert.equal(store.saves.length, 0);
  assert.equal(objects.size, 0);
  assert.deepEqual(store.rateLimits, []);
});

test("a wrong image format keeps the existing upload error and never reaches the model", async () => {
  const { service, recognizer, objects } = setup();
  await assert.rejects(
    service.create(
      admin,
      { bytes: new Uint8Array([1, 2, 3]), claimedType: "image/png" },
      definition(),
    ),
    { name: "BadRequestException" },
  );
  await assert.rejects(
    service.create(
      admin,
      { bytes: png(), claimedType: "image/jpeg" },
      definition(),
    ),
    { name: "BadRequestException" },
  );
  await assert.rejects(
    service.analyze(admin, { bytes: png(), claimedType: "text/plain" }),
    {
      name: "BadRequestException",
    },
  );
  assert.equal(recognizer.analyzeCalls, 0);
  assert.equal(objects.size, 0);
});

test("the stored image is removed when saving fails", async () => {
  const { service, store, objects } = setup();
  store.saveError = new ConflictException();
  await assert.rejects(
    service.create(admin, upload, definition()),
    ConflictException,
  );
  assert.equal(objects.size, 0);
});

test("recognition rejections surface as stable codes with TEMPLATE_MISMATCH details", async () => {
  const { service, recognizer } = setup();
  recognizer.failure = new RecognitionV2Error("GRID_NOT_FOUND");
  assert.equal(
    await codeOf(service.create(admin, upload, definition())),
    "GRID_NOT_FOUND",
  );
  recognizer.failure = new RecognitionV2Error("MALFORMED_RESPONSE");
  assert.equal(
    await codeOf(service.analyze(admin, upload)),
    "MALFORMED_RESPONSE",
  );
  recognizer.failure = new RecognitionV2Error("SOMETHING_NEW");
  assert.equal(
    await codeOf(service.analyze(admin, upload)),
    "RECOGNITION_SERVICE_ERROR",
  );
});

test("analyze only proxies the model: nothing is saved or uploaded", async () => {
  const { service, store, objects } = setup();
  const result = await service.analyze(admin, upload);
  assert.equal(result.columnCount, 6);
  assert.equal(result.previewPngBase64, "AAAA");
  assert.equal(store.saves.length, 0);
  assert.equal(objects.size, 0);
  assert.deepEqual(store.audits, []);
});

test("only administrators write; teachers and students get 403 on every write", async () => {
  const { service, store, recognizer, objects } = setup();
  for (const actor of [teacher, student]) {
    await assert.rejects(service.analyze(actor, upload), ForbiddenException);
    await assert.rejects(
      service.create(actor, upload, definition()),
      ForbiddenException,
    );
    await assert.rejects(
      service.update(actor, 1, {
        expectedVersion: 0,
        ...JSON.parse(definition()),
      }),
      ForbiddenException,
    );
    await assert.rejects(
      service.createVersion(actor, 1, {
        expectedVersion: 0,
        ...JSON.parse(definition()),
      }),
      ForbiddenException,
    );
    await assert.rejects(
      service.activate(actor, 1, { expectedVersion: 0 }),
      ForbiddenException,
    );
    await assert.rejects(
      service.retire(actor, 1, { expectedVersion: 0 }),
      ForbiddenException,
    );
    await assert.rejects(
      service.tryTemplate(actor, 1, upload),
      ForbiddenException,
    );
  }
  await assert.rejects(
    service.create(undefined, upload, definition()),
    UnauthorizedException,
  );
  assert.equal(recognizer.analyzeCalls, 0);
  assert.equal(recognizer.recognizeCalls.length, 0);
  assert.equal(store.saves.length, 0);
  assert.equal(store.statusChanges.length, 0);
  assert.equal(objects.size, 0);
});

test("students cannot read templates; teachers see only DANG_DUNG", async () => {
  const { service } = setup();
  await assert.rejects(service.list(student), ForbiddenException);
  await assert.rejects(service.detail(student, 1), ForbiddenException);
  await assert.rejects(service.list(undefined), UnauthorizedException);

  const teacherList = await service.list(teacher, undefined, "NHAP");
  assert.deepEqual(
    teacherList.items.map((item) => [item.id, item.status]),
    [[1, "DANG_DUNG"]],
  );
  assert.equal((await service.detail(teacher, 1)).id, 1);
  // Mẫu NHAP không tồn tại với giáo viên.
  assert.equal(await codeOf(service.detail(teacher, 2)), "TEMPLATE_NOT_FOUND");
  const adminList = await service.list(admin);
  assert.equal(adminList.items.length, 2);
  assert.equal((await service.detail(admin, 2)).status, "NHAP");

  await assert.rejects(service.list(admin, "abc"), {
    name: "BadRequestException",
  });
  await assert.rejects(service.list(admin, undefined, "KHAC"), {
    name: "BadRequestException",
  });
});

test("update and versions go through the store with the optimistic version", async () => {
  const { service, store } = setup();
  const body = { expectedVersion: 4, ...JSON.parse(definition()) };
  await service.update(admin, 2, body);
  await service.createVersion(admin, 1, body);
  assert.deepEqual(
    store.saves.map((s) => [s.mode, s.templateId, s.expectedVersion]),
    [
      ["SUA", 2, 4],
      ["PHIEN_BAN", 1, 4],
    ],
  );
  // Thiếu expectedVersion hoặc sai kiểu: 400, không chạm store.
  await assert.rejects(service.update(admin, 2, JSON.parse(definition())), {
    name: "BadRequestException",
  });
  await assert.rejects(
    service.update(admin, 2, { ...body, expectedVersion: "4" }),
    { name: "BadRequestException" },
  );
  // Định nghĩa sai trong PUT bị chặn ở domain.
  assert.equal(
    await codeOf(
      service.update(admin, 2, {
        ...body,
        columns: columns().map((c) =>
          c.role === "HO_TEN" ? col(1, "BO_QUA") : c,
        ),
      }),
    ),
    "INVALID_TEMPLATE_DEFINITION",
  );
  assert.equal(store.saves.length, 2);
});

test("a template already used by tickets cannot be edited in place", async () => {
  const { service, store } = setup();
  store.saveError = new TemplateException("TEMPLATE_IN_USE", "x");
  const body = { expectedVersion: 0, ...JSON.parse(definition()) };
  assert.equal(await codeOf(service.update(admin, 1, body)), "TEMPLATE_IN_USE");
  // Phiên bản mới vẫn tạo được.
  store.saveError = null;
  await service.createVersion(admin, 1, body);
  assert.equal(store.saves.at(-1)?.mode, "PHIEN_BAN");
});

test("activate and retire pass expectedVersion and reject extra fields", async () => {
  const { service, store } = setup();
  await service.activate(admin, 2, { expectedVersion: 0 });
  await service.retire(admin, 1, { expectedVersion: 3 });
  assert.deepEqual(store.statusChanges, [
    [2, 0, "DANG_DUNG"],
    [1, 3, "NGUNG"],
  ]);
  await assert.rejects(service.activate(admin, 2, {}), {
    name: "BadRequestException",
  });
  await assert.rejects(
    service.activate(admin, 2, { expectedVersion: 0, status: "NGUNG" }),
    { name: "BadRequestException" },
  );
});

test("try builds the layout from template columns, saves nothing and audits once", async () => {
  const { service, store, recognizer, objects } = setup();
  const result = await service.tryTemplate(admin, 1, upload);
  assert.deepEqual(recognizer.recognizeCalls, [
    {
      signature: signature(),
      columns: [
        { index: 0, role: "STT" },
        { index: 1, role: "HO_TEN" },
        { index: 2, role: "DIEM", key: "TX1", writtenIndex: 3 },
        { index: 3, role: "DIEM_CHU" },
        { index: 4, role: "DIEM", key: "GK1", writtenIndex: null },
      ],
    },
  ]);
  assert.equal(result.rows[0]?.sttRead, 1);
  assert.equal(result.rows[0]?.nameRead, "Họ tên giả");
  assert.deepEqual(
    result.rows[0]?.grades.map((g) => [g.key, g.writtenValue, g.reviewLevel]),
    [
      ["TX1", "8.0", "XANH"],
      ["GK1", null, "VANG"],
    ],
  );
  // Không có ảnh ô cắt, không ghép học sinh, không lưu gì ngoài một dòng audit "thử mẫu".
  assert.equal(JSON.stringify(result).includes("CropBase64"), false);
  assert.equal(JSON.stringify(result).includes("studentId"), false);
  assert.equal(store.saves.length, 0);
  assert.equal(store.statusChanges.length, 0);
  assert.equal(objects.size, 0);
  assert.deepEqual(store.audits, [["FORM_TEMPLATE_TRIED", "mau_bang_diem:1"]]);
  assert.deepEqual(store.rateLimits, ["FORM_TEMPLATE_TRY"]);
});

test("try failures map to stable codes and write no audit", async () => {
  const { service, store, recognizer } = setup();
  const expected: Array<[string, TemplateErrorCode, number]> = [
    ["MODEL_UNAVAILABLE", "MODEL_UNAVAILABLE", 503],
    ["RECOGNITION_TIMEOUT", "RECOGNITION_TIMEOUT", 504],
    ["TEMPLATE_MISMATCH", "TEMPLATE_MISMATCH", 422],
    ["IMAGE_QUALITY_LOW", "IMAGE_QUALITY_LOW", 422],
    ["MALFORMED_RESPONSE", "MALFORMED_RESPONSE", 502],
  ];
  for (const [serviceCode, code, status] of expected) {
    recognizer.failure = new RecognitionV2Error(
      serviceCode,
      serviceCode === "TEMPLATE_MISMATCH"
        ? { score: 0.4, minScore: 0.8, unmappedColumns: [2] }
        : null,
    );
    try {
      await service.tryTemplate(admin, 1, upload);
      assert.fail("expected a failure");
    } catch (error) {
      assert.ok(error instanceof TemplateException);
      assert.equal(error.code, code);
      assert.equal(error.getStatus(), status);
      if (code === "TEMPLATE_MISMATCH")
        assert.deepEqual(error.details, {
          score: 0.4,
          minScore: 0.8,
          unmappedColumns: [2],
        });
    }
  }
  assert.deepEqual(store.audits, []);
  assert.equal(store.saves.length, 0);
});

test("try honours the rate limit and unknown templates", async () => {
  const { service, store, recognizer } = setup();
  store.allowRate = false;
  try {
    await service.tryTemplate(admin, 1, upload);
    assert.fail("expected 429");
  } catch (error) {
    assert.ok(error instanceof HttpException);
    assert.equal(error.getStatus(), 429);
  }
  assert.equal(recognizer.recognizeCalls.length, 0);
  store.allowRate = true;
  assert.equal(
    await codeOf(service.tryTemplate(admin, 99, upload)),
    "TEMPLATE_NOT_FOUND",
  );
});

test("the error filter writes the stable envelope with request id and details", () => {
  let status = 0;
  let body: unknown;
  const response = {
    status(value: number) {
      status = value;
      return this;
    },
    json(value: unknown) {
      body = value;
    },
    getHeader: () => "req-1",
  };
  new TemplateErrorFilter().catch(
    new TemplateException("TEMPLATE_IN_USE", "đang dùng", { a: 1 }),
    {
      switchToHttp: () => ({ getResponse: () => response }),
    } as never,
  );
  assert.equal(status, 409);
  assert.deepEqual(body, {
    code: "TEMPLATE_IN_USE",
    message: "đang dùng",
    details: { a: 1 },
    requestId: "req-1",
  });
});

// ── Store: dịch lỗi của hàm SQL ──

function failingDb(message: string, state: string, code = "P2010") {
  let attempts = 0;
  const db = {
    attempts: () => attempts,
    $transaction: async (work: (tx: unknown) => Promise<unknown>) => {
      attempts += 1;
      return work({
        $queryRaw: async () => {
          throw Object.assign(
            new Error(
              `Raw query failed. Code: \`${state}\`. Message: \`${message}\``,
            ),
            { code, meta: { code: state, message } },
          );
        },
      });
    },
  };
  return db;
}

const saveInput = (): SaveTemplate => ({
  actor: admin,
  mode: "SUA",
  templateId: 1,
  expectedVersion: 0,
  name: "Mẫu",
  description: null,
  columns: columns(),
});

test("SQL errors are translated to stable template codes", async () => {
  const cases: Array<[string, string, string]> = [
    ["ERROR: TEMPLATE_IN_USE", "23514", "TEMPLATE_IN_USE"],
    ["ERROR: VERSION_CONFLICT", "23514", "VERSION_CONFLICT"],
    ["ERROR: TEMPLATE_INACTIVE", "23514", "TEMPLATE_INACTIVE"],
    ["ERROR: TEMPLATE_NOT_FOUND", "P0002", "TEMPLATE_NOT_FOUND"],
    [
      "ERROR: INVALID_TEMPLATE_DEFINITION: HO_TEN",
      "23514",
      "INVALID_TEMPLATE_DEFINITION",
    ],
    [
      "ERROR: INVALID_TEMPLATE_DEFINITION: SO_COT",
      "23514",
      "TEMPLATE_COLUMN_COUNT_MISMATCH",
    ],
  ];
  for (const [message, state, code] of cases) {
    const store = new PrismaFormTemplateStore(
      failingDb(message, state) as never,
      {} as never,
    );
    assert.equal(await codeOf(store.save(saveInput())), code, message);
  }
  const forbidden = new PrismaFormTemplateStore(
    failingDb("ERROR: FORBIDDEN", "42501") as never,
    {} as never,
  );
  await assert.rejects(forbidden.save(saveInput()), ForbiddenException);
});

test("serialization failures are retried and then reported as a conflict", async () => {
  const db = failingDb("could not serialize", "40001");
  const store = new PrismaFormTemplateStore(db as never, {} as never);
  await assert.rejects(store.save(saveInput()), ConflictException);
  assert.equal(db.attempts(), 3);
});

test("save passes the session, mode, version and JSON columns to luu_mau_bang_diem", async () => {
  let values: unknown[] = [];
  const db = {
    $transaction: async (work: (tx: unknown) => Promise<unknown>) =>
      work({
        $queryRaw: async (_strings: unknown, ...args: unknown[]) => {
          values = args;
          return [{ result: { templateId: 5 } }];
        },
      }),
  };
  const store = new PrismaFormTemplateStore(db as never, {} as never);
  assert.deepEqual(await store.save(saveInput()), { templateId: 5 });
  assert.equal(values[0], admin.sessionHash);
  assert.equal(values[1], "SUA");
  assert.equal(values[2], 1);
  assert.equal(values[3], 0);
  assert.equal(values[4], "Mẫu");
  assert.equal(values[5], null);
  assert.deepEqual(JSON.parse(values[6] as string), columns());
  // Chế độ không phải TAO: không gửi chữ ký hay ảnh.
  assert.deepEqual(values.slice(7), [null, null, null]);
});

// ── Client HTTP v2 với fetch giả ──

const analysisBody = () => ({
  signature: signature(4),
  columns: analysis(4).columns,
  previewPngBase64: "AAAA",
});

const recognizeBody = () => ({
  modelVersion: "fake-v2",
  pageStartStt: 1,
  templateMatch: { score: 0.95, columnMap: { "0": 0, "1": 1 } },
  rows: [
    {
      rowIndex: 1,
      struck: false,
      stt: { raw: "1", value: 1, confidence: "0.9000", isBlank: false },
      name: { raw: "Họ tên giả", confidence: "0.9000", isBlank: false },
      nameCropBase64: "AAAA",
      sttRead: 1,
      sttFromPosition: null,
      grades: [
        {
          key: "GK1",
          numeric: {
            rawOutput: "7",
            value: "7.0",
            confidence: "0.9500",
            isBlank: false,
          },
          written: null,
          numericCropBase64: "AAAA",
          writtenCropBase64: null,
          comparison: "MOT_KENH",
          reviewLevel: "VANG",
          suggestedSource: "SO",
        },
      ],
    },
  ],
});

const respond = (
  status: number,
  body: unknown,
  calls: Array<[string, RequestInit]> = [],
) =>
  (async (url: string | URL | Request, init?: RequestInit) => {
    calls.push([String(url), init!]);
    return new Response(
      typeof body === "string" ? body : JSON.stringify(body),
      {
        status,
      },
    );
  }) as typeof fetch;

const layout = (): V2Layout => ({
  signature: signature(4),
  columns: [
    { index: 1, role: "HO_TEN" },
    { index: 2, role: "DIEM", key: "GK1", writtenIndex: null },
  ],
});

test("v2 client parses layout analysis and posts only the image", async () => {
  const calls: Array<[string, RequestInit]> = [];
  const client = new HttpRecognitionV2Client(
    "http://recognition.test",
    respond(200, analysisBody(), calls),
  );
  const result = await client.analyzeLayout(png());
  assert.equal(result.columns.length, 4);
  assert.equal(calls[0]![0], "http://recognition.test/v2/layout/analyze");
  const form = calls[0]![1].body as FormData;
  assert.deepEqual([...form.keys()], ["image"]);
});

test("v2 client sends the layout JSON and parses a one-channel result", async () => {
  const calls: Array<[string, RequestInit]> = [];
  const client = new HttpRecognitionV2Client(
    "http://recognition.test",
    respond(200, recognizeBody(), calls),
  );
  const result = await client.recognize(png(), layout());
  assert.equal(calls[0]![0], "http://recognition.test/v2/recognize");
  const form = calls[0]![1].body as FormData;
  assert.deepEqual(JSON.parse(form.get("layout") as string), layout());
  assert.deepEqual(result.templateMatch.columnMap, { 0: 0, 1: 1 });
  assert.equal(result.rows[0]!.grades[0]!.written, null);
});

test("v2 client never accepts a Green one-channel cell or a malformed body", async () => {
  const green = recognizeBody();
  green.rows[0]!.grades[0]!.reviewLevel = "XANH";
  const bodies: unknown[] = [
    green,
    { ...recognizeBody(), rows: [{ rowIndex: 1 }] },
    { ...recognizeBody(), templateMatch: { score: 2, columnMap: {} } },
    "not json",
  ];
  for (const body of bodies) {
    const client = new HttpRecognitionV2Client(
      "http://recognition.test",
      respond(200, body),
    );
    await assert.rejects(client.recognize(png(), layout()), {
      code: "MALFORMED_RESPONSE",
    });
  }
  const wrongColumns = analysisBody();
  wrongColumns.columns = wrongColumns.columns.slice(1);
  await assert.rejects(
    new HttpRecognitionV2Client(
      "http://recognition.test",
      respond(200, wrongColumns),
    ).analyzeLayout(png()),
    { code: "MALFORMED_RESPONSE" },
  );
});

test("v2 client maps unavailable, timeout, 422 and server errors", async () => {
  const client = (fetcher: typeof fetch) =>
    new HttpRecognitionV2Client("http://recognition.test", fetcher);
  await assert.rejects(
    client(respond(503, { detail: "MODEL_UNAVAILABLE" })).recognize(
      png(),
      layout(),
    ),
    { code: "MODEL_UNAVAILABLE" },
  );
  await assert.rejects(
    client(respond(500, "boom")).recognize(png(), layout()),
    { code: "RECOGNITION_SERVICE_ERROR" },
  );
  const timeout = (async () => {
    throw new DOMException("timed out", "TimeoutError");
  }) as unknown as typeof fetch;
  await assert.rejects(client(timeout).recognize(png(), layout()), {
    code: "RECOGNITION_TIMEOUT",
  });
  // Header tới rồi body mới bị treo đến khi hết hạn: vẫn là RECOGNITION_TIMEOUT, cả HTTP 200 lẫn 422.
  for (const status of [200, 422]) {
    const stalledBody = (async (_url: unknown, init?: RequestInit) =>
      new Response(
        new ReadableStream({
          start(controller) {
            init?.signal?.addEventListener(
              "abort",
              () => controller.error(init.signal?.reason),
              { once: true },
            );
          },
        }),
        { status },
      )) as unknown as typeof fetch;
    await assert.rejects(
      new HttpRecognitionV2Client(
        "http://recognition.test",
        stalledBody,
        20,
        20,
      ).recognize(png(), layout()),
      { code: "RECOGNITION_TIMEOUT" },
    );
  }
  const down = (async () => {
    throw new TypeError("fetch failed");
  }) as unknown as typeof fetch;
  await assert.rejects(client(down).analyzeLayout(png()), {
    code: "MODEL_UNAVAILABLE",
  });

  const mismatch = {
    detail: {
      code: "TEMPLATE_MISMATCH",
      message: "tự do",
      details: { score: 0.5, minScore: 0.8, unmappedColumns: [2] },
    },
  };
  await assert.rejects(
    client(respond(422, mismatch)).recognize(png(), layout()),
    (error: RecognitionV2Error) =>
      error.code === "TEMPLATE_MISMATCH" &&
      (error.details as { score: number }).score === 0.5 &&
      !JSON.stringify(error).includes("tự do"),
  );
  await assert.rejects(
    client(
      respond(422, { detail: { code: "GRID_NOT_FOUND", message: "m" } }),
    ).analyzeLayout(png()),
    (error: RecognitionV2Error) =>
      error.code === "GRID_NOT_FOUND" && error.details === null,
  );
  await assert.rejects(
    client(
      respond(422, { detail: { code: "SOMETHING_ELSE", message: "m" } }),
    ).analyzeLayout(png()),
    { code: "RECOGNITION_SERVICE_ERROR" },
  );
});
