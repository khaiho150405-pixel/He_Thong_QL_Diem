import {
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import type { PrismaClient } from "../../../generated/prisma/client.js";
import { sqlStateOf, transaction } from "../../../common/transaction.js";
import type { StudentRemovalStore } from "../application/port.js";

@Injectable()
export class PrismaStudentRemovalStore implements StudentRemovalStore {
  constructor(@Inject("DATABASE") private readonly db: PrismaClient) {}

  async remove(sessionHash: string, studentId: number, reason: string) {
    try {
      const rows = await transaction(
        this.db,
        (tx) => tx.$queryRaw<{ mode: "DELETED" | "ANONYMIZED" }[]>`
          SELECT public.xoa_hoc_sinh(${sessionHash}::text,${studentId}::integer,${reason}::text) ->> 'mode' AS mode`,
      );
      return rows[0]!.mode;
    } catch (error) {
      const state = sqlStateOf(error);
      if (state === "P0002") throw new NotFoundException();
      if (state === "42501") throw new ForbiddenException();
      throw error;
    }
  }
}
