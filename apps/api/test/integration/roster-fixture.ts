import { createHash, randomBytes, randomUUID } from "node:crypto";
import { Pool } from "pg";

// Dữ liệu hoàn toàn giả cho các test phiếu nhận dạng + danh sách lớp đã chốt (ADR-0015).
export interface Receipt {
  ticketId: string;
  jobId: string;
  status: string;
}

export async function createRosterFixture() {
  const ownerUrl = process.env.TEST_MIGRATION_URL;
  const runtimeUrl = process.env.TEST_RUNTIME_URL;
  if (
    !ownerUrl ||
    !runtimeUrl ||
    !new URL(ownerUrl).pathname.endsWith("_test") ||
    !new URL(runtimeUrl).pathname.endsWith("_test")
  )
    throw new Error("Explicit isolated test URLs required");
  const owner = new Pool({ connectionString: ownerUrl });
  const runtime = new Pool({ connectionString: runtimeUrl });
  const suffix = randomBytes(5).toString("hex");
  const teacherId: number = (
    await owner.query(
      "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'test-only','GIAO_VIEN') RETURNING ma_nguoi_dung",
      [`roster_${suffix}`],
    )
  ).rows[0].ma_nguoi_dung;
  const session = createHash("sha256").update(randomBytes(32)).digest("hex");
  await owner.query(
    "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
    [session, teacherId, randomBytes(32).toString("hex")],
  );
  await owner.query(
    "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'GV roster giả')",
    [teacherId],
  );
  const year = (
    await owner.query(
      "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2026-09-01','2027-06-01') RETURNING ma_nam_hoc",
      [`RS-${suffix}`],
    )
  ).rows[0].ma_nam_hoc;
  const term = (
    await owner.query(
      "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'Kỳ roster',1,'2026-09-01','2027-01-01') RETURNING ma_hoc_ky",
      [year],
    )
  ).rows[0].ma_hoc_ky;
  const makeClass = async (name: string) =>
    (
      await owner.query(
        "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,10) RETURNING ma_lop",
        [year, teacherId, `${name}-${suffix}`],
      )
    ).rows[0].ma_lop as number;
  const cls = await makeClass("A");
  const otherCls = await makeClass("B");
  const names = new Map<number, string>();
  const makeStudent = async (classId: number, name: string, active = true) => {
    const id = (
      await owner.query(
        "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh,dang_theo_hoc) VALUES($1,$2,'2010-01-01',$3) RETURNING ma_hoc_sinh",
        [classId, name, active],
      )
    ).rows[0].ma_hoc_sinh as number;
    names.set(id, name);
    return id;
  };
  // Mã học sinh tăng dần nhưng thứ tự tên là An, Bảo, Cường, Đạt: STT khác thứ tự mã.
  const students = {
    dat: await makeStudent(cls, "Nguyễn Văn Đạt"),
    an: await makeStudent(cls, "Trần Thị An"),
    cuong: await makeStudent(cls, "Lê Văn Cường"),
    bao: await makeStudent(cls, "Phạm Văn Bảo"),
    left: await makeStudent(cls, "Hoàng Văn Nghỉ", false),
    outsider: await makeStudent(otherCls, "Vũ Thị Khác"),
  };
  const subject = (
    await owner.query(
      "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,2) RETURNING ma_mon",
      [`RS-${suffix}`],
    )
  ).rows[0].ma_mon;
  const component = (
    await owner.query(
      "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,he_so,thu_tu_hien_thi) VALUES($1,'Ảnh roster',1,1) RETURNING ma_thanh_phan",
      [subject],
    )
  ).rows[0].ma_thanh_phan;
  await owner.query(
    "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,CURRENT_DATE)",
    [teacherId, cls, subject, term],
  );
  const book = (
    await owner.query(
      "INSERT INTO bang_diem(ma_lop,ma_mon,ma_hoc_ky) VALUES($1,$2,$3) RETURNING ma_bang_diem",
      [cls, subject, term],
    )
  ).rows[0].ma_bang_diem as number;
  // Ô điểm cho học sinh đang học: cần khi duyệt phiếu.
  await owner.query(
    "INSERT INTO diem_thanh_phan(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan) SELECT $1,ma_hoc_sinh,$2 FROM hoc_sinh WHERE ma_lop=$3 AND dang_theo_hoc",
    [book, component, cls],
  );

  const entry = (stt: number, studentId: number) => ({
    stt,
    studentId,
    fullName: names.get(studentId)!,
  });
  // Danh sách đúng theo thứ tự tên.
  const valid = [
    entry(1, students.an),
    entry(2, students.bao),
    entry(3, students.cuong),
    entry(4, students.dat),
  ];
  const createTicket = async (
    roster: unknown,
    key: string,
    hash = "a".repeat(64),
    checksum = randomBytes(32).toString("hex"),
  ): Promise<Receipt> => {
    const client = await runtime.connect();
    try {
      await client.query("BEGIN ISOLATION LEVEL SERIALIZABLE");
      try {
        const { rows } = await client.query(
          "SELECT public.tao_phieu_nhan_dien($1,$2,$3,$4,$5,$6::jsonb,$7,$8) AS result",
          [
            session,
            book,
            component,
            checksum,
            `recognition/original/${randomUUID()}.png`,
            JSON.stringify(roster),
            key,
            hash,
          ],
        );
        await client.query("COMMIT");
        return rows[0].result as Receipt;
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      }
    } finally {
      client.release();
    }
  };
  const countTickets = async () =>
    Number(
      (
        await owner.query(
          "SELECT count(*) FROM phieu_nhan_dien WHERE ma_bang_diem=$1",
          [book],
        )
      ).rows[0].count,
    );
  // Chạy một hàm SQL của runtime trong giao dịch SERIALIZABLE.
  const serializable = async <T>(
    work: (query: Pool["query"]) => Promise<T>,
  ): Promise<T> => {
    const client = await runtime.connect();
    try {
      await client.query("BEGIN ISOLATION LEVEL SERIALIZABLE");
      try {
        const value = await work(client.query.bind(client) as Pool["query"]);
        await client.query("COMMIT");
        return value;
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      }
    } finally {
      client.release();
    }
  };
  return {
    owner,
    runtime,
    suffix,
    session,
    teacherId,
    cls,
    book,
    component,
    students,
    makeStudent,
    entry,
    valid,
    createTicket,
    countTickets,
    serializable,
    close: async () => {
      // Không để lại sự kiện outbox chưa gửi: dispatcher của test khác lấy theo lô 10 sự kiện cũ nhất.
      await owner.query(
        "UPDATE recognition_outbox SET da_gui_luc=now() WHERE da_gui_luc IS NULL AND ma_phieu IN (SELECT ma_phieu FROM phieu_nhan_dien WHERE ma_bang_diem=$1)",
        [book],
      );
      await owner.end();
      await runtime.end();
    },
  };
}
