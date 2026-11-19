import { BadRequestException } from "@nestjs/common";

export const DEFAULT_PAGE_SIZE = 50;
export const MAX_PAGE_SIZE = 500;

export function pageSize(raw?: unknown): number {
  if (raw === undefined) return DEFAULT_PAGE_SIZE;
  if (
    typeof raw !== "string" ||
    !/^[1-9][0-9]{0,3}$/.test(raw) ||
    Number(raw) > MAX_PAGE_SIZE
  )
    throw new BadRequestException(
      `limit phải là số nguyên từ 1 đến ${MAX_PAGE_SIZE}.`,
    );
  return Number(raw);
}

export function allowQuery(
  query: Record<string, unknown>,
  allowed: readonly string[],
): void {
  if (Object.keys(query).some((key) => !allowed.includes(key)))
    throw new BadRequestException(
      `Chỉ hỗ trợ tham số truy vấn: ${allowed.join(", ")}.`,
    );
}
