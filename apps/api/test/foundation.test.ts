import "reflect-metadata";
import { test } from "node:test";
import assert from "node:assert/strict";
import { createApp } from "../src/app.js";
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
});
