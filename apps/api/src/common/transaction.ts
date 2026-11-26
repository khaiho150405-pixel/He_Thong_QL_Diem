import { codedFailure } from "./coded-error.js";
import {
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from "@nestjs/common";
import { databaseMessage } from "./db-messages.js";
import type { PrismaClient, Prisma } from "../generated/prisma/client.js";
export function sqlStateOf(error: unknown): string | undefined {
  const e = error as {
    cause?: { originalCode?: string };
    meta?: {
      code?: string;
      driverAdapterError?: { cause?: { originalCode?: string } };
    };
  };
  return (
    e?.meta?.code ??
    e?.meta?.driverAdapterError?.cause?.originalCode ??
    e?.cause?.originalCode
  );
}
export interface TransactionOptions {
  isolationLevel?: "Serializable" | "ReadCommitted";
}

export const MAX_TRANSACTION_ATTEMPTS = 5;

export function retryDelayMs(
  retry: number,
  random: () => number = Math.random,
) {
  const low = 20 * 2 ** (retry - 1);
  return low + random() * low * 2;
}

export async function transaction<T>(
  db: PrismaClient,
  work: (tx: Prisma.TransactionClient) => Promise<T>,
  options: TransactionOptions = {},
): Promise<T> {
  for (let attempt = 0; ; attempt++) {
    try {
      return await db.$transaction(work, {
        isolationLevel: options.isolationLevel ?? "Serializable",
        timeout: 15000,
      });
    } catch (error) {
      const code = (error as { code?: string }).code;
      const sqlState = sqlStateOf(error);
      const retryable =
        code === "P2034" || ["40001", "40P01"].includes(sqlState ?? "");
      if (retryable && attempt < MAX_TRANSACTION_ATTEMPTS - 1) {
        await new Promise((resolve) =>
          setTimeout(resolve, retryDelayMs(attempt + 1)),
        );
        continue;
      }
      if (retryable)
        throw new ConflictException(
          "Dữ liệu vừa thay đổi; tải lại và thử lại.",
        );
      if (sqlState === "23514") {
        const coded = codedFailure(error);
        if (coded) throw coded;
        const diagnostic =
          String(error) +
          JSON.stringify((error as { meta?: unknown }).meta ?? {});
        throw new ConflictException(
          databaseMessage(diagnostic) ??
            "Dữ liệu vi phạm ràng buộc của hệ thống; tải lại dữ liệu rồi thử lại.",
        );
      }
      if (sqlState === "P0002" || sqlState === "42501") {
        const message = databaseMessage(
          String(error) +
            JSON.stringify((error as { meta?: unknown }).meta ?? {}),
        );
        if (message)
          throw sqlState === "P0002"
            ? new NotFoundException(message)
            : new ForbiddenException(message);
      }
      if (
        sqlState === "23505" &&
        (
          String(error) +
          JSON.stringify((error as { meta?: unknown }).meta ?? {})
        ).includes("DUPLICATE_FILE")
      )
        throw new ConflictException(
          "Ảnh này đã được tải lên ở một phiếu khác.",
        );
      if (["P2002", "P2003", "P2025", "P2034"].includes(code ?? ""))
        throw new ConflictException();
      throw error;
    }
  }
}
