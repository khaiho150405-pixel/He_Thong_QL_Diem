import "dotenv/config";
import { PrismaClient } from "../src/generated/prisma/client.js";
import { PrismaPg } from "@prisma/adapter-pg";

const db = new PrismaClient({
  adapter: new PrismaPg({
    connectionString: (() => {
      if (!process.env.MIGRATION_DATABASE_URL)
        throw new Error("MIGRATION_DATABASE_URL required");
      return process.env.MIGRATION_DATABASE_URL;
    })(),
  }),
});

async function main() {
  console.log("Cleaning up duplicate teachers and user accounts...");

  const mapping: Record<number, number> = {
    66: 27, // Pham Thu Ha
    68: 67, // Tran Minh Anh
    70: 69, // Nguyen Mai Linh
    72: 71, // Le Quoc Bao
    74: 73, // Dinh Van Thang
  };

  for (const [dupId, canonId] of Object.entries(mapping)) {
    const dup = Number(dupId);
    // Delete timetable slots belonging to duplicate
    const deletedTkb = await db.thoi_khoa_bieu.deleteMany({
      where: { ma_giao_vien: dup },
    });
    console.log(
      `Deleted ${deletedTkb.count} timetable slots from duplicate teacher ${dup}`,
    );

    // Update phan_cong_giang_day if any
    const updatedPc = await db.phan_cong_giang_day.updateMany({
      where: { ma_giao_vien: dup },
      data: { ma_giao_vien: canonId },
    });
    console.log(
      `Updated ${updatedPc.count} assignments from teacher ${dup} to ${canonId}`,
    );

    // Update lop if any
    const updatedLop = await db.lop.updateMany({
      where: { ma_gv_chu_nhiem: dup },
      data: { ma_gv_chu_nhiem: canonId },
    });
    console.log(
      `Updated ${updatedLop.count} homeroom classes from teacher ${dup} to ${canonId}`,
    );

    // Delete duplicate teacher
    await db.giao_vien.deleteMany({
      where: { ma_giao_vien: dup },
    });
    console.log(`Deleted duplicate teacher ${dup}`);

    // Delete duplicate user
    await db.nguoi_dung.deleteMany({
      where: { ma_nguoi_dung: dup },
    });
    console.log(`Deleted duplicate user ${dup}`);
  }

  const remainingTeachers = await db.giao_vien.findMany();
  console.log(`Remaining teachers count: ${remainingTeachers.length}`);
  remainingTeachers.forEach((t) =>
    console.log(`- ${t.ma_giao_vien}: ${t.ho_ten}`),
  );

  const remainingUsers = await db.nguoi_dung.findMany({
    where: { vai_tro: "GIAO_VIEN" },
  });
  console.log(`Remaining teacher accounts count: ${remainingUsers.length}`);
  remainingUsers.forEach((u) =>
    console.log(`- ${u.ma_nguoi_dung}: ${u.ten_dang_nhap}`),
  );
}

main()
  .catch(console.error)
  .finally(() => process.exit(0));
