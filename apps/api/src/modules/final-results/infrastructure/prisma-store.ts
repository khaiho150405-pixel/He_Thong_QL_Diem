import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import type { PrismaClient } from "../../../generated/prisma/client.js";
import { unit } from "../../../common/store.js";
import { sqlStateOf, transaction } from "../../../common/transaction.js";
import type {
  CalculationHistory,
  CalculationResult,
  ClassificationPolicy,
  FinalResult,
  FinalResultBook,
  FinalResultStore,
  FinalResultUnit,
  StudentSubjectResult,
} from "../application/port.js";

interface BookRow {
  ma_bang_diem: number;
  ma_lop: number;
  ma_mon: number;
  ma_hoc_ky: number;
  trang_thai: FinalResultBook["status"];
  version: number;
}

function mapBook(row: BookRow): FinalResultBook {
  return {
    id: row.ma_bang_diem,
    classId: row.ma_lop,
    subjectId: row.ma_mon,
    termId: row.ma_hoc_ky,
    status: row.trang_thai,
    version: row.version,
  };
}

@Injectable()
export class PrismaFinalResultStore implements FinalResultStore {
  constructor(@Inject("DATABASE") private readonly db: PrismaClient) {}

  async run<T>(work: (unit: FinalResultUnit) => Promise<T>): Promise<T> {
    try {
      return await transaction(this.db, (tx) =>
        work({
          authorization: unit(tx),
          findBook: async (id) => {
            const rows = await tx.$queryRaw<BookRow[]>`
              SELECT * FROM public.bang_diem WHERE ma_bang_diem=${id}::integer`;
            return rows[0] ? mapBook(rows[0]) : null;
          },
          calculate: async (input) => {
            const rows = await tx.$queryRaw<
              Array<{ result: CalculationResult }>
            >`
              SELECT public.tinh_ket_qua_bang_diem(
                ${input.sessionHash}::text,${input.gradebookId}::integer,
                ${input.expectedVersion}::integer,${input.reason}::text,
                ${input.idempotencyKey}::text,${input.requestHash}::text
              ) AS result`;
            return rows[0]!.result;
          },
          list: (gradebookId, after) => tx.$queryRaw<FinalResult[]>`
            SELECT k.ma_ket_qua::text AS id,hs.ma_hoc_sinh AS "studentId",hs.ho_ten AS "studentName",
              k.diem_tong_ket::text AS "finalScore",k.xep_loai AS classification,
              k.phien_ban_he_so AS "weightVersion",
              k.bo_he_so->'classificationPolicy'->>'version' AS "policyVersion",
              to_char(k.ngay_tinh AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') AS "calculatedAt"
            FROM public.ket_qua_tong_ket k
            JOIN public.hoc_sinh hs USING(ma_hoc_sinh)
            JOIN public.bang_diem b ON b.ma_bang_diem=${gradebookId}::integer
              AND b.ma_lop=hs.ma_lop AND b.ma_mon=k.ma_mon AND b.ma_hoc_ky=k.ma_hoc_ky
            WHERE k.ma_ket_qua>${BigInt(after)}::bigint
            ORDER BY k.ma_ket_qua LIMIT 51`,
          history: (gradebookId, resultId, after) =>
            tx.$queryRaw<CalculationHistory[]>`
              SELECT h.ma_lich_su::text AS id,h.ma_ket_qua::text AS "resultId",
                h.nguoi_tinh AS "calculatorId",h.diem_cu::text AS "oldScore",
                h.xep_loai_cu AS "oldClassification",h.diem_moi::text AS "newScore",
                h.xep_loai_moi AS "newClassification",h.ly_do AS reason,
                to_char(h.thoi_diem AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') AS "calculatedAt"
              FROM public.lich_su_tong_ket h
              JOIN public.ket_qua_tong_ket k USING(ma_ket_qua)
              JOIN public.hoc_sinh hs USING(ma_hoc_sinh)
              JOIN public.bang_diem b ON b.ma_bang_diem=${gradebookId}::integer
                AND b.ma_lop=hs.ma_lop AND b.ma_mon=k.ma_mon AND b.ma_hoc_ky=k.ma_hoc_ky
              WHERE h.ma_ket_qua=${BigInt(resultId)}::bigint
                AND h.ma_lich_su>${BigInt(after)}::bigint
              ORDER BY h.ma_lich_su LIMIT 51`,
          activePolicy: async () => {
            const rows = await tx.$queryRaw<
              Array<{ policy: ClassificationPolicy }>
            >`
              SELECT jsonb_build_object('version',p.phien_ban,'name',p.ten,
                'roundingDigits',p.so_chu_so_lam_tron,'active',p.dang_ap_dung,
                'criteria',jsonb_agg(jsonb_build_object('code',c.ma_xep_loai,
                  'minimum',c.diem_toi_thieu::text,'passing',c.dat,'order',c.thu_tu)
                  ORDER BY c.diem_toi_thieu DESC)) AS policy
              FROM public.chinh_sach_xep_loai p
              JOIN public.tieu_chi_xep_loai c USING(ma_chinh_sach)
              WHERE p.dang_ap_dung GROUP BY p.ma_chinh_sach`;
            return rows[0]?.policy ?? null;
          },
          activatePolicy: async (input) => {
            const rows = await tx.$queryRaw<
              Array<{ policy: ClassificationPolicy }>
            >`
              SELECT public.kich_hoat_chinh_sach_xep_loai(
                ${input.sessionHash}::text,${input.version}::text,${input.name}::text,
                ${input.roundingDigits}::smallint,${JSON.stringify(input.criteria)}::jsonb,
                ${input.idempotencyKey}::text,${input.requestHash}::text
              ) AS policy`;
            return rows[0]!.policy;
          },
          studentResults: (userId, termId) =>
            tx.$queryRaw<StudentSubjectResult[]>`
              SELECT b.ma_bang_diem AS "gradebookId",m.ma_mon AS "subjectId",
                m.ten_mon AS "subjectName",h.ma_hoc_ky AS "termId",h.ten AS "termName",
                jsonb_agg(jsonb_build_object('componentId',tp.ma_thanh_phan,
                  'componentName',tp.ten_thanh_phan,'coefficient',tp.he_so::text,
                  'value',d.gia_tri::text) ORDER BY tp.thu_tu_hien_thi) AS components,
                k.diem_tong_ket::text AS "finalScore",k.xep_loai AS classification,
                CASE WHEN k.ngay_tinh IS NULL THEN NULL ELSE
                  to_char(k.ngay_tinh AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') END AS "calculatedAt"
              FROM public.hoc_sinh hs JOIN public.bang_diem b ON b.ma_lop=hs.ma_lop
              JOIN public.mon_hoc m ON m.ma_mon=b.ma_mon JOIN public.hoc_ky h ON h.ma_hoc_ky=b.ma_hoc_ky
              JOIN public.diem_thanh_phan d ON d.ma_bang_diem=b.ma_bang_diem
                AND d.ma_hoc_sinh=hs.ma_hoc_sinh AND d.trang_thai='DA_DUYET' AND d.gia_tri IS NOT NULL
              JOIN public.thanh_phan_diem tp ON tp.ma_thanh_phan=d.ma_thanh_phan AND tp.ma_mon=b.ma_mon
              LEFT JOIN public.ket_qua_tong_ket k ON k.ma_hoc_sinh=hs.ma_hoc_sinh
                AND k.ma_mon=b.ma_mon AND k.ma_hoc_ky=b.ma_hoc_ky
              WHERE hs.ma_nguoi_dung=${userId}::integer
                AND (${termId}::integer IS NULL OR b.ma_hoc_ky=${termId}::integer)
              GROUP BY b.ma_bang_diem,m.ma_mon,m.ten_mon,h.ma_hoc_ky,h.ten,
                k.diem_tong_ket,k.xep_loai,k.ngay_tinh
              ORDER BY h.ma_hoc_ky DESC,m.ten_mon`,
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
