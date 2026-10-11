import "reflect-metadata";
import { test } from "node:test";
import assert from "node:assert/strict";
import { createApp, makeOpenApi } from "../src/app.js";
import { readConfig } from "../src/common/config.js";

test("health, failure envelope, correlation ID and CORS use real HTTP", async () => {
  let ready = true;
  let fail = false;
  const app = await createApp(
    { environment: "production", origins: ["http://localhost:8080"] },
    {
      check: async () => {
        if (fail) throw new Error("sensitive-internal-test-marker");
        return ready;
      },
      close: async () => {},
    },
  );
  await app.listen(0, "127.0.0.1");
  try {
    const schema = makeOpenApi(app).components!.schemas!.YearsInput as {
      properties: Record<string, { pattern: string }>;
    };
    const datePattern = new RegExp(schema.properties.ngay_bat_dau!.pattern);
    assert.equal(datePattern.test("2026-09-01"), true);
    assert.equal(datePattern.test("01/09/2026"), false);
    const url = await app.getUrl();
    const live = await fetch(`${url}/api/v1/health/live`, {
      headers: {
        "x-request-id": "test-request",
        origin: "http://localhost:8080",
      },
    });
    assert.equal(live.status, 200);
    assert.deepEqual(await live.json(), { status: "ok" });
    assert.equal(live.headers.get("x-request-id"), "test-request");
    assert.equal(live.headers.get("x-content-type-options"), "nosniff");
    assert.equal(live.headers.get("x-frame-options"), "DENY");
    assert.equal(live.headers.get("referrer-policy"), "no-referrer");
    assert.equal(live.headers.get("cache-control"), "no-store");
    assert.equal(
      live.headers.get("strict-transport-security"),
      "max-age=31536000; includeSubDomains",
    );
    assert.match(
      live.headers.get("content-security-policy") ?? "",
      /default-src/,
    );
    assert.equal(
      live.headers.get("access-control-allow-origin"),
      "http://localhost:8080",
    );
    ready = false;
    const unavailable = await fetch(`${url}/api/v1/health/ready`);
    assert.equal(unavailable.status, 503);
    assert.equal(
      ((await unavailable.json()) as { code: string }).code,
      "DEPENDENCY_UNAVAILABLE",
    );
    const missing = await fetch(`${url}/api/v1/missing`, {
      headers: {
        "x-request-id": "bad id",
        origin: "https://untrusted.example",
      },
    });
    assert.equal(missing.status, 404);
    assert.notEqual(missing.headers.get("x-request-id"), "bad id");
    assert.equal(missing.headers.get("access-control-allow-origin"), null);
    assert.equal(
      ((await missing.json()) as { code: string }).code,
      "NOT_FOUND",
    );
    fail = true;
    const internal = await fetch(`${url}/api/v1/health/ready`);
    assert.equal(internal.status, 500);
    const failureBody = await internal.text();
    assert.equal(JSON.parse(failureBody).code, "INTERNAL_ERROR");
    assert.ok(!failureBody.includes("sensitive-internal-test-marker"));
    const malformed = await fetch(`${url}/api/v1/health/live`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: "{",
    });
    assert.equal(malformed.status, 400);
    assert.equal(
      ((await malformed.json()) as { code: string }).code,
      "VALIDATION_ERROR",
    );
  } finally {
    await app.close();
  }
});
test("configuration fails without secrets and rejects owner database roles", () => {
  assert.throws(() => readConfig({}), /APP_ENV/);
  assert.throws(
    () =>
      readConfig({
        APP_ENV: "development",
        API_PORT: "3000",
        DATABASE_URL: "postgresql://postgres:hidden@localhost/db",
      }),
    /runtime role/,
  );
  const secure = {
    APP_ENV: "production",
    API_PORT: "3000",
    ALLOWED_ORIGINS: "https://grades.example.edu",
    DATABASE_URL:
      "postgresql://app_runtime:hidden@db.example.edu/grades?sslmode=verify-full",
    REDIS_URL: "rediss://cache.example.edu",
    S3_ENDPOINT: "https://objects.example.edu",
    S3_ACCESS_KEY: "runtime-access",
    S3_SECRET_KEY: "hidden-secret",
    S3_BUCKET: "gradebook-images",
    RECOGNITION_SERVICE_URL: "https://recognition.example.edu",
  };
  assert.equal(readConfig(secure).environment, "production");
  // S3_PUBLIC_ENDPOINT (tùy chọn): không đặt/để trống → undefined; kiểm http/https như S3_ENDPOINT, ngoài development phải https.
  assert.equal(readConfig(secure).s3PublicEndpoint, undefined);
  assert.equal(
    readConfig({ ...secure, S3_PUBLIC_ENDPOINT: "  " }).s3PublicEndpoint,
    undefined,
  );
  assert.equal(
    readConfig({ ...secure, S3_PUBLIC_ENDPOINT: "https://files.example.edu" })
      .s3PublicEndpoint,
    "https://files.example.edu",
  );
  assert.throws(
    () =>
      readConfig({ ...secure, S3_PUBLIC_ENDPOINT: "http://192.168.0.10:9000" }),
    /TLS required: S3_PUBLIC_ENDPOINT/,
  );
  for (const invalid of ["not a url", "ftp://files.example.edu"])
    assert.throws(
      () => readConfig({ ...secure, S3_PUBLIC_ENDPOINT: invalid }),
      /S3_PUBLIC_ENDPOINT/,
      invalid,
    );
  const development = {
    ...secure,
    APP_ENV: "development",
    ALLOWED_ORIGINS: "http://localhost:8080",
    REDIS_URL: "redis://localhost:6379",
    S3_ENDPOINT: "http://localhost:9000",
    RECOGNITION_SERVICE_URL: "http://localhost:8000",
    DATABASE_URL: "postgresql://app_runtime:hidden@localhost/grades",
  };
  assert.equal(
    readConfig({
      ...development,
      S3_PUBLIC_ENDPOINT: "http://192.168.0.10:9000",
    }).s3PublicEndpoint,
    "http://192.168.0.10:9000",
  );
  assert.equal(readConfig(development).s3PublicEndpoint, undefined);
  assert.equal(readConfig(secure).uploadRateLimitPerMinute, 10);
  assert.equal(
    readConfig({ ...secure, UPLOAD_RATE_LIMIT_PER_MINUTE: "25" })
      .uploadRateLimitPerMinute,
    25,
  );
  assert.throws(
    () => readConfig({ ...secure, UPLOAD_RATE_LIMIT_PER_MINUTE: "0" }),
    /UPLOAD_RATE_LIMIT_PER_MINUTE/,
  );
  assert.equal(readConfig(secure).recognitionTimeoutMs, 120_000);
  assert.equal(
    readConfig({ ...secure, RECOGNITION_TIMEOUT_MS: "45000" })
      .recognitionTimeoutMs,
    45_000,
  );
  for (const invalid of ["999", "600001", "abc", "1.5", "0"])
    assert.throws(
      () => readConfig({ ...secure, RECOGNITION_TIMEOUT_MS: invalid }),
      /RECOGNITION_TIMEOUT_MS/,
      invalid,
    );
  for (const insecure of [
    {
      ...secure,
      DATABASE_URL: "postgresql://app_runtime:hidden@db.example.edu/grades",
    },
    { ...secure, REDIS_URL: "redis://cache.example.edu" },
    { ...secure, S3_ENDPOINT: "http://objects.example.edu" },
    { ...secure, RECOGNITION_SERVICE_URL: "http://recognition.example.edu" },
  ])
    assert.throws(() => readConfig(insecure), /TLS required/);
});
