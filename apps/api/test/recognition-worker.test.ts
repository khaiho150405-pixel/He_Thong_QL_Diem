import assert from "node:assert/strict";
import { test } from "node:test";
import type {
  ObjectStorage,
  StoredObject,
} from "../src/modules/files/application/port.js";
import { RecognitionJobProcessor } from "../src/modules/recognition/application/worker.js";
import { HttpRecognitionModel } from "../src/modules/recognition/infrastructure/http-model.js";

const pixel =
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=";
const row = (order: number) => ({
  order,
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
  comparison: "KHOP" as const,
  reviewLevel: "XANH" as const,
});

test("worker preserves two channels and never writes an official grade", async () => {
  const objects = new Map<string, StoredObject>();
  objects.set("original.png", {
    key: "original.png",
    bytes: new Uint8Array([1]),
    contentType: "image/png",
    checksum: "a".repeat(64),
  });
  const storage: ObjectStorage = {
    put: async (value) => void objects.set(value.key, value),
    get: async (key) => objects.get(key)!.bytes,
    remove: async (key) => void objects.delete(key),
  };
  let completed: unknown[] | undefined;
  let failed: string | undefined;
  const processor = new RecognitionJobProcessor(
    {
      load: async () => ({
        status: "DANG_XU_LY",
        objectKey: "original.png",
        declaredRows: 2,
      }),
      complete: async (_id, _version, rows) => void (completed = rows),
      fail: async (_id, code) => void (failed = code),
    },
    storage,
    {
      recognize: async () => ({
        detectedRows: 2,
        modelVersion: "fake-dev-v1",
        rows: [row(1), row(2)],
      }),
    },
  );
  await processor.process("42");
  assert.equal(failed, undefined);
  assert.equal(completed?.length, 2);
  assert.equal(
    (completed?.[0] as { numeric: { value: string } }).numeric.value,
    "0.0",
  );
  assert.equal("officialGrade" in (completed?.[0] as object), false);
  assert.equal(objects.size, 5);
});

test("grid mismatch fails before persisting rows", async () => {
  let failure = "";
  const processor = new RecognitionJobProcessor(
    {
      load: async () => ({
        status: "DANG_XU_LY",
        objectKey: "x",
        declaredRows: 2,
      }),
      complete: async () => assert.fail("must not complete"),
      fail: async (_id, code) => void (failure = code),
    },
    {
      put: async () => {},
      get: async () => new Uint8Array([1]),
      remove: async () => {},
    },
    {
      recognize: async () => ({
        detectedRows: 1,
        modelVersion: "fake",
        rows: [row(1)],
      }),
    },
  );
  await processor.process("9");
  assert.equal(failure, "GRID_ROW_COUNT_MISMATCH");
});

test("HTTP model rejects malformed output and maps unavailable model", async () => {
  const malformed = new HttpRecognitionModel(
    "http://ocr",
    async () => new Response(JSON.stringify({ rows: [] }), { status: 200 }),
    100,
  );
  await assert.rejects(
    malformed.recognize(new Uint8Array([1]), 1),
    /MALFORMED_RESPONSE/,
  );
  const unavailable = new HttpRecognitionModel(
    "http://ocr",
    async () => new Response("", { status: 503 }),
    100,
  );
  await assert.rejects(
    unavailable.recognize(new Uint8Array([1]), 1),
    /MODEL_UNAVAILABLE/,
  );
  const timedOut = new HttpRecognitionModel(
    "http://ocr",
    async () => {
      throw new Error("timeout");
    },
    1,
  );
  await assert.rejects(
    timedOut.recognize(new Uint8Array([1]), 1),
    /RECOGNITION_TIMEOUT/,
  );
  const inconsistent = new HttpRecognitionModel(
    "http://ocr",
    async () =>
      new Response(
        JSON.stringify({
          detectedRows: 1,
          modelVersion: "bad",
          rows: [
            { ...row(1), comparison: "KHONG_DOC_DUOC", reviewLevel: "XANH" },
          ],
        }),
        { status: 200 },
      ),
    100,
  );
  await assert.rejects(
    inconsistent.recognize(new Uint8Array([1]), 1),
    /MALFORMED_RESPONSE/,
  );
});
