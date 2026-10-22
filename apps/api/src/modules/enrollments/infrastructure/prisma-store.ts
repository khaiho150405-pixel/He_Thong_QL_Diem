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
  AffectedGradebook,
  Enrollment,
  EnrollmentStore,
  EnrollmentUnit,
  PromotionPreviewData,
  PromotionResult,
} from "../application/port.js";

const TS = `'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'`;

async function selectEnrollments(
  tx: Prisma.TransactionClient,
  filter: Prisma.Sql,
): Promise<Enrollment[]> {
  return tx.$queryRaw<Enrollment[]>(Prisma.sql`
    SELECT g.ma::text AS id, g.ma_lop AS "classId", l.ten_lop AS "className", l.khoi AS grade,
      g.ma_nam_hoc AS "yearId", n.ten AS "yearName",
      to_char(g.tu_ngay, 'YYYY-MM-DD') AS "fromDate", to_char(g.den_ngay, 'YYYY-MM-DD') AS "toDate",
      g.trang_thai AS status, g.ly_do AS reason, coalesce(gv.ho_ten, u.ten_dang_nhap) AS "actorName",
      to_char(g.tao_luc AT TIME ZONE 'UTC', ${Prisma.raw(TS)}) AS "createdAt"
    FROM public.hoc_sinh_lop g
    JOIN public.lop l ON l.ma_lop = g.ma_lop
    JOIN public.nam_hoc n ON n.ma_nam_hoc = g.ma_nam_hoc
    LEFT JOIN public.nguoi_dung u ON u.ma_nguoi_dung = g.nguoi_thuc_hien
    LEFT JOIN public.giao_vien gv ON gv.ma_giao_vien = g.nguoi_thuc_hien
    WHERE ${filter}
    ORDER BY g.tu_ngay DESC, g.ma DESC`);
}

@Injectable()
export class PrismaEnrollmentStore implements EnrollmentStore {
  constructor(@Inject("DATABASE") private readonly db: PrismaClient) {}

  async run<T>(work: (tx: EnrollmentUnit) => Promise<T>): Promise<T> {
    try {
      return await transaction(this.db, (tx) =>
        work({
          authorization: unit(tx),
          preview: async (classId, targetYearId) => {
            const source = await tx.$queryRaw<
              Array<PromotionPreviewData["sourceClass"]>
            >`
              SELECT l.ma_lop AS id, l.ten_lop AS name, l.khoi AS grade, l.ma_nam_hoc AS "yearId", n.ten AS "yearName",
                to_char(n.ngay_ket_thuc, 'YYYY-MM-DD') AS "yearEnd"
              FROM public.lop l JOIN public.nam_hoc n ON n.ma_nam_hoc = l.ma_nam_hoc
              WHERE l.ma_lop = ${classId}::integer`;
            const target = await tx.$queryRaw<
              Array<PromotionPreviewData["targetYear"]>
            >`
              SELECT ma_nam_hoc AS id, ten AS name, to_char(ngay_bat_dau, 'YYYY-MM-DD') AS "startDate"
              FROM public.nam_hoc WHERE ma_nam_hoc = ${targetYearId}::integer`;
            if (!source[0] || !target[0]) return null;
            const targetClasses = await tx.$queryRaw<
              PromotionPreviewData["targetClasses"]
            >`
              SELECT ma_lop AS id, ten_lop AS name, khoi AS grade FROM public.lop
              WHERE ma_nam_hoc = ${targetYearId}::integer ORDER BY khoi, ten_lop`;
            const students = await tx.$queryRaw<
              PromotionPreviewData["students"]
            >`
              SELECT hs.ma_hoc_sinh AS id, hs.ho_ten AS name,
                EXISTS(SELECT 1 FROM public.hoc_sinh_lop t WHERE t.ma_hoc_sinh = hs.ma_hoc_sinh
                  AND t.ma_nam_hoc = ${targetYearId}::integer) AS "enrolledInTargetYear"
              FROM public.hoc_sinh_lop g JOIN public.hoc_sinh hs ON hs.ma_hoc_sinh = g.ma_hoc_sinh
              WHERE g.ma_lop = ${classId}::integer AND g.trang_thai = 'DANG_HOC'`;
            return {
              sourceClass: source[0],
              targetYear: target[0],
              targetClasses,
              students,
            };
          },
          promote: async (sessionHash, classId, targetYearId, items, call) => {
            const rows = await tx.$queryRaw<Array<{ result: PromotionResult }>>`
              SELECT public.xep_lop_nam_moi(${sessionHash}::text,${classId}::integer,${targetYearId}::integer,
                ${JSON.stringify(items)}::jsonb,${call.idempotencyKey}::text,${call.requestHash}::text) AS result`;
            return rows[0]!.result;
          },
          transfer: async (
            sessionHash,
            studentId,
            targetClassId,
            effectiveDate,
            reason,
            call,
          ) => {
            const rows = await tx.$queryRaw<
              Array<{
                result: {
                  enrollmentId: string;
                  affectedGradebooks: AffectedGradebook[];
                };
              }>
            >`
              SELECT public.chuyen_lop_hoc_sinh(${sessionHash}::text,${studentId}::integer,${targetClassId}::integer,
                ${effectiveDate}::date,${reason}::text,${call.idempotencyKey}::text,${call.requestHash}::text) AS result`;
            return rows[0]!.result;
          },
          withdraw: async (
            sessionHash,
            studentId,
            effectiveDate,
            reason,
            call,
          ) => {
            const rows = await tx.$queryRaw<
              Array<{ result: { enrollmentId: string } }>
            >`
              SELECT public.cho_nghi_hoc(${sessionHash}::text,${studentId}::integer,${effectiveDate}::date,
                ${reason}::text,${call.idempotencyKey}::text,${call.requestHash}::text) AS result`;
            return rows[0]!.result;
          },
          reenroll: async (
            sessionHash,
            studentId,
            classId,
            effectiveDate,
            reason,
            call,
          ) => {
            const rows = await tx.$queryRaw<
              Array<{ result: { enrollmentId: string } }>
            >`
              SELECT public.cho_hoc_lai(${sessionHash}::text,${studentId}::integer,${classId}::integer,
                ${effectiveDate}::date,${reason}::text,${call.idempotencyKey}::text,${call.requestHash}::text) AS result`;
            return rows[0]!.result;
          },
          enrollment: async (id) =>
            (
              await selectEnrollments(tx, Prisma.sql`g.ma = ${id}::bigint`)
            )[0] ?? null,
          enrollmentsOf: (studentId) =>
            selectEnrollments(
              tx,
              Prisma.sql`g.ma_hoc_sinh = ${studentId}::integer`,
            ),
          teacherMaySee: async (studentId, teacherId) => {
            const rows = await tx.$queryRaw<Array<{ ok: boolean }>>`
              SELECT EXISTS(
                SELECT 1 FROM public.hoc_sinh_lop g JOIN public.lop l ON l.ma_lop = g.ma_lop
                WHERE g.ma_hoc_sinh = ${studentId}::integer
                  AND (l.ma_gv_chu_nhiem = ${teacherId}::integer
                    OR EXISTS(SELECT 1 FROM public.phan_cong_giang_day pc
                      WHERE pc.ma_lop = g.ma_lop AND pc.ma_giao_vien = ${teacherId}::integer))) AS ok`;
            return rows[0]!.ok;
          },
        }),
      );
    } catch (error) {
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
