import {
  ForbiddenException,
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
} from "@nestjs/common";
import type { PrismaClient } from "../../../generated/prisma/client.js";
import { unit } from "../../../common/store.js";
import { transaction } from "../../../common/transaction.js";
import type {
  ExportRow,
  GradebookSummary,
  ReportBook,
  ReportStore,
  ReportUnit,
} from "../application/port.js";

interface BookRow {
  ma_bang_diem: number;
  ma_lop: number;
  ma_mon: number;
  ma_hoc_ky: number;
  trang_thai: ReportBook["status"];
  version: number;
  ten_lop: string;
  ten_mon: string;
  ten_hoc_ky: string;
}

@Injectable()
export class PrismaReportStore implements ReportStore {
  constructor(@Inject("DATABASE") private readonly db: PrismaClient) {}

  run<T>(work: (unit: ReportUnit) => Promise<T>): Promise<T> {
    return transaction(this.db, (tx) =>
      work({
        authorization: unit(tx),
        findBook: async (id) => {
          const rows = await tx.$queryRaw<BookRow[]>`
            SELECT b.*,l.ten_lop,m.ten_mon,h.ten AS ten_hoc_ky
            FROM public.bang_diem b JOIN public.lop l USING(ma_lop)
            JOIN public.mon_hoc m USING(ma_mon) JOIN public.hoc_ky h USING(ma_hoc_ky)
            WHERE b.ma_bang_diem=${id}::integer`;
          const row = rows[0];
          return row
            ? {
                id: row.ma_bang_diem,
                classId: row.ma_lop,
                subjectId: row.ma_mon,
                termId: row.ma_hoc_ky,
                status: row.trang_thai,
                version: row.version,
                className: row.ten_lop,
                subjectName: row.ten_mon,
                termName: row.ten_hoc_ky,
              }
            : null;
        },
        summary: async (gradebookId) => {
          const rows = await tx.$queryRaw<GradebookSummary[]>`
            WITH scoped AS (
              SELECT k.*,
                coalesce((SELECT c.dat FROM public.chinh_sach_xep_loai p
                  JOIN public.tieu_chi_xep_loai c USING(ma_chinh_sach)
                  WHERE p.phien_ban=k.bo_he_so->'classificationPolicy'->>'version'
                    AND c.ma_xep_loai=k.xep_loai LIMIT 1),false) AS dat
              FROM public.ket_qua_tong_ket k JOIN public.hoc_sinh hs USING(ma_hoc_sinh)
              JOIN public.bang_diem b ON b.ma_bang_diem=${gradebookId}::integer
                AND b.ma_lop=hs.ma_lop AND b.ma_mon=k.ma_mon AND b.ma_hoc_ky=k.ma_hoc_ky
            ), dist AS (
              SELECT xep_loai,count(*)::integer AS students FROM scoped GROUP BY xep_loai
            )
            SELECT ${gradebookId}::integer AS "gradebookId",count(*)::integer AS students,
              round(avg(diem_tong_ket),1)::text AS average,max(diem_tong_ket)::text AS highest,
              min(diem_tong_ket)::text AS lowest,count(*) FILTER(WHERE dat)::integer AS passed,
              count(*) FILTER(WHERE NOT dat)::integer AS failed,
              coalesce((SELECT jsonb_agg(jsonb_build_object('classification',xep_loai,
                'students',students) ORDER BY xep_loai) FROM dist),'[]'::jsonb) AS distribution
            FROM scoped`;
          return rows[0]!;
        },
        exportRows: (gradebookId) => tx.$queryRaw<ExportRow[]>`
          SELECT hs.ma_hoc_sinh AS "studentId",hs.ho_ten AS "studentName",
            coalesce(jsonb_agg(jsonb_build_object('name',tp.ten_thanh_phan,
              'coefficient',tp.he_so::text,'value',CASE WHEN d.trang_thai='DA_DUYET'
              THEN d.gia_tri::text ELSE NULL END) ORDER BY tp.thu_tu_hien_thi)
              FILTER(WHERE tp.ma_thanh_phan IS NOT NULL),'[]'::jsonb) AS components,
            k.diem_tong_ket::text AS "finalScore",k.xep_loai AS classification
          FROM public.bang_diem b JOIN public.hoc_sinh hs ON hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc
          LEFT JOIN public.thanh_phan_diem tp ON tp.ma_mon=b.ma_mon
          LEFT JOIN public.diem_thanh_phan d ON d.ma_bang_diem=b.ma_bang_diem
            AND d.ma_hoc_sinh=hs.ma_hoc_sinh AND d.ma_thanh_phan=tp.ma_thanh_phan
          LEFT JOIN public.ket_qua_tong_ket k ON k.ma_hoc_sinh=hs.ma_hoc_sinh
            AND k.ma_mon=b.ma_mon AND k.ma_hoc_ky=b.ma_hoc_ky
          WHERE b.ma_bang_diem=${gradebookId}::integer
          GROUP BY hs.ma_hoc_sinh,hs.ho_ten,k.diem_tong_ket,k.xep_loai ORDER BY hs.ma_hoc_sinh`,
        recordExport: async (actorId, gradebookId) => {
          const count = await tx.nhat_ky_bao_mat.count({
            where: {
              ma_tac_nhan: actorId,
              hanh_dong: "GRADEBOOK_EXPORTED",
              thoi_diem: { gt: new Date(Date.now() - 60_000) },
            },
          });
          if (count >= 5)
            throw new HttpException(
              "Too many exports",
              HttpStatus.TOO_MANY_REQUESTS,
            );
          try {
            await tx.nhat_ky_bao_mat.create({
              data: {
                ma_tac_nhan: actorId,
                hanh_dong: "GRADEBOOK_EXPORTED",
                doi_tuong: `bang_diem:${gradebookId}`,
              },
            });
          } catch {
            throw new ForbiddenException();
          }
        },
      }),
    );
  }
}
