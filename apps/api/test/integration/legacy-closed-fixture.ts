import { createHash } from "node:crypto";
import type { Pool } from "pg";
import {
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from "@nestjs/common";
import type { Actor } from "../../src/modules/authorization/application/policy.js";
import type { GradebooksService } from "../../src/modules/gradebooks/application/service.js";
import type { Gradebook } from "../../src/modules/gradebooks/application/port.js";
// Simulate a column closed under ADR-0013 before the new deadline policy.
// This helper uses the isolated test migration role; runtime execute is revoked.
export async function closedFixture(
  owner: Pool,
  service: GradebooksService,
  actor: Actor,
  bookId: number,
  componentId: number,
  key: string,
  input: { expectedVersion: number },
): Promise<Gradebook> {
  const c = await owner.connect();
  const hash = createHash("sha256")
    .update(JSON.stringify({ bookId, componentId, input }))
    .digest("hex");
  try {
    await c.query("BEGIN ISOLATION LEVEL SERIALIZABLE");
    const replay = await c.query(
      "SELECT ket_qua,ma_bam_yeu_cau FROM khoa_idempotency WHERE ma_nguoi_dung=$1 AND thao_tac='LOCK_COLUMN' AND khoa=$2",
      [actor.id, key],
    );
    if (replay.rowCount) {
      if (replay.rows[0].ma_bam_yeu_cau !== hash) throw new ConflictException();
      await c.query("COMMIT");
      return replay.rows[0].ket_qua;
    }
    await c.query("SELECT * FROM public.chot_cot($1,$2,$3,$4)", [
      actor.sessionHash,
      bookId,
      componentId,
      input.expectedVersion,
    ]);
    const row = (
      await c.query(
        "SELECT b.*,l.ten_lop,m.ten_mon,h.ten FROM bang_diem b JOIN lop l USING(ma_lop) JOIN mon_hoc m USING(ma_mon) JOIN hoc_ky h USING(ma_hoc_ky) WHERE ma_bang_diem=$1",
        [bookId],
      )
    ).rows[0];
    const result: Gradebook = {
      id: bookId,
      classId: row.ma_lop,
      subjectId: row.ma_mon,
      termId: row.ma_hoc_ky,
      className: row.ten_lop,
      subjectName: row.ten_mon,
      termName: row.ten,
      status: row.trang_thai,
      version: row.version,
    };
    await c.query(
      "INSERT INTO khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua) VALUES($1,$2,'LOCK_COLUMN',$3,$4)",
      [key, actor.id, hash, JSON.stringify(result)],
    );
    await c.query("COMMIT");
    void service;
    return result;
  } catch (e) {
    await c.query("ROLLBACK");
    const code = (e as { code?: string }).code;
    if (code === "23514") throw new ConflictException();
    if (code === "42501") throw new ForbiddenException();
    if (code === "P0002") throw new NotFoundException();
    throw e;
  } finally {
    c.release();
  }
}
