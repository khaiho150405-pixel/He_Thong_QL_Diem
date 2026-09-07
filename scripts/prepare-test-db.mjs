import { Pool } from "pg";
// Explicitly targets an isolated test cluster, never DATABASE_URL or personal databases.
const url = process.env.TEST_ADMIN_URL;
if (!url || !new URL(url).pathname.endsWith("/postgres"))
  throw new Error("TEST_ADMIN_URL ending /postgres required");
const pool = new Pool({ connectionString: url });
try {
  for (const role of ["app_migration", "app_runtime"]) {
    if (
      !(await pool.query("SELECT 1 FROM pg_roles WHERE rolname=$1", [role]))
        .rowCount
    )
      await pool.query(
        `CREATE ROLE ${role} LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE`,
      );
  }
  if (
    !(
      await pool.query(
        "SELECT 1 FROM pg_database WHERE datname='quan_ly_diem_test'",
      )
    ).rowCount
  )
    await pool.query("CREATE DATABASE quan_ly_diem_test OWNER app_migration");
} finally {
  await pool.end();
}
const testUrl = new URL(url);
testUrl.pathname = "/quan_ly_diem_test";
const db = new Pool({ connectionString: testUrl.toString() });
try {
  await db.query("GRANT app_runtime TO app_migration");
  await db.query(
    "REVOKE CREATE ON SCHEMA public FROM PUBLIC; GRANT USAGE ON SCHEMA public TO app_runtime; GRANT USAGE, CREATE ON SCHEMA public TO app_migration",
  );
} finally {
  await db.end();
}
