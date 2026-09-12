import "dotenv/config";
import assert from "node:assert/strict";
import { createHash, randomUUID } from "node:crypto";
import { test } from "node:test";
import { HeadObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { Queue } from "bullmq";
import { readConfig } from "../../src/common/config.js";
import { S3ObjectStorage } from "../../src/modules/files/infrastructure/s3-object-storage.js";
import {
  BullRecognitionQueue,
  redisConnection,
} from "../../src/modules/recognition/infrastructure/bull-queue.js";

test("recognition infrastructure stores a private object and deduplicates BullMQ job IDs", async () => {
  const config = readConfig(process.env);
  const storage = new S3ObjectStorage(config);
  const key = `recognition/original/${randomUUID()}.png`;
  const bytes = new Uint8Array([137, 80, 78, 71, 13, 10, 26, 10]);
  const checksum = createHash("sha256").update(bytes).digest("hex");
  const s3 = new S3Client({
    endpoint: config.s3Endpoint,
    region: "us-east-1",
    forcePathStyle: true,
    credentials: {
      accessKeyId: config.s3AccessKey,
      secretAccessKey: config.s3SecretKey,
    },
  });
  const queue = new BullRecognitionQueue(config.redisUrl);
  const inspection = new Queue("recognition", {
    connection: redisConnection(config.redisUrl),
  });
  const jobId = `recognition-infra-${randomUUID()}`;
  try {
    await storage.put({ key, bytes, contentType: "image/png", checksum });
    const stored = await s3.send(
      new HeadObjectCommand({ Bucket: config.s3Bucket, Key: key }),
    );
    assert.equal(stored.Metadata?.sha256, checksum);
    assert.deepEqual(await storage.get(key), bytes);
    const event = { id: "1", ticketId: "999", jobId, attempts: 1 };
    await queue.enqueue(event);
    await queue.enqueue(event);
    const job = await inspection.getJob(jobId);
    assert.deepEqual(job?.data, { ticketId: "999" });
    assert.equal(job?.opts.attempts, 3);
    await job?.remove();
  } finally {
    await storage.remove(key);
    await queue.close();
    await inspection.close();
    s3.destroy();
  }
});
