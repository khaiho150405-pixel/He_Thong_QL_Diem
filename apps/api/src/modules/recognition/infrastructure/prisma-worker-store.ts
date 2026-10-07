import type { PrismaClient } from "../../../generated/prisma/client.js";
import { transaction } from "../../../common/transaction.js";
import type { RecognitionWorkerStore } from "../application/worker.js";
import type { RosterEntry } from "../domain/row-matching.js";

export class PrismaRecognitionWorkerStore implements RecognitionWorkerStore {
  constructor(private readonly db: PrismaClient) {}

  async load(ticketId: string) {
    const ticket = await this.db.phieu_nhan_dien.findUnique({
      where: { ma_phieu: BigInt(ticketId) },
      select: {
        trang_thai: true,
        duong_dan_anh_goc: true,
      },
    });
    return ticket
      ? {
          status: ticket.trang_thai,
          objectKey: ticket.duong_dan_anh_goc,
        }
      : null;
  }

  async roster(ticketId: string): Promise<RosterEntry[]> {
    const rows = await this.db.danh_sach_phieu.findMany({
      where: { ma_phieu: BigInt(ticketId) },
      orderBy: { stt: "asc" },
    });
    return rows.map((row) => ({
      stt: row.stt,
      studentId: row.ma_hoc_sinh,
      fullName: row.ho_ten,
    }));
  }

  complete(
    ticketId: string,
    modelVersion: string,
    rows: unknown[],
  ): Promise<void> {
    return transaction(this.db, async (tx) => {
      await tx.$queryRaw`
        SELECT public.luu_ket_qua_nhan_dien(
          ${BigInt(ticketId)}::bigint,
          ${modelVersion}::text,
          ${JSON.stringify(rows)}::jsonb
        ) IS NULL AS applied`;
    });
  }

  fail(ticketId: string, code: string): Promise<void> {
    return transaction(this.db, async (tx) => {
      await tx.$queryRaw`
        SELECT public.danh_dau_phieu_nhan_dien_loi(
          ${BigInt(ticketId)}::bigint,
          ${code}::text
        ) IS NULL AS applied`;
    });
  }
}
