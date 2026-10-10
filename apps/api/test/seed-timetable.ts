import "dotenv/config";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "../src/generated/prisma/client.js";

const connectionString = process.env.DATABASE_URL;
if (!connectionString) throw new Error("DATABASE_URL required");
const db = new PrismaClient({ adapter: new PrismaPg({ connectionString }) });

async function main() {
  const activeYear = await db.nam_hoc.findFirst({
    where: { hien_hanh: true },
    include: { hoc_ky_rows: { orderBy: { thu_tu: "asc" } } },
  });
  const term = activeYear?.hoc_ky_rows[0];
  if (!term) throw new Error("No active semester found");

  const assignments = await db.phan_cong_giang_day.findMany({
    where: { ma_hoc_ky: term.ma_hoc_ky },
    include: { ma_lop_ref: true },
    orderBy: [{ ma_lop: "asc" }, { ma_mon: "asc" }],
  });
  const byClass = new Map<number, typeof assignments>();
  for (const assignment of assignments) {
    const rows = byClass.get(assignment.ma_lop) ?? [];
    rows.push(assignment);
    byClass.set(assignment.ma_lop, rows);
  }
  const eligible = [...byClass.entries()]
    .filter(([, rows]) => new Set(rows.map((row) => row.ma_mon)).size >= 3)
    .slice(0, 4);
  if (eligible.length === 0) {
    throw new Error("No class has at least three assigned subjects");
  }

  const schedule: Array<{
    ma_lop: number;
    ma_mon: number;
    ma_giao_vien: number;
    ma_hoc_ky: number;
    thu: number;
    tiet: number;
    phong_hoc: string;
    ghi_chu: string;
  }> = [];
  // A,A,B,C gives one consecutive double period and three subjects.
  // The offsets keep each teacher in only one class at the same period.
  const patterns = [
    [0, 0, 1, 2],
    [1, 2, 2, 3],
    [2, 3, 4, 4],
    [3, 4, 0, 0],
  ];
  for (let day = 2; day <= 8; day += 1) {
    const firstPeriod = day % 2 === 0 ? 6 : 1;
    eligible.forEach(([classId, rows], classIndex) => {
      const distinctRows = [
        ...new Map(rows.map((row) => [row.ma_mon, row])).values(),
      ];
      patterns[classIndex]!.forEach((baseIndex, periodIndex) => {
        const assignment =
          distinctRows[(baseIndex + day - 2) % distinctRows.length]!;
        const isDouble =
          (periodIndex > 0 &&
            patterns[classIndex]![periodIndex - 1] === baseIndex) ||
          (periodIndex < 3 &&
            patterns[classIndex]![periodIndex + 1] === baseIndex);
        schedule.push({
          ma_lop: classId,
          ma_mon: assignment.ma_mon,
          ma_giao_vien: assignment.ma_giao_vien,
          ma_hoc_ky: term.ma_hoc_ky,
          thu: day,
          tiet: firstPeriod + periodIndex,
          phong_hoc: `P.${assignment.ma_lop_ref.ten_lop}`,
          ghi_chu: isDouble ? "Tiết đôi" : "Lịch học chính khóa",
        });
      });
    });
  }

  await db.$transaction(async (tx) => {
    await tx.thoi_khoa_bieu.deleteMany({
      where: { ma_hoc_ky: term.ma_hoc_ky },
    });
    await tx.thoi_khoa_bieu.createMany({ data: schedule });
  });
  console.log(
    `Seeded ${schedule.length} valid timetable slots for ${eligible.length} classes.`,
  );
}

main()
  .catch((error) => {
    console.error(error instanceof Error ? error.message : error);
    process.exitCode = 1;
  })
  .finally(() => db.$disconnect());
