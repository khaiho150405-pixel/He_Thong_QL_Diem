import { createHash } from "node:crypto";
import {
  existsSync,
  mkdirSync,
  readFileSync,
  renameSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { basename, join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

export function parsePostgresUrl(raw: string, restore = false) {
  const url = new URL(raw);
  if (!["postgres:", "postgresql:"].includes(url.protocol))
    throw new Error("PostgreSQL URL required");
  const database = decodeURIComponent(url.pathname.slice(1));
  if (!database) throw new Error("Database name required");
  if (restore && !database.endsWith("_restore_test"))
    throw new Error("Restore target must end with _restore_test");
  const sslmode = url.searchParams.get("sslmode");
  return {
    database,
    env: {
      PGHOST: url.hostname,
      PGPORT: url.port || "5432",
      PGUSER: decodeURIComponent(url.username),
      PGPASSWORD: decodeURIComponent(url.password),
      PGDATABASE: database,
      ...(sslmode ? { PGSSLMODE: sslmode } : {}),
    },
  };
}

export function checksum(path: string) {
  return createHash("sha256").update(readFileSync(path)).digest("hex");
}

export function cliArguments(values: string[]) {
  return values.filter((value) => value !== "--");
}

function run(binary: string, args: string[], pgEnv: Record<string, string>) {
  const result = spawnSync(binary, args, {
    env: { ...process.env, ...pgEnv },
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0)
    throw new Error(`${basename(binary)} failed: ${result.stderr.trim()}`);
}

export function backup(databaseUrl: string, outputDirectory: string) {
  const { database, env } = parsePostgresUrl(databaseUrl);
  const directory = resolve(outputDirectory);
  mkdirSync(directory, { recursive: true, mode: 0o700 });
  const stamp = new Date().toISOString().replace(/[:.]/g, "-");
  const finalPath = join(directory, `${database}-${stamp}.dump`);
  const temporaryPath = `${finalPath}.part`;
  try {
    run(
      process.env.PG_DUMP_BIN || "pg_dump",
      ["--format=custom", "--no-owner", `--file=${temporaryPath}`],
      env,
    );
    renameSync(temporaryPath, finalPath);
  } finally {
    if (existsSync(temporaryPath)) rmSync(temporaryPath);
  }
  const manifest = {
    format: "postgres-custom-v1",
    createdAt: new Date().toISOString(),
    database,
    file: basename(finalPath),
    sha256: checksum(finalPath),
  };
  writeFileSync(`${finalPath}.json`, `${JSON.stringify(manifest, null, 2)}\n`, {
    mode: 0o600,
  });
  return finalPath;
}

export function verify(path: string) {
  const backupPath = resolve(path);
  const manifest = JSON.parse(readFileSync(`${backupPath}.json`, "utf8")) as {
    format: string;
    file: string;
    sha256: string;
  };
  if (
    manifest.format !== "postgres-custom-v1" ||
    manifest.file !== basename(backupPath)
  )
    throw new Error("Backup manifest mismatch");
  if (checksum(backupPath) !== manifest.sha256)
    throw new Error("Backup checksum mismatch");
  run(process.env.PG_RESTORE_BIN || "pg_restore", ["--list", backupPath], {});
  return manifest;
}

export function restore(databaseUrl: string, path: string) {
  const { database, env } = parsePostgresUrl(databaseUrl, true);
  verify(path);
  run(
    process.env.PG_RESTORE_BIN || "pg_restore",
    [
      "--clean",
      "--if-exists",
      "--no-owner",
      "--exit-on-error",
      `--dbname=${database}`,
      resolve(path),
    ],
    env,
  );
}

function required(name: string) {
  const value = process.env[name];
  if (!value) throw new Error(`${name} is required`);
  return value;
}

if (
  process.argv[1] &&
  resolve(process.argv[1]) === fileURLToPath(import.meta.url)
) {
  const [command, target] = cliArguments(process.argv.slice(2));
  if (!target || !["backup", "verify", "restore"].includes(command ?? ""))
    throw new Error(
      "Usage: backup <directory> | verify <dump> | restore <dump>",
    );
  if (command === "backup")
    console.log(backup(required("BACKUP_DATABASE_URL"), target));
  if (command === "verify") console.log(JSON.stringify(verify(target)));
  if (command === "restore") {
    restore(required("RESTORE_DATABASE_URL"), target);
    console.log("Restore rehearsal completed.");
  }
}
