import "dotenv/config";
import { test } from "node:test";
import assert from "node:assert/strict";
import { readConfig } from "../../src/common/config.js";
import { InfrastructureProbe } from "../../src/common/dependency-probe.js";

test("real stack is ready and private bucket rejects anonymous access", async () => {
  const config = readConfig(process.env);
  const probe = new InfrastructureProbe(config);
  try {
    assert.equal(await probe.check(), true);
    const response = await fetch(`${config.s3Endpoint}/${config.s3Bucket}`);
    assert.equal(response.status, 403);
  } finally {
    await probe.close();
  }
});
test("an unavailable dependency fails readiness within a bounded time", async () => {
  const config = readConfig(process.env);
  const probe = new InfrastructureProbe({
    ...config,
    redisUrl: "redis://127.0.0.1:1",
  });
  const started = performance.now();
  try {
    assert.equal(await probe.check(), false);
    assert.ok(performance.now() - started < 8000);
  } finally {
    await probe.close();
  }
});
