import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import "dotenv/config";
import { Pool } from "pg";
import { passwordHash } from "../modules/identity/application/service.js";
import { blockedPasswords } from "./public-deploy-check.js";

export function passwordProblem(password: string, env: NodeJS.ProcessEnv) {
  if (password.length < 12 || password.length > 128)
    return "Mật khẩu phải dài từ 12 đến 128 ký tự.";
  if (blockedPasswords(env).includes(password))
    return "Mật khẩu này là mật khẩu thử; chọn mật khẩu khác.";
  return null;
}

export async function setAdminPassword(
  connectionString: string,
  password: string,
) {
  const hashed = await passwordHash(password);
  const pool = new Pool({ connectionString });
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const admins = await client.query<{ id: number; username: string }>(
      "SELECT ma_nguoi_dung AS id,ten_dang_nhap AS username FROM nguoi_dung WHERE vai_tro='QUAN_TRI_VIEN' AND trang_thai FOR UPDATE",
    );
    if (admins.rows.length !== 1)
      throw new Error(
        `Cần đúng một quản trị viên đang hoạt động, hiện có ${admins.rows.length}.`,
      );
    const admin = admins.rows[0]!;
    await client.query(
      "UPDATE nguoi_dung SET mat_khau_ma_hoa=$2,so_lan_dang_nhap_sai=0,khoa_den=NULL WHERE ma_nguoi_dung=$1",
      [admin.id, hashed],
    );
    for (const table of ["phien_lam_viec", "phien_ghi_nho"])
      await client.query(`DELETE FROM ${table} WHERE ma_nguoi_dung=$1`, [
        admin.id,
      ]);
    await client.query(
      "INSERT INTO nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES($1,'PASSWORD_RESET_LOCAL',$2)",
      [admin.id, String(admin.id)],
    );
    await client.query("COMMIT");
    return admin.username;
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

function askHidden(prompt: string) {
  return new Promise<string>((done, fail) => {
    const input = process.stdin;
    process.stdout.write(prompt);
    let value = "";
    input.setRawMode(true);
    input.setEncoding("utf8");
    input.resume();
    const stop = () => {
      input.off("data", read);
      input.setRawMode(false);
      input.pause();
      process.stdout.write("\n");
    };
    const read = (chunk: string) => {
      for (const char of chunk) {
        if (char === "\r" || char === "\n") {
          stop();
          return done(value);
        }
        if (char === "\u0003") {
          stop();
          return fail(new Error("Đã hủy."));
        }
        if (char === "\b" || char === "\u007f") value = value.slice(0, -1);
        else if (char >= " ") value += char;
      }
    };
    input.on("data", read);
  });
}

async function main() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) throw new Error("DATABASE_URL required");
  if (!process.stdin.isTTY)
    throw new Error("Hãy chạy lệnh này trực tiếp trong cửa sổ PowerShell.");
  process.stdout.write(
    `Database: ${new URL(connectionString).pathname.slice(1)}\n`,
  );
  const password = await askHidden(
    "Mật khẩu mới cho quản trị viên (ít nhất 12 ký tự, không hiện khi gõ): ",
  );
  const problem = passwordProblem(password, process.env);
  if (problem) throw new Error(problem);
  if ((await askHidden("Gõ lại mật khẩu: ")) !== password)
    throw new Error("Hai lần gõ không giống nhau.");
  const username = await setAdminPassword(connectionString, password);
  process.stdout.write(`Đã đổi mật khẩu cho tài khoản ${username}.\n`);
}

if (
  process.argv[1] &&
  fileURLToPath(import.meta.url) === resolve(process.argv[1])
)
  await main().catch((error: Error) => {
    process.stdout.write(`${error.message}\n`);
    process.exitCode = 1;
  });
