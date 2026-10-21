import { createHash } from "node:crypto";
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { parseYearId, validateInput } from "../../../common/catalog.js";
import {
  administrator,
  currentActor,
  type Actor,
} from "../../authorization/application/policy.js";
import {
  gradebookAccess,
  gradebookActor,
} from "../../authorization/application/gradebook-policy.js";
import { deadlineError } from "./deadline-errors.js";
import { audit } from "../../audit/application/write.js";
import {
  GRADEBOOK_STORE,
  type Gradebook,
  type GradebookStore,
  type GradebookScope,
  type GradebookUnit,
  type BatchResult,
  type DeadlineType,
} from "./port.js";

const DEADLINE_TYPES: readonly DeadlineType[] = ["TX", "GK", "CK"];

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
      // Thông báo rõ cho riêng luồng tạo bảng điểm; gradebookActor/gradebookAccess dùng chung giữ nguyên hành vi.
      await currentActor(tx.authorization, actor);
      if (actor.role !== "GIAO_VIEN")
        throw new ForbiddenException(
          "Chỉ giáo viên được phân công mới tạo được bảng điểm.",
        );
      if (
        !(await tx.authorization.find("phan_cong_giang_day", {
          ma_giao_vien: actor.id,
          ma_lop: data.classId,
          ma_mon: data.subjectId,
          ma_hoc_ky: data.termId,
        }))
      )
        throw new ForbiddenException(
          "Bạn chưa được phân công dạy môn này cho lớp và học kỳ đã chọn.",
        );
      await gradebookAccess(tx.authorization, actor, data, true);
      return tx.createBlankGrid(actor.sessionHash, data);
    });
  }
  list(actor: Actor, after = 0, yearIdInput?: unknown) {
    id(after, true);
    const yearId = parseYearId(yearIdInput);
    return this.run(actor, async (tx) => {
      await gradebookActor(tx.authorization, actor);
      return page(
        await tx.list(
          actor.role === "QUAN_TRI_VIEN" ? null : actor.id,
          after,
          yearId,
        ),
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
  processDue() {
    return this.store.run((tx) => tx.processDue());
  }
  setDeadline(
    actor: Actor,
    bookId: number,
    componentId: number,
    input: unknown,
  ) {
    id(bookId);
    id(componentId);
    const body = objectInput(input, ["opensAt", "closesAt", "expectedVersion"]);
    for (const value of [body.opensAt, body.closesAt]) {
      if (
        typeof value !== "string" ||
        !/^\d{4}-\d{2}-\d{2}T.*(?:Z|[+-]\d{2}:\d{2})$/.test(value) ||
        !Number.isFinite(Date.parse(value))
      )
        throw new BadRequestException("Thời gian phải hợp lệ và có múi giờ.");
    }
    if (typeof body.expectedVersion !== "number")
      throw new BadRequestException();
    id(body.expectedVersion, true);
    if (
      Date.parse(body.closesAt as string) <=
        Date.parse(body.opensAt as string) ||
      Date.parse(body.closesAt as string) <= Date.now()
    )
      throw new BadRequestException(
        "Hạn nhập phải sau thời điểm mở và nằm trong tương lai.",
      );
    return this.run(actor, async (tx) => {
      await currentActor(tx.authorization, actor);
      administrator(actor);
      const book = await tx.find(bookId);
      if (!book) throw new NotFoundException();
      await tx.setDeadline(
        actor.sessionHash,
        bookId,
        componentId,
        body.opensAt as string,
        body.closesAt as string,
        body.expectedVersion as number,
      );
    });
  }
  semesterDeadlines(actor: Actor, termId: number) {
    id(termId);
    return this.run(actor, async (tx) => {
      await gradebookActor(tx.authorization, actor);
      if (!(await tx.authorization.find("hoc_ky", { ma_hoc_ky: termId })))
        throw new NotFoundException();
      return { items: await tx.semesterDeadlines(termId) };
    });
  }
  setSemesterDeadline(
    actor: Actor,
    termId: number,
    type: string,
    input: unknown,
  ) {
    id(termId);
    if (!DEADLINE_TYPES.includes(type as DeadlineType))
      throw new BadRequestException("Loại điểm phải là TX, GK hoặc CK.");
    const body = objectInput(input, ["opensAt", "closesAt", "expectedVersion"]);
    for (const value of [body.opensAt, body.closesAt])
      if (
        typeof value !== "string" ||
        !/^\d{4}-\d{2}-\d{2}T.*(?:Z|[+-]\d{2}:\d{2})$/.test(value) ||
        !Number.isFinite(Date.parse(value))
      )
        throw new BadRequestException("Thời gian phải hợp lệ và có múi giờ.");
    if (typeof body.expectedVersion !== "number")
      throw new BadRequestException();
    id(body.expectedVersion, true);
    if (
      Date.parse(body.closesAt as string) <=
        Date.parse(body.opensAt as string) ||
      Date.parse(body.closesAt as string) <= Date.now()
    )
      throw deadlineError("INVALID_ENTRY_WINDOW");
    return this.run(actor, async (tx) => {
      await currentActor(tx.authorization, actor);
      administrator(actor);
      if (!(await tx.authorization.find("hoc_ky", { ma_hoc_ky: termId })))
        throw new NotFoundException();
      await tx.setSemesterDeadline(
        actor.sessionHash,
        termId,
        type as DeadlineType,
        body.opensAt as string,
        body.closesAt as string,
        body.expectedVersion as number,
      );
      const rows = await tx.semesterDeadlines(termId);
      return rows.find((row) => row.type === type)!;
    });
  }
  initializeSemesterGradebooks(actor: Actor, termId: number, key: unknown) {
    id(termId);
    if (typeof key !== "string" || !/^[a-zA-Z0-9_-]{1,64}$/.test(key))
      throw new BadRequestException();
    const hash = createHash("sha256")
      .update(JSON.stringify({ termId }))
      .digest("hex");
    return this.run(actor, async (tx) => {
      await currentActor(tx.authorization, actor);
      administrator(actor);
      if (!(await tx.authorization.find("hoc_ky", { ma_hoc_ky: termId })))
        throw new NotFoundException();
      return tx.initializeSemester(actor.sessionHash, termId, key, hash);
    });
  }
  exemptions(actor: Actor, bookId: number, key: unknown, input: unknown) {
    id(bookId);
    if (typeof key !== "string" || !/^[a-zA-Z0-9_-]{1,64}$/.test(key))
      throw new BadRequestException();
    const body = objectInput(input, ["expectedVersion", "changes"]);
    if (typeof body.expectedVersion !== "number")
      throw new BadRequestException();
    const version = id(body.expectedVersion, true);
    if (
      !Array.isArray(body.changes) ||
      !body.changes.length ||
      body.changes.length > 100
    )
      throw new BadRequestException();
    const seen = new Set<string>();
    const changes = body.changes.map((change: unknown) => {
      const c = objectInput(change, ["cellId", "exempt", "reason"]);
      bigintCursor(c.cellId as string, false);
      if (seen.has(c.cellId as string) || typeof c.exempt !== "boolean")
        throw new BadRequestException();
      seen.add(c.cellId as string);
      if (
        typeof c.reason !== "string" ||
        !c.reason.trim() ||
        c.reason.trim().length > 500
      )
        throw new BadRequestException();
      return {
        cellId: c.cellId as string,
        exempt: c.exempt,
        reason: c.reason.trim(),
      };
    });
    const hash = createHash("sha256")
      .update(JSON.stringify({ bookId, version, changes }))
      .digest("hex");
    return this.run(actor, async (tx) => {
      await gradebookActor(tx.authorization, actor, true);
      const book = await tx.find(bookId);
      if (!book) throw new NotFoundException();
      await gradebookAccess(tx.authorization, actor, book, true);
      const result = await tx.setExemptions(
        actor.sessionHash,
        bookId,
        version,
        changes,
        key,
        hash,
      );
      return {
        bookId: result.bookId,
        version: result.version,
        items: await tx.cellsByIds(bookId, result.cellIds),
      };
    });
  }
  missingStudents(actor: Actor, bookId: number) {
    id(bookId);
    return this.run(actor, async (tx) => {
      await gradebookActor(tx.authorization, actor);
      const book = await tx.find(bookId);
      if (!book) throw new NotFoundException();
      await gradebookAccess(tx.authorization, actor, book);
      return { items: await tx.missingStudents(bookId) };
    });
  }
  lateStudent(actor: Actor, bookId: number, key: unknown, input: unknown) {
    id(bookId);
    if (typeof key !== "string" || !/^[a-zA-Z0-9_-]{1,64}$/.test(key))
      throw new BadRequestException();
    const body = objectInput(input, ["studentId", "reason"]);
    if (typeof body.studentId !== "number") throw new BadRequestException();
    const studentId = id(body.studentId);
    if (
      typeof body.reason !== "string" ||
      !body.reason.trim() ||
      body.reason.trim().length > 500
    )
      throw new BadRequestException();
    const reason = body.reason.trim();
    const hash = createHash("sha256")
      .update(JSON.stringify({ bookId, studentId, reason }))
      .digest("hex");
    return this.run(actor, async (tx) => {
      await currentActor(tx.authorization, actor);
      administrator(actor);
      if (!(await tx.find(bookId))) throw new NotFoundException();
      return tx.addLateStudent(
        actor.sessionHash,
        bookId,
        studentId,
        reason,
        key,
        hash,
      );
    });
  }
  publishReadiness(actor: Actor, termId: number) {
    id(termId);
    return this.run(actor, async (tx) => {
      await currentActor(tx.authorization, actor);
      administrator(actor);
      if (!(await tx.authorization.find("hoc_ky", { ma_hoc_ky: termId })))
        throw new NotFoundException();
      return tx.publishReadiness(termId);
    });
  }
  lockColumn(
    actor: Actor,
    bookId: number,
    componentId: number,
    key: unknown,
    input: unknown,
  ): Promise<Gradebook> {
    void [actor, bookId, componentId, key, input];
    throw new ForbiddenException(
      "Nhà trường đặt hạn nhập; hệ thống tự khóa cột khi đến hạn. Giáo viên không chốt thủ công.",
    );
  }

  lock(_actor: Actor, _bookId: number, _key: unknown, _input: unknown): never {
    void [_actor, _bookId, _key, _input];
    throw new ForbiddenException(
      "Bảng điểm tự khóa theo hạn nhập do nhà trường đặt.",
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
  historyAll(actor: Actor, bookId: number, after = "0") {
    id(bookId);
    bigintCursor(after);
    return this.run(actor, async (tx) => {
      await gradebookActor(tx.authorization, actor);
      const book = await tx.find(bookId);
      if (!book) throw new NotFoundException();
      await gradebookAccess(tx.authorization, actor, book);
      return page(await tx.gradebookHistory(bookId, after));
    });
  }
}
