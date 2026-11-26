import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { verify } from "argon2";
import "dotenv/config";
import { Pool } from "pg";

export interface AccountHash {
  role: string;
  hash: string;
}

export function storageProblems(env: NodeJS.ProcessEnv) {
  if (env.S3_ACCESS_KEY && env.S3_ACCESS_KEY === env.MINIO_ROOT_USER)
    return [
      "API đang dùng tài khoản root của MinIO. Đặt S3_ACCESS_KEY và S3_SECRET_KEY khác trong .env rồi chạy pnpm infra:up.",
    ];
  return [];
}

export function blockedPasswords(env: NodeJS.ProcessEnv) {
  return [
    ...new Set(
      [env.SEED_PASSWORD, ...(env.DEPLOY_BLOCKED_PASSWORDS ?? "").split(",")]
        .map((value) => value?.trim() ?? "")
        .filter(Boolean),
    ),
  ];
}

export async function weakAccountCounts(
  accounts: AccountHash[],
  passwords: string[],
  matches: (hash: string, password: string) => Promise<boolean> = verify,
) {
  const counts = new Map<string, number>();
  for (const account of accounts)
    for (const password of passwords)
      if (await matches(account.hash, password).catch(() => false)) {
        counts.set(account.role, (counts.get(account.role) ?? 0) + 1);
        break;
      }
  return counts;
}

async function readAccounts(connectionString: string) {
  const pool = new Pool({ connectionString });
  try {
    const result = await pool.query<AccountHash>(`
      (SELECT vai_tro::text AS role, mat_khau_ma_hoa AS hash FROM nguoi_dung
        WHERE trang_thai AND vai_tro <> 'HOC_SINH')
      UNION ALL
      (SELECT vai_tro::text, mat_khau_ma_hoa FROM nguoi_dung
        WHERE trang_thai AND vai_tro = 'HOC_SINH' ORDER BY random() LIMIT 20)`);
    return result.rows;
  } finally {
    await pool.end();
  }
}

async function main() {
  const databaseUrl = process.env.MIGRATION_DATABASE_URL;
  if (!databaseUrl) throw new Error("MIGRATION_DATABASE_URL required");
  const problems = storageProblems(process.env);
  const passwords = blockedPasswords(process.env);
  if (!passwords.length)
    problems.push(
      "Không có mật khẩu thử để đối chiếu. Đặt DEPLOY_BLOCKED_PASSWORDS (cách nhau bằng dấu phẩy) trong .env.",
    );
  else {
    const counts = await weakAccountCounts(
      await readAccounts(databaseUrl),
      passwords,
    );
    for (const [role, total] of counts)
      problems.push(
        `${total} tài khoản ${role} còn dùng mật khẩu thử. Đổi mật khẩu trước khi mở công khai.`,
      );
  }
  if (!problems.length) {
    process.stdout.write("Kiểm tra trước khi mở công khai: đạt.\n");
    return;
  }
  for (const problem of problems) process.stdout.write(`- ${problem}\n`);
  process.exitCode = 1;
}

if (
  process.argv[1] &&
  fileURLToPath(import.meta.url) === resolve(process.argv[1])
)
  await main();
