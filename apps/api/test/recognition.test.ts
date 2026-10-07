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
import type {
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
