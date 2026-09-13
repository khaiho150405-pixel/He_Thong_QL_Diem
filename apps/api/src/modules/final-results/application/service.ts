import { createHash } from "node:crypto";
import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import {
  currentActor,
  type Actor,
} from "../../authorization/application/policy.js";
import {
  gradebookAccess,
  gradebookActor,
} from "../../authorization/application/gradebook-policy.js";
import {
  FINAL_RESULT_STORE,
  type CalculationResult,
  type ClassificationCriterion,
  type FinalResultStore,
} from "./port.js";

function positiveId(value: number) {
  if (!Number.isSafeInteger(value) || value < 1 || value > 2147483647)
    throw new BadRequestException();
  return value;
}

function bigintCursor(value: string, allowZero = true) {
  if (
    typeof value !== "string" ||
    !/^(0|[1-9][0-9]{0,18})$/.test(value) ||
    BigInt(value) > 9223372036854775807n ||
    (!allowZero && value === "0")
  )
    throw new BadRequestException();
  return value;
}

function page<T extends { id: string }>(rows: T[]) {
  return {
    items: rows.slice(0, 50),
    nextCursor: rows.length > 50 ? rows[49]!.id : null,
  };
}

export function calculationInput(input: unknown) {
  if (!input || typeof input !== "object" || Array.isArray(input))
    throw new BadRequestException();
  const data = input as Record<string, unknown>;
  if (
    Object.keys(data).some(
      (key) => !["expectedVersion", "reason"].includes(key),
    ) ||
    !Object.hasOwn(data, "expectedVersion") ||
    !Object.hasOwn(data, "reason") ||
    typeof data.expectedVersion !== "number" ||
    !Number.isSafeInteger(data.expectedVersion) ||
    data.expectedVersion < 0 ||
    data.expectedVersion > 2147483647 ||
    typeof data.reason !== "string" ||
    data.reason.trim().length < 1 ||
    data.reason.trim().length > 500
  )
    throw new BadRequestException();
  return {
    expectedVersion: data.expectedVersion,
    reason: data.reason.trim(),
  };
}

export function policyInput(input: unknown) {
  if (!input || typeof input !== "object" || Array.isArray(input))
    throw new BadRequestException();
  const data = input as Record<string, unknown>;
  if (
    Object.keys(data).some(
      (key) => !["version", "name", "roundingDigits", "criteria"].includes(key),
    ) ||
    !/^[A-Za-z0-9._-]{1,20}$/.test(String(data.version ?? "")) ||
    typeof data.name !== "string" ||
    data.name.trim().length < 1 ||
    data.name.trim().length > 100 ||
    !Number.isInteger(data.roundingDigits) ||
    ![0, 1].includes(data.roundingDigits as number) ||
    !Array.isArray(data.criteria) ||
    data.criteria.length < 2 ||
    data.criteria.length > 20
  )
    throw new BadRequestException();
  const criteria = data.criteria.map((raw) => {
    if (!raw || typeof raw !== "object" || Array.isArray(raw))
      throw new BadRequestException();
    const item = raw as Record<string, unknown>;
    if (
      Object.keys(item).some(
        (key) => !["code", "minimum", "passing", "order"].includes(key),
      ) ||
      !/^[A-Z][A-Z0-9_]{0,19}$/.test(String(item.code ?? "")) ||
      typeof item.minimum !== "string" ||
      !/^(10[.]0|[0-9][.][0-9])$/.test(item.minimum) ||
      typeof item.passing !== "boolean" ||
      !Number.isSafeInteger(item.order) ||
      (item.order as number) < 1 ||
      (item.order as number) > 32767
    )
      throw new BadRequestException();
    return item as unknown as ClassificationCriterion;
  });
  if (
    new Set(criteria.map((item) => item.code)).size !== criteria.length ||
    new Set(criteria.map((item) => item.minimum)).size !== criteria.length ||
    new Set(criteria.map((item) => item.order)).size !== criteria.length ||
    !criteria.some((item) => item.minimum === "0.0") ||
    !criteria.some((item) => item.passing) ||
    !criteria.some((item) => !item.passing)
  )
    throw new BadRequestException();
  return {
    version: data.version as string,
    name: data.name.trim(),
    roundingDigits: data.roundingDigits as number,
    criteria,
  };
}

@Injectable()
export class FinalResultsService {
  constructor(
    @Inject(FINAL_RESULT_STORE) private readonly store: FinalResultStore,
  ) {}

  list(actor: Actor, gradebookId: number, after = "0") {
    positiveId(gradebookId);
    bigintCursor(after);
    return this.store.run(async (tx) => {
      await gradebookActor(tx.authorization, actor);
      const book = await tx.findBook(gradebookId);
      if (!book) throw new NotFoundException();
      await gradebookAccess(tx.authorization, actor, book);
      return page(await tx.list(gradebookId, after));
    });
  }

  calculate(
    actor: Actor,
    gradebookId: number,
    idempotencyKey: unknown,
    input: unknown,
  ): Promise<CalculationResult> {
    positiveId(gradebookId);
    if (
      typeof idempotencyKey !== "string" ||
      !/^[a-zA-Z0-9_-]{1,64}$/.test(idempotencyKey)
    )
      throw new BadRequestException();
    const data = calculationInput(input);
    const requestHash = createHash("sha256")
      .update(JSON.stringify({ gradebookId, ...data }))
      .digest("hex");
    return this.store.run(async (tx) => {
      await gradebookActor(tx.authorization, actor, true);
      const book = await tx.findBook(gradebookId);
      if (!book) throw new NotFoundException();
      await gradebookAccess(tx.authorization, actor, book, true);
      return tx.calculate({
        sessionHash: actor.sessionHash,
        gradebookId,
        expectedVersion: data.expectedVersion,
        reason: data.reason,
        idempotencyKey,
        requestHash,
      });
    });
  }

  history(actor: Actor, gradebookId: number, resultId: string, after = "0") {
    positiveId(gradebookId);
    bigintCursor(resultId, false);
    bigintCursor(after);
    return this.store.run(async (tx) => {
      await gradebookActor(tx.authorization, actor);
      const book = await tx.findBook(gradebookId);
      if (!book) throw new NotFoundException();
      await gradebookAccess(tx.authorization, actor, book);
      return page(await tx.history(gradebookId, resultId, after));
    });
  }

  activePolicy(actor: Actor) {
    return this.store.run(async (tx) => {
      await currentActor(tx.authorization, actor);
      const policy = await tx.activePolicy();
      if (!policy) throw new NotFoundException();
      return policy;
    });
  }

  activatePolicy(actor: Actor, idempotencyKey: unknown, input: unknown) {
    if (actor.role !== "QUAN_TRI_VIEN") throw new ForbiddenException();
    if (
      typeof idempotencyKey !== "string" ||
      !/^[a-zA-Z0-9_-]{1,64}$/.test(idempotencyKey)
    )
      throw new BadRequestException();
    const data = policyInput(input);
    const requestHash = createHash("sha256")
      .update(JSON.stringify(data))
      .digest("hex");
    return this.store.run(async (tx) => {
      await currentActor(tx.authorization, actor);
      return tx.activatePolicy({
        sessionHash: actor.sessionHash,
        ...data,
        idempotencyKey,
        requestHash,
      });
    });
  }

  myResults(actor: Actor, termId?: number) {
    if (actor.role !== "HOC_SINH") throw new ForbiddenException();
    if (
      termId !== undefined &&
      (!Number.isSafeInteger(termId) || termId < 1 || termId > 2147483647)
    )
      throw new BadRequestException();
    return this.store.run(async (tx) => {
      await currentActor(tx.authorization, actor);
      return tx.studentResults(actor.id, termId ?? null);
    });
  }
}
