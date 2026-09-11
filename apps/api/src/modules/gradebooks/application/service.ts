import { createHash } from "node:crypto";
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { validateInput } from "../../../common/catalog.js";
import {
  currentActor,
  type Actor,
} from "../../authorization/application/policy.js";
import {
  gradebookAccess,
  gradebookActor,
} from "../../authorization/application/gradebook-policy.js";
import { audit } from "../../audit/application/write.js";
import {
  GRADEBOOK_STORE,
  type GradebookStore,
  type GradebookScope,
  type GradebookUnit,
  type BatchResult,
} from "./port.js";

export function objectInput(
  input: unknown,
  keys: string[],
): Record<string, unknown> {
  if (
    !input ||
    typeof input !== "object" ||
    Array.isArray(input) ||
    Object.keys(input).some((k) => !keys.includes(k)) ||
    keys.some((k) => !Object.hasOwn(input, k))
  )
    throw new BadRequestException();
  return input as Record<string, unknown>;
}
function id(value: number, zero = false) {
  if (
    !Number.isSafeInteger(value) ||
    value < (zero ? 0 : 1) ||
    value > 2147483647
  )
    throw new BadRequestException();
  return value;
}
function bigintCursor(value: string, zero = true) {
  if (
    typeof value !== "string" ||
    !/^(0|[1-9][0-9]{0,18})$/.test(value) ||
    BigInt(value) > 9223372036854775807n ||
    (!zero && value === "0")
  )
    throw new BadRequestException();
  return value;
}
function page<T extends { id: number | string }>(rows: T[]) {
  return {
    items: rows.slice(0, 50),
    nextCursor: rows.length > 50 ? rows[49]!.id : null,
  };
}
export interface GradeChange {
  cellId: string;
  value: string | null;
  reason: string;
}
export function gradeChanges(input: unknown): GradeChange[] {
  if (!Array.isArray(input) || !input.length || input.length > 100)
    throw new BadRequestException();
  const seen = new Set<string>();
  return input.map((change) => {
    const c = objectInput(change, ["cellId", "value", "reason"]);
    bigintCursor(c.cellId as string, false);
    if (seen.has(c.cellId as string)) throw new BadRequestException();
    seen.add(c.cellId as string);
    if (
      c.value !== null &&
      (typeof c.value !== "string" || !/^(10[.]0|[0-9][.][0-9])$/.test(c.value))
    )
      throw new BadRequestException();
    if (
      typeof c.reason !== "string" ||
      !c.reason.trim() ||
      c.reason.length > 500
    )
      throw new BadRequestException();
    return {
      cellId: c.cellId as string,
      value: c.value as string | null,
      reason: c.reason.trim(),
    };
  });
}
@Injectable()
export class GradebooksService {
  constructor(
    @Inject(GRADEBOOK_STORE) private readonly store: GradebookStore,
  ) {}
  private async run<T>(
    actor: Actor,
    work: (tx: GradebookUnit) => Promise<T>,
  ): Promise<T> {
    try {
      return await this.store.run(work);
    } catch (error) {
      if (error instanceof ForbiddenException) {
        // The denied transaction is rolled back; persist denial separately without point values.
        await this.store.run(async (tx) => {
          await currentActor(tx.authorization, actor);
          await audit(
            tx.authorization,
            actor.id,
            "GRADEBOOK_ACCESS_DENIED",
            "gradebooks",
          );
        });
      }
      throw error;
    }
  }
  create(actor: Actor, input: unknown) {
    const data = validateInput(input, {
      classId: { kind: "int" },
      subjectId: { kind: "int" },
      termId: { kind: "int" },
    }) as unknown as GradebookScope;
    return this.run(actor, async (tx) => {
      await gradebookAccess(tx.authorization, actor, data, true);
      return tx.createBlankGrid(actor.sessionHash, data);
    });
  }
  list(actor: Actor, after = 0) {
    id(after, true);
    return this.run(actor, async (tx) => {
      await gradebookActor(tx.authorization, actor);
      return page(
        await tx.list(actor.role === "QUAN_TRI_VIEN" ? null : actor.id, after),
      );
    });
  }
  cells(actor: Actor, bookId: number, after = "0") {
    id(bookId);
    bigintCursor(after);
    return this.run(actor, async (tx) => {
      await gradebookActor(tx.authorization, actor);
      const book = await tx.find(bookId);
      if (!book) throw new NotFoundException();
      await gradebookAccess(tx.authorization, actor, book);
      return { book, ...page(await tx.cells(bookId, after)) };
    });
  }
  private mutate<T>(
    actor: Actor,
    bookId: number,
    idemKey: unknown,
    expectedVersion: unknown,
    operation: string,
    payload: unknown,
    action: (tx: GradebookUnit, version: number) => Promise<T>,
  ) {
    id(bookId);
    if (typeof idemKey !== "string" || !/^[a-zA-Z0-9_-]{1,64}$/.test(idemKey))
      throw new BadRequestException();
    if (typeof expectedVersion !== "number") throw new BadRequestException();
    const version = id(expectedVersion, true);
    const hash = createHash("sha256")
      .update(JSON.stringify({ bookId, expectedVersion, payload }))
      .digest("hex");
    return this.run(actor, async (tx) => {
      await gradebookActor(tx.authorization, actor, true);
      const book = await tx.find(bookId);
      if (!book) throw new NotFoundException();
      await gradebookAccess(tx.authorization, actor, book, true);
      const existing = await tx.findIdempotencyKey(
        idemKey,
        actor.id,
        operation,
      );
      if (existing) {
        if (existing.requestHash !== hash) throw new ConflictException();
        return existing.result as T;
      }
      const result = await action(tx, version);
      await tx.saveIdempotencyKey(idemKey, actor.id, operation, hash, result);
      return result;
    });
  }
  batchUpdate(actor: Actor, bookId: number, key: unknown, input: unknown) {
    const body = objectInput(input, ["expectedVersion", "changes"]);
    const changes = gradeChanges(body.changes);
    return this.mutate<BatchResult>(
      actor,
      bookId,
      key,
      body.expectedVersion,
      "BATCH_UPDATE",
      changes,
      (tx, v) => tx.updateGrades(actor.sessionHash, bookId, v, changes),
    );
  }
  lock(actor: Actor, bookId: number, key: unknown, input: unknown) {
    const body = objectInput(input, ["expectedVersion"]);
    return this.mutate(
      actor,
      bookId,
      key,
      body.expectedVersion,
      "LOCK",
      null,
      (tx, v) => tx.lockGradebook(actor.sessionHash, bookId, v),
    );
  }
  syncRoster(actor: Actor, bookId: number, key: unknown, input: unknown) {
    const body = objectInput(input, ["expectedVersion"]);
    return this.mutate(
      actor,
      bookId,
      key,
      body.expectedVersion,
      "SYNC_ROSTER",
      null,
      (tx, v) => tx.syncRoster(actor.sessionHash, bookId, v),
    );
  }
  history(actor: Actor, bookId: number, cellId: string, after = "0") {
    id(bookId);
    bigintCursor(cellId, false);
    bigintCursor(after);
    return this.run(actor, async (tx) => {
      await gradebookActor(tx.authorization, actor);
      const book = await tx.find(bookId);
      if (!book) throw new NotFoundException();
      await gradebookAccess(tx.authorization, actor, book);
      if (
        !(await tx.authorization.find("diem_thanh_phan", {
          ma_diem: BigInt(cellId),
          ma_bang_diem: bookId,
        }))
      )
        throw new NotFoundException();
      return page(await tx.gradeHistory(bookId, cellId, after));
    });
  }
}
