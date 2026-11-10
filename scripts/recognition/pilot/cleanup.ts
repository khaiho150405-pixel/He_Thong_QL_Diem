import { readFileSync, existsSync, renameSync } from "node:fs";
import { createRequire } from "node:module";
import { Pool } from "pg";

const { DeleteObjectCommand, S3Client } = createRequire(
  new URL("../../../apps/api/package.json", import.meta.url),
)("@aws-sdk/client-s3") as typeof import("@aws-sdk/client-s3");

const file = process.argv[2] ?? ".local/pilot/pilot.json";
const url = process.env.TEST_MIGRATION_URL ?? "";
if (!new URL(url || "http://x/").pathname.endsWith("_test"))
  throw new Error("TEST_MIGRATION_URL ending with _test is required");
if (!existsSync(file)) throw new Error(`Không thấy ${file}`);
const pilot = JSON.parse(readFileSync(file, "utf8")) as {
  yearId: number;
  termId: number;
  classId: number;
  subjectId: number;
  componentId: number;
  teacherId: number;
};

const pool = new Pool({ connectionString: url });
const db = await pool.connect();
const keys: string[] = [];
try {
  await db.query("BEGIN");
  await db.query(
    "ALTER TABLE lich_su_sua_diem DISABLE TRIGGER lich_su_append_only",
  );
  await db.query(
    "ALTER TABLE danh_sach_phieu DISABLE TRIGGER danh_sach_phieu_append_only",
  );
  const books = (
    await db.query("SELECT ma_bang_diem FROM bang_diem WHERE ma_lop=$1", [
      pilot.classId,
    ])
  ).rows.map((row) => row.ma_bang_diem as number);
  const tickets = (
    await db.query(
      "SELECT ma_phieu, duong_dan_anh_goc FROM phieu_nhan_dien WHERE ma_bang_diem = ANY($1::int[])",
      [books],
    )
  ).rows as Array<{ ma_phieu: string; duong_dan_anh_goc: string }>;
  const ticketIds = tickets.map((row) => row.ma_phieu);
  keys.push(...tickets.map((row) => row.duong_dan_anh_goc));
  const crops = await db.query(
    "SELECT duong_dan_anh_o_so a, duong_dan_anh_o_chu b, duong_dan_anh_o_ten c FROM ket_qua_dong WHERE ma_phieu = ANY($1::bigint[])",
    [ticketIds],
  );
  for (const row of crops.rows)
    for (const key of [row.a, row.b, row.c]) if (key) keys.push(key as string);
  const run = async (sql: string, params: unknown[]) =>
    (await db.query(sql, params)).rowCount ?? 0;
  const counts: Record<string, number> = {};
  counts.ket_qua_dong = await run(
    "DELETE FROM ket_qua_dong WHERE ma_phieu = ANY($1::bigint[])",
    [ticketIds],
  );
  counts.danh_sach_phieu = await run(
    "DELETE FROM danh_sach_phieu WHERE ma_phieu = ANY($1::bigint[])",
    [ticketIds],
  );
  counts.recognition_outbox = await run(
    "DELETE FROM recognition_outbox WHERE ma_phieu = ANY($1::bigint[])",
    [ticketIds],
  );
  counts.phieu_nhan_dien = await run(
    "DELETE FROM phieu_nhan_dien WHERE ma_phieu = ANY($1::bigint[])",
    [ticketIds],
  );
  counts.lich_su_sua_diem = await run(
    "DELETE FROM lich_su_sua_diem WHERE ma_diem IN (SELECT ma_diem FROM diem_thanh_phan WHERE ma_bang_diem = ANY($1::int[]))",
    [books],
  );
  counts.diem_thanh_phan = await run(
    "DELETE FROM diem_thanh_phan WHERE ma_bang_diem = ANY($1::int[])",
    [books],
  );
  counts.chot_cot_diem = await run(
    "DELETE FROM chot_cot_diem WHERE ma_bang_diem = ANY($1::int[])",
    [books],
  );
  counts.lich_nhap_diem = await run(
    "DELETE FROM lich_nhap_diem WHERE ma_bang_diem = ANY($1::int[])",
    [books],
  );
  counts.ket_qua_tong_ket = await run(
    "DELETE FROM ket_qua_tong_ket WHERE ma_mon=$1 AND ma_hoc_ky=$2",
    [pilot.subjectId, pilot.termId],
  );
  counts.bang_diem = await run(
    "DELETE FROM bang_diem WHERE ma_bang_diem = ANY($1::int[])",
    [books],
  );
  counts.phan_cong_giang_day = await run(
    "DELETE FROM phan_cong_giang_day WHERE ma_lop=$1",
    [pilot.classId],
  );
  counts.hoc_sinh = await run("DELETE FROM hoc_sinh WHERE ma_lop=$1", [
    pilot.classId,
  ]);
  counts.lop = await run("DELETE FROM lop WHERE ma_lop=$1", [pilot.classId]);
  await run("DELETE FROM he_so_hoc_ky WHERE ma_hoc_ky=$1", [pilot.termId]);
  await run("DELETE FROM he_so_hoc_ky_chung WHERE ma_hoc_ky=$1", [
    pilot.termId,
  ]);
  counts.thanh_phan_diem = await run(
    "DELETE FROM thanh_phan_diem WHERE ma_mon=$1",
    [pilot.subjectId],
  );
  counts.mon_hoc = await run("DELETE FROM mon_hoc WHERE ma_mon=$1", [
    pilot.subjectId,
  ]);
  counts.hoc_ky = await run("DELETE FROM hoc_ky WHERE ma_hoc_ky=$1", [
    pilot.termId,
  ]);
  counts.nam_hoc = await run("DELETE FROM nam_hoc WHERE ma_nam_hoc=$1", [
    pilot.yearId,
  ]);
  for (const table of ["phien_lam_viec", "khoa_idempotency", "gioi_han_tac_vu"])
    await run(`DELETE FROM ${table} WHERE ma_nguoi_dung=$1`, [pilot.teacherId]);
  counts.giao_vien = await run("DELETE FROM giao_vien WHERE ma_giao_vien=$1", [
    pilot.teacherId,
  ]);
  counts.nguoi_dung = await run(
    "DELETE FROM nguoi_dung WHERE ma_nguoi_dung=$1",
    [pilot.teacherId],
  );
  await db.query(
    "ALTER TABLE lich_su_sua_diem ENABLE TRIGGER lich_su_append_only",
  );
  await db.query(
    "ALTER TABLE danh_sach_phieu ENABLE TRIGGER danh_sach_phieu_append_only",
  );
  await db.query("COMMIT");
  console.log(JSON.stringify({ deleted: counts, objects: keys.length }));
} catch (error) {
  await db.query("ROLLBACK");
  throw error;
} finally {
  db.release();
  await pool.end();
}

if (keys.length && process.env.S3_ENDPOINT) {
  const s3 = new S3Client({
    endpoint: process.env.S3_ENDPOINT,
    region: "us-east-1",
    forcePathStyle: true,
    credentials: {
      accessKeyId: process.env.S3_ACCESS_KEY ?? "",
      secretAccessKey: process.env.S3_SECRET_KEY ?? "",
    },
  });
  let removed = 0;
  for (const key of new Set(keys)) {
    try {
      await s3.send(
        new DeleteObjectCommand({ Bucket: process.env.S3_BUCKET, Key: key }),
      );
      removed += 1;
    } catch {}
  }
  console.log(JSON.stringify({ objectsRemoved: removed }));
}
renameSync(file, `${file}.removed`);
