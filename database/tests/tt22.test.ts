import { test } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { readFileSync } from "node:fs";
import { Pool } from "pg";
import { DB_MESSAGES } from "../../apps/api/src/common/db-messages.js";

function testPool() {
  const url = process.env.TEST_MIGRATION_URL;
  if (!url || !new URL(url).pathname.endsWith("_test"))
    throw new Error("Cần TEST_MIGRATION_URL trỏ DB kết thúc _test");
  return new Pool({ connectionString: url });
}

test("mọi mã lỗi do hàm PostgreSQL ném ra đều có thông báo tiếng Việt riêng", async () => {
  const pool = testPool();
  const elsewhere = [
    "apps/api/src/common/coded-error.ts",
    "apps/api/src/modules/recognition/application/batch-errors.ts",
  ]
    .map((path) => readFileSync(path, "utf8"))
    .join("\n");
  try {
    const { rows } = await pool.query<{ name: string; body: string }>(
      "SELECT p.proname AS name,p.prosrc AS body FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public'",
    );
    const missing = new Set<string>();
    let found = 0;
    for (const row of rows)
      for (const match of row.body.matchAll(
        /(?:RAISE\s+EXCEPTION\s+|MESSAGE\s*=\s*)'([A-Z][A-Z0-9_]{2,})/gi,
      )) {
        const code = match[1]!;
        if (code !== code.toUpperCase()) continue;
        found++;
        if (
          !["FORBIDDEN", "NOT_FOUND"].includes(code) &&
          !DB_MESSAGES[code] &&
          !new RegExp(`\\b${code}\\b`).test(elsewhere)
        )
          missing.add(`${code} (${row.name})`);
      }
    assert.ok(found > 50, `chỉ đọc được ${found} mã lỗi`);
    assert.deepEqual([...missing].sort(), []);
  } finally {
    await pool.end();
  }
});

test("mức kết quả học tập học kỳ theo Thông tư 22/2021, kể cả quy tắc nâng mức", async () => {
  const pool = testPool();
  const db = await pool.connect();
  const tag = randomUUID().slice(0, 8);
  const id = async (sql: string, params: unknown[] = []) =>
    Number((await db.query(sql, params)).rows[0].id);
  try {
    await db.query("BEGIN");
    const teacher = await id(
      "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'x','GIAO_VIEN') RETURNING ma_nguoi_dung AS id",
      [`tt22_${tag}`],
    );
    await db.query(
      "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'Giáo viên giả')",
      [teacher],
    );
    const year = await id(
      "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2050-09-01','2051-06-01') RETURNING ma_nam_hoc AS id",
      [`TT-${tag}`],
    );
    const term = await id(
      "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'HK1',1,'2050-09-01','2051-01-15') RETURNING ma_hoc_ky AS id",
      [year],
    );
    const klass = await id(
      "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,10) RETURNING ma_lop AS id",
      [year, teacher, `TT-${tag}`],
    );
    const subject = (name: string, passFail: boolean) =>
      id(
        "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan,danh_gia_dat) VALUES($1,2,$2) RETURNING ma_mon AS id",
        [`${name} ${tag}`, passFail],
      );
    const numeric: number[] = [];
    for (let i = 0; i < 8; i++) numeric.push(await subject(`So${i}`, false));
    const comments = [
      await subject("NhanXet1", true),
      await subject("NhanXet2", true),
    ];

    const level = async (scores: number[], passFail: boolean[] = []) => {
      const student = await id(
        "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,'Học sinh giả','2035-01-01') RETURNING ma_hoc_sinh AS id",
        [klass],
      );
      const results: Array<[number, number, string | null]> = [
        ...scores.map(
          (score, i) => [numeric[i]!, score, null] as [number, number, null],
        ),
        ...passFail.map(
          (ok, i) =>
            [comments[i]!, ok ? 10 : 0, ok ? "DAT" : "CHUA_DAT"] as [
              number,
              number,
              string,
            ],
        ),
      ];
      for (const [subjectId, score, code] of results)
        await db.query(
          "INSERT INTO ket_qua_tong_ket(ma_hoc_sinh,ma_mon,ma_hoc_ky,diem_tong_ket,xep_loai,phien_ban_he_so,bo_he_so,ngay_tinh) VALUES($1,$2,$3,$4,$5,'T','{}',now())",
          [student, subjectId, term, score, code],
        );
      return (
        await db.query("SELECT xep_muc_hoc_tap($1,$2) AS result", [
          student,
          term,
        ])
      ).rows[0].result as { level: string | null; raised: boolean };
    };
    const expect = async (
      name: string,
      expected: [string | null, boolean],
      scores: number[],
      passFail: boolean[] = [],
    ) => {
      const result = await level(scores, passFail);
      assert.deepEqual([result.level, result.raised], expected, name);
    };

    await expect("Tốt", ["TOT", false], [8, 8, 8, 8, 8, 8, 6.5, 6.5], [true]);
    await expect(
      "chỉ 5 môn từ 8,0",
      ["KHA", false],
      [8, 8, 8, 8, 8, 7.9, 7, 7],
    );
    await expect("Khá", ["KHA", false], [7, 7, 7, 7, 7, 7, 5, 5]);
    await expect("Đạt", ["DAT", false], [5, 5, 5, 5, 5, 5, 3.5, 3.5]);
    await expect("Chưa đạt", ["CHUA_DAT", false], [5, 5, 5, 5, 5, 4, 4, 4]);
    await expect(
      "một môn kéo Tốt xuống Đạt được nâng lên Khá",
      ["KHA", true],
      [9, 9, 9, 9, 9, 9, 9, 4],
    );
    await expect(
      "một môn nhận xét Chưa đạt kéo Tốt xuống Đạt được nâng lên Khá",
      ["KHA", true],
      [9, 9, 9, 9, 9, 9, 9, 9],
      [false],
    );
    await expect(
      "hai môn nhận xét Chưa đạt",
      ["CHUA_DAT", false],
      [9, 9, 9, 9, 9, 9, 9, 9],
      [false, false],
    );
    await expect("chưa đủ 6 môn có điểm", [null, false], [9, 9, 9, 9, 9]);
  } finally {
    await db.query("ROLLBACK");
    db.release();
    await pool.end();
  }
});
