import assert from "node:assert/strict";
import { test } from "node:test";
import {
  cliArguments,
  parsePostgresUrl,
} from "../../../scripts/ops/postgres-backup.js";
import {
  backupFileName,
  cliArguments as storageCliArguments,
  readStorageSettings,
} from "../src/ops/object-storage-backup.js";
import { readLoadProfile } from "../../../scripts/testing/business-load.js";
import {
  flutterWebReleaseArguments,
  readWebReleaseSettings,
} from "../../../scripts/ops/web-release.js";

test("backup connection parsing keeps credentials out of command arguments", () => {
  const parsed = parsePostgresUrl(
    "postgresql://backup_user:sensitive%20value@db.example.edu:5433/grades?sslmode=verify-full",
  );
  assert.equal(parsed.database, "grades");
  assert.equal(parsed.env.PGPASSWORD, "sensitive value");
  assert.equal(parsed.env.PGSSLMODE, "verify-full");
  assert.equal(
    JSON.stringify({ database: parsed.database }).includes("sensitive"),
    false,
  );
});

test("restore rehearsal rejects every target outside an isolated restore database", () => {
  for (const database of ["grades", "grades_test", "production"])
    assert.throws(
      () =>
        parsePostgresUrl(`postgresql://restore@localhost/${database}`, true),
      /_restore_test/,
    );
  assert.equal(
    parsePostgresUrl("postgresql://restore@localhost/grades_restore_test", true)
      .database,
    "grades_restore_test",
  );
});

test("pnpm argument separator cannot become a backup directory", () => {
  assert.deepEqual(cliArguments(["backup", "--", ".local/backups"]), [
    "backup",
    ".local/backups",
  ]);
});

test("storage restore only accepts an isolated S3-compatible bucket", () => {
  const env = {
    S3_ENDPOINT: "https://objects.example.edu",
    S3_ACCESS_KEY: "backup-access",
    S3_SECRET_KEY: "hidden-secret",
    S3_BUCKET: "gradebook-images",
  };
  for (const bucket of ["gradebook-images", "gradebook-images_restore_test"])
    assert.throws(
      () => readStorageSettings({ ...env, RESTORE_S3_BUCKET: bucket }, true),
      /valid S3 bucket|-restore-test|differ/,
    );
  assert.equal(
    readStorageSettings(
      { ...env, RESTORE_S3_BUCKET: "gradebook-images-restore-test" },
      true,
    ).restoreBucket,
    "gradebook-images-restore-test",
  );
  assert.throws(
    () => readStorageSettings({ ...env, S3_BUCKET: "../images" }),
    /valid S3 bucket/,
  );
});

test("storage backup maps hostile object keys to fixed local filenames", () => {
  const file = backupFileName("../../student/private image.png");
  assert.match(file, /^[a-f0-9]{64}\.object$/);
  assert.deepEqual(
    storageCliArguments(["backup", "--", ".local/storage-backups"]),
    ["backup", ".local/storage-backups"],
  );
});

test("load profile requires an authenticated business endpoint and explicit limits", () => {
  const env = {
    LOAD_BASE_URL: "http://127.0.0.1:3000",
    LOAD_PATH: "/api/v1/gradebooks?cursor=0",
    LOAD_AUTHORIZATION: "Bearer test-only-token",
    LOAD_DURATION_SECONDS: "5",
    LOAD_CONCURRENCY: "2",
    LOAD_REQUEST_TIMEOUT_MS: "2000",
    LOAD_MAX_P95_MS: "1000",
    LOAD_MAX_ERROR_RATE: "0.01",
  };
  const profile = readLoadProfile(env);
  assert.equal(profile.path, "/api/v1/gradebooks?cursor=0");
  assert.equal(profile.concurrency, 2);
  assert.throws(
    () => readLoadProfile({ ...env, LOAD_PATH: "/api/v1/health/ready" }),
    /business \/api\/v1/,
  );
  assert.throws(
    () => readLoadProfile({ ...env, LOAD_PATH: "/api/v1/identity/login" }),
    /business \/api\/v1/,
  );
  assert.throws(
    () =>
      readLoadProfile({
        ...env,
        LOAD_BASE_URL: "https://staging.example.edu",
      }),
    /LOAD_ALLOW_REMOTE/,
  );
});

test("web release requires a real HTTPS API origin", () => {
  const settings = readWebReleaseSettings({
    WEB_API_BASE_URL: "https://api.diemtruong.vn",
  });
  assert.deepEqual(flutterWebReleaseArguments(settings), [
    "build",
    "web",
    "--release",
    "--dart-define=APP_ENV=production",
    "--dart-define=API_BASE_URL=https://api.diemtruong.vn",
  ]);
  for (const value of [
    "http://api.grades.example.edu",
    "https://production.example.invalid",
    "https://localhost",
    "https://user:secret@api.grades.example.edu",
    "https://api.grades.example.edu/api",
    "https://api.grades.example.edu?token=secret",
  ])
    assert.throws(
      () => readWebReleaseSettings({ WEB_API_BASE_URL: value }),
      /production HTTPS origin/,
    );
});
