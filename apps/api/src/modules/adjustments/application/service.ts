import { createHash } from "node:crypto";
import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import {
  administrator,
  currentActor,
  type Actor,
} from "../../authorization/application/policy.js";
import {
  gradebookAccess,
  gradebookActor,
} from "../../authorization/application/gradebook-policy.js";
import {
  ADJUSTMENT_STORE,
  type Adjustment,
  type AdjustmentChange,
  type AdjustmentStatus,
  type AdjustmentStore,
  type AdjustmentUnit,
  type IdempotentCall,
} from "./port.js";

const STATUSES: readonly AdjustmentStatus[] = [
  "CHO_DUYET",
  "DA_DUYET",
  "TU_CHOI",
  "DA_HUY",
];

function intId(value: number) {
  if (!Number.isSafeInteger(value) || value < 1 || value > 2147483647)
    throw new BadRequestException();
  return value;
}
function bigId(value: unknown, zero = false) {
  if (
    typeof value !== "string" ||
    !/^(0|[1-9][0-9]{0,18})$/.test(value) ||
    BigInt(value) > 9223372036854775807n ||
    (!zero && value === "0")
  )
    throw new BadRequestException();
  return value;
}
function exactObject(
  input: unknown,
  required: string[],
  optional: string[] = [],
) {
  if (
    !input ||
    typeof input !== "object" ||
    Array.isArray(input) ||
    Object.keys(input).some((k) => ![...required, ...optional].includes(k)) ||
    required.some((k) => !Object.hasOwn(input, k))
  )
    throw new BadRequestException();
  return input as Record<string, unknown>;
}
function text(value: unknown, max: number) {
  if (typeof value !== "string" || !value.trim() || value.trim().length > max)
    throw new BadRequestException();
  return value.trim();
}
function idempotencyKey(value: unknown) {
  if (typeof value !== "string" || !/^[a-zA-Z0-9_-]{1,64}$/.test(value))
    throw new BadRequestException();
  return value;
}
function call(key: string, payload: unknown): IdempotentCall {
  return {
    idempotencyKey: key,
    requestHash: createHash("sha256")
      .update(JSON.stringify(payload))
      .digest("hex"),
  };
}
function version(value: unknown) {
  if (typeof value !== "number") throw new BadRequestException();
  if (!Number.isSafeInteger(value) || value < 0 || value > 2147483647)
    throw new BadRequestException();
  return value;
}

@Injectable()
export class AdjustmentsService {
  constructor(
    @Inject(ADJUSTMENT_STORE) private readonly store: AdjustmentStore,
  ) {}

  /** Phạm vi bảng điểm của phiếu, để kiểm quyền theo phân công như mọi thao tác trên bảng điểm. */
  private async scopeOf(tx: AdjustmentUnit, bookId: number) {
    const book = await tx.authorization.find("bang_diem", {
      ma_bang_diem: bookId,
    });
    if (!book) throw new NotFoundException();
    return {
      classId: book.ma_lop as number,
      subjectId: book.ma_mon as number,
      termId: book.ma_hoc_ky as number,
    };
  }
  private async loadFor(
    tx: AdjustmentUnit,
    actor: Actor,
    adjId: string,
    write = false,
  ): Promise<Adjustment> {
    await gradebookActor(tx.authorization, actor, write);
    const found = await tx.detail(adjId);
    if (!found) throw new NotFoundException();
    await gradebookAccess(
      tx.authorization,
      actor,
      await this.scopeOf(tx, found.gradebookId),
      write,
    );
    return found;
  }

  submit(actor: Actor, bookId: number, key: unknown, input: unknown) {
    intId(bookId);
    const idem = idempotencyKey(key);
    const body = exactObject(input, ["expectedVersion", "reason", "changes"]);
    const expectedVersion = version(body.expectedVersion);
    const reason = text(body.reason, 500);
    if (
      !Array.isArray(body.changes) ||
      !body.changes.length ||
      body.changes.length > 100
    )
      throw new BadRequestException();
    const seen = new Set<string>();
    const changes: AdjustmentChange[] = body.changes.map((item: unknown) => {
      const c = exactObject(item, ["cellId", "value", "exempt"], ["note"]);
      bigId(c.cellId);
      if (
        seen.has(c.cellId as string) ||
        typeof c.exempt !== "boolean" ||
        (c.value !== null && typeof c.value !== "string")
      )
        throw new BadRequestException();
      seen.add(c.cellId as string);
      const note =
        c.note === undefined || c.note === null
          ? null
          : typeof c.note === "string"
            ? c.note.trim() || null
            : (() => {
                throw new BadRequestException();
              })();
      if (note !== null && note.length > 200) throw new BadRequestException();
      return {
        cellId: c.cellId as string,
        value: c.value as string | null,
        exempt: c.exempt,
        note,
      };
    });
    const idempotent = call(idem, { bookId, expectedVersion, reason, changes });
    return this.store.run(async (tx) => {
      await gradebookActor(tx.authorization, actor, true);
      await gradebookAccess(
        tx.authorization,
        actor,
        await this.scopeOf(tx, bookId),
        true,
      );
      const id = await tx.submit(
        actor.sessionHash,
        bookId,
        expectedVersion,
        reason,
        changes,
        idempotent,
      );
      return (await tx.detail(id))!;
    });
  }

  listForBook(actor: Actor, bookId: number) {
    intId(bookId);
    return this.store.run(async (tx) => {
      await gradebookActor(tx.authorization, actor);
      await gradebookAccess(
        tx.authorization,
        actor,
        await this.scopeOf(tx, bookId),
      );
      return { items: await tx.listForBook(bookId) };
    });
  }

  list(actor: Actor, statusInput?: string, cursorInput?: string) {
    if (
      statusInput !== undefined &&
      !STATUSES.includes(statusInput as AdjustmentStatus)
    )
      throw new BadRequestException();
    const status = (statusInput as AdjustmentStatus | undefined) ?? null;
    const cursor = cursorInput === undefined ? "0" : bigId(cursorInput, true);
    return this.store.run(async (tx) => {
      await currentActor(tx.authorization, actor);
      administrator(actor);
      const rows = await tx.list(status, cursor);
      return {
        items: rows.slice(0, 50),
        nextCursor: rows.length > 50 ? rows[49]!.id : null,
      };
    });
  }

  detail(actor: Actor, adjId: string) {
    bigId(adjId);
    return this.store.run((tx) => this.loadFor(tx, actor, adjId));
  }

  approve(actor: Actor, adjId: string, key: unknown, input: unknown) {
    bigId(adjId);
    const idem = idempotencyKey(key);
    const expectedVersion = version(
      exactObject(input, ["expectedVersion"]).expectedVersion,
    );
    const idempotent = call(idem, { adjId, expectedVersion });
    return this.store.run(async (tx) => {
      await currentActor(tx.authorization, actor);
      administrator(actor);
      if (!(await tx.detail(adjId))) throw new NotFoundException();
      await tx.approve(actor.sessionHash, adjId, expectedVersion, idempotent);
      return (await tx.detail(adjId))!;
    });
  }

  reject(actor: Actor, adjId: string, key: unknown, input: unknown) {
    bigId(adjId);
    const idem = idempotencyKey(key);
    const body = exactObject(input, ["expectedVersion", "reason"]);
    const expectedVersion = version(body.expectedVersion);
    const reason = text(body.reason, 500);
    const idempotent = call(idem, { adjId, expectedVersion, reason });
    return this.store.run(async (tx) => {
      await currentActor(tx.authorization, actor);
      administrator(actor);
      if (!(await tx.detail(adjId))) throw new NotFoundException();
      await tx.reject(
        actor.sessionHash,
        adjId,
        expectedVersion,
        reason,
        idempotent,
      );
      return (await tx.detail(adjId))!;
    });
  }

  cancel(actor: Actor, adjId: string, key: unknown, input: unknown) {
    bigId(adjId);
    const idem = idempotencyKey(key);
    const expectedVersion = version(
      exactObject(input, ["expectedVersion"]).expectedVersion,
    );
    const idempotent = call(idem, { adjId, expectedVersion });
    return this.store.run(async (tx) => {
      // Chỉ giáo viên (phụ trách bảng) mới hủy; SQL kiểm thêm đúng người đã gửi.
      await this.loadFor(tx, actor, adjId, true);
      await tx.cancel(actor.sessionHash, adjId, expectedVersion, idempotent);
      return (await tx.detail(adjId))!;
    });
  }
}
