import { test } from "node:test";
import assert from "node:assert/strict";
import { randomBytes } from "node:crypto";
import { Pool } from "pg";
import { createApp } from "../../src/app.js";
import { GradebooksService } from "../../src/modules/gradebooks/application/service.js";

test("phân công giảng dạy tự tạo bảng điểm; bổ sung khi lớp có học sinh sau phân công; không tạo ở học kỳ đã công bố", async () => {
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
  const app = await createApp(
    { environment: "development", origins: [], databaseUrl: runtimeUrl },
    { check: async () => true, close: async () => {} },
  );
  await app.init();
  const service = app.get(GradebooksService);
  const suffix = randomBytes(5).toString("hex");
  try {
    const username = `auto_gv_${suffix}`;
    const teacherId: number = (
      await owner.query(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'test-only-no-login','GIAO_VIEN') RETURNING ma_nguoi_dung",
        [username],
      )
    ).rows[0].ma_nguoi_dung;
    const sessionHash = randomBytes(32).toString("hex");
    await owner.query(
      "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
      [sessionHash, teacherId, randomBytes(32).toString("hex")],
    );
    const teacher = {
      id: teacherId,
      username,
      role: "GIAO_VIEN" as const,
      sessionHash,
    };
    await owner.query(
      "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'Giáo viên tự động')",
      [teacherId],
    );
    const year = (
      await owner.query(
        "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2026-09-01','2027-06-01') RETURNING ma_nam_hoc",
        [`AG-${suffix}`],
      )
    ).rows[0].ma_nam_hoc;
    const term = (
      await owner.query(
        "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'Kỳ tự động',1,'2026-09-01','2027-01-01') RETURNING ma_hoc_ky",
        [year],
      )
    ).rows[0].ma_hoc_ky;
    const makeClass = async (name: string, students: number) => {
      const id = (
        await owner.query(
          "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,10) RETURNING ma_lop",
          [year, teacherId, name],
        )
      ).rows[0].ma_lop as number;
      if (students)
        await owner.query(
          "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh,dang_theo_hoc) SELECT $1,'HS ' || n,'2010-01-01',true FROM generate_series(1,$2::int) n",
          [id, students],
        );
      return id;
    };
    const makeSubject = async (tag: string, components: boolean) => {
      const id = (
        await owner.query(
          "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,2) RETURNING ma_mon",
          [`Môn ${tag} ${suffix}`],
        )
      ).rows[0].ma_mon as number;
      if (components)
        await owner.query(
          "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,he_so,thu_tu_hien_thi) VALUES($1,'Thường xuyên',1.00,1),($1,'Cuối kỳ',2.00,2)",
          [id],
        );
      return id;
    };
    const assign = (cls: number, subject: number, termId = term) =>
      owner.query(
        "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,CURRENT_DATE)",
        [teacherId, cls, subject, termId],
      );
    const books = async (cls: number, subject: number) =>
      (
        await owner.query(
          "SELECT ma_bang_diem FROM bang_diem WHERE ma_lop=$1 AND ma_mon=$2 AND ma_hoc_ky=$3",
          [cls, subject, term],
        )
      ).rows;
    const cells = async (bookId: number) =>
      Number(
        (
          await owner.query(
            "SELECT count(*) FROM diem_thanh_phan WHERE ma_bang_diem=$1 AND gia_tri IS NULL AND trang_thai='CHUA_CO'",
            [bookId],
          )
        ).rows[0].count,
      );

    // 1. Phân công lớp đủ học sinh + môn có thành phần: bảng điểm xuất hiện cùng ô trống (NULL, không phải 0.0).
    const full = await makeClass(`AG-full-${suffix}`, 3);
    const math = await makeSubject("math", true);
    await assign(full, math);
    const created = await books(full, math);
    assert.equal(created.length, 1);
    assert.equal(await cells(created[0].ma_bang_diem), 3 * 2);
    const audit = await owner.query(
      "SELECT ma_tac_nhan FROM nhat_ky_bao_mat WHERE hanh_dong='GRADEBOOK_CREATED' AND doi_tuong=$1",
      [`bang_diem:${created[0].ma_bang_diem}`],
    );
    assert.equal(audit.rowCount, 1);
    assert.equal(audit.rows[0].ma_tac_nhan, null);
    // Giáo viên thấy bảng ngay trong danh sách; gọi lại không tạo trùng.
    const listed = await service.list(teacher);
    assert.ok(
      listed.items.some((b) => b.id === created[0].ma_bang_diem),
      "teacher sees the auto-created gradebook",
    );
    assert.equal((await books(full, math)).length, 1);

    // 2. Lớp chưa có học sinh hoặc môn chưa có thành phần: phân công vẫn thành công, chưa có bảng.
    const empty = await makeClass(`AG-empty-${suffix}`, 0);
    const bare = await makeSubject("bare", false);
    await assign(empty, math);
    await assign(full, bare);
    assert.equal((await books(empty, math)).length, 0);
    assert.equal((await books(full, bare)).length, 0);

    // 3. Lớp có học sinh sau đó: giáo viên mở danh sách thì bảng được bổ sung.
    await owner.query(
      "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh,dang_theo_hoc) VALUES($1,'HS muộn','2010-01-01',true)",
      [empty],
    );
    await service.list(teacher);
    const late = await books(empty, math);
    assert.equal(late.length, 1);
    assert.equal(await cells(late[0].ma_bang_diem), 2);

    // 4. Học kỳ đã công bố: không tạo thêm bảng mới.
    const closedTerm = (
      await owner.query(
        "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc,da_cong_bo) VALUES($1,'Kỳ đã công bố',2,'2027-01-02','2027-06-01',true) RETURNING ma_hoc_ky",
        [year],
      )
    ).rows[0].ma_hoc_ky;
    await assign(full, math, closedTerm);
    assert.equal(
      (
        await owner.query(
          "SELECT 1 FROM bang_diem WHERE ma_lop=$1 AND ma_mon=$2 AND ma_hoc_ky=$3",
          [full, math, closedTerm],
        )
      ).rowCount,
      0,
    );
  } finally {
    await app.close();
    await owner.end();
  }
});
