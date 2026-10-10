import "dotenv/config";
import { PrismaClient } from "../src/generated/prisma/client.js";
import { PrismaPg } from "@prisma/adapter-pg";

const connectionString = process.env.DATABASE_URL;
if (!connectionString) throw new Error("DATABASE_URL required");

const db = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});

async function main() {
  const gv = await db.giao_vien.findMany({
    include: { ma_giao_vien_ref: true },
    orderBy: { ma_giao_vien: "asc" },
  });
  console.log("=== GIAO VIEN (" + gv.length + ") ===");
  gv.forEach((g) => {
    console.log(
      `ID: ${g.ma_giao_vien} | Ten: ${g.ho_ten} | UserID: ${g.ma_giao_vien} | Username: ${g.ma_giao_vien_ref?.ten_dang_nhap} | To: ${g.to_chuyen_mon}`,
    );
  });

  const users = await db.nguoi_dung.findMany({
    where: { vai_tro: "GIAO_VIEN" },
    orderBy: { ma_nguoi_dung: "asc" },
  });
  console.log("=== NGUOI DUNG ROLE GIAO_VIEN (" + users.length + ") ===");
  users.forEach((u) => {
    console.log(
      `ID: ${u.ma_nguoi_dung} | Username: ${u.ten_dang_nhap} | Active: ${u.trang_thai}`,
    );
  });
}

main()
  .catch(console.error)
  .finally(() => process.exit(0));
