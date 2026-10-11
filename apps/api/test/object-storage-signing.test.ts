import assert from "node:assert/strict";
import { mock, test } from "node:test";
import { GetObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { S3ObjectStorage } from "../src/modules/files/infrastructure/s3-object-storage.js";
import type { Settings } from "../src/common/database.js";

const base: Settings = {
  environment: "development",
  origins: [],
  s3Endpoint: "http://localhost:9000",
  s3AccessKey: "test-access",
  s3SecretKey: "test-secret",
  s3Bucket: "gradebook-images",
};
const KEY = "recognition/crops/42/1-numeric.png";
const FROZEN = new Date("2026-10-10T08:00:00.000Z");

const reference = (endpoint: string) =>
  getSignedUrl(
    new S3Client({
      endpoint,
      region: "us-east-1",
      forcePathStyle: true,
      credentials: {
        accessKeyId: "test-access",
        secretAccessKey: "test-secret",
      },
    }),
    new GetObjectCommand({ Bucket: "gradebook-images", Key: KEY }),
    { expiresIn: 60, signingDate: FROZEN },
  );

test("signed URLs use S3_ENDPOINT when no public endpoint is configured", async () => {
  mock.timers.enable({ apis: ["Date"], now: FROZEN });
  try {
    const url = await new S3ObjectStorage(base).signedGetUrl(KEY, 60);
    assert.equal(new URL(url).host, "localhost:9000");
    assert.equal(url, await reference("http://localhost:9000"));
  } finally {
    mock.timers.reset();
  }
});

test("signed URLs are signed directly with S3_PUBLIC_ENDPOINT, not rewritten after signing", async () => {
  mock.timers.enable({ apis: ["Date"], now: FROZEN });
  try {
    const publicEndpoint = "http://192.168.0.10:9000";
    const storage = new S3ObjectStorage({
      ...base,
      s3PublicEndpoint: publicEndpoint,
    });
    const url = await storage.signedGetUrl(KEY, 60);
    const parsed = new URL(url);
    assert.equal(parsed.host, "192.168.0.10:9000");
    assert.equal(parsed.pathname, `/gradebook-images/${KEY}`);
    // Chữ ký tính trực tiếp cho host công khai (host nằm trong chữ ký)...
    assert.equal(url, await reference(publicEndpoint));
    // ...nên khác với URL ký cho host nội bộ rồi chỉ thay chuỗi host.
    const internal = await reference("http://localhost:9000");
    assert.notEqual(
      parsed.searchParams.get("X-Amz-Signature"),
      new URL(internal).searchParams.get("X-Amz-Signature"),
    );
    // Thay host bằng chuỗi sau khi ký sẽ cho URL khác (chữ ký sai), nên không làm như vậy.
    assert.notEqual(
      url,
      internal.replace("http://localhost:9000", publicEndpoint),
    );
    // Hết hạn vẫn bị giới hạn như cũ.
    await assert.rejects(storage.signedGetUrl(KEY, 301));
    await assert.rejects(storage.signedGetUrl(KEY, 0));
  } finally {
    mock.timers.reset();
  }
});

test("an unconfigured storage still refuses to sign", async () => {
  const storage = new S3ObjectStorage({
    environment: "development",
    origins: [],
    s3PublicEndpoint: "http://192.168.0.10:9000",
  });
  await assert.rejects(storage.signedGetUrl(KEY, 60));
});
