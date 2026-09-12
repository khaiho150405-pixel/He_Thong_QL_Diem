import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import type { PrismaClient } from "../../../generated/prisma/client.js";
import { sqlStateOf, transaction } from "../../../common/transaction.js";
import type {
  ApproveRecognitionInput,
  ReviewApprovalResult,
  ReviewStore,
} from "../application/port.js";

@Injectable()
export class PrismaReviewStore implements ReviewStore {
  constructor(@Inject("DATABASE") private readonly db: PrismaClient) {}

  async approve(input: ApproveRecognitionInput) {
    try {
      return await transaction(this.db, async (tx) => {
        const rows = await tx.$queryRaw<
          Array<{ result: ReviewApprovalResult }>
        >`
          SELECT public.duyet_phieu_nhan_dien(
            ${input.sessionHash}::text,
            ${input.gradebookId}::integer,
            ${BigInt(input.ticketId)}::bigint,
            ${input.expectedTicketVersion}::integer,
            ${input.expectedGradebookVersion}::integer,
            ${JSON.stringify(input.decisions)}::jsonb,
            ${input.idempotencyKey}::text,
            ${input.requestHash}::text
          ) AS result`;
        return rows[0]!.result;
      });
    } catch (error) {
      const code = (error as { code?: string }).code;
      const sqlState = sqlStateOf(error);
      if (code === "P2010" && sqlState === "42501")
        throw new ForbiddenException();
      if (code === "P2010" && ["02000", "P0002"].includes(sqlState ?? ""))
        throw new NotFoundException();
      if (
        code === "P2010" &&
        ["23514", "23505", "40001", "40P01"].includes(sqlState ?? "")
      )
        throw new ConflictException();
      throw error;
    }
  }
}
