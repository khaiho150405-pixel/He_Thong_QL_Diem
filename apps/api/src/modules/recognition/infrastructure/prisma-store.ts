import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import type { PrismaClient, Prisma } from "../../../generated/prisma/client.js";
import { unit } from "../../../common/store.js";
import { sqlStateOf, transaction } from "../../../common/transaction.js";
import { gradebookAccess } from "../../authorization/application/gradebook-policy.js";
import { currentActor } from "../../authorization/application/policy.js";
import type {
  CreateRecognitionTicket,
  RecognitionEvidenceRow,
  RecognitionStore,
  StoredRecognitionReceipt,
} from "../application/port.js";

@Injectable()
export class PrismaRecognitionStore implements RecognitionStore {
  constructor(@Inject("DATABASE") private readonly db: PrismaClient) {}

  private async authorizeRead(
    tx: Prisma.TransactionClient,
    actor: CreateRecognitionTicket["actor"],
    gradebookId: number,
  ) {
    const authorization = unit(tx);
    await currentActor(authorization, actor);
    const row = await tx.bang_diem.findUnique({
      where: { ma_bang_diem: gradebookId },
    });
    if (!row) throw new NotFoundException();
    await gradebookAccess(authorization, actor, {
      classId: row.ma_lop,
      subjectId: row.ma_mon,
      termId: row.ma_hoc_ky,
    });
    return row;
  }

  list(actor: CreateRecognitionTicket["actor"], gradebookId: number) {
    return transaction(this.db, async (tx) => {
      await this.authorizeRead(tx, actor, gradebookId);
      const rows = await tx.phieu_nhan_dien.findMany({
        where: { ma_bang_diem: gradebookId },
        include: { ma_thanh_phan_ref: { select: { ten_thanh_phan: true } } },
        orderBy: { ma_phieu: "desc" },
        take: 20,
      });
      return rows.map((row) => ({
        ticketId: row.ma_phieu.toString(),
        gradebookId: row.ma_bang_diem,
        componentId: row.ma_thanh_phan,
        componentName: row.ma_thanh_phan_ref.ten_thanh_phan,
        declaredRows: row.so_dong_khai_bao,
        detectedRows: row.so_dong_nhan_dien,
        status: row.trang_thai,
        errorCode: row.ma_loi,
        modelVersion: row.phien_ban_mo_hinh,
        version: row.version,
        createdAt: row.ngay_tao.toISOString(),
      }));
    });
  }

  detail(
    actor: CreateRecognitionTicket["actor"],
    gradebookId: number,
    ticketId: string,
  ) {
    return transaction(this.db, async (tx) => {
      await this.authorizeRead(tx, actor, gradebookId);
      const row = await tx.phieu_nhan_dien.findFirst({
        where: { ma_phieu: BigInt(ticketId), ma_bang_diem: gradebookId },
        include: {
          ma_thanh_phan_ref: { select: { ten_thanh_phan: true } },
          ket_qua_dong_rows: {
            include: { ma_hoc_sinh_ref: { select: { ho_ten: true } } },
            orderBy: { thu_tu_dong: "asc" },
          },
        },
      });
      if (!row) return null;
      const evidence: RecognitionEvidenceRow[] = row.ket_qua_dong_rows.map(
        (item) => ({
          rowId: item.ma_dong.toString(),
          order: item.thu_tu_dong,
          studentId: item.ma_hoc_sinh,
          studentName: item.ma_hoc_sinh_ref.ho_ten,
          numericRaw: item.raw_kenh_a,
          numericValue: item.gia_tri_kenh_a?.toFixed(1) ?? null,
          numericConfidence: item.do_tin_cay_a?.toFixed(4) ?? null,
          writtenRaw: item.raw_kenh_b,
          writtenValue: item.gia_tri_kenh_b?.toFixed(1) ?? null,
          writtenConfidence: item.do_tin_cay_b?.toFixed(4) ?? null,
          comparison: item.ket_luan_doi_chieu,
          reviewLevel: item.muc_phan_loai,
          finalValue: item.gia_tri_chot?.toFixed(1) ?? null,
          numericCropKey: item.duong_dan_anh_o_so,
          writtenCropKey: item.duong_dan_anh_o_chu,
        }),
      );
      return {
        ticketId: row.ma_phieu.toString(),
        gradebookId: row.ma_bang_diem,
        componentId: row.ma_thanh_phan,
        componentName: row.ma_thanh_phan_ref.ten_thanh_phan,
        declaredRows: row.so_dong_khai_bao,
        detectedRows: row.so_dong_nhan_dien,
        status: row.trang_thai,
        errorCode: row.ma_loi,
        modelVersion: row.phien_ban_mo_hinh,
        version: row.version,
        createdAt: row.ngay_tao.toISOString(),
        sourceObjectKey: row.duong_dan_anh_goc,
        rows: evidence,
      };
    });
  }

  authorizeUpload(
    actor: CreateRecognitionTicket["actor"],
    gradebookId: number,
    componentId: number,
  ): Promise<void> {
    return transaction(this.db, async (tx) => {
      const authorization = unit(tx);
      await currentActor(authorization, actor);
      const row = await tx.bang_diem.findUnique({
        where: { ma_bang_diem: gradebookId },
      });
      if (!row) throw new NotFoundException();
      await gradebookAccess(
        authorization,
        actor,
        {
          classId: row.ma_lop,
          subjectId: row.ma_mon,
          termId: row.ma_hoc_ky,
        },
        true,
      );
      if (row.trang_thai !== "DANG_NHAP_LIEU") throw new ConflictException();
      const component = await tx.thanh_phan_diem.findFirst({
        where: { ma_thanh_phan: componentId, ma_mon: row.ma_mon },
        select: { ma_thanh_phan: true },
      });
      if (!component) throw new NotFoundException();
    });
  }

  async createTicket(
    input: CreateRecognitionTicket,
  ): Promise<StoredRecognitionReceipt> {
    try {
      return await transaction(this.db, async (tx) => {
        const rows = await tx.$queryRaw<
          Array<{ result: StoredRecognitionReceipt }>
        >`
          SELECT public.tao_phieu_nhan_dien(
            ${input.actor.sessionHash}::text,
            ${input.gradebookId}::integer,
            ${input.componentId}::integer,
            ${input.checksum}::text,
            ${input.objectKey}::text,
            ${input.declaredRows}::integer,
            ${input.idempotencyKey}::text,
            ${input.requestHash}::text
          ) AS result`;
        return rows[0]!.result;
      });
    } catch (error) {
      const code = (error as { code?: string }).code;
      const state = sqlStateOf(error);
      if (code === "P2010" && state === "42501") throw new ForbiddenException();
      if (code === "P2010" && ["02000", "P0002"].includes(state ?? ""))
        throw new NotFoundException();
      if (code === "P2010" && ["23505", "23514", "40001"].includes(state ?? ""))
        throw new ConflictException();
      throw error;
    }
  }
}
