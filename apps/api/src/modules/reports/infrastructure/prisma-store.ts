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
        adminOverview: async () => {
          // 1. KPI
          const totalStudents = await tx.hoc_sinh.count({
            where: { dang_theo_hoc: true },
          });
          const totalClasses = await tx.lop.count();
          const totalTeachers = await tx.giao_vien.count();
          const totalGradebooks = await tx.bang_diem.count();
          const lockedGradebooks = await tx.bang_diem.count({
            where: { trang_thai: "DA_CHOT" },
          });
          const completionRate =
            totalGradebooks > 0
              ? Math.round((lockedGradebooks / totalGradebooks) * 100)
              : 0;
          const pendingOcrTickets = await tx.phieu_nhan_dien.count({
            where: { trang_thai: "CHO_DOI_CHIEU" },
          });

          // 2. Grade Distribution
          const distRows = await tx.$queryRaw<
            { xep_loai: string; count: number }[]
          >`
            SELECT xep_loai, count(*)::integer AS count
            FROM public.ket_qua_tong_ket
            WHERE xep_loai IS NOT NULL
            GROUP BY xep_loai
          `;
          const totalDist = distRows.reduce(
            (sum, r) => sum + Number(r.count),
            0,
          );
          const labelsMap: Record<string, { label: string; color: string }> = {
            GIOI: { label: "Giỏi", color: "#173F43" },
            KHA: { label: "Khá", color: "#2D7D75" },
            DAT: { label: "Đạt", color: "#C69C3C" },
            CHUA_DAT: { label: "Chưa đạt", color: "#C87858" },
            YEU: { label: "Chưa đạt", color: "#C87858" },
          };
          const gradeDistribution = ["GIOI", "KHA", "DAT", "CHUA_DAT"].map(
            (code) => {
              const found = distRows.find(
                (r) =>
                  r.xep_loai.toUpperCase() === code ||
                  (code === "CHUA_DAT" && r.xep_loai.toUpperCase() === "YEU"),
              );
              const cnt = found ? Number(found.count) : 0;
              const pct =
                totalDist > 0 ? Math.round((cnt / totalDist) * 100) : 0;
              return {
                code,
                label: labelsMap[code]?.label || code,
                count: cnt,
                percentage: pct,
                color: labelsMap[code]?.color || "#2D7D75",
              };
            },
          );

          // 3. Grade Level Progress (Khối 10, 11, 12)
          const classes = await tx.lop.findMany({
            select: { ma_lop: true, khoi: true },
          });
          const gradeLevels = [10, 11, 12];
          const gradeLevelProgress = await Promise.all(
            gradeLevels.map(async (grade) => {
              const gradeClasses = classes.filter((c) => c.khoi === grade);
              const classIds = gradeClasses.map((c) => c.ma_lop);
              const totalGradeClasses = classIds.length;
              if (totalGradeClasses === 0) {
                return {
                  grade,
                  title: `Khối ${grade}`,
                  lockedClasses: 0,
                  totalClasses: 0,
                  percentage: 0,
                };
              }
              const lockedInGrade = await tx.bang_diem.groupBy({
                by: ["ma_lop"],
                where: { ma_lop: { in: classIds }, trang_thai: "DA_CHOT" },
              });
              const lockedCount = lockedInGrade.length;
              const pct = Math.round((lockedCount / totalGradeClasses) * 100);
              return {
                grade,
                title: `Khối ${grade}`,
                lockedClasses: lockedCount,
                totalClasses: totalGradeClasses,
                percentage: pct,
              };
            }),
          );

          // 4. OCR Accuracy (ket_qua_dong)
          const ocrRows = await tx.$queryRaw<
            { muc_phan_loai: string; count: number }[]
          >`
            SELECT muc_phan_loai, count(*)::integer AS count
            FROM public.ket_qua_dong
            GROUP BY muc_phan_loai
          `;
          let greenCount = 0;
          let yellowCount = 0;
          let redCount = 0;
          for (const r of ocrRows) {
            if (r.muc_phan_loai === "XANH") greenCount = Number(r.count);
            else if (r.muc_phan_loai === "VANG") yellowCount = Number(r.count);
            else if (r.muc_phan_loai === "DO") redCount = Number(r.count);
          }
          const totalCells = greenCount + yellowCount + redCount;
          const accuracyRate =
            totalCells > 0 ? Math.round((greenCount / totalCells) * 100) : 0;

          // 5. Recent Activities
          const recentBooks = await tx.$queryRaw<
            {
              ten_lop: string;
              ten_mon: string;
              ho_ten: string;
              trang_thai: string;
            }[]
          >`
            SELECT l.ten_lop, m.ten_mon, coalesce(gv.ho_ten, 'Chưa gán') AS ho_ten, b.trang_thai
            FROM public.bang_diem b
            JOIN public.lop l ON l.ma_lop = b.ma_lop
            JOIN public.mon_hoc m ON m.ma_mon = b.ma_mon
            LEFT JOIN public.phan_cong_giang_day pc ON pc.ma_lop = b.ma_lop AND pc.ma_mon = b.ma_mon AND pc.ma_hoc_ky = b.ma_hoc_ky
            LEFT JOIN public.giao_vien gv ON gv.ma_giao_vien = pc.ma_giao_vien
            ORDER BY b.ma_bang_diem DESC
            LIMIT 4
          `;
          const recentActivities = recentBooks.map((b) => ({
            className: b.ten_lop,
            subjectName: b.ten_mon,
            teacherName: b.ho_ten,
            status: b.trang_thai === "DA_CHOT" ? "Đã chốt" : "Đang nhập",
            updatedAt: new Date().toISOString(),
          }));

          return {
            kpi: {
              totalStudents,
              totalClasses,
              totalTeachers,
              lockedGradebooks,
              totalGradebooks,
              completionRate,
              pendingOcrTickets,
            },
            gradeDistribution,
            gradeLevelProgress,
            ocrAccuracy: {
              totalCells,
              greenCount,
              yellowCount,
              redCount,
              accuracyRate,
            },
            recentActivities,
          };
        },
      }),
    );
  }
}
