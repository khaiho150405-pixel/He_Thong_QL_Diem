import {
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import type { PrismaClient } from "../../../generated/prisma/client.js";
import { sqlStateOf, transaction } from "../../../common/transaction.js";
import type {
  YearClosingEvent,
  YearClosingIssue,
  YearClosingStore,
} from "../application/closing-port.js";

@Injectable()
export class PrismaYearClosingStore implements YearClosingStore {
  constructor(@Inject("DATABASE") private readonly db: PrismaClient) {}

  status(yearId: number) {
    return transaction(this.db, async (tx) => {
      const year = await tx.nam_hoc.findUnique({
        where: { ma_nam_hoc: yearId },
      });
      if (!year) throw new NotFoundException("Không tìm thấy năm học.");
      const [row] = await tx.$queryRaw<
        { result: { ready: boolean; issues: YearClosingIssue[] } }[]
      >`SELECT public.kiem_san_sang_dong_nam(${yearId}::integer) AS result`;
      const history = await tx.$queryRaw<YearClosingEvent[]>`
        SELECT h.hanh_dong AS action,h.ly_do AS reason,u.ten_dang_nhap AS actor,
          to_char(h.thoi_diem AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') AS at
        FROM public.lich_su_dong_nam h
        JOIN public.nguoi_dung u ON u.ma_nguoi_dung=h.nguoi_thuc_hien
        WHERE h.ma_nam_hoc=${yearId}::integer ORDER BY h.ma DESC LIMIT 20`;
      return {
        yearId,
        closedAt: year.da_dong_luc?.toISOString() ?? null,
        ready: row!.result.ready,
        issues: row!.result.issues,
        history,
      };
    });
  }

  async change(
    sessionHash: string,
    yearId: number,
    close: boolean,
    reason: string,
  ) {
    try {
      await transaction(
        this.db,
        (tx) => tx.$queryRaw`
          SELECT public.doi_trang_thai_nam_hoc(${sessionHash}::text,${yearId}::integer,${close}::boolean,${reason}::text)::text AS result`,
      );
    } catch (error) {
      const state = sqlStateOf(error);
      if (state === "P0002")
        throw new NotFoundException("Không tìm thấy năm học.");
      if (state === "42501") throw new ForbiddenException();
      throw error;
    }
  }
}
