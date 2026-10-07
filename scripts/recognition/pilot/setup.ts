/**
 * Dựng lớp thử nhận dạng (BE-20) trong DATABASE TEST CỤC BỘ. Không có họ tên nào trong mã nguồn này.
 *
 *   pnpm exec tsx scripts/recognition/pilot/setup.ts db     # lớp + học sinh + giáo viên + phân công (cần TEST_MIGRATION_URL *_test)
 *   pnpm exec tsx scripts/recognition/pilot/setup.ts book   # bảng điểm + lịch nhập đang mở (cần API đang chạy, SEED_PASSWORD)
 *
 * Danh sách học sinh đọc từ `.local/pilot/class.json` (git ignore): [{ stt, name, num, txt }]. Kết quả ghi vào
 * `.local/pilot/pilot.json` (id, tên đăng nhập và mật khẩu giáo viên thử). Gỡ bằng `cleanup.ts`.
 */
import { randomBytes } from "node:crypto";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { argon2id, hash } from "argon2";
import { Pool } from "pg";
import { classStudentOrder } from "../../../apps/api/src/common/student-order.ts";

const DIR = ".local/pilot";
const url = process.env.TEST_MIGRATION_URL ?? "";
if (!new URL(url || "http://x/").pathname.endsWith("_test"))
  throw new Error("TEST_MIGRATION_URL ending with _test is required");

interface Pilot {
  tag: string;
  yearId: number;
  termId: number;
  classId: number;
  className: string;
  subjectId: number;
  subjectName: string;
  componentId: number;
  componentName: string;
  teacherId: number;
  teacherUsername: string;
  teacherPassword: string;
  studentIds: number[];
  gradebookId?: number;
  extraComponents?: Array<{ id: number; name: string }>;
}

async function setupDb(): Promise<void> {
  const students = JSON.parse(
    readFileSync(`${DIR}/class.json`, "utf8"),
  ) as Array<{
    stt: number;
    name: string;
  }>;
  const tag = new Date().toISOString().slice(0, 16).replace(/[-:T]/g, "");
  const pool = new Pool({ connectionString: url });
  const db = await pool.connect();
  try {
    await db.query("BEGIN");
    let phone = 900000020;
    while (
      (
        await db.query("SELECT 1 FROM nguoi_dung WHERE ten_dang_nhap=$1", [
          `0${phone}`,
        ])
      ).rowCount
    )
      phone += 1;
    const username = `0${phone}`;
    const password = randomBytes(9).toString("base64url");
    const passwordHash = await hash(password, {
      type: argon2id,
      memoryCost: 65536,
      timeCost: 3,
      parallelism: 1,
    });
    const teacherId = (
      await db.query(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,$2,'GIAO_VIEN') RETURNING ma_nguoi_dung",
        [username, passwordHash],
      )
    ).rows[0].ma_nguoi_dung as number;
    await db.query(
      "INSERT INTO giao_vien(ma_giao_vien,ho_ten,to_chuyen_mon) VALUES($1,$2,'Thử nghiệm')",
      [teacherId, "Giáo viên thử BE-20"],
    );
    const yearId = (
      await db.query(
        "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2026-09-01','2027-06-01') RETURNING ma_nam_hoc",
        [`BE20 ${tag}`],
      )
    ).rows[0].ma_nam_hoc as number;
    const termId = (
      await db.query(
        "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'HK thử',1,'2026-09-01','2027-01-01') RETURNING ma_hoc_ky",
        [yearId],
      )
    ).rows[0].ma_hoc_ky as number;
    const className = "Lớp thử BE20";
    const classId = (
      await db.query(
        "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,10) RETURNING ma_lop",
        [yearId, teacherId, className],
      )
    ).rows[0].ma_lop as number;
    const studentRows: Array<{
      ma_hoc_sinh: number;
      ma_lop: number;
      ho_ten: string;
      dang_theo_hoc: boolean;
    }> = [];
    for (const student of students) {
      const id = (
        await db.query(
          "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh,dang_theo_hoc) VALUES($1,$2,'2006-01-01',true) RETURNING ma_hoc_sinh",
          [classId, student.name],
        )
      ).rows[0].ma_hoc_sinh as number;
      studentRows.push({
        ma_hoc_sinh: id,
        ma_lop: classId,
        ho_ten: student.name,
        dang_theo_hoc: true,
      });
    }
    // Thứ tự STT hệ thống (theo tên) phải trùng thứ tự in trên giấy, nếu không thuật toán ghép theo thứ tự sẽ lệch.
    const order = classStudentOrder(studentRows);
    const mismatched = students.filter(
      (student, index) =>
        order.get(studentRows[index]!.ma_hoc_sinh) !== student.stt,
    ).length;
    const subjectName = `Môn thử BE20 ${tag}`;
    const subjectId = (
      await db.query(
        "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,2) RETURNING ma_mon",
        [subjectName],
      )
    ).rows[0].ma_mon as number;
    const componentName = "Điểm thử nhận dạng";
    const componentId = (
      await db.query(
        "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,loai_he_so,bat_buoc,thu_tu_hien_thi) VALUES($1,$2,'CK',true,1) RETURNING ma_thanh_phan",
        [subjectId, componentName],
      )
    ).rows[0].ma_thanh_phan as number;
    await db.query(
      "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,CURRENT_DATE)",
      [teacherId, classId, subjectId, termId],
    );
    await db.query("COMMIT");
    const pilot: Pilot = {
      tag,
      yearId,
      termId,
      classId,
      className,
      subjectId,
      subjectName,
      componentId,
      componentName,
      teacherId,
      teacherUsername: username,
      teacherPassword: password,
      studentIds: studentRows.map((row) => row.ma_hoc_sinh),
    };
    mkdirSync(DIR, { recursive: true });
    writeFileSync(`${DIR}/pilot.json`, JSON.stringify(pilot, null, 2));
    console.log(
      JSON.stringify({
        students: students.length,
        classId,
        termId,
        subjectId,
        componentId,
        teacher: username,
        systemOrderDiffersFromPaperOrder: mismatched,
      }),
    );
  } catch (error) {
    await db.query("ROLLBACK");
    throw error;
  } finally {
    db.release();
    await pool.end();
  }
}

async function login(base: string, username: string, password: string) {
  const response = await fetch(`${base}/api/v1/identity/login`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-client-platform": "native",
    },
    body: JSON.stringify({ username, password }),
  });
  if (!response.ok) throw new Error(`login failed: ${response.status}`);
  return ((await response.json()) as { token: string }).token;
}

async function setupBook(): Promise<void> {
  const base = process.env.API_BASE_URL ?? "http://localhost:3000";
  const pilot = JSON.parse(readFileSync(`${DIR}/pilot.json`, "utf8")) as Pilot;
  const adminPassword = process.env.SEED_PASSWORD ?? "";
  if (!adminPassword) throw new Error("SEED_PASSWORD required (seeded admin)");
  const teacher = await login(
    base,
    pilot.teacherUsername,
    pilot.teacherPassword,
  );
  const created = await fetch(`${base}/api/v1/gradebooks`, {
    method: "POST",
    headers: {
      authorization: `Bearer ${teacher}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      classId: pilot.classId,
      subjectId: pilot.subjectId,
      termId: pilot.termId,
    }),
  });
  if (!created.ok)
    throw new Error(
      `create gradebook failed: ${created.status} ${await created.text()}`,
    );
  const book = (await created.json()) as { id: number };
  const admin = await login(base, "admin", adminPassword);
  const opens = new Date(Date.now() - 3_600_000).toISOString();
  const closes = new Date(Date.now() + 90 * 86_400_000).toISOString();
  const deadline = await fetch(
    `${base}/api/v1/gradebooks/${book.id}/components/${pilot.componentId}/deadline`,
    {
      method: "PUT",
      headers: {
        authorization: `Bearer ${admin}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        opensAt: opens,
        closesAt: closes,
        expectedVersion: 0,
      }),
    },
  );
  const deadlineStatus = deadline.status;
  pilot.gradebookId = book.id;
  writeFileSync(`${DIR}/pilot.json`, JSON.stringify(pilot, null, 2));
  console.log(
    JSON.stringify({ gradebookId: book.id, deadlineStatus, opens, closes }),
  );
}

// Thêm thành phần điểm để mỗi ảnh mẫu có phiếu chờ đối chiếu riêng (mỗi bảng điểm + thành phần chỉ có một phiếu đang chờ).
async function setupMore(): Promise<void> {
  const base = process.env.API_BASE_URL ?? "http://localhost:3000";
  const pilot = JSON.parse(readFileSync(`${DIR}/pilot.json`, "utf8")) as Pilot;
  if (!pilot.gradebookId) throw new Error("Run `book` first");
  const names = [
    "Điểm thử nhận dạng 2",
    "Điểm thử nhận dạng 3",
    "Điểm thử nhận dạng 4",
  ];
  const pool = new Pool({ connectionString: url });
  const extra: Array<{ id: number; name: string }> = [];
  try {
    for (const [index, name] of names.entries()) {
      const id = (
        await pool.query(
          "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,loai_he_so,bat_buoc,thu_tu_hien_thi) VALUES($1,$2,'TX',false,$3) RETURNING ma_thanh_phan",
          [pilot.subjectId, name, index + 2],
        )
      ).rows[0].ma_thanh_phan as number;
      extra.push({ id, name });
    }
  } finally {
    await pool.end();
  }
  const adminPassword = process.env.SEED_PASSWORD ?? "";
  if (!adminPassword) throw new Error("SEED_PASSWORD required (seeded admin)");
  const admin = await login(base, "admin", adminPassword);
  const opens = new Date(Date.now() - 3_600_000).toISOString();
  const closes = new Date(Date.now() + 90 * 86_400_000).toISOString();
  const statuses: number[] = [];
  for (const component of extra) {
    const response = await fetch(
      `${base}/api/v1/gradebooks/${pilot.gradebookId}/components/${component.id}/deadline`,
      {
        method: "PUT",
        headers: {
          authorization: `Bearer ${admin}`,
          "content-type": "application/json",
        },
        body: JSON.stringify({
          opensAt: opens,
          closesAt: closes,
          expectedVersion: 0,
        }),
      },
    );
    statuses.push(response.status);
  }
  pilot.extraComponents = extra;
  writeFileSync(`${DIR}/pilot.json`, JSON.stringify(pilot, null, 2));
  console.log(
    JSON.stringify({
      componentIds: extra.map((c) => c.id),
      deadlineStatuses: statuses,
    }),
  );
}

const command = process.argv[2];
if (command === "db") await setupDb();
else if (command === "book") await setupBook();
else if (command === "more") await setupMore();
else throw new Error("usage: setup.ts db|book|more");
