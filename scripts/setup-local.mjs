import { randomBytes } from "node:crypto";
import { readFile, writeFile, access } from "node:fs/promises";

try {
  await access(".env");
  console.log(".env already exists; no changes made.");
} catch {
  const secret = () => randomBytes(24).toString("hex");
  const admin = secret(),
    migration = secret(),
    runtime = secret(),
    storage = secret();
  let template = await readFile(".env.example", "utf8");
  const values = {
    POSTGRES_PASSWORD: admin,
    MIGRATION_PASSWORD: migration,
    RUNTIME_PASSWORD: runtime,
    DATABASE_URL: `postgresql://app_runtime:${runtime}@localhost:5433/quan_ly_diem_dev`,
    MIGRATION_DATABASE_URL: `postgresql://app_migration:${migration}@localhost:5433/quan_ly_diem_dev`,
    MINIO_ROOT_PASSWORD: storage,
    S3_ACCESS_KEY: "local_admin",
    S3_SECRET_KEY: storage,
    SEED_PASSWORD: secret(),
  };
  for (const [key, value] of Object.entries(values))
    template = template.replace(
      new RegExp(`^${key}=.*$`, "m"),
      `${key}=${value}`,
    );
  if (process.argv.includes("--test"))
    template = template.replaceAll("quan_ly_diem_dev", "quan_ly_diem_test");
  await writeFile(".env", template, { flag: "wx", mode: 0o600 });
  console.log(
    "Created local .env with random credentials; values are not logged.",
  );
}
