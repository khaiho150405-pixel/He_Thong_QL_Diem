import { ConflictException } from "@nestjs/common";
import type { PrismaClient, Prisma } from "../generated/prisma/client.js";
export function sqlStateOf(error: unknown): string | undefined {
  const e = error as {
    meta?: {
      code?: string;
      driverAdapterError?: { cause?: { originalCode?: string } };
    };
  };
  return e?.meta?.code ?? e?.meta?.driverAdapterError?.cause?.originalCode;
}
export async function transaction<T>(
  db: PrismaClient,
  work: (tx: Prisma.TransactionClient) => Promise<T>,
): Promise<T> {
  for (let attempt = 0; ; attempt++) {
    try {
      return await db.$transaction(work, {
        isolationLevel: "Serializable",
        timeout: 15000,
      });
    } catch (error) {
      const code = (error as { code?: string }).code;
      const sqlState = sqlStateOf(error);
      const retryable =
        code === "P2034" ||
        (code === "P2010" && ["40001", "40P01"].includes(sqlState ?? ""));
      if (retryable && attempt < 2) continue;
      if (retryable) throw new ConflictException();
      if (["P2002", "P2003", "P2025", "P2034"].includes(code ?? ""))
        throw new ConflictException();
      throw error;
    }
  }
}
