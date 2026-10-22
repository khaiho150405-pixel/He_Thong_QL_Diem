import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { Prisma } from "../../../generated/prisma/client.js";
import type { PrismaClient } from "../../../generated/prisma/client.js";
import { unit } from "../../../common/store.js";
import { sqlStateOf, transaction } from "../../../common/transaction.js";
import type {
  Adjustment,
  AdjustmentLine,
  AdjustmentStore,
  AdjustmentUnit,
} from "../application/port.js";

const TS = `'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'`;

interface Row {
  id: string;
  gradebookId: number;
  className: string;
  subjectName: string;
  termName: string;
  status: Adjustment["status"];
  reason: string;
  submitterId: number;
  submitterName: string;
  submittedAt: string;
  deciderId: number | null;
  deciderName: string | null;
  decidedAt: string | null;
  decisionReason: string | null;
  lineCount: number;
  version: number;
}

function adjustment(row: Row, lines?: AdjustmentLine[]): Adjustment {
  return {
    id: row.id,
    gradebookId: row.gradebookId,
    className: row.className,
    subjectName: row.subjectName,
    termName: row.termName,
    status: row.status,
    reason: row.reason,
    submittedBy: { id: row.submitterId, name: row.submitterName },
    submittedAt: row.submittedAt,
    decidedBy:
      row.deciderId === null
        ? null
        : { id: row.deciderId, name: row.deciderName ?? "" },
    decidedAt: row.decidedAt,
    decisionReason: row.decisionReason,
    lineCount: row.lineCount,
    version: row.version,
    ...(lines ? { lines } : {}),
  };
}

/** Phiếu điều chỉnh kèm tên lớp/môn/học kỳ và tên người gửi/xử lý; `filter` chọn phiếu, `limit` giới hạn số dòng. */
async function selectAdjustments(
  tx: Prisma.TransactionClient,
  filter: Prisma.Sql,
  limit: Prisma.Sql,
): Promise<Row[]> {
  return tx.$queryRaw<Row[]>(Prisma.sql`
    SELECT p.ma::text AS id, p.ma_bang_diem AS "gradebookId", l.ten_lop AS "className",
      m.ten_mon AS "subjectName", h.ten AS "termName", p.trang_thai AS status, p.ly_do AS reason,
      p.nguoi_gui AS "submitterId", coalesce(gv.ho_ten, ug.ten_dang_nhap) AS "submitterName",
      to_char(p.thoi_diem_gui AT TIME ZONE 'UTC', ${Prisma.raw(TS)}) AS "submittedAt",
      p.nguoi_xu_ly AS "deciderId", coalesce(gx.ho_ten, ux.ten_dang_nhap) AS "deciderName",
      to_char(p.thoi_diem_xu_ly AT TIME ZONE 'UTC', ${Prisma.raw(TS)}) AS "decidedAt",
      p.ly_do_xu_ly AS "decisionReason",
      (SELECT count(*)::integer FROM public.dong_dieu_chinh d WHERE d.ma_phieu = p.ma) AS "lineCount",
      p.version
    FROM public.phieu_dieu_chinh p
    JOIN public.bang_diem b ON b.ma_bang_diem = p.ma_bang_diem
    JOIN public.lop l ON l.ma_lop = b.ma_lop
    JOIN public.mon_hoc m ON m.ma_mon = b.ma_mon
    JOIN public.hoc_ky h ON h.ma_hoc_ky = b.ma_hoc_ky
    JOIN public.nguoi_dung ug ON ug.ma_nguoi_dung = p.nguoi_gui
    LEFT JOIN public.giao_vien gv ON gv.ma_giao_vien = p.nguoi_gui
    LEFT JOIN public.nguoi_dung ux ON ux.ma_nguoi_dung = p.nguoi_xu_ly
    LEFT JOIN public.giao_vien gx ON gx.ma_giao_vien = p.nguoi_xu_ly
    WHERE ${filter}
    ORDER BY p.ma DESC ${limit}`);
}

@Injectable()
export class PrismaAdjustmentStore implements AdjustmentStore {
  constructor(@Inject("DATABASE") private readonly db: PrismaClient) {}

  async run<T>(work: (tx: AdjustmentUnit) => Promise<T>): Promise<T> {
    try {
      return await transaction(this.db, (tx) =>
        work({
          authorization: unit(tx),
          submit: async (
            sessionHash,
            bookId,
            version,
            reason,
            changes,
            call,
          ) => {
            const rows = await tx.$queryRaw<Array<{ result: { id: string } }>>`
              SELECT public.gui_phieu_dieu_chinh(${sessionHash}::text,${bookId}::integer,${version}::integer,
                ${reason}::text,${JSON.stringify(changes)}::jsonb,${call.idempotencyKey}::text,${call.requestHash}::text) AS result`;
            return rows[0]!.result.id;
          },
          approve: async (sessionHash, adjId, version, call) => {
            const rows = await tx.$queryRaw<Array<{ result: { id: string } }>>`
              SELECT public.duyet_phieu_dieu_chinh(${sessionHash}::text,${adjId}::bigint,${version}::integer,
                ${call.idempotencyKey}::text,${call.requestHash}::text) AS result`;
            return rows[0]!.result.id;
          },
          reject: async (sessionHash, adjId, version, reason, call) => {
            const rows = await tx.$queryRaw<Array<{ result: { id: string } }>>`
              SELECT public.tu_choi_phieu_dieu_chinh(${sessionHash}::text,${adjId}::bigint,${version}::integer,
                ${reason}::text,${call.idempotencyKey}::text,${call.requestHash}::text) AS result`;
            return rows[0]!.result.id;
          },
          cancel: async (sessionHash, adjId, version, call) => {
            const rows = await tx.$queryRaw<Array<{ result: { id: string } }>>`
              SELECT public.huy_phieu_dieu_chinh(${sessionHash}::text,${adjId}::bigint,${version}::integer,
                ${call.idempotencyKey}::text,${call.requestHash}::text) AS result`;
            return rows[0]!.result.id;
          },
          detail: async (adjId) => {
            const rows = await selectAdjustments(
              tx,
              Prisma.sql`p.ma = ${adjId}::bigint`,
              Prisma.empty,
            );
            if (!rows[0]) return null;
            const lines = await tx.$queryRaw<AdjustmentLine[]>`
              SELECT l.ma_diem::text AS "cellId", hs.ma_hoc_sinh AS "studentId", hs.ho_ten AS "studentName",
                tp.ma_thanh_phan AS "componentId", tp.ten_thanh_phan AS "componentName",
                l.gia_tri_cu::text AS "oldValue", l.trang_thai_cu AS "oldStatus",
                l.gia_tri_moi::text AS "newValue", l.mien_moi AS "newExempt", l.ghi_chu AS note
              FROM public.dong_dieu_chinh l
              JOIN public.diem_thanh_phan d ON d.ma_diem = l.ma_diem
              JOIN public.hoc_sinh hs ON hs.ma_hoc_sinh = d.ma_hoc_sinh
              JOIN public.thanh_phan_diem tp ON tp.ma_thanh_phan = d.ma_thanh_phan
              WHERE l.ma_phieu = ${adjId}::bigint ORDER BY l.ma`;
            return adjustment(rows[0], lines);
          },
          listForBook: async (bookId) =>
            (
              await selectAdjustments(
                tx,
                Prisma.sql`p.ma_bang_diem = ${bookId}::integer`,
                Prisma.sql`LIMIT 200`,
              )
            ).map((row) => adjustment(row)),
          list: async (status, before) =>
            (
              await selectAdjustments(
                tx,
                Prisma.sql`(${status}::text IS NULL OR p.trang_thai::text = ${status}::text)
                  AND (${before}::bigint = 0 OR p.ma < ${before}::bigint)`,
                Prisma.sql`LIMIT 51`,
              )
            ).map((row) => adjustment(row)),
        }),
      );
    } catch (error) {
      // Chuẩn hóa lỗi driver adapter; không lộ SQL/phiên.
      const e = error as { code?: string };
      const state = sqlStateOf(error);
      if (e.code === "P2010" && state === "42501")
        throw new ForbiddenException();
      if (e.code === "P2010" && ["02000", "P0002"].includes(state ?? ""))
        throw new NotFoundException();
      if (
        e.code === "P2010" &&
        ["23514", "23505", "40001"].includes(state ?? "")
      )
        throw new ConflictException();
      throw error;
    }
  }
}
