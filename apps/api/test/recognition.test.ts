import assert from "node:assert/strict";
import { test } from "node:test";
import type {
  ObjectStorage,
  StoredObject,
} from "../src/modules/files/application/port.js";
import type { Actor } from "../src/modules/authorization/application/policy.js";
import { inspectImage } from "../src/modules/recognition/application/image.js";
import type {
  RecognitionOutbox,
  RecognitionOutboxEvent,
  RecognitionQueue,
} from "../src/modules/recognition/application/outbox.js";
import { RecognitionDispatcher } from "../src/modules/recognition/application/outbox.js";
import { BadRequestException } from "@nestjs/common";
import type {
  CancelRecognitionTicket,
  CreateRecognitionTicket,
  RecognitionStore,
} from "../src/modules/recognition/application/port.js";
import { RecognitionService } from "../src/modules/recognition/application/service.js";

function png(width = 2, height = 3): Uint8Array {
  const bytes = new Uint8Array(24);
  bytes.set([137, 80, 78, 71, 13, 10, 26, 10]);
  bytes.set([73, 72, 68, 82], 12);
  new DataView(bytes.buffer).setUint32(16, width);
  new DataView(bytes.buffer).setUint32(20, height);
  return bytes;
}

function jpeg(): Uint8Array {
  return Uint8Array.from([
    0xff, 0xd8, 0xff, 0xc0, 0x00, 0x11, 0x08, 0x00, 0x03, 0x00, 0x02, 0x03,
    0x01, 0x11, 0x00, 0x02, 0x11, 0x00, 0x03, 0x11, 0x00, 0xff, 0xd9,
  ]);
}

const actor: Actor = {
  id: 7,
  username: "teacher_test",
  role: "GIAO_VIEN",
  sessionHash: "a".repeat(64),
};

test("image inspection trusts bytes, not a claimed MIME", () => {
  assert.deepEqual(inspectImage(png(), "image/png"), {
    contentType: "image/png",
    extension: "png",
    width: 2,
    height: 3,
  });
  assert.deepEqual(inspectImage(jpeg(), "image/jpeg"), {
    contentType: "image/jpeg",
    extension: "jpg",
    width: 2,
    height: 3,
  });
  assert.throws(() => inspectImage(png(), "image/jpeg"));
  assert.throws(() => inspectImage(new Uint8Array([1, 2, 3]), "image/png"));
  assert.throws(() => inspectImage(png(10_001, 1), "image/png"));
});

test("upload keeps one object on replay and never exposes the object key", async () => {
  const objects = new Map<string, StoredObject>();
  const storage: ObjectStorage = {
    put: async (object) => void objects.set(object.key, object),
    get: async (key) => objects.get(key)!.bytes,
    signedGetUrl: async (key) => `https://storage.test/${key}`,
    remove: async (key) => void objects.delete(key),
  };
  let stored: CreateRecognitionTicket | undefined;
  const store: RecognitionStore = {
    authorizeUpload: async () => {},
    list: async () => [],
    detail: async () => null,
    cancel: async () => assert.fail("not used"),
    createTicket: async (input) => {
      if (!stored) stored = input;
      return {
        ticketId: "42",
        jobId: "recognition-42",
        status: "DANG_XU_LY",
        storedObjectKey: stored.objectKey,
      };
    },
  };
  const service = new RecognitionService(store, storage);
  const upload = {
    bytes: png(),
    claimedType: "image/png",
    componentId: "2",
  };
  const first = await service.upload(actor, 1, "same-key", upload);
  const replay = await service.upload(actor, 1, "same-key", upload);
  assert.deepEqual(replay, first);
  assert.deepEqual(first, {
    ticketId: "42",
    jobId: "recognition-42",
    status: "DANG_XU_LY",
  });
  assert.equal(objects.size, 1);
  assert.equal("declaredRows" in stored!, false);
  assert.equal(stored!.componentId, 2);
});

test("legacy declaredRows never changes the idempotency hash", async () => {
  const hashes: string[] = [];
  const store: RecognitionStore = {
    authorizeUpload: async () => {},
    list: async () => [],
    detail: async () => null,
    cancel: async () => assert.fail("not used"),
    createTicket: async (input) => {
      hashes.push(input.requestHash);
      return {
        ticketId: "42",
        jobId: "recognition-42",
        status: "DANG_XU_LY",
        storedObjectKey: input.objectKey,
      };
    },
  };
  const storage: ObjectStorage = {
    put: async () => {},
    get: async () => new Uint8Array(),
    signedGetUrl: async () => "",
    remove: async () => {},
  };
  const service = new RecognitionService(store, storage);
  const base = { bytes: png(), claimedType: "image/png", componentId: "2" };
  await service.upload(actor, 1, "key-a", base);
  await service.upload(actor, 1, "key-b", {
    ...base,
    declaredRows: "99",
  } as typeof base);
  assert.equal(hashes.length, 2);
  assert.equal(hashes[0], hashes[1]);
});

test("detail signs private images and keeps storage keys internal", async () => {
  const signed: string[] = [];
  const storage: ObjectStorage = {
    put: async () => {},
    get: async () => new Uint8Array(),
    signedGetUrl: async (key, expires) => {
      signed.push(`${key}:${expires}`);
      return `https://storage.test/${key}?expires=${expires}`;
    },
    remove: async () => {},
  };
  const store: RecognitionStore = {
    authorizeUpload: async () => {},
    createTicket: async () => assert.fail("not used"),
    list: async () => [],
    cancel: async () => assert.fail("not used"),
    detail: async () => ({
      ticketId: "42",
      gradebookId: 1,
      componentId: 2,
      componentName: "Giữa kỳ",
      declaredRows: 1,
      detectedRows: 1,
      status: "CHO_DOI_CHIEU",
      errorCode: null,
      modelVersion: "fake-dev-v1",
      version: 1,
      createdAt: "2026-09-12T00:00:00.000Z",
      cancelReason: null,
      cancelledAt: null,
      greenRows: 1,
      yellowRows: 0,
      redRows: 0,
      sourceObjectKey: "recognition/original/private.png",
      rows: [
        {
          rowId: "9",
          order: 1,
          stt: 4,
          sttOnPaper: 4,
          studentId: 3,
          studentName: "Học sinh giả",
          nameRead: "Hoc sinh gia",
          matchConfidence: "0.9700",
          matchNote: "Khớp họ tên và STT.",
          numericRaw: "0.0",
          numericValue: "0.0",
          numericConfidence: "0.9500",
          writtenRaw: "không",
          writtenValue: "0.0",
          writtenConfidence: "0.9300",
          comparison: "KHOP",
          reviewLevel: "XANH",
          suggestedSource: "SO",
          matchLevel: "XANH",
          gradeLevel: "XANH",
          finalValue: null,
          numericCropKey: "recognition/crops/42/1-numeric.png",
          writtenCropKey: "recognition/crops/42/1-written.png",
          nameCropKey: "recognition/crops/42/1-name.png",
        },
      ],
    }),
  };
  const result = await new RecognitionService(store, storage).detail(
    actor,
    1,
    "42",
  );
  assert.equal(result.sourceImageUrl.includes("private.png"), true);
  assert.equal(result.rows[0]!.numericValue, "0.0");
  assert.equal(result.rows[0]!.numericCropUrl?.includes("numeric.png"), true);
  assert.equal("sourceObjectKey" in result, false);
  assert.equal("numericCropKey" in result.rows[0]!, false);
  assert.equal("nameCropKey" in result.rows[0]!, false);
  assert.equal(result.rows[0]!.nameCropUrl?.includes("1-name.png"), true);
  assert.equal(result.rows[0]!.stt, 4);
  assert.equal(result.rows[0]!.sttOnPaper, 4);
  assert.equal(result.rows[0]!.nameRead, "Hoc sinh gia");
  assert.equal(result.rows[0]!.matchConfidence, "0.9700");
  assert.equal(result.rows[0]!.matchNote, "Khớp họ tên và STT.");
  assert.equal(result.rows[0]!.suggestedSource, "SO");
  assert.equal(result.rows[0]!.matchLevel, "XANH");
  assert.equal(result.rows[0]!.gradeLevel, "XANH");
  // Không trường nào của bản ghi trong kho được âm thầm bỏ khi dựng DTO (ngoài khóa đối tượng, được đổi thành URL ký).
  const stored = (await store.detail(actor, 1, "42"))!.rows[0]!;
  for (const key of Object.keys(stored).filter((k) => !k.endsWith("CropKey")))
    assert.equal(key in result.rows[0]!, true, `thiếu trường ${key}`);
  assert.deepEqual(
    [result.greenRows, result.yellowRows, result.redRows],
    [1, 0, 0],
  );
  assert.deepEqual(signed, [
    "recognition/original/private.png:300",
    "recognition/crops/42/1-numeric.png:300",
    "recognition/crops/42/1-written.png:300",
    "recognition/crops/42/1-name.png:300",
  ]);
});

test("dispatcher publishes a claimed outbox event and acknowledges it", async () => {
  const event: RecognitionOutboxEvent = {
    id: "9",
    ticketId: "42",
    jobId: "recognition-42",
    attempts: 1,
  };
  const calls: string[] = [];
  const outbox: RecognitionOutbox = {
    claim: async () => [event],
    published: async (id) => void calls.push("published:" + id),
    failed: async (id) => void calls.push("failed:" + id),
  };
  const queue: RecognitionQueue = {
    enqueue: async (item) => void calls.push("queued:" + item.jobId),
    close: async () => {},
  };
  assert.equal(
    await new RecognitionDispatcher(outbox, queue).dispatchOnce(),
    1,
  );
  assert.deepEqual(calls, ["queued:recognition-42", "published:9"]);
});

const cancelStorage = (removed: string[], failing = new Set<string>()) =>
  ({
    put: async () => {},
    get: async () => new Uint8Array(),
    signedGetUrl: async (key: string) => `https://storage.test/${key}`,
    remove: async (key: string) => {
      if (failing.has(key)) throw new Error("storage down");
      removed.push(key);
    },
  }) satisfies ObjectStorage;

function cancelStore(
  calls: CancelRecognitionTicket[],
  keys = ["recognition/original/a.png", "recognition/crops/42/1-numeric.png"],
): RecognitionStore {
  const cancelled = {
    ticketId: "42",
    gradebookId: 1,
    componentId: 2,
    componentName: "Giữa kỳ",
    declaredRows: 1,
    detectedRows: 1,
    status: "DA_HUY" as const,
    errorCode: null,
    modelVersion: "fake-dev-v1",
    version: 3,
    createdAt: "2026-09-12T00:00:00.000Z",
    cancelReason: "Chụp nhầm bảng",
    cancelledAt: "2026-09-12T01:00:00.000Z",
    greenRows: 1,
    yellowRows: 0,
    redRows: 0,
    sourceObjectKey: keys[0]!,
    rows: [
      {
        rowId: "9",
        order: 1,
        stt: 1,
        sttOnPaper: 1,
        studentId: 3,
        studentName: "Học sinh giả",
        nameRead: null,
        matchConfidence: null,
        matchNote: null,
        numericRaw: "8.0",
        numericValue: "8.0",
        numericConfidence: "0.9900",
        writtenRaw: null,
        writtenValue: null,
        writtenConfidence: null,
        comparison: "MOT_KENH" as const,
        reviewLevel: "VANG" as const,
        suggestedSource: "SO" as const,
        matchLevel: "XANH" as const,
        gradeLevel: "VANG" as const,
        finalValue: null,
        numericCropKey: "recognition/crops/42/1-numeric.png",
        writtenCropKey: null,
        nameCropKey: null,
      },
    ],
  };
  return {
    authorizeUpload: async () => {},
    createTicket: async () => assert.fail("not used"),
    list: async () => [],
    detail: async () => cancelled,
    cancel: async (input) => {
      calls.push(input);
      return { objectKeys: keys };
    },
  };
}

test("cancel validates input, hashes it, removes images and returns the cancelled ticket without image URLs", async () => {
  const calls: CancelRecognitionTicket[] = [];
  const removed: string[] = [];
  const service = new RecognitionService(
    cancelStore(calls),
    cancelStorage(removed),
  );
  const result = await service.cancel(actor, 1, "42", "cancel-key", {
    expectedVersion: 2,
    reason: "  Chụp nhầm bảng  ",
  });
  assert.equal(calls.length, 1);
  assert.equal(calls[0]!.reason, "Chụp nhầm bảng");
  assert.equal(calls[0]!.expectedVersion, 2);
  assert.match(calls[0]!.requestHash, /^[0-9a-f]{64}$/);
  assert.deepEqual(removed.sort(), [
    "recognition/crops/42/1-numeric.png",
    "recognition/original/a.png",
  ]);
  assert.equal(result.status, "DA_HUY");
  assert.equal(result.cancelReason, "Chụp nhầm bảng");
  assert.equal(result.cancelledAt, "2026-09-12T01:00:00.000Z");
  // Ảnh đã bị xóa nên không ký URL.
  assert.equal(result.sourceImageUrl, "");
  assert.equal(result.rows[0]!.numericCropUrl, null);
  // Cùng yêu cầu → cùng hash (idempotency); khác lý do → hash khác.
  await service.cancel(actor, 1, "42", "cancel-key", {
    expectedVersion: 2,
    reason: "Chụp nhầm bảng",
  });
  await service.cancel(actor, 1, "42", "cancel-key", {
    expectedVersion: 2,
    reason: "Lý do khác",
  });
  assert.equal(calls[1]!.requestHash, calls[0]!.requestHash);
  assert.notEqual(calls[2]!.requestHash, calls[0]!.requestHash);
});

test("cancel survives storage cleanup failures (best-effort, logged only)", async () => {
  const calls: CancelRecognitionTicket[] = [];
  const removed: string[] = [];
  const service = new RecognitionService(
    cancelStore(calls),
    cancelStorage(removed, new Set(["recognition/original/a.png"])),
  );
  const result = await service.cancel(actor, 1, "42", "cancel-key", {
    expectedVersion: 0,
    reason: "x",
  });
  assert.equal(result.status, "DA_HUY");
  assert.deepEqual(removed, ["recognition/crops/42/1-numeric.png"]);
});

test("cancel rejects malformed requests before touching the store", async () => {
  const calls: CancelRecognitionTicket[] = [];
  const service = new RecognitionService(cancelStore(calls), cancelStorage([]));
  const ok = { expectedVersion: 1, reason: "lý do" };
  const bad: Array<[string, unknown, unknown, unknown]> = [
    ["no key", "42", undefined, ok],
    ["bad key", "42", "bad key!", ok],
    ["bad ticket", "0", "k", ok],
    ["huge ticket", "9223372036854775808", "k", ok],
    ["no body", "42", "k", null],
    ["extra field", "42", "k", { ...ok, extra: 1 }],
    ["negative version", "42", "k", { ...ok, expectedVersion: -1 }],
    ["float version", "42", "k", { ...ok, expectedVersion: 1.5 }],
    ["string version", "42", "k", { ...ok, expectedVersion: "1" }],
    ["empty reason", "42", "k", { ...ok, reason: "   " }],
    ["long reason", "42", "k", { ...ok, reason: "a".repeat(201) }],
    ["numeric reason", "42", "k", { ...ok, reason: 5 }],
  ];
  for (const [name, ticket, key, body] of bad)
    await assert.rejects(
      service.cancel(actor, 1, ticket, key, body),
      BadRequestException,
      name,
    );
  assert.equal(calls.length, 0);
  // Đủ 200 ký tự thì hợp lệ.
  await service.cancel(actor, 1, "42", "k", {
    expectedVersion: 0,
    reason: "a".repeat(200),
  });
  assert.equal(calls.length, 1);
});

test("list only accepts includeCancelled true/false and passes the flag to the store", async () => {
  const flags: boolean[] = [];
  const store: RecognitionStore = {
    ...cancelStore([]),
    list: async (_actor, _id, includeCancelled) => {
      flags.push(includeCancelled);
      return [];
    },
  };
  const service = new RecognitionService(store, cancelStorage([]));
  await service.list(actor, 1);
  await service.list(actor, 1, "false");
  await service.list(actor, 1, "true");
  assert.deepEqual(flags, [false, false, true]);
  assert.throws(() => service.list(actor, 1, "yes"), BadRequestException);
});
