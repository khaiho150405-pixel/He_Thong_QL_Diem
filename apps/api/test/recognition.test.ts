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
    remove: async (key) => void objects.delete(key),
  };
  let stored: CreateRecognitionTicket | undefined;
  const store: RecognitionStore = {
    authorizeUpload: async () => {},
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
    declaredRows: "3",
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
