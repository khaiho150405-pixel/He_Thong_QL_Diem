import { ConflictException } from "@nestjs/common";
import type { PrismaClient, Prisma } from "../generated/prisma/client.js";
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
      if (code === "P2034" && attempt < 2) continue;
      if (["P2002", "P2003", "P2025", "P2034"].includes(code ?? ""))
        throw new ConflictException();
      throw error;
    }
  }
}
