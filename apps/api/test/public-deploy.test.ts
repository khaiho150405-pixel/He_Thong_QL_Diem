import "reflect-metadata";
import assert from "node:assert/strict";
import { test } from "node:test";
import { createApp } from "../src/app.js";
import { isPublicFacing, readConfig } from "../src/common/config.js";
import {
  accountFindings,
  allowedTestRoles,
  blockedPasswords,
  storageProblems,
  weakAccountCounts,
} from "../src/ops/public-deploy-check.js";
import { passwordProblem } from "../src/ops/set-admin-password.js";

const env = {
  APP_ENV: "development",
  API_PORT: "3000",
  ALLOWED_ORIGINS: "https://app.example.test",
  DATABASE_URL: "postgresql://app_runtime:x@127.0.0.1:5432/db",
  REDIS_URL: "redis://127.0.0.1:6379",
  S3_ENDPOINT: "http://127.0.0.1:9000",
  S3_ACCESS_KEY: "app",
  S3_SECRET_KEY: "secret",
  S3_BUCKET: "bucket",
  RECOGNITION_SERVICE_URL: "http://127.0.0.1:8000",
};

test("PUBLIC_DEPLOYMENT hardens a development stack that is exposed", () => {
  assert.equal(isPublicFacing(readConfig(env)), false);
  assert.equal(
    isPublicFacing(readConfig({ ...env, PUBLIC_DEPLOYMENT: "1" })),
    true,
  );
  assert.equal(isPublicFacing({ environment: "production" }), true);
});

for (const publicDeployment of [false, true])
  test(`API docs and strict headers when publicDeployment=${publicDeployment}`, async () => {
    const app = await createApp(
      { environment: "development", origins: [], publicDeployment },
      { check: async () => true, close: async () => {} },
    );
    await app.listen(0, "127.0.0.1");
    try {
      const base = await app.getUrl();
      const docs = await fetch(`${base}/api/docs`);
      const health = await fetch(`${base}/api/v1/health/live`);
      assert.equal(docs.status, publicDeployment ? 404 : 200);
      assert.equal(
        health.headers.has("strict-transport-security"),
        publicDeployment,
      );
      assert.equal(
        health.headers.has("content-security-policy"),
        publicDeployment,
      );
    } finally {
      await app.close();
    }
  });

test("test passwords can be allowed for teachers and students, never for the administrator", () => {
  assert.deepEqual([...allowedTestRoles({})], []);
  const allowed = allowedTestRoles({
    DEPLOY_ALLOW_TEST_PASSWORD_ROLES:
      " GIAO_VIEN, HOC_SINH ,QUAN_TRI_VIEN,khac",
  });
  assert.deepEqual([...allowed], ["GIAO_VIEN", "HOC_SINH"]);
  const found = accountFindings(
    new Map([
      ["QUAN_TRI_VIEN", 1],
      ["GIAO_VIEN", 10],
      ["HOC_SINH", 4],
    ]),
    allowed,
  );
  assert.equal(found.problems.length, 1);
  assert.match(found.problems[0]!, /1 tài khoản QUAN_TRI_VIEN/);
  assert.equal(found.warnings.length, 2);
  assert.equal(passwordProblem("ngan", {}) !== null, true);
  assert.equal(
    passwordProblem("mat-khau-thu-dung-chung", {
      SEED_PASSWORD: "mat-khau-thu-dung-chung",
    }) !== null,
    true,
  );
  assert.equal(passwordProblem("mot-mat-khau-rieng-dai", {}), null);
});

test("deploy check rejects the MinIO root account and shared test passwords", async () => {
  assert.equal(
    storageProblems({ S3_ACCESS_KEY: "root", MINIO_ROOT_USER: "root" }).length,
    1,
  );
  assert.deepEqual(
    storageProblems({ S3_ACCESS_KEY: "app", MINIO_ROOT_USER: "root" }),
    [],
  );
  const passwords = blockedPasswords({
    SEED_PASSWORD: "seed-value",
    DEPLOY_BLOCKED_PASSWORDS: " shared-value ,seed-value,",
  });
  assert.deepEqual(passwords, ["seed-value", "shared-value"]);
  const counts = await weakAccountCounts(
    [
      { role: "QUAN_TRI_VIEN", hash: "shared-value" },
      { role: "GIAO_VIEN", hash: "private-value" },
      { role: "GIAO_VIEN", hash: "seed-value" },
    ],
    passwords,
    async (hash, password) => hash === password,
  );
  assert.deepEqual(
    [...counts],
    [
      ["QUAN_TRI_VIEN", 1],
      ["GIAO_VIEN", 1],
    ],
  );
});
