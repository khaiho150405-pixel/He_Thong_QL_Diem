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
import { gradebookAccess } from "../../authorization/application/gradebook-policy.js";
import { currentActor } from "../../authorization/application/policy.js";
import type {
  CreateRecognitionTicket,
  RecognitionStore,
  StoredRecognitionReceipt,
} from "../application/port.js";

@Injectable()
export class PrismaRecognitionStore implements RecognitionStore {
  constructor(@Inject("DATABASE") private readonly db: PrismaClient) {}

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
