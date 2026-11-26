import {
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import type { PrismaClient } from "../../../generated/prisma/client.js";
import { unit } from "../../../common/store.js";
import { sqlStateOf, transaction } from "../../../common/transaction.js";
import type {
  YearComparisonItem,
  YearReportStore,
  YearReportUnit,
  YearStatistics,
  YearStudentRow,
  YearSubjectRow,
} from "../application/year-port.js";

@Injectable()
export class PrismaYearReportStore implements YearReportStore {
  constructor(@Inject("DATABASE") private readonly db: PrismaClient) {}

  async run<T>(work: (unit: YearReportUnit) => Promise<T>): Promise<T> {
    try {
      return await transaction(this.db, (tx) =>
        work({
          authorization: unit(tx),
          statistics: async (yearId, term) =>
            (
              await tx.$queryRaw<{ result: YearStatistics }[]>`
                SELECT public.thong_ke_nam_hoc(${yearId}::integer,${term}::integer) AS result`
            )[0]!.result,
          comparison: async (term) =>
            (
              await tx.$queryRaw<{ result: YearComparisonItem[] }[]>`
                SELECT public.so_sanh_nam_hoc(${term}::integer) AS result`
            )[0]!.result,
          students: (yearId, term) => tx.$queryRaw<YearStudentRow[]>`
            SELECT s.ma_hoc_ky AS "termId",s.ten_hoc_ky AS "termName",s.ma_hoc_sinh AS "studentId",
              s.ho_ten AS "studentName",s.ngay_sinh::text AS "birthDate",s.ma_lop AS "classId",
              s.ten_lop AS "className",s.khoi::integer AS grade,s.gv_chu_nhiem AS "homeroomTeacher",
              s.muc_hoc_tap AS level
            FROM public.nguon_hoc_sinh_nam(${yearId}::integer) s
            WHERE s.thu_tu=${term}::integer ORDER BY s.khoi,s.ten_lop,s.ma_hoc_sinh`,
          subjects: (yearId, term) => tx.$queryRaw<YearSubjectRow[]>`
            SELECT m.ma_hoc_ky AS "termId",m.ma_hoc_sinh AS "studentId",m.ma_mon AS "subjectId",
              m.ten_mon AS "subjectName",m.danh_gia_dat AS "passFail",m.giao_vien AS teacher,
              m.diem_tong_ket::numeric(3,1)::text AS "finalScore",m.xep_loai AS classification,
              m.thanh_phan AS components
            FROM public.nguon_mon_nam(${yearId}::integer) m
            JOIN public.nguon_hoc_sinh_nam(${yearId}::integer) s USING(ma_hoc_ky,ma_hoc_sinh)
            WHERE s.thu_tu=${term}::integer`,
          recordExport: async (actorId, yearId) => {
            const recent = await tx.nhat_ky_bao_mat.count({
              where: {
                ma_tac_nhan: actorId,
                hanh_dong: "YEAR_RECORD_EXPORTED",
                thoi_diem: { gt: new Date(Date.now() - 60_000) },
              },
            });
            if (recent >= 5)
              throw new HttpException(
                "Bạn xuất quá nhiều lần. Vui lòng chờ một phút.",
                HttpStatus.TOO_MANY_REQUESTS,
              );
            await tx.nhat_ky_bao_mat.create({
              data: {
                ma_tac_nhan: actorId,
                hanh_dong: "YEAR_RECORD_EXPORTED",
                doi_tuong: `nam_hoc:${yearId}`,
              },
            });
          },
        }),
      );
    } catch (error) {
      if (sqlStateOf(error) === "P0002")
        throw new NotFoundException("Không tìm thấy năm học.");
      throw error;
    }
  }
}
