import "dotenv/config";
import { Pool } from "pg";
import { hash, argon2id } from "argon2";

if (!["development", "test"].includes(process.env.APP_ENV ?? ""))
  throw new Error("Sample data restricted to development/test");
if (
  !process.env.SEED_PASSWORD ||
  process.env.SEED_PASSWORD === "REPLACE_LOCALLY"
)
  throw new Error("SEED_PASSWORD required");
if (!process.env.MIGRATION_DATABASE_URL)
  throw new Error("MIGRATION_DATABASE_URL required");

const SUBJECTS = [
  { name: "Toán học", periods: 4, dept: "Toán - Tin", teachers: 5 },
  { name: "Ngữ văn", periods: 4, dept: "Ngữ văn", teachers: 5 },
  { name: "Tiếng Anh", periods: 3, dept: "Ngoại ngữ", teachers: 4 },
  { name: "Vật lý", periods: 2, dept: "Vật lý - KHTN", teachers: 3 },
  { name: "Hóa học", periods: 2, dept: "Hóa - Sinh", teachers: 3 },
  { name: "Sinh học", periods: 2, dept: "Hóa - Sinh", teachers: 3 },
  { name: "Lịch sử", periods: 2, dept: "Sử - Địa - GDCD", teachers: 3 },
  { name: "Địa lý", periods: 2, dept: "Sử - Địa - GDCD", teachers: 3 },
  {
    name: "Giáo dục công dân",
    periods: 1,
    dept: "Sử - Địa - GDCD",
    teachers: 4,
  },
  { name: "Tin học", periods: 1, dept: "Toán - Tin", teachers: 4 },
] as const;

const LAST = ["Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Huỳnh", "Phan", "Vũ"];
const MIDDLE = ["Văn", "Thị", "Minh", "Ngọc", "Thanh", "Quốc", "Hữu", "Thu"];
const FIRST = [
  "An",
  "Bình",
  "Châu",
  "Dũng",
  "Giang",
  "Hà",
  "Hạnh",
  "Hiếu",
  "Khoa",
  "Lan",
  "Linh",
  "Mai",
  "Nam",
  "Phúc",
  "Quyên",
  "Sơn",
  "Thảo",
  "Trang",
  "Tú",
  "Vy",
  "Yến",
  "Hùng",
  "Loan",
  "Nhung",
  "Phong",
  "Thủy",
];

const WEEK: { thu: number; plan: string[] }[] = [
  { thu: 2, plan: ["Toán học", "Toán học", "Tiếng Anh", "Lịch sử"] },
  { thu: 3, plan: ["Ngữ văn", "Ngữ văn", "Toán học", "Địa lý"] },
  { thu: 4, plan: ["Vật lý", "Vật lý", "Ngữ văn", "Tiếng Anh"] },
  { thu: 5, plan: ["Hóa học", "Hóa học", "Toán học", "Lịch sử"] },
  { thu: 6, plan: ["Sinh học", "Sinh học", "Ngữ văn", "Địa lý"] },
  { thu: 7, plan: ["Tiếng Anh", "Giáo dục công dân", "Tin học"] },
];

const pool = new Pool({ connectionString: process.env.MIGRATION_DATABASE_URL });
const db = await pool.connect();

type Slot = { thu: number; tiet: number; subject: string };

function permutations(items: number[]): number[][] {
  if (items.length <= 1) return [items];
  return items.flatMap((item, i) =>
    permutations([...items.slice(0, i), ...items.slice(i + 1)]).map((rest) => [
      item,
      ...rest,
    ]),
  );
}
const DAY_ORDERS = permutations([0, 1, 2, 3, 4]);
const SATURDAY_ORDERS = permutations([0, 1, 2]);

function weekVariant(
  order: number[],
  satOrder: number[],
  flip: boolean,
  afternoon: boolean,
) {
  const slots: Slot[] = [];
  const weekdays = WEEK.slice(0, 5);
  for (let d = 0; d < 5; d++) {
    const plan = [...weekdays[order[d]!]!.plan];
    if (flip) plan.reverse();
    plan.forEach((subject, i) =>
      slots.push({
        thu: weekdays[d]!.thu,
        tiet: i + 1 + (afternoon ? 5 : 0),
        subject,
      }),
    );
  }
  const sat = WEEK[5]!;
  const satPlan = satOrder.map((i) => sat.plan[i]!);
  satPlan.forEach((subject, i) =>
    slots.push({ thu: sat.thu, tiet: i + 1 + (afternoon ? 5 : 0), subject }),
  );
  return slots;
}

try {
  await db.query("BEGIN");

  const year = await db.query(
    "SELECT ma_nam_hoc FROM nam_hoc WHERE hien_hanh LIMIT 1",
  );
  const term = year.rows[0]
    ? await db.query(
        "SELECT ma_hoc_ky FROM hoc_ky WHERE ma_nam_hoc = $1 AND thu_tu = 1",
        [year.rows[0].ma_nam_hoc],
      )
    : { rows: [] };
  const classRows = year.rows[0]
    ? (
        await db.query(
          "SELECT ma_lop, ten_lop, khoi FROM lop WHERE ma_nam_hoc = $1 ORDER BY khoi, ten_lop",
          [year.rows[0].ma_nam_hoc],
        )
      ).rows
    : [];
  if (!term.rows[0] || classRows.length === 0) {
    await db.query("ROLLBACK");
    console.error(
      "Chưa có dữ liệu nền (năm học hiện hành, học kỳ 1, lớp). Chạy `pnpm db:seed` trước.",
    );
    process.exitCode = 2;
  } else {
    const termId = term.rows[0].ma_hoc_ky as number;

    const subjectId = new Map<string, number>();
    for (const s of SUBJECTS) {
      await db.query(
        `INSERT INTO mon_hoc (ten_mon, so_tiet_tuan) VALUES ($1, $2)
         ON CONFLICT (ten_mon) DO NOTHING`,
        [s.name, s.periods],
      );
      const id = (
        await db.query("SELECT ma_mon FROM mon_hoc WHERE ten_mon = $1", [
          s.name,
        ])
      ).rows[0].ma_mon as number;
      subjectId.set(s.name, id);
      for (const [name, weight, order] of [
        ["ĐĐGtx 1", 1, 1],
        ["ĐĐGtx 2", 1, 2],
        ["ĐĐGgk", 2, 3],
        ["ĐĐGck", 3, 4],
      ] as const) {
        await db.query(
          `INSERT INTO thanh_phan_diem (ma_mon, ten_thanh_phan, he_so, bat_buoc, thu_tu_hien_thi, loai_he_so)
           VALUES ($1, $2, $3, true, $4, $5)
           ON CONFLICT (ma_mon, ten_thanh_phan) DO NOTHING`,
          [
            id,
            name,
            weight,
            order,
            weight === 3 ? "CK" : weight === 2 ? "GK" : "TX",
          ],
        );
      }
    }

    const passwordHash = await hash(process.env.SEED_PASSWORD!, {
      type: argon2id,
      memoryCost: 65536,
      timeCost: 3,
      parallelism: 1,
    });
    const teachersBySubject = new Map<string, number[]>();
    let serial = 0;
    for (const s of SUBJECTS) {
      const ids: number[] = [];
      const existing = await db.query(
        `SELECT DISTINCT pc.ma_giao_vien FROM phan_cong_giang_day pc
         WHERE pc.ma_mon = $1 AND pc.ma_hoc_ky = $2 ORDER BY pc.ma_giao_vien`,
        [subjectId.get(s.name), termId],
      );
      for (const row of existing.rows) ids.push(row.ma_giao_vien as number);
      for (let i = 0; ids.length < s.teachers; i++) {
        const n = serial++;
        const phone = `0900${String(1000 + SUBJECTS.indexOf(s) * 10 + i).padStart(6, "0")}`;
        const name = `${LAST[(n * 3) % LAST.length]} ${MIDDLE[(n * 5) % MIDDLE.length]} ${FIRST[n % FIRST.length]}`;
        await db.query(
          `INSERT INTO nguoi_dung (ten_dang_nhap, mat_khau_ma_hoa, vai_tro)
           VALUES ($1, $2, 'GIAO_VIEN') ON CONFLICT (ten_dang_nhap) DO NOTHING`,
          [phone, passwordHash],
        );
        const userId = (
          await db.query(
            "SELECT ma_nguoi_dung FROM nguoi_dung WHERE ten_dang_nhap = $1",
            [phone],
          )
        ).rows[0].ma_nguoi_dung as number;
        await db.query(
          `INSERT INTO giao_vien (ma_giao_vien, ho_ten, to_chuyen_mon, email, dien_thoai)
           VALUES ($1, $2, $3, $4, $5) ON CONFLICT (ma_giao_vien) DO NOTHING`,
          [userId, name, s.dept, `gv.${phone}@truong.test`, phone],
        );
        if (!ids.includes(userId)) ids.push(userId);
      }
      teachersBySubject.set(s.name, ids);
    }

    const teacherOf = new Map<string, number>();
    const loads = new Map<string, number>();
    const classKhoi = new Map<number, number>(
      classRows.map((c) => [c.ma_lop as number, c.khoi as number]),
    );
    const loadKey = (teacher: number, lop: number) =>
      `${teacher}|${classKhoi.get(lop) === 10}`;
    const existingAssign = await db.query(
      "SELECT ma_lop, ma_mon, ma_giao_vien FROM phan_cong_giang_day WHERE ma_hoc_ky = $1",
      [termId],
    );
    for (const a of existingAssign.rows) {
      teacherOf.set(`${a.ma_lop}|${a.ma_mon}`, a.ma_giao_vien);
      const k = loadKey(a.ma_giao_vien, a.ma_lop);
      loads.set(k, (loads.get(k) ?? 0) + 1);
    }
    let addedAssignments = 0;
    for (const cls of classRows) {
      for (const s of SUBJECTS) {
        const key = `${cls.ma_lop}|${subjectId.get(s.name)}`;
        if (teacherOf.has(key)) continue;
        const candidates = [...teachersBySubject.get(s.name)!].sort(
          (a, b) =>
            (loads.get(loadKey(a, cls.ma_lop)) ?? 0) -
              (loads.get(loadKey(b, cls.ma_lop)) ?? 0) || a - b,
        );
        const chosen = candidates[0]!;
        await db.query(
          `INSERT INTO phan_cong_giang_day (ma_giao_vien, ma_lop, ma_mon, ma_hoc_ky, ngay_phan_cong)
           VALUES ($1, $2, $3, $4, CURRENT_DATE) ON CONFLICT (ma_lop, ma_mon, ma_hoc_ky) DO NOTHING`,
          [chosen, cls.ma_lop, subjectId.get(s.name), termId],
        );
        teacherOf.set(key, chosen);
        const chosenKey = loadKey(chosen, cls.ma_lop);
        loads.set(chosenKey, (loads.get(chosenKey) ?? 0) + 1);
        addedAssignments++;
      }
    }

    const busy = new Set<string>();
    for (const row of (
      await db.query(
        "SELECT ma_giao_vien, thu, tiet FROM thoi_khoa_bieu WHERE ma_hoc_ky = $1",
        [termId],
      )
    ).rows)
      busy.add(`${row.ma_giao_vien}|${row.thu}|${row.tiet}`);
    const scheduled = new Set<number>(
      (
        await db.query(
          "SELECT DISTINCT ma_lop FROM thoi_khoa_bieu WHERE ma_hoc_ky = $1",
          [termId],
        )
      ).rows.map((r) => r.ma_lop as number),
    );

    let addedSlots = 0;
    let classesScheduled = 0;
    const perGrade = new Map<number, number>();
    const indexOf = new Map<number, number>();
    for (const cls of classRows) {
      const index = perGrade.get(cls.khoi) ?? 0;
      perGrade.set(cls.khoi, index + 1);
      indexOf.set(cls.ma_lop, index);
    }
    const sharedTeachers = (lop: number) =>
      SUBJECTS.filter(
        (s) =>
          (loads.get(
            loadKey(teacherOf.get(`${lop}|${subjectId.get(s.name)}`)!, lop),
          ) ?? 0) >= 4,
      ).length;
    const order = [...classRows].sort(
      (x, y) =>
        sharedTeachers(y.ma_lop) - sharedTeachers(x.ma_lop) ||
        x.ma_lop - y.ma_lop,
    );
    for (const cls of order) {
      const index = indexOf.get(cls.ma_lop)!;
      if (scheduled.has(cls.ma_lop)) continue;
      const afternoon = cls.khoi === 10;
      let placed: Slot[] | null = null;
      const variants = DAY_ORDERS.length * 2 * SATURDAY_ORDERS.length;
      for (let attempt = 0; attempt < variants && !placed; attempt++) {
        const start = (index * 37 + cls.khoi * 11) % DAY_ORDERS.length;
        const order = DAY_ORDERS[(start + attempt) % DAY_ORDERS.length]!;
        const flip = Math.floor(attempt / DAY_ORDERS.length) % 2 === 1;
        const satOrder =
          SATURDAY_ORDERS[
            Math.floor(attempt / (DAY_ORDERS.length * 2)) %
              SATURDAY_ORDERS.length
          ]!;
        const slots = weekVariant(order, satOrder, flip, afternoon);
        const ok = slots.every((slot) => {
          const teacher = teacherOf.get(
            `${cls.ma_lop}|${subjectId.get(slot.subject)}`,
          );
          return (
            teacher !== undefined &&
            !busy.has(`${teacher}|${slot.thu}|${slot.tiet}`)
          );
        });
        if (ok) placed = slots;
      }
      if (!placed) {
        console.warn(
          `Bỏ qua lớp ${cls.ten_lop}: không xếp được tuần mẫu không trùng giáo viên.`,
        );
        continue;
      }
      const room = `P.${cls.khoi}${String(index + 1).padStart(2, "0")}`;
      for (const slot of placed) {
        const teacher = teacherOf.get(
          `${cls.ma_lop}|${subjectId.get(slot.subject)}`,
        )!;
        busy.add(`${teacher}|${slot.thu}|${slot.tiet}`);
        await db.query(
          `INSERT INTO thoi_khoa_bieu (ma_lop, ma_mon, ma_giao_vien, ma_hoc_ky, thu, tiet, phong_hoc)
           VALUES ($1, $2, $3, $4, $5, $6, $7)
           ON CONFLICT DO NOTHING`,
          [
            cls.ma_lop,
            subjectId.get(slot.subject),
            teacher,
            termId,
            slot.thu,
            slot.tiet,
            room,
          ],
        );
        addedSlots++;
      }
      classesScheduled++;
    }

    await db.query("COMMIT");
    console.log(
      `Dữ liệu mẫu: thêm ${addedAssignments} phân công, ${addedSlots} tiết của ${classesScheduled} lớp (phần đã có được giữ nguyên).`,
    );
  }
} catch (error) {
  await db.query("ROLLBACK");
  throw error;
} finally {
  db.release();
  await pool.end();
}
