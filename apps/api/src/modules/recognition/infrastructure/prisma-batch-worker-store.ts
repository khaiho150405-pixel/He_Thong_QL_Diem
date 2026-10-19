import type { PrismaClient } from "../../../generated/prisma/client.js";
import { transaction } from "../../../common/transaction.js";
import type { TemplateColumn } from "../../form-templates/public.js";
import type {
  BatchWorkerJob,
  RecognitionBatchWorkerStore,
} from "../application/batch-worker.js";
import type { RosterEntry } from "../domain/row-matching.js";
import type { LayoutSignature } from "./http-model.js";

export class PrismaRecognitionBatchWorkerStore
  implements RecognitionBatchWorkerStore
{
  constructor(private readonly db: PrismaClient) {}

  async load(batchId: string): Promise<BatchWorkerJob | null> {
    const batch = await this.db.lo_nhan_dien.findUnique({
      where: { ma_lo: BigInt(batchId) },
      include: {
        trang_rows: { orderBy: { so_trang: "asc" } },
        phieu_rows: { orderBy: { ma_phieu: "asc" } },
        ma_mau_ref: { include: { cot_rows: true } },
      },
    });
    if (!batch) return null;
    const columns: TemplateColumn[] = [...batch.ma_mau_ref.cot_rows]
      .sort((a, b) => a.chi_so_cot - b.chi_so_cot)
      .map((column) => ({
        index: column.chi_so_cot,
        role: column.vai_tro,
        group: column.loai_he_so as TemplateColumn["group"],
        order: column.thu_tu_trong_nhom,
        pairedWith: column.cot_diem_di_kem,
        headerText: column.nhan_tieu_de,
      }));
    return {
      status: batch.trang_thai,
      signature: batch.ma_mau_ref.chu_ky_luoi as unknown as LayoutSignature,
      columns,
      pages: batch.trang_rows.map((page) => ({
        page: page.so_trang,
        objectKey: page.duong_dan_anh,
      })),
      tickets: batch.phieu_rows.map((ticket) => ({
        ticketId: ticket.ma_phieu.toString(),
        status: ticket.trang_thai,
        templateColumnIndex: ticket.chi_so_cot_mau!,
      })),
    };
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
    batchId: string,
    modelVersion: string,
    tickets: Array<{ ticketId: string; rows: unknown[] }>,
  ): Promise<void> {
    // Một giao dịch SERIALIZABLE cho cả lô: mọi phiếu có kết quả hoặc không phiếu nào có.
    return transaction(this.db, async (tx) => {
      await tx.$queryRaw`
        SELECT public.luu_ket_qua_lo(
          ${BigInt(batchId)}::bigint,
          ${modelVersion}::text,
          ${JSON.stringify(tickets)}::jsonb
        ) IS NULL AS applied`;
    });
  }

  fail(batchId: string, code: string, page: number | null): Promise<void> {
    return transaction(this.db, async (tx) => {
      await tx.$queryRaw`
        SELECT public.danh_dau_lo_nhan_dien_loi(
          ${BigInt(batchId)}::bigint,
          ${code}::text,
          ${page}::integer
        ) IS NULL AS applied`;
    });
  }
}
