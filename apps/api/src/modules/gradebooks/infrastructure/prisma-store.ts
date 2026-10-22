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
import { classStudentOrder } from "../../../common/student-order.js";
import { transaction, sqlStateOf } from "../../../common/transaction.js";
import type {
  Gradebook,
  GradebookStore,
  GradebookUnit,
  GradeCell,
  GradeHistoryEntry,
  GradebookHistoryEntry,
  BatchResult,
  SemesterDeadline,
  InitializeResult,
  ExemptionResult,
  LateStudentResult,
  MissingStudent,
  PublishReadiness,
} from "../application/port.js";
import { deadlineFailure } from "../application/deadline-errors.js";

interface BookRow {
  ma_bang_diem: number;
  ma_lop: number;
  ma_mon: number;
  ma_hoc_ky: number;
  ten_lop: string;
  ten_mon: string;
  ten_hoc_ky: string;
  ma_phieu_cho?: string | null;
  can_tinh_lai_tong_ket?: boolean;
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
    pendingAdjustmentId: row.ma_phieu_cho ?? null,
    resultsOutdated: row.can_tinh_lai_tong_ket ?? false,
    status: row.trang_thai,
    version: row.version,
  };
}

/**
 * Lỗi nghiệp vụ của tao_luoi_diem_trong → thông báo tiếng Việt cụ thể (chỉ cho luồng tạo bảng điểm).
 * Không lộ chi tiết SQL/phiên; lỗi khác trả null để giữ cách xử lý chung.
 */
export function createGridFailure(error: unknown): Error | null {
  const diagnostic =
    String(error) + JSON.stringify((error as { meta?: unknown }).meta ?? {});
  if (diagnostic.includes("GRADEBOOK_FORBIDDEN"))
    return new ForbiddenException(
      "Bạn chưa được phân công dạy môn này cho lớp và học kỳ đã chọn.",
    );
  if (diagnostic.includes("GRADEBOOK_YEAR_MISMATCH"))
    return new ConflictException("Học kỳ đã chọn không thuộc năm học của lớp.");
  if (diagnostic.includes("GRADEBOOK_EMPTY_ROSTER_OR_COMPONENTS"))
    return new ConflictException(
      "Lớp chưa có học sinh đang theo học hoặc môn học chưa có thành phần điểm.",
    );
  return null;
}

/** Ô điểm của một bảng kèm lịch hiệu lực, trạng thái miễn và STT; `filter` chọn ô, `limit` giới hạn số dòng. */
async function selectCells(
  tx: Prisma.TransactionClient,
  bookId: number,
  filter: Prisma.Sql,
  limit: Prisma.Sql,
): Promise<GradeCell[]> {
  const rows = await tx.$queryRaw<Array<Omit<GradeCell, "stt">>>(Prisma.sql`
    SELECT d.ma_diem::text AS id, hs.ma_hoc_sinh AS "studentId", hs.ho_ten AS "studentName",
      coalesce(cl.con_hoc, false) AS active,
      tp.ma_thanh_phan AS "componentId", tp.ten_thanh_phan AS "componentName",
      public.he_so_ap_dung(tp.ma_thanh_phan,b.ma_hoc_ky)::text AS coefficient, tp.bat_buoc AS required, tp.thu_tu_hien_thi AS "displayOrder",
      (tp.cho_phep_nhap AND d.trang_thai<>'MIEN' AND (w.dong_luc IS NULL OR (clock_timestamp()>=w.mo_luc AND clock_timestamp()<w.dong_luc))) AS "openForInput",
      to_char(w.mo_luc AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') AS "opensAt",
      to_char(w.dong_luc AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') AS "closesAt",
      CASE WHEN w.nguon='RIENG' THEN w.version ELSE 0 END AS "deadlineVersion",
      w.nguon AS "deadlineSource",
      EXISTS(SELECT 1 FROM public.chot_cot_diem c WHERE c.ma_bang_diem=b.ma_bang_diem AND c.ma_thanh_phan=tp.ma_thanh_phan) AS "columnLocked",
      (SELECT danh_gia_dat FROM public.mon_hoc WHERE ma_mon=b.ma_mon) AS "passFail",
      d.gia_tri::text AS value, d.trang_thai AS status, d.nguon_nhap AS source,
      (SELECT m.ly_do FROM public.lich_su_mien_diem m WHERE m.ma_diem=d.ma_diem AND d.trang_thai='MIEN'
        ORDER BY m.ma DESC LIMIT 1) AS "exemptionReason"
    FROM public.diem_thanh_phan d JOIN public.bang_diem b USING (ma_bang_diem)
    JOIN public.hoc_sinh hs USING (ma_hoc_sinh)
    LEFT JOIN LATERAL (SELECT s.con_hoc FROM public.hoc_sinh_cua_lop(b.ma_lop, b.ma_hoc_ky) s
      WHERE s.ma_hoc_sinh = d.ma_hoc_sinh) cl ON true
    JOIN public.thanh_phan_diem tp USING (ma_thanh_phan)
    LEFT JOIN LATERAL public.lich_hieu_luc(b.ma_bang_diem,tp.ma_thanh_phan) w ON true
    WHERE d.ma_bang_diem = ${bookId}::integer AND ${filter}
    ORDER BY d.ma_diem ${limit}`);
  if (!rows.length) return [];
  const roster = await tx.$queryRaw<
    Array<{ ma_hoc_sinh: number; ma_lop: number; ho_ten: string }>
  >`
    SELECT s.ma_hoc_sinh, b.ma_lop, s.ho_ten
    FROM public.bang_diem b CROSS JOIN LATERAL public.hoc_sinh_cua_lop(b.ma_lop, b.ma_hoc_ky) s
    WHERE b.ma_bang_diem = ${bookId}::integer AND s.con_hoc`;
  const order = classStudentOrder(
    roster.map((row) => ({ ...row, dang_theo_hoc: true })),
  );
  return rows.map((row) => ({
    ...row,
    stt: row.active ? (order.get(row.studentId) ?? null) : null,
  }));
}

@Injectable()
export class PrismaGradebookStore implements GradebookStore {
  constructor(@Inject("DATABASE") private readonly db: PrismaClient) {}
  async run<T>(work: (tx: GradebookUnit) => Promise<T>): Promise<T> {
    try {
      return await transaction(this.db, (tx) =>
        work({
          authorization: unit(tx),
          semesterDeadlines: (termId) =>
            tx.$queryRaw<SemesterDeadline[]>`
              SELECT v.type, to_char(h.mo_luc AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') AS "opensAt",
                to_char(h.dong_luc AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') AS "closesAt",
                coalesce(h.version,0) AS version,
                coalesce(h.dong_luc<=clock_timestamp(),false) AS expired
              FROM (VALUES ('TX',1),('GK',2),('CK',3)) v(type,position)
              LEFT JOIN public.lich_nhap_hoc_ky h ON h.ma_hoc_ky=${termId}::integer AND h.loai_he_so=v.type
              ORDER BY v.position`,
          setSemesterDeadline: async (
            sessionHash,
            termId,
            type,
            opensAt,
            closesAt,
            version,
          ) => {
            try {
              await tx.$queryRaw`SELECT public.dat_lich_nhap_hoc_ky(${sessionHash}::text,${termId}::integer,${type}::text,${opensAt}::timestamptz,${closesAt}::timestamptz,${version}::integer)::text`;
            } catch (error) {
              throw deadlineFailure(error) ?? error;
            }
          },
          initializeSemester: async (sessionHash, termId, key, requestHash) => {
            try {
              const rows = await tx.$queryRaw<
                Array<{ result: InitializeResult }>
              >`
                SELECT public.khoi_tao_bang_diem_hoc_ky(${sessionHash}::text,${termId}::integer,${key}::text,${requestHash}::text) AS result`;
              return rows[0]!.result;
            } catch (error) {
              throw deadlineFailure(error) ?? error;
            }
          },
          processDue: async () => {
            const rows = await tx.$queryRaw<
              Array<{ count: number }>
            >`SELECT public.xu_ly_han_nhap_diem() AS count`;
            return rows[0]!.count;
          },
          setDeadline: async (
            sessionHash,
            bookId,
            componentId,
            opensAt,
            closesAt,
            version,
          ) => {
            await tx.$queryRaw`SELECT public.dat_lich_nhap_diem(${sessionHash}::text,${bookId}::integer,${componentId}::integer,${opensAt}::timestamptz,${closesAt}::timestamptz,${version}::integer)::text`;
          },
          createBlankGrid: async (sessionHash, scope) => {
            try {
              const rows = await tx.$queryRaw<BookRow[]>`
            SELECT created.*, l.ten_lop, m.ten_mon, h.ten AS ten_hoc_ky, (SELECT p.ma::text FROM public.phieu_dieu_chinh p WHERE p.ma_bang_diem = created.ma_bang_diem AND p.trang_thai = 'CHO_DUYET') AS ma_phieu_cho
            FROM public.tao_luoi_diem_trong(${sessionHash}::text,
              ${scope.classId}::integer, ${scope.subjectId}::integer, ${scope.termId}::integer) created
            JOIN public.lop l ON l.ma_lop = created.ma_lop
            JOIN public.mon_hoc m ON m.ma_mon = created.ma_mon
            JOIN public.hoc_ky h ON h.ma_hoc_ky = created.ma_hoc_ky`;
              return book(rows[0]!);
            } catch (error) {
              throw createGridFailure(error) ?? error;
            }
          },
          find: async (id) => {
            const rows = await tx.$queryRaw<BookRow[]>`
              SELECT b.*, l.ten_lop, m.ten_mon, h.ten AS ten_hoc_ky, (SELECT p.ma::text FROM public.phieu_dieu_chinh p WHERE p.ma_bang_diem = b.ma_bang_diem AND p.trang_thai = 'CHO_DUYET') AS ma_phieu_cho
              FROM public.bang_diem b
              JOIN public.lop l USING(ma_lop)
              JOIN public.mon_hoc m USING(ma_mon)
              JOIN public.hoc_ky h USING(ma_hoc_ky)
              WHERE b.ma_bang_diem = ${id}::integer`;
            return rows[0] ? book(rows[0]) : null;
          },
          list: async (teacherId, after, yearId) => {
            const rows = await tx.$queryRaw<BookRow[]>`
            SELECT b.*, l.ten_lop, m.ten_mon, h.ten AS ten_hoc_ky, (SELECT p.ma::text FROM public.phieu_dieu_chinh p WHERE p.ma_bang_diem = b.ma_bang_diem AND p.trang_thai = 'CHO_DUYET') AS ma_phieu_cho
            FROM public.bang_diem b
            JOIN public.lop l USING(ma_lop)
            JOIN public.mon_hoc m USING(ma_mon)
            JOIN public.hoc_ky h USING(ma_hoc_ky)
            WHERE b.ma_bang_diem > ${after}::integer
              AND (${yearId}::integer IS NULL OR h.ma_nam_hoc = ${yearId}::integer)
              AND (${teacherId}::integer IS NULL OR EXISTS (
                SELECT 1 FROM public.phan_cong_giang_day pc
                WHERE pc.ma_giao_vien = ${teacherId}::integer AND pc.ma_lop = b.ma_lop
                  AND pc.ma_mon = b.ma_mon AND pc.ma_hoc_ky = b.ma_hoc_ky))
            ORDER BY b.ma_bang_diem LIMIT 51`;
            return rows.map(book);
          },
          cells: async (bookId, after) =>
            selectCells(
              tx,
              bookId,
              Prisma.sql`d.ma_diem > ${after}::bigint`,
              Prisma.sql`LIMIT 51`,
            ),
          cellsByIds: async (bookId, ids) =>
            ids.length
              ? selectCells(
                  tx,
                  bookId,
                  Prisma.sql`d.ma_diem = ANY(${ids}::bigint[])`,
                  Prisma.empty,
                )
              : [],
          setExemptions: async (
            sessionHash,
            bookId,
            version,
            changes,
            key,
            requestHash,
          ) => {
            const rows = await tx.$queryRaw<Array<{ result: ExemptionResult }>>`
              SELECT public.dat_mien_diem(${sessionHash}::text,${bookId}::integer,${version}::integer,
                ${JSON.stringify(changes)}::jsonb,${key}::text,${requestHash}::text) AS result`;
            return rows[0]!.result;
          },
          missingStudents: (bookId) =>
            tx.$queryRaw<MissingStudent[]>`
              SELECT ma_hoc_sinh AS "studentId", ho_ten AS "studentName"
              FROM public.hoc_sinh_thieu_o(${bookId}::integer)`,
          addLateStudent: async (
            sessionHash,
            bookId,
            studentId,
            reason,
            key,
            requestHash,
          ) => {
            const rows = await tx.$queryRaw<
              Array<{ result: LateStudentResult }>
            >`
              SELECT public.them_hoc_sinh_sau_chot(${sessionHash}::text,${bookId}::integer,
                ${studentId}::integer,${reason}::text,${key}::text,${requestHash}::text) AS result`;
            return rows[0]!.result;
          },
          publishReadiness: async (termId) => {
            const rows = await tx.$queryRaw<
              Array<{ result: PublishReadiness }>
            >`
              SELECT public.kiem_san_sang_cong_bo(${termId}::integer) AS result`;
            return rows[0]!.result;
          },
          updateGrades: async (sessionHash, bookId, version, changes) => {
            const rows = await tx.$queryRaw<Array<{ result: BatchResult }>>`
              SELECT public.cap_nhat_diem(${sessionHash}::text, ${bookId}::integer,
                ${version}::integer, ${JSON.stringify(changes)}::jsonb) AS result`;
            return rows[0]!.result;
          },
          syncRoster: async (sessionHash, bookId, version) => {
            const rows = await tx.$queryRaw<BookRow[]>`
              SELECT updated.*, l.ten_lop, m.ten_mon, h.ten AS ten_hoc_ky, (SELECT p.ma::text FROM public.phieu_dieu_chinh p WHERE p.ma_bang_diem = updated.ma_bang_diem AND p.trang_thai = 'CHO_DUYET') AS ma_phieu_cho
              FROM public.dong_bo_si_so(${sessionHash}::text,${bookId}::integer,${version}::integer) updated
              JOIN public.lop l ON l.ma_lop = updated.ma_lop
              JOIN public.mon_hoc m ON m.ma_mon = updated.ma_mon
              JOIN public.hoc_ky h ON h.ma_hoc_ky = updated.ma_hoc_ky`;
            return book(rows[0]!);
          },
          lockColumn: async (sessionHash, bookId, componentId, version) => {
            const rows = await tx.$queryRaw<
              BookRow[]
            >`SELECT c.*,l.ten_lop,m.ten_mon,h.ten AS ten_hoc_ky, (SELECT p.ma::text FROM public.phieu_dieu_chinh p WHERE p.ma_bang_diem = c.ma_bang_diem AND p.trang_thai = 'CHO_DUYET') AS ma_phieu_cho
            FROM public.chot_cot(${sessionHash}::text,${bookId}::integer,${componentId}::integer,${version}::integer) c
            JOIN public.lop l ON l.ma_lop=c.ma_lop JOIN public.mon_hoc m ON m.ma_mon=c.ma_mon JOIN public.hoc_ky h ON h.ma_hoc_ky=c.ma_hoc_ky`;
            return book(rows[0]!);
          },
          lockGradebook: async (sessionHash, bookId, expectedVersion) => {
            const rows = await tx.$queryRaw<BookRow[]>`
            SELECT locked.*, l.ten_lop, m.ten_mon, h.ten AS ten_hoc_ky, (SELECT p.ma::text FROM public.phieu_dieu_chinh p WHERE p.ma_bang_diem = locked.ma_bang_diem AND p.trang_thai = 'CHO_DUYET') AS ma_phieu_cho
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
