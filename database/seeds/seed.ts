import "dotenv/config";
import { Pool } from "pg";
import { hash, argon2id } from "argon2";

if (!["development", "test"].includes(process.env.APP_ENV ?? ""))
  throw new Error("Seed restricted to development/test");
if (
  !process.env.SEED_PASSWORD ||
  process.env.SEED_PASSWORD === "REPLACE_LOCALLY"
)
  throw new Error("SEED_PASSWORD required");
if (!process.env.MIGRATION_DATABASE_URL)
  throw new Error("MIGRATION_DATABASE_URL required");

const pool = new Pool({ connectionString: process.env.MIGRATION_DATABASE_URL });
const db = await pool.connect();

try {
  await db.query("BEGIN");

  // Seed adds fixtures without deleting existing accounts or academic records.
  // Single argon2id hash computation for all seed accounts
  const passwordHash = await hash(process.env.SEED_PASSWORD, {
    type: argon2id,
    memoryCost: 65536,
    timeCost: 3,
    parallelism: 1,
  });

  // 1. BASELINE PRODUCTION USERS FOR THPT BÀ ĐIỂM
  const usersToSeed: [string, string][] = [
    // Quản trị viên
    ["admin", "QUAN_TRI_VIEN"],

    // 5 Giáo viên bộ môn cốt lõi (hỗ trợ cả định dạng _ và . để thuận tiện đăng nhập)
    ["giaovien_toan", "GIAO_VIEN"],
    ["giaovien.toan", "GIAO_VIEN"],
    ["giaovien_van", "GIAO_VIEN"],
    ["giaovien.van", "GIAO_VIEN"],
    ["giaovien_anh", "GIAO_VIEN"],
    ["giaovien.anh", "GIAO_VIEN"],
    ["giaovien_ly", "GIAO_VIEN"],
    ["giaovien.ly", "GIAO_VIEN"],
    ["giaovien_hoa", "GIAO_VIEN"],
    ["giaovien.hoa", "GIAO_VIEN"],

    // Học sinh thật của các khối (đại diện học sinh tra cứu kết quả)
    ["hocsinh_a", "HOC_SINH"],
    ["hocsinh.anh", "HOC_SINH"],
    ["hocsinh_10a2", "HOC_SINH"],
    ["hocsinh_11a1", "HOC_SINH"],
    ["hocsinh_12a1", "HOC_SINH"],
  ];

  const userMap = new Map<string, number>();

  for (const [name, role] of usersToSeed) {
    await db.query(
      `INSERT INTO nguoi_dung (ten_dang_nhap, mat_khau_ma_hoa, vai_tro)
       VALUES ($1, $2, $3)
       ON CONFLICT (ten_dang_nhap) DO UPDATE
       SET mat_khau_ma_hoa = EXCLUDED.mat_khau_ma_hoa,
           vai_tro = EXCLUDED.vai_tro`,
      [name, passwordHash, role],
    );
    const id = (
      await db.query(
        "SELECT ma_nguoi_dung FROM nguoi_dung WHERE ten_dang_nhap = $1",
        [name],
      )
    ).rows[0].ma_nguoi_dung as number;
    userMap.set(name, id);
  }

  // 2. TEACHER PROFILES (5 Giáo viên chính thức THPT Bà Điểm)
  const teacherProfiles = [
    {
      userId: userMap.get("giaovien_toan")!,
      name: "Phạm Thu Hà",
      dept: "Toán - Tin",
      email: "phamthuha@thptbadiem.edu.vn",
      phone: "0903112233",
    },
    {
      userId: userMap.get("giaovien.toan")!,
      name: "Phạm Thu Hà",
      dept: "Toán - Tin",
      email: "phamthuha.toan@thptbadiem.edu.vn",
      phone: "0903112234",
    },
    {
      userId: userMap.get("giaovien_van")!,
      name: "Trần Minh Anh",
      dept: "Ngữ văn",
      email: "tranminhanh@thptbadiem.edu.vn",
      phone: "0903223344",
    },
    {
      userId: userMap.get("giaovien.van")!,
      name: "Trần Minh Anh",
      dept: "Ngữ văn",
      email: "tranminhanh.van@thptbadiem.edu.vn",
      phone: "0903223345",
    },
    {
      userId: userMap.get("giaovien_anh")!,
      name: "Nguyễn Mai Linh",
      dept: "Ngoại ngữ",
      email: "nguyenmailinh@thptbadiem.edu.vn",
      phone: "0903334455",
    },
    {
      userId: userMap.get("giaovien.anh")!,
      name: "Nguyễn Mai Linh",
      dept: "Ngoại ngữ",
      email: "nguyenmailinh.anh@thptbadiem.edu.vn",
      phone: "0903334456",
    },
    {
      userId: userMap.get("giaovien_ly")!,
      name: "Lê Quốc Bảo",
      dept: "Vật lý - KHTN",
      email: "lequocbao@thptbadiem.edu.vn",
      phone: "0903445566",
    },
    {
      userId: userMap.get("giaovien.ly")!,
      name: "Lê Quốc Bảo",
      dept: "Vật lý - KHTN",
      email: "lequocbao.ly@thptbadiem.edu.vn",
      phone: "0903445567",
    },
    {
      userId: userMap.get("giaovien_hoa")!,
      name: "Đinh Văn Thắng",
      dept: "Hóa - Sinh",
      email: "dinhvanthang@thptbadiem.edu.vn",
      phone: "0903556677",
    },
    {
      userId: userMap.get("giaovien.hoa")!,
      name: "Đinh Văn Thắng",
      dept: "Hóa - Sinh",
      email: "dinhvanthang.hoa@thptbadiem.edu.vn",
      phone: "0903556678",
    },
  ];

  for (const t of teacherProfiles) {
    await db.query(
      `INSERT INTO giao_vien (ma_giao_vien, ho_ten, to_chuyen_mon, email, dien_thoai)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (ma_giao_vien) DO UPDATE
       SET ho_ten = EXCLUDED.ho_ten,
           to_chuyen_mon = EXCLUDED.to_chuyen_mon,
           email = EXCLUDED.email,
           dien_thoai = EXCLUDED.dien_thoai`,
      [t.userId, t.name, t.dept, t.email, t.phone],
    );
  }

  // 3. ACADEMIC YEAR 2024–2025 (THPT Bà Điểm)
  await db.query(
    `INSERT INTO nam_hoc (ten, ngay_bat_dau, ngay_ket_thuc, hien_hanh)
     VALUES ('2024-2025', '2024-09-01', '2025-05-31', true)
     ON CONFLICT (ten) DO UPDATE
     SET hien_hanh = true,
         ngay_bat_dau = EXCLUDED.ngay_bat_dau,
         ngay_ket_thuc = EXCLUDED.ngay_ket_thuc`,
  );
  const currentYearId = (
    await db.query("SELECT ma_nam_hoc FROM nam_hoc WHERE ten = '2024-2025'")
  ).rows[0].ma_nam_hoc as number;

  await db.query(
    `INSERT INTO hoc_ky (ma_nam_hoc, ten, thu_tu, ngay_bat_dau, ngay_ket_thuc)
     VALUES ($1, 'Học kỳ 1', 1, '2024-09-01', '2025-01-15')
     ON CONFLICT (ma_nam_hoc, thu_tu) DO NOTHING`,
    [currentYearId],
  );
  await db.query(
    `INSERT INTO hoc_ky (ma_nam_hoc, ten, thu_tu, ngay_bat_dau, ngay_ket_thuc)
     VALUES ($1, 'Học kỳ 2', 2, '2025-01-16', '2025-05-31')
     ON CONFLICT (ma_nam_hoc, thu_tu) DO NOTHING`,
    [currentYearId],
  );

  const term1Id = (
    await db.query(
      "SELECT ma_hoc_ky FROM hoc_ky WHERE ma_nam_hoc = $1 AND thu_tu = 1",
      [currentYearId],
    )
  ).rows[0].ma_hoc_ky as number;

  // 4. CORE SUBJECTS & EVALUATION COMPONENTS (Theo Thông tư 22/BGDĐT)
  const coreSubjects = [
    { name: "Toán học", periods: 4 },
    { name: "Ngữ văn", periods: 4 },
    { name: "Tiếng Anh", periods: 3 },
    { name: "Vật lý", periods: 2 },
    { name: "Hóa học", periods: 2 },
    { name: "Lịch sử", periods: 2 },
  ];

  const subjectMap = new Map<string, number>();
  const componentMap = new Map<string, number[]>();

  for (const s of coreSubjects) {
    await db.query(
      `INSERT INTO mon_hoc (ten_mon, so_tiet_tuan) VALUES ($1, $2)
       ON CONFLICT (ten_mon) DO UPDATE SET so_tiet_tuan = EXCLUDED.so_tiet_tuan`,
      [s.name, s.periods],
    );
    const subId = (
      await db.query("SELECT ma_mon FROM mon_hoc WHERE ten_mon = $1", [s.name])
    ).rows[0].ma_mon as number;
    subjectMap.set(s.name, subId);

    // 4 thành phần đánh giá chuẩn
    const components = [
      { name: "ĐĐGtx 1", weight: 1.0, order: 1 },
      { name: "ĐĐGtx 2", weight: 1.0, order: 2 },
      { name: "ĐĐGgk", weight: 2.0, order: 3 },
      { name: "ĐĐGck", weight: 3.0, order: 4 },
    ];

    const compIds: number[] = [];
    for (const c of components) {
      await db.query(
        `INSERT INTO thanh_phan_diem (ma_mon, ten_thanh_phan, he_so, bat_buoc, thu_tu_hien_thi, loai_he_so)
         VALUES ($1, $2, $3, true, $4, $5)
         ON CONFLICT (ma_mon, ten_thanh_phan) DO NOTHING`,
        [
          subId,
          c.name,
          c.weight,
          c.order,
          c.weight === 3 ? "CK" : c.weight === 2 ? "GK" : "TX",
        ],
      );
      const cId = (
        await db.query(
          "SELECT ma_thanh_phan FROM thanh_phan_diem WHERE ma_mon = $1 AND ten_thanh_phan = $2",
          [subId, c.name],
        )
      ).rows[0].ma_thanh_phan as number;
      compIds.push(cId);
    }
    componentMap.set(s.name, compIds);
  }

  // 5. 15 LỚP HỌC CHUẨN: 5 LỚP MỖI KHỐI (10A1-10A5, 11A1-11A5, 12A1-12A5)
  const gvToanId = userMap.get("giaovien_toan")!;
  const gvVanId = userMap.get("giaovien_van")!;
  const gvAnhId = userMap.get("giaovien_anh")!;
  const gvLyId = userMap.get("giaovien_ly")!;
  const gvHoaId = userMap.get("giaovien_hoa")!;

  const grades = [
    {
      grade: 10,
      classes: ["10A1", "10A2", "10A3", "10A4", "10A5"],
      homeroomTeachers: [gvToanId, gvLyId, gvToanId, gvLyId, gvToanId],
      birthYear: 2009,
    },
    {
      grade: 11,
      classes: ["11A1", "11A2", "11A3", "11A4", "11A5"],
      homeroomTeachers: [gvVanId, gvHoaId, gvVanId, gvHoaId, gvVanId],
      birthYear: 2008,
    },
    {
      grade: 12,
      classes: ["12A1", "12A2", "12A3", "12A4", "12A5"],
      homeroomTeachers: [gvAnhId, gvAnhId, gvAnhId, gvLyId, gvHoaId],
      birthYear: 2007,
    },
  ];

  const classMap = new Map<string, number>();

  for (const g of grades) {
    for (let cIdx = 0; cIdx < g.classes.length; cIdx++) {
      const className = g.classes[cIdx]!;
      const hrTeacher = g.homeroomTeachers[cIdx]!;

      await db.query(
        `INSERT INTO lop (ma_nam_hoc, ma_gv_chu_nhiem, ten_lop, khoi)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (ma_nam_hoc, ten_lop) DO UPDATE
         SET ma_gv_chu_nhiem = EXCLUDED.ma_gv_chu_nhiem,
             khoi = EXCLUDED.khoi`,
        [currentYearId, hrTeacher, className, g.grade],
      );

      const clsId = (
        await db.query(
          "SELECT ma_lop FROM lop WHERE ma_nam_hoc = $1 AND ten_lop = $2",
          [currentYearId, className],
        )
      ).rows[0].ma_lop as number;
      classMap.set(className, clsId);
    }
  }

  // 6. SEED 41 HỌC SINH MỖI LỚP (15 * 41 = 615 HỌC SINH THỰC TẾ)
  const lastNames = [
    "Nguyễn",
    "Trần",
    "Lê",
    "Phạm",
    "Hoàng",
    "Huỳnh",
    "Phan",
    "Vũ",
    "Võ",
    "Đặng",
    "Bùi",
    "Đỗ",
    "Hồ",
    "Ngô",
    "Dương",
    "Lý",
  ];
  const middleNames = [
    "Văn",
    "Thị",
    "Minh",
    "Hoàng",
    "Đức",
    "Hữu",
    "Tuấn",
    "Ngọc",
    "Thanh",
    "Quỳnh",
    "Mai",
    "Phương",
  ];
  const firstNames = [
    "An",
    "Bình",
    "Cường",
    "Dũng",
    "Đạt",
    "Giang",
    "Hà",
    "Hải",
    "Hưng",
    "Huy",
    "Khánh",
    "Khoa",
    "Linh",
    "Long",
    "Minh",
    "Nam",
    "Nghĩa",
    "Nhân",
    "Phong",
    "Phúc",
    "Quân",
    "Sơn",
    "Tài",
    "Tâm",
    "Thảo",
    "Thịnh",
    "Thu",
    "Trang",
    "Triết",
    "Trí",
    "Trung",
    "Tú",
    "Tuấn",
    "Tùng",
    "Uyên",
    "Vinh",
    "Vy",
    "Vũ",
    "Xuân",
    "Yên",
    "Bảo",
  ];

  const studentUserIds = [
    userMap.get("hocsinh_a"),
    userMap.get("hocsinh.anh"),
    userMap.get("hocsinh_10a2"),
    userMap.get("hocsinh_11a1"),
    userMap.get("hocsinh_12a1"),
  ].filter((id): id is number => typeof id === "number");

  if (studentUserIds.length > 0) {
    await db.query(
      `UPDATE hoc_sinh SET ma_nguoi_dung = NULL WHERE ma_nguoi_dung = ANY($1::int[])`,
      [studentUserIds],
    );
  }

  const studentsByClass = new Map<string, number[]>();

  for (const g of grades) {
    for (let cIdx = 0; cIdx < g.classes.length; cIdx++) {
      const className = g.classes[cIdx]!;
      const clsId = classMap.get(className)!;
      const classStudentIds: number[] = [];

      const currentStudents = (
        await db.query(
          "SELECT ma_hoc_sinh, ho_ten FROM hoc_sinh WHERE ma_lop = $1 ORDER BY ma_hoc_sinh",
          [clsId],
        )
      ).rows;

      if (currentStudents.length < 41) {
        for (let sIdx = currentStudents.length; sIdx < 41; sIdx++) {
          const lName =
            lastNames[(sIdx + cIdx * 3 + g.grade) % lastNames.length];
          const mName = middleNames[(sIdx + cIdx * 2) % middleNames.length];
          const fName = firstNames[sIdx % firstNames.length];
          const studentName = `${lName} ${mName} ${fName}`;

          const month = String((sIdx % 12) + 1).padStart(2, "0");
          const day = String((sIdx % 27) + 1).padStart(2, "0");
          const birthDate = `${g.birthYear}-${month}-${day}`;

          const insertRes = await db.query(
            `INSERT INTO hoc_sinh (ma_nguoi_dung, ma_lop, ho_ten, ngay_sinh, dang_theo_hoc)
             VALUES (NULL, $1, $2, $3, true)
             RETURNING ma_hoc_sinh`,
            [clsId, studentName, birthDate],
          );
          classStudentIds.push(insertRes.rows[0].ma_hoc_sinh);
        }
      } else {
        for (const r of currentStudents) classStudentIds.push(r.ma_hoc_sinh);
      }

      studentsByClass.set(className, classStudentIds);
    }
  }

  // Gán tài khoản học sinh chuẩn xác cho từng học sinh cụ thể
  const s10A1 = studentsByClass.get("10A1")!;
  if (s10A1.length > 0) {
    await db.query(
      `UPDATE hoc_sinh SET ma_nguoi_dung = $1, ho_ten = 'Lê Bảo Châu' WHERE ma_hoc_sinh = $2`,
      [userMap.get("hocsinh.anh"), s10A1[0]],
    );
  }
  if (s10A1.length > 1) {
    await db.query(
      `UPDATE hoc_sinh SET ma_nguoi_dung = $1, ho_ten = 'Trần Thảo Linh' WHERE ma_hoc_sinh = $2`,
      [userMap.get("hocsinh_a"), s10A1[1]],
    );
  }
  const s10A2 = studentsByClass.get("10A2")!;
  if (s10A2.length > 0) {
    await db.query(
      `UPDATE hoc_sinh SET ma_nguoi_dung = $1, ho_ten = 'Nguyễn Minh An' WHERE ma_hoc_sinh = $2`,
      [userMap.get("hocsinh_10a2"), s10A2[0]],
    );
  }
  const s11A1 = studentsByClass.get("11A1")!;
  if (s11A1.length > 0) {
    await db.query(
      `UPDATE hoc_sinh SET ma_nguoi_dung = $1, ho_ten = 'Trần Đức Anh' WHERE ma_hoc_sinh = $2`,
      [userMap.get("hocsinh_11a1"), s11A1[0]],
    );
  }
  const s12A1 = studentsByClass.get("12A1")!;
  if (s12A1.length > 0) {
    await db.query(
      `UPDATE hoc_sinh SET ma_nguoi_dung = $1, ho_ten = 'Phạm Quỳnh Chi' WHERE ma_hoc_sinh = $2`,
      [userMap.get("hocsinh_12a1"), s12A1[0]],
    );
  }

  // 7. PHÂN CÔNG GIẢNG DẠY (5 GIÁO VIÊN QUA CÁC LỚP HỌC KỲ 1)
  const mathId = subjectMap.get("Toán học")!;
  const litId = subjectMap.get("Ngữ văn")!;
  const engId = subjectMap.get("Tiếng Anh")!;
  const physId = subjectMap.get("Vật lý")!;
  const chemId = subjectMap.get("Hóa học")!;

  const teachingAssignments = [
    // Cô Phạm Thu Hà (Toán): 10A1, 10A2, 10A3, 11A1, 12A1
    { t: gvToanId, c: "10A1", sub: mathId },
    { t: gvToanId, c: "10A2", sub: mathId },
    { t: gvToanId, c: "10A3", sub: mathId },
    { t: gvToanId, c: "11A1", sub: mathId },
    { t: gvToanId, c: "12A1", sub: mathId },

    // Cô Trần Minh Anh (Ngữ văn): 10A1, 10A2, 11A1, 11A2, 12A1
    { t: gvVanId, c: "10A1", sub: litId },
    { t: gvVanId, c: "10A2", sub: litId },
    { t: gvVanId, c: "11A1", sub: litId },
    { t: gvVanId, c: "11A2", sub: litId },
    { t: gvVanId, c: "12A1", sub: litId },

    // Cô Nguyễn Mai Linh (Tiếng Anh): 10A1, 10A2, 11A1, 12A1, 12A2
    { t: gvAnhId, c: "10A1", sub: engId },
    { t: gvAnhId, c: "10A2", sub: engId },
    { t: gvAnhId, c: "11A1", sub: engId },
    { t: gvAnhId, c: "12A1", sub: engId },
    { t: gvAnhId, c: "12A2", sub: engId },

    // Thầy Lê Quốc Bảo (Vật lý): 10A1, 10A2, 10A3, 11A1, 12A1
    { t: gvLyId, c: "10A1", sub: physId },
    { t: gvLyId, c: "10A2", sub: physId },
    { t: gvLyId, c: "10A3", sub: physId },
    { t: gvLyId, c: "11A1", sub: physId },
    { t: gvLyId, c: "12A1", sub: physId },

    // Thầy Đinh Văn Thắng (Hóa học): 10A1, 10A2, 11A1, 11A2, 12A1
    { t: gvHoaId, c: "10A1", sub: chemId },
    { t: gvHoaId, c: "10A2", sub: chemId },
    { t: gvHoaId, c: "11A1", sub: chemId },
    { t: gvHoaId, c: "11A2", sub: chemId },
    { t: gvHoaId, c: "12A1", sub: chemId },
  ];

  for (const a of teachingAssignments) {
    const cId = classMap.get(a.c)!;
    await db.query(
      `INSERT INTO phan_cong_giang_day (ma_giao_vien, ma_lop, ma_mon, ma_hoc_ky, ngay_phan_cong)
       VALUES ($1, $2, $3, $4, CURRENT_DATE)
       ON CONFLICT (ma_lop, ma_mon, ma_hoc_ky) DO NOTHING`,
      [a.t, cId, a.sub, term1Id],
    );
  }

  // 8. BẢNG ĐIỂM VÀ DỮ LIỆU ĐIỂM MẪU SỐNG ĐỘNG
  // Định nghĩa các bảng điểm cần khởi tạo
  const gradebookDefinitions = [
    // Lớp 10A1: Đầy đủ 5 môn chính
    {
      className: "10A1",
      subjectName: "Toán học",
      status: "DA_CHOT",
      version: 1,
    },
    {
      className: "10A1",
      subjectName: "Ngữ văn",
      status: "DANG_NHAP_LIEU",
      version: 0,
    },
    {
      className: "10A1",
      subjectName: "Tiếng Anh",
      status: "DANG_NHAP_LIEU",
      version: 0,
    },
    {
      className: "10A1",
      subjectName: "Vật lý",
      status: "DANG_NHAP_LIEU",
      version: 0,
    },
    {
      className: "10A1",
      subjectName: "Hóa học",
      status: "DANG_NHAP_LIEU",
      version: 0,
    },

    // Lớp 10A2: Toán, Văn, Anh
    {
      className: "10A2",
      subjectName: "Toán học",
      status: "DANG_NHAP_LIEU",
      version: 0,
    },
    {
      className: "10A2",
      subjectName: "Ngữ văn",
      status: "DANG_NHAP_LIEU",
      version: 0,
    },
    {
      className: "10A2",
      subjectName: "Tiếng Anh",
      status: "DANG_NHAP_LIEU",
      version: 0,
    },

    // Lớp 11A1: Toán, Văn
    {
      className: "11A1",
      subjectName: "Toán học",
      status: "DANG_NHAP_LIEU",
      version: 0,
    },
    {
      className: "11A1",
      subjectName: "Ngữ văn",
      status: "DANG_NHAP_LIEU",
      version: 0,
    },

    // Lớp 12A1: Toán, Anh
    {
      className: "12A1",
      subjectName: "Toán học",
      status: "DANG_NHAP_LIEU",
      version: 0,
    },
    {
      className: "12A1",
      subjectName: "Tiếng Anh",
      status: "DANG_NHAP_LIEU",
      version: 0,
    },
  ];

  // Mẫu điểm thực tế phân phối tự nhiên (6.0 - 9.8)
  const baseScores = [
    8.5, 9.0, 7.5, 8.0, 9.5, 8.5, 7.0, 9.0, 10.0, 8.0, 7.5, 8.5, 9.0, 8.0, 6.5,
    7.5, 8.5, 9.0, 8.0, 8.5, 9.5, 7.5, 8.0, 8.5, 9.0, 7.0, 8.5, 9.0, 8.0, 7.5,
    8.5, 9.0, 8.0, 8.5, 9.5, 7.5, 8.0, 8.5, 9.0, 8.5, 9.0,
  ];

  for (const def of gradebookDefinitions) {
    const cId = classMap.get(def.className)!;
    const sId = subjectMap.get(def.subjectName)!;
    const studentIds = studentsByClass.get(def.className) ?? [];
    const compIds = componentMap.get(def.subjectName) ?? [];

    const gbRes = await db.query(
      `INSERT INTO bang_diem (ma_lop, ma_mon, ma_hoc_ky, trang_thai, version)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (ma_lop, ma_mon, ma_hoc_ky) DO UPDATE
       SET trang_thai = EXCLUDED.trang_thai,
           version = EXCLUDED.version
       RETURNING ma_bang_diem`,
      [cId, sId, term1Id, def.status, def.version],
    );
    const gbId = gbRes.rows[0].ma_bang_diem as number;

    // Chèn điểm thành phần cho từng học sinh
    for (let sIdx = 0; sIdx < studentIds.length; sIdx++) {
      const studentId = studentIds[sIdx];
      const base = baseScores[sIdx % baseScores.length]!;

      // ĐĐGtx 1 (1.0), ĐĐGtx 2 (1.0), ĐĐGgk (2.0), ĐĐGck (3.0)
      const compScores: number[] = [];
      for (let cIdx = 0; cIdx < compIds.length; cIdx++) {
        const compId = compIds[cIdx];
        // Dao động tự nhiên giữa các lần kiểm tra
        const delta =
          cIdx === 2 ? 0.3 : cIdx === 3 ? -0.2 : cIdx % 2 === 0 ? 0.2 : -0.3;
        const scoreVal = Math.min(
          10.0,
          Math.max(5.5, Number((base + delta).toFixed(1))),
        );
        compScores.push(scoreVal);

        await db.query(
          `INSERT INTO diem_thanh_phan (ma_bang_diem, ma_hoc_sinh, ma_thanh_phan, gia_tri, trang_thai, nguon_nhap)
           VALUES ($1, $2, $3, $4, 'DA_DUYET', 'NHAP_TAY')
           ON CONFLICT (ma_bang_diem, ma_hoc_sinh, ma_thanh_phan) DO UPDATE
           SET gia_tri = EXCLUDED.gia_tri,
               trang_thai = EXCLUDED.trang_thai`,
          [gbId, studentId, compId, scoreVal.toFixed(1)],
        );
      }

      // Nếu là lớp 10A1 (hoặc bảng điểm DA_CHOT), tạo thêm kết quả tổng kết cho học sinh!
      if (def.className === "10A1" && compScores.length === 4) {
        // Công thức Thông tư 22: (ĐĐGtx1*1 + ĐĐGtx2*1 + ĐĐGgk*2 + ĐĐGck*3) / 7.0
        const finalScore = Number(
          (
            (compScores[0]! * 1.0 +
              compScores[1]! * 1.0 +
              compScores[2]! * 2.0 +
              compScores[3]! * 3.0) /
            7.0
          ).toFixed(1),
        );
        let classification = "CHUA_DAT";
        if (finalScore >= 8.0) classification = "GIOI";
        else if (finalScore >= 6.5) classification = "KHA";
        else if (finalScore >= 5.0) classification = "DAT";

        const boHeSo = JSON.stringify({
          weights: [
            { name: "ĐĐGtx 1", coefficient: "1.00", componentId: compIds[0] },
            { name: "ĐĐGtx 2", coefficient: "1.00", componentId: compIds[1] },
            { name: "ĐĐGgk", coefficient: "2.00", componentId: compIds[2] },
            { name: "ĐĐGck", coefficient: "3.00", componentId: compIds[3] },
          ],
          classificationPolicy: {
            version: "TT22-2024",
            roundingDigits: 1,
            criteria: [
              { code: "GIOI", minimum: "8.0" },
              { code: "KHA", minimum: "6.5" },
              { code: "DAT", minimum: "5.0" },
              { code: "CHUA_DAT", minimum: "0.0" },
            ],
          },
        });

        await db.query(
          `INSERT INTO ket_qua_tong_ket (ma_hoc_sinh, ma_mon, ma_hoc_ky, diem_tong_ket, xep_loai, phien_ban_he_so, bo_he_so, ngay_tinh)
           VALUES ($1, $2, $3, $4, $5, 'TT22-2024', $6::jsonb, CURRENT_TIMESTAMP)
           ON CONFLICT (ma_hoc_sinh, ma_mon, ma_hoc_ky) DO UPDATE
           SET diem_tong_ket = EXCLUDED.diem_tong_ket,
               xep_loai = EXCLUDED.xep_loai,
               ngay_tinh = EXCLUDED.ngay_tinh,
               bo_he_so = EXCLUDED.bo_he_so`,
          [
            studentId,
            sId,
            term1Id,
            finalScore.toFixed(1),
            classification,
            boHeSo,
          ],
        );
      }
    }
  }

  // 9. TỪ ĐIỂN ĐIỂM CHỮ (HỖ TRỢ OCR HAI KÊNH UC11–UC13)
  const scoreWords: [string, number][] = [
    ["không", 0.0],
    ["một", 1.0],
    ["hai", 2.0],
    ["ba", 3.0],
    ["bốn", 4.0],
    ["năm", 5.0],
    ["sáu", 6.0],
    ["bảy", 7.0],
    ["tám", 8.0],
    ["chín", 9.0],
    ["mười", 10.0],
    ["không rưỡi", 0.5],
    ["một rưỡi", 1.5],
    ["hai rưỡi", 2.5],
    ["ba rưỡi", 3.5],
    ["bốn rưỡi", 4.5],
    ["năm rưỡi", 5.5],
    ["sáu rưỡi", 6.5],
    ["bảy rưỡi", 7.5],
    ["tám rưỡi", 8.5],
    ["chín rưỡi", 9.5],
    ["sáu phẩy năm", 6.5],
    ["bảy phẩy không", 7.0],
    ["bảy phẩy năm", 7.5],
    ["tám phẩy không", 8.0],
    ["tám phẩy năm", 8.5],
    ["chín phẩy không", 9.0],
    ["chín phẩy năm", 9.5],
    ["mười phẩy không", 10.0],
  ];

  for (const [w, v] of scoreWords) {
    await db.query(
      `INSERT INTO tu_dien_diem_chu (cach_doc, gia_tri)
       VALUES ($1, $2)
       ON CONFLICT (cach_doc) DO UPDATE SET gia_tri = EXCLUDED.gia_tri`,
      [w, v],
    );
  }

  await db.query("COMMIT");
  console.log(
    "Development/test fixtures seeded successfully; existing demo records retained.",
  );
} catch (error) {
  await db.query("ROLLBACK");
  throw error;
} finally {
  db.release();
  await pool.end();
}
