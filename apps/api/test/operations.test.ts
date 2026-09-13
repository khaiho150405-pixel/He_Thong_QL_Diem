import assert from "node:assert/strict";
import { test } from "node:test";
import {
  cliArguments,
  parsePostgresUrl,
} from "../../../scripts/ops/postgres-backup.js";

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
