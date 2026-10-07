/**
 * Xóa các phiếu nhận dạng CHƯA DUYỆT của bảng điểm thử (BE-20) để có thể tải lại đúng ảnh đó (ảnh trùng SHA-256 bị từ chối).
 *
 *   pnpm exec tsx scripts/recognition/pilot/reset-tickets.ts [LOI|CHUA_DUYET|<mã phiếu>]   (mặc định LOI)
 *
 * LOI: chỉ phiếu lỗi. CHUA_DUYET: phiếu lỗi, đang xử lý và chờ đối chiếu. <mã phiếu>: đúng một phiếu chưa duyệt đó.
 * Phiếu ĐÃ DUYỆT không bao giờ bị xóa (đã ghi điểm).
 * Chỉ chạy với database `*_test` (TEST_MIGRATION_URL, chủ sở hữu bảng); tắt trigger chỉ-ghi-thêm của `danh_sach_phieu`
 * trong một giao dịch rồi bật lại. Xóa luôn ảnh gốc và ảnh ô trong object storage.
 */
import { readFileSync } from "node:fs";
import { createRequire } from "node:module";
import { Pool } from "pg";

// @aws-sdk/client-s3 chỉ được cài trong workspace apps/api.
const { DeleteObjectCommand, S3Client } = createRequire(
  new URL("../../../apps/api/package.json", import.meta.url),
)("@aws-sdk/client-s3") as typeof import("@aws-sdk/client-s3");

const mode = process.argv[2] ?? "LOI";
if (!["LOI", "CHUA_DUYET"].includes(mode) && !/^[1-9][0-9]*$/.test(mode))
  throw new Error("usage: reset-tickets.ts [LOI|CHUA_DUYET|<ticketId>]");
const url = process.env.TEST_MIGRATION_URL ?? "";
if (!new URL(url || "http://x/").pathname.endsWith("_test"))
  throw new Error("TEST_MIGRATION_URL ending with _test is required");
const pilot = JSON.parse(readFileSync(".local/pilot/pilot.json", "utf8")) as {
  gradebookId: number;
};
const statuses =
  mode === "LOI" ? ["LOI"] : ["LOI", "DANG_XU_LY", "CHO_DOI_CHIEU"];
const onlyTicket = /^[1-9][0-9]*$/.test(mode) ? mode : null;

const pool = new Pool({ connectionString: url });
const db = await pool.connect();
const keys: string[] = [];
let removed = 0;
try {
  await db.query("BEGIN");
  await db.query(
    "ALTER TABLE danh_sach_phieu DISABLE TRIGGER danh_sach_phieu_append_only",
  );
  const tickets = (
    await db.query(
      'SELECT ma_phieu, duong_dan_anh_goc FROM phieu_nhan_dien WHERE ma_bang_diem=$1 AND trang_thai = ANY($2::"TrangThaiPhieu"[]) AND ($3::bigint IS NULL OR ma_phieu = $3::bigint)',
      [pilot.gradebookId, statuses, onlyTicket],
    )
  ).rows as Array<{ ma_phieu: string; duong_dan_anh_goc: string }>;
  const ids = tickets.map((row) => row.ma_phieu);
  keys.push(...tickets.map((row) => row.duong_dan_anh_goc));
  const crops = await db.query(
    "SELECT duong_dan_anh_o_so a, duong_dan_anh_o_chu b, duong_dan_anh_o_ten c FROM ket_qua_dong WHERE ma_phieu = ANY($1::bigint[])",
    [ids],
  );
  for (const row of crops.rows)
    for (const key of [row.a, row.b, row.c]) if (key) keys.push(key as string);
  const counts = {
    ket_qua_dong: (
      await db.query(
        "DELETE FROM ket_qua_dong WHERE ma_phieu = ANY($1::bigint[])",
        [ids],
      )
    ).rowCount,
    danh_sach_phieu: (
      await db.query(
        "DELETE FROM danh_sach_phieu WHERE ma_phieu = ANY($1::bigint[])",
        [ids],
      )
    ).rowCount,
    recognition_outbox: (
      await db.query(
        "DELETE FROM recognition_outbox WHERE ma_phieu = ANY($1::bigint[])",
        [ids],
      )
    ).rowCount,
    phieu_nhan_dien: (
      await db.query(
        "DELETE FROM phieu_nhan_dien WHERE ma_phieu = ANY($1::bigint[])",
        [ids],
      )
    ).rowCount,
  };
  await db.query(
    "ALTER TABLE danh_sach_phieu ENABLE TRIGGER danh_sach_phieu_append_only",
  );
  await db.query("COMMIT");
  console.log(JSON.stringify({ mode, deleted: counts }));
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
  for (const key of new Set(keys)) {
    try {
      await s3.send(
        new DeleteObjectCommand({ Bucket: process.env.S3_BUCKET, Key: key }),
      );
      removed += 1;
    } catch {
      // đối tượng đã mất hoặc storage không sẵn sàng
    }
  }
  console.log(JSON.stringify({ objectsRemoved: removed }));
}
