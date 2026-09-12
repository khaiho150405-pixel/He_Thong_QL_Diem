import { createHash } from "node:crypto";
import { BadRequestException, Inject, Injectable } from "@nestjs/common";
import type { Actor } from "../../authorization/application/policy.js";
import { REVIEW_STORE, type ReviewDecision, type ReviewStore } from "./port.js";

function int(value: unknown, zero = false): number {
  if (
    typeof value !== "number" ||
    !Number.isSafeInteger(value) ||
    value < (zero ? 0 : 1) ||
    value > 2_147_483_647
  )
    throw new BadRequestException();
  return value;
}

function bigint(value: unknown): string {
  if (
    typeof value !== "string" ||
    !/^[1-9][0-9]{0,18}$/.test(value) ||
    BigInt(value) > 9_223_372_036_854_775_807n
  )
    throw new BadRequestException();
  return value;
}

export function reviewDecisions(value: unknown): ReviewDecision[] {
  if (!Array.isArray(value) || value.length < 1 || value.length > 500)
    throw new BadRequestException();
  const seen = new Set<string>();
  return value.map((item) => {
    if (
      !item ||
      typeof item !== "object" ||
      Array.isArray(item) ||
      Object.keys(item).length !== 3 ||
      !Object.hasOwn(item, "rowId") ||
      !Object.hasOwn(item, "value") ||
      !Object.hasOwn(item, "reason")
    )
      throw new BadRequestException();
    const row = item as Record<string, unknown>;
    const rowId = bigint(row.rowId);
    if (seen.has(rowId)) throw new BadRequestException();
    seen.add(rowId);
    if (
      row.value !== null &&
      (typeof row.value !== "string" ||
        !/^(10[.]0|[0-9][.][0-9])$/.test(row.value))
    )
      throw new BadRequestException();
    if (
      typeof row.reason !== "string" ||
      !row.reason.trim() ||
      row.reason.length > 500
    )
      throw new BadRequestException();
    return {
      rowId,
      value: row.value as string | null,
      reason: row.reason.trim(),
    };
  });
}

@Injectable()
export class ReviewService {
  constructor(@Inject(REVIEW_STORE) private readonly store: ReviewStore) {}

  approve(
    actor: Actor,
    gradebookIdInput: unknown,
    ticketIdInput: unknown,
    idempotencyKey: unknown,
    bodyInput: unknown,
  ) {
    const gradebookId = int(gradebookIdInput);
    const ticketId = bigint(ticketIdInput);
    if (
      typeof idempotencyKey !== "string" ||
      !/^[a-zA-Z0-9_-]{1,64}$/.test(idempotencyKey)
    )
      throw new BadRequestException();
    if (
      !bodyInput ||
      typeof bodyInput !== "object" ||
      Array.isArray(bodyInput) ||
      Object.keys(bodyInput).length !== 3 ||
      !Object.hasOwn(bodyInput, "expectedTicketVersion") ||
      !Object.hasOwn(bodyInput, "expectedGradebookVersion") ||
      !Object.hasOwn(bodyInput, "decisions")
    )
      throw new BadRequestException();
    const body = bodyInput as Record<string, unknown>;
    const expectedTicketVersion = int(body.expectedTicketVersion, true);
    const expectedGradebookVersion = int(body.expectedGradebookVersion, true);
    const decisions = reviewDecisions(body.decisions);
    const requestHash = createHash("sha256")
      .update(
        JSON.stringify({
          gradebookId,
          ticketId,
          expectedTicketVersion,
          expectedGradebookVersion,
          decisions,
        }),
      )
      .digest("hex");
    return this.store.approve({
      sessionHash: actor.sessionHash,
      actorId: actor.id,
      gradebookId,
      ticketId,
      expectedTicketVersion,
      expectedGradebookVersion,
      idempotencyKey,
      requestHash,
      decisions,
    });
  }
}
