import type { PrismaClient } from "../../../generated/prisma/client.js";
import { transaction } from "../../../common/transaction.js";
import type { RecognitionWorkerStore } from "../application/worker.js";

export class PrismaRecognitionWorkerStore implements RecognitionWorkerStore {
  constructor(private readonly db: PrismaClient) {}

  async load(ticketId: string) {
    const ticket = await this.db.phieu_nhan_dien.findUnique({
      where: { ma_phieu: BigInt(ticketId) },
      select: {
        trang_thai: true,
        duong_dan_anh_goc: true,
        so_dong_khai_bao: true,
      },
    });
    return ticket
      ? {
          status: ticket.trang_thai,
          objectKey: ticket.duong_dan_anh_goc,
          declaredRows: ticket.so_dong_khai_bao,
        }
      : null;
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
