import { PrismaClient } from "../apps/api/src/generated/prisma/client.js";
import { PrismaPg } from "@prisma/adapter-pg";

const connectionString = process.env.DATABASE_URL;
if (!connectionString) throw new Error("DATABASE_URL required");

const db = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});

async function main() {
  console.log("Seeding timetable...");

  // Get active semester
  const activeYear = await db.nam_hoc.findFirst({
    where: { hien_hanh: true },
    include: { hoc_ky_rows: { orderBy: { thu_tu: "asc" } } },
  });
  if (!activeYear || !activeYear.hoc_ky_rows.length) {
    throw new Error("No active semester found");
  }
  const term = activeYear.hoc_ky_rows[0];
  const termId = term.ma_hoc_ky;

  const classes = await db.lop.findMany();
  const subjects = await db.mon_hoc.findMany();
  const teachers = await db.giao_vien.findMany();

  const classMap = new Map(classes.map((c) => [c.ten_lop, c.ma_lop]));
  const teacherList = teachers.map((t) => t.ma_giao_vien);

  const mathTeacher = teachers[0]?.ma_giao_vien || teacherList[0];
  const litTeacher = teachers[1]?.ma_giao_vien || teacherList[0];
  const engTeacher = teachers[2]?.ma_giao_vien || teacherList[0];
  const physTeacher = teachers[3]?.ma_giao_vien || teacherList[0];
  const chemTeacher = teachers[4]?.ma_giao_vien || teacherList[0];

  const mathSub =
    subjects.find((s) => s.ten_mon.includes("Toán"))?.ma_mon ||
    subjects[0].ma_mon;
  const litSub =
    subjects.find((s) => s.ten_mon.includes("Văn"))?.ma_mon ||
    subjects[1].ma_mon;
  const engSub =
    subjects.find((s) => s.ten_mon.includes("Anh"))?.ma_mon ||
    subjects[2].ma_mon;
  const physSub =
    subjects.find((s) => s.ten_mon.includes("Lí") || s.ten_mon.includes("Lý"))
      ?.ma_mon || subjects[3].ma_mon;
  const chemSub =
    subjects.find((s) => s.ten_mon.includes("Hóa"))?.ma_mon ||
    subjects[4]?.ma_mon ||
    subjects[0].ma_mon;

  const class10A1 = classMap.get("10A1");
  const class10A2 = classMap.get("10A2");
  const class11A1 = classMap.get("11A1");

  // Clear existing timetable
  await db.thoi_khoa_bieu.deleteMany({});

  const scheduleData = [];

  if (class10A1) {
    // 10A1 Schedule
    scheduleData.push(
      // Thứ 2
      {
        ma_lop: class10A1,
        ma_mon: mathSub,
        ma_giao_vien: mathTeacher,
        ma_hoc_ky: termId,
        thu: 2,
        tiet: 1,
        phong_hoc: "P.101",
        ghi_chu: "Đại số",
      },
      {
        ma_lop: class10A1,
        ma_mon: mathSub,
        ma_giao_vien: mathTeacher,
        ma_hoc_ky: termId,
        thu: 2,
        tiet: 2,
        phong_hoc: "P.101",
        ghi_chu: "Hình học",
      },
      {
        ma_lop: class10A1,
        ma_mon: litSub,
        ma_giao_vien: litTeacher,
        ma_hoc_ky: termId,
        thu: 2,
        tiet: 3,
        phong_hoc: "P.101",
        ghi_chu: "Đọc hiểu",
      },
      {
        ma_lop: class10A1,
        ma_mon: litSub,
        ma_giao_vien: litTeacher,
        ma_hoc_ky: termId,
        thu: 2,
        tiet: 4,
        phong_hoc: "P.101",
        ghi_chu: "Nghị luận",
      },
      // Thứ 3
      {
        ma_lop: class10A1,
        ma_mon: engSub,
        ma_giao_vien: engTeacher,
        ma_hoc_ky: termId,
        thu: 3,
        tiet: 1,
        phong_hoc: "P.101",
        ghi_chu: "Unit 1: Reading",
      },
      {
        ma_lop: class10A1,
        ma_mon: engSub,
        ma_giao_vien: engTeacher,
        ma_hoc_ky: termId,
        thu: 3,
        tiet: 2,
        phong_hoc: "P.101",
        ghi_chu: "Listening",
      },
      {
        ma_lop: class10A1,
        ma_mon: physSub,
        ma_giao_vien: physTeacher,
        ma_hoc_ky: termId,
        thu: 3,
        tiet: 3,
        phong_hoc: "P.101",
        ghi_chu: "Cơ học",
      },
      {
        ma_lop: class10A1,
        ma_mon: physSub,
        ma_giao_vien: physTeacher,
        ma_hoc_ky: termId,
        thu: 3,
        tiet: 4,
        phong_hoc: "P.101",
        ghi_chu: "Thực hành lí",
      },
      // Thứ 4
      {
        ma_lop: class10A1,
        ma_mon: chemSub,
        ma_giao_vien: chemTeacher,
        ma_hoc_ky: termId,
        thu: 4,
        tiet: 1,
        phong_hoc: "Lab Hóa",
        ghi_chu: "Cấu tạo nguyên tử",
      },
      {
        ma_lop: class10A1,
        ma_mon: chemSub,
        ma_giao_vien: chemTeacher,
        ma_hoc_ky: termId,
        thu: 4,
        tiet: 2,
        phong_hoc: "Lab Hóa",
        ghi_chu: "Thực hành hóa",
      },
      {
        ma_lop: class10A1,
        ma_mon: litSub,
        ma_giao_vien: litTeacher,
        ma_hoc_ky: termId,
        thu: 4,
        tiet: 3,
        phong_hoc: "P.101",
        ghi_chu: "Tiếng Việt",
      },
      {
        ma_lop: class10A1,
        ma_mon: litSub,
        ma_giao_vien: litTeacher,
        ma_hoc_ky: termId,
        thu: 4,
        tiet: 4,
        phong_hoc: "P.101",
        ghi_chu: "Luyện đề",
      },
      // Thứ 5
      {
        ma_lop: class10A1,
        ma_mon: mathSub,
        ma_giao_vien: mathTeacher,
        ma_hoc_ky: termId,
        thu: 5,
        tiet: 1,
        phong_hoc: "P.101",
        ghi_chu: "Đại số nâng cao",
      },
      {
        ma_lop: class10A1,
        ma_mon: mathSub,
        ma_giao_vien: mathTeacher,
        ma_hoc_ky: termId,
        thu: 5,
        tiet: 2,
        phong_hoc: "P.101",
        ghi_chu: "Luyện tập",
      },
      {
        ma_lop: class10A1,
        ma_mon: engSub,
        ma_giao_vien: engTeacher,
        ma_hoc_ky: termId,
        thu: 5,
        tiet: 3,
        phong_hoc: "P.101",
        ghi_chu: "Grammar",
      },
      {
        ma_lop: class10A1,
        ma_mon: engSub,
        ma_giao_vien: engTeacher,
        ma_hoc_ky: termId,
        thu: 5,
        tiet: 4,
        phong_hoc: "P.101",
        ghi_chu: "Writing",
      },
      // Thứ 6
      {
        ma_lop: class10A1,
        ma_mon: physSub,
        ma_giao_vien: physTeacher,
        ma_hoc_ky: termId,
        thu: 6,
        tiet: 1,
        phong_hoc: "P.101",
        ghi_chu: "Nhiệt học",
      },
      {
        ma_lop: class10A1,
        ma_mon: chemSub,
        ma_giao_vien: chemTeacher,
        ma_hoc_ky: termId,
        thu: 6,
        tiet: 2,
        phong_hoc: "Lab Hóa",
        ghi_chu: "Phản ứng OXH",
      },
      {
        ma_lop: class10A1,
        ma_mon: mathSub,
        ma_giao_vien: mathTeacher,
        ma_hoc_ky: termId,
        thu: 6,
        tiet: 3,
        phong_hoc: "P.101",
        ghi_chu: "Kiểm tra 15p",
      },
      // Thứ 7
      {
        ma_lop: class10A1,
        ma_mon: engSub,
        ma_giao_vien: engTeacher,
        ma_hoc_ky: termId,
        thu: 7,
        tiet: 1,
        phong_hoc: "P.101",
        ghi_chu: "Speaking",
      },
      {
        ma_lop: class10A1,
        ma_mon: mathSub,
        ma_giao_vien: mathTeacher,
        ma_hoc_ky: termId,
        thu: 7,
        tiet: 2,
        phong_hoc: "P.101",
        ghi_chu: "Ôn tập tuần",
      },
      {
        ma_lop: class10A1,
        ma_mon: litSub,
        ma_giao_vien: litTeacher,
        ma_hoc_ky: termId,
        thu: 7,
        tiet: 3,
        phong_hoc: "P.101",
        ghi_chu: "Sinh hoạt chủ nhiệm",
      },
    );
  }

  if (class10A2) {
    // 10A2 Schedule (non-conflicting with teachers)
    scheduleData.push(
      // Thứ 2
      {
        ma_lop: class10A2,
        ma_mon: litSub,
        ma_giao_vien: litTeacher,
        ma_hoc_ky: termId,
        thu: 2,
        tiet: 1,
        phong_hoc: "P.102",
        ghi_chu: "Văn học",
      },
      {
        ma_lop: class10A2,
        ma_mon: litSub,
        ma_giao_vien: litTeacher,
        ma_hoc_ky: termId,
        thu: 2,
        tiet: 2,
        phong_hoc: "P.102",
        ghi_chu: "Luyện tập",
      },
      {
        ma_lop: class10A2,
        ma_mon: mathSub,
        ma_giao_vien: mathTeacher,
        ma_hoc_ky: termId,
        thu: 2,
        tiet: 4,
        phong_hoc: "P.102",
        ghi_chu: "Đại số",
      },
      {
        ma_lop: class10A2,
        ma_mon: mathSub,
        ma_giao_vien: mathTeacher,
        ma_hoc_ky: termId,
        thu: 2,
        tiet: 5,
        phong_hoc: "P.102",
        ghi_chu: "Hình học",
      },
      // Thứ 3
      {
        ma_lop: class10A2,
        ma_mon: mathSub,
        ma_giao_vien: mathTeacher,
        ma_hoc_ky: termId,
        thu: 3,
        tiet: 3,
        phong_hoc: "P.102",
        ghi_chu: "Hàm số",
      },
      {
        ma_lop: class10A2,
        ma_mon: mathSub,
        ma_giao_vien: mathTeacher,
        ma_hoc_ky: termId,
        thu: 3,
        tiet: 4,
        phong_hoc: "P.102",
        ghi_chu: "Phương trình",
      },
      // Thứ 4
      {
        ma_lop: class10A2,
        ma_mon: engSub,
        ma_giao_vien: engTeacher,
        ma_hoc_ky: termId,
        thu: 4,
        tiet: 1,
        phong_hoc: "P.102",
        ghi_chu: "Tiếng Anh",
      },
      {
        ma_lop: class10A2,
        ma_mon: engSub,
        ma_giao_vien: engTeacher,
        ma_hoc_ky: termId,
        thu: 4,
        tiet: 2,
        phong_hoc: "P.102",
        ghi_chu: "Vocabulary",
      },
      // Thứ 5
      {
        ma_lop: class10A2,
        ma_mon: physSub,
        ma_giao_vien: physTeacher,
        ma_hoc_ky: termId,
        thu: 5,
        tiet: 1,
        phong_hoc: "P.102",
        ghi_chu: "Vật lí",
      },
      {
        ma_lop: class10A2,
        ma_mon: physSub,
        ma_giao_vien: physTeacher,
        ma_hoc_ky: termId,
        thu: 5,
        tiet: 2,
        phong_hoc: "P.102",
        ghi_chu: "Quang học",
      },
      {
        ma_lop: class10A2,
        ma_mon: mathSub,
        ma_giao_vien: mathTeacher,
        ma_hoc_ky: termId,
        thu: 5,
        tiet: 3,
        phong_hoc: "P.102",
        ghi_chu: "Luyện tập",
      },
    );
  }

  if (class11A1) {
    // 11A1 Schedule
    scheduleData.push(
      {
        ma_lop: class11A1,
        ma_mon: mathSub,
        ma_giao_vien: mathTeacher,
        ma_hoc_ky: termId,
        thu: 3,
        tiet: 5,
        phong_hoc: "P.201",
        ghi_chu: "Lượng giác",
      },
      {
        ma_lop: class11A1,
        ma_mon: mathSub,
        ma_giao_vien: mathTeacher,
        ma_hoc_ky: termId,
        thu: 4,
        tiet: 5,
        phong_hoc: "P.201",
        ghi_chu: "Hình không gian",
      },
      {
        ma_lop: class11A1,
        ma_mon: mathSub,
        ma_giao_vien: mathTeacher,
        ma_hoc_ky: termId,
        thu: 6,
        tiet: 4,
        phong_hoc: "P.201",
        ghi_chu: "Tổ hợp xác suất",
      },
    );
  }

  for (const item of scheduleData) {
    await db.thoi_khoa_bieu.create({ data: item });
  }

  console.log(`Seeded ${scheduleData.length} timetable periods successfully!`);
  await db.$disconnect();
}

main().catch((e) => {
  console.error("Error seeding timetable:", e);
  process.exit(1);
});
