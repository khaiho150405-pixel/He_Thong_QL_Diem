import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import type { PrismaClient } from "../../../generated/prisma/client.js";
import { unit } from "../../../common/store.js";
import { transaction, sqlStateOf } from "../../../common/transaction.js";
import type {
  Gradebook,
  GradebookStore,
  GradebookUnit,
  GradeCell,
  GradeHistoryEntry,
  GradebookHistoryEntry,
  BatchResult,
} from "../application/port.js";

interface BookRow {
  ma_bang_diem: number;
  ma_lop: number;
  ma_mon: number;
  ma_hoc_ky: number;
  ten_lop: string;
  ten_mon: string;
  ten_hoc_ky: string;
  trang_thai: Gradebook["status"];
  version: number;
}
function book(row: BookRow): Gradebook {
  return {
    id: row.ma_bang_diem,
    classId: row.ma_lop,
    subjectId: row.ma_mon,
    termId: row.ma_hoc_ky,
    className: row.ten_lop,
    subjectName: row.ten_mon,
    termName: row.ten_hoc_ky,
    status: row.trang_thai,
    version: row.version,
  };
}

@Injectable()
export class PrismaGradebookStore implements GradebookStore {
  constructor(@Inject("DATABASE") private readonly db: PrismaClient) {}
  async run<T>(work: (tx: GradebookUnit) => Promise<T>): Promise<T> {
    try {
      return await transaction(this.db, (tx) =>
        work({
          authorization: unit(tx),
          createBlankGrid: async (sessionHash, scope) => {
            const rows = await tx.$queryRaw<BookRow[]>`
            SELECT created.*, l.ten_lop, m.ten_mon, h.ten AS ten_hoc_ky
            FROM public.tao_luoi_diem_trong(${sessionHash}::text,
              ${scope.classId}::integer, ${scope.subjectId}::integer, ${scope.termId}::integer) created
            JOIN public.lop l ON l.ma_lop = created.ma_lop
            JOIN public.mon_hoc m ON m.ma_mon = created.ma_mon
            JOIN public.hoc_ky h ON h.ma_hoc_ky = created.ma_hoc_ky`;
            return book(rows[0]!);
          },
          find: async (id) => {
            const rows = await tx.$queryRaw<BookRow[]>`
              SELECT b.*, l.ten_lop, m.ten_mon, h.ten AS ten_hoc_ky
              FROM public.bang_diem b
              JOIN public.lop l USING(ma_lop)
              JOIN public.mon_hoc m USING(ma_mon)
              JOIN public.hoc_ky h USING(ma_hoc_ky)
              WHERE b.ma_bang_diem = ${id}::integer`;
            return rows[0] ? book(rows[0]) : null;
          },
          list: async (teacherId, after) => {
            const rows = await tx.$queryRaw<BookRow[]>`
            SELECT b.*, l.ten_lop, m.ten_mon, h.ten AS ten_hoc_ky
            FROM public.bang_diem b
            JOIN public.lop l USING(ma_lop)
            JOIN public.mon_hoc m USING(ma_mon)
            JOIN public.hoc_ky h USING(ma_hoc_ky)
            WHERE b.ma_bang_diem > ${after}::integer
              AND (${teacherId}::integer IS NULL OR EXISTS (
                SELECT 1 FROM public.phan_cong_giang_day pc
                WHERE pc.ma_giao_vien = ${teacherId}::integer AND pc.ma_lop = b.ma_lop
                  AND pc.ma_mon = b.ma_mon AND pc.ma_hoc_ky = b.ma_hoc_ky))
            ORDER BY b.ma_bang_diem LIMIT 51`;
            return rows.map(book);
          },
          cells: (bookId, after) => tx.$queryRaw<GradeCell[]>`
          SELECT d.ma_diem::text AS id, hs.ma_hoc_sinh AS "studentId", hs.ho_ten AS "studentName",
            (hs.dang_theo_hoc AND hs.ma_lop = b.ma_lop) AS active,
            tp.ma_thanh_phan AS "componentId", tp.ten_thanh_phan AS "componentName",
            tp.he_so::text AS coefficient, tp.bat_buoc AS required, tp.thu_tu_hien_thi AS "displayOrder",
            tp.cho_phep_nhap AS "openForInput",
            d.gia_tri::text AS value, d.trang_thai AS status, d.nguon_nhap AS source
          FROM public.diem_thanh_phan d JOIN public.bang_diem b USING (ma_bang_diem)
          JOIN public.hoc_sinh hs USING (ma_hoc_sinh)
          JOIN public.thanh_phan_diem tp USING (ma_thanh_phan)
          WHERE d.ma_bang_diem = ${bookId}::integer AND d.ma_diem > ${after}::bigint
          ORDER BY d.ma_diem LIMIT 51`,
          updateGrades: async (sessionHash, bookId, version, changes) => {
            const rows = await tx.$queryRaw<Array<{ result: BatchResult }>>`
              SELECT public.cap_nhat_diem(${sessionHash}::text, ${bookId}::integer,
                ${version}::integer, ${JSON.stringify(changes)}::jsonb) AS result`;
            return rows[0]!.result;
          },
          syncRoster: async (sessionHash, bookId, version) => {
            const rows = await tx.$queryRaw<BookRow[]>`
              SELECT updated.*, l.ten_lop, m.ten_mon, h.ten AS ten_hoc_ky
              FROM public.dong_bo_si_so(${sessionHash}::text,${bookId}::integer,${version}::integer) updated
              JOIN public.lop l ON l.ma_lop = updated.ma_lop
              JOIN public.mon_hoc m ON m.ma_mon = updated.ma_mon
              JOIN public.hoc_ky h ON h.ma_hoc_ky = updated.ma_hoc_ky`;
            return book(rows[0]!);
          },
          lockGradebook: async (sessionHash, bookId, expectedVersion) => {
            const rows = await tx.$queryRaw<BookRow[]>`
            SELECT locked.*, l.ten_lop, m.ten_mon, h.ten AS ten_hoc_ky
            FROM public.chot_bang_diem(
              ${sessionHash}::text, ${bookId}::integer, ${expectedVersion}::integer) locked
            JOIN public.lop l ON l.ma_lop = locked.ma_lop
            JOIN public.mon_hoc m ON m.ma_mon = locked.ma_mon
            JOIN public.hoc_ky h ON h.ma_hoc_ky = locked.ma_hoc_ky`;
            if (rows.length === 0) throw new NotFoundException();
            return book(rows[0]!);
          },
          gradeHistory: (bookId, cellId, after) => tx.$queryRaw<
            GradeHistoryEntry[]
          >`
          SELECT h.ma_lich_su::text AS id, h.ma_diem::text AS "cellId",
            h.nguoi_sua AS editor,
            h.gia_tri_cu::text AS "oldValue", h.gia_tri_moi::text AS "newValue",
            h.ly_do AS reason, to_char(h.thoi_diem AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') AS timestamp
          FROM public.lich_su_sua_diem h JOIN public.diem_thanh_phan d USING(ma_diem)
          WHERE d.ma_bang_diem = ${bookId}::integer AND h.ma_diem = ${BigInt(cellId)}::bigint AND h.ma_lich_su > ${BigInt(after)}::bigint
          ORDER BY h.ma_lich_su LIMIT 51`,
          gradebookHistory: (bookId, after) => tx.$queryRaw<
            GradebookHistoryEntry[]
          >`
          SELECT h.ma_lich_su::text AS id, h.ma_diem::text AS "cellId",
            h.nguoi_sua AS editor,
            h.gia_tri_cu::text AS "oldValue", h.gia_tri_moi::text AS "newValue",
            h.ly_do AS reason,
            to_char(h.thoi_diem AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') AS timestamp,
            hs.ho_ten AS "studentName", tp.ten_thanh_phan AS "componentName"
          FROM public.lich_su_sua_diem h
          JOIN public.diem_thanh_phan d USING(ma_diem)
          JOIN public.hoc_sinh hs USING(ma_hoc_sinh)
          JOIN public.thanh_phan_diem tp USING(ma_thanh_phan)
          WHERE d.ma_bang_diem = ${bookId}::integer
            AND (${BigInt(after)}::bigint = 0 OR h.ma_lich_su < ${BigInt(after)}::bigint)
          ORDER BY h.ma_lich_su DESC LIMIT 51`,
          findIdempotencyKey: async (key, userId, operation) => {
            const row = await tx.khoa_idempotency.findUnique({
              where: {
                ma_nguoi_dung_thao_tac_khoa: {
                  khoa: key,
                  ma_nguoi_dung: userId,
                  thao_tac: operation,
                },
              },
            });
            if (!row) return null; // Retain replay protection until a reviewed retention job exists.
            return {
              key: row.khoa,
              userId: row.ma_nguoi_dung,
              operation: row.thao_tac,
              requestHash: row.ma_bam_yeu_cau,
              result: row.ket_qua,
            };
          },
          saveIdempotencyKey: async (
            key,
            userId,
            operation,
            reqHash,
            result,
          ) => {
            await tx.khoa_idempotency.create({
              data: {
                khoa: key,
                ma_nguoi_dung: userId,
                thao_tac: operation,
                ma_bam_yeu_cau: reqHash,
                ket_qua: result as object,
              },
            });
          },
        }),
      );
    } catch (error) {
      // Normalize the driver adapter error; never expose SQL/session details.
      const e = error as { code?: string };
      const sqlState = sqlStateOf(error);
      if (e.code === "P2010" && sqlState === "42501")
        throw new ForbiddenException();
      if (e.code === "P2010" && ["02000", "P0002"].includes(sqlState ?? ""))
        throw new NotFoundException();
      if (
        e.code === "P2010" &&
        ["23514", "23505", "40001"].includes(sqlState ?? "")
      )
        throw new ConflictException();
      throw error;
    }
  }
}
