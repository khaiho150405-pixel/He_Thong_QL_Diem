import "dotenv/config";
import { PrismaClient } from "../src/generated/prisma/client.js";
import { PrismaPg } from "@prisma/adapter-pg";

const db = new PrismaClient({
  adapter: new PrismaPg({
    connectionString: (() => {
      if (!process.env.DATABASE_URL) throw new Error("DATABASE_URL required");
      return process.env.DATABASE_URL;
    })(),
  }),
});

async function main() {
  const gvIds = [27, 66, 67, 68, 69, 70, 71, 72, 73, 74];

  console.log("=== LOP GVCN ===");
  const lops = await db.lop.findMany({
    where: { ma_gv_chu_nhiem: { in: gvIds } },
    select: { ma_lop: true, ten_lop: true, ma_gv_chu_nhiem: true },
  });
  console.log(lops);

  console.log("=== PHAN CONG GIANG DAY ===");
  const pc = await db.phan_cong_giang_day.findMany({
    where: { ma_giao_vien: { in: gvIds } },
    select: {
      ma_phan_cong: true,
      ma_lop: true,
      ma_mon: true,
      ma_giao_vien: true,
    },
  });
  console.log("Total pc:", pc.length, pc);

  console.log("=== THOI KHOA BIEU ===");
  const tkb = await db.thoi_khoa_bieu.findMany({
    where: { ma_giao_vien: { in: gvIds } },
    select: { ma_tiet_hoc: true, ma_lop: true, ma_giao_vien: true },
  });
  console.log(
    "Total tkb:",
    tkb.length,
    tkb.map((x) => x.ma_giao_vien),
  );
}

main()
  .catch(console.error)
  .finally(() => process.exit(0));
