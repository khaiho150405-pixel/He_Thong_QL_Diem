import { createHash } from "node:crypto";
import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { CodedException } from "../../../common/coded-error.js";
import { numberByClass } from "../../../common/student-order.js";
import {
  administrator,
  currentActor,
  type Actor,
} from "../../authorization/application/policy.js";
import {
  ENROLLMENT_STORE,
  type EnrollmentStore,
  type IdempotentCall,
  type PromotionAction,
  type PromotionItem,
} from "./port.js";

const ACTIONS: readonly PromotionAction[] = [
  "LEN_LOP",
  "LUU_BAN",
  "TOT_NGHIEP",
  "NGHI_HOC",
];

function intId(value: unknown) {
  if (
    typeof value !== "number" ||
    !Number.isSafeInteger(value) ||
    value < 1 ||
    value > 2147483647
  )
    throw new BadRequestException();
  return value;
}
function pathId(value: number) {
  return intId(value);
}
function exact(input: unknown, required: string[], optional: string[] = []) {
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
function text(value: unknown, max = 500) {
  if (typeof value !== "string" || !value.trim() || value.trim().length > max)
    throw new BadRequestException();
  return value.trim();
}
function isoDate(value: unknown) {
  if (
    typeof value !== "string" ||
    !/^\d{4}-\d{2}-\d{2}$/.test(value) ||
    new Date(`${value}T00:00:00Z`).toISOString().slice(0, 10) !== value
  )
    throw new BadRequestException("Ngày phải theo dạng YYYY-MM-DD.");
  return value;
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
/** Hậu tố tên lớp sau số khối: 10A1 → a1. */
const suffix = (name: string) => name.replace(/^\d+/, "").trim().toLowerCase();

@Injectable()
export class EnrollmentsService {
  constructor(
    @Inject(ENROLLMENT_STORE) private readonly store: EnrollmentStore,
  ) {}

  preview(actor: Actor, classId: number, targetYearInput?: string) {
    pathId(classId);
    if (
      typeof targetYearInput !== "string" ||
      !/^[1-9]\d{0,9}$/.test(targetYearInput)
    )
      throw new BadRequestException();
    const targetYearId = intId(Number(targetYearInput));
    return this.store.run(async (tx) => {
      await currentActor(tx.authorization, actor);
      administrator(actor);
      const data = await tx.preview(classId, targetYearId);
      if (!data) throw new NotFoundException();
      if (data.targetYear.startDate <= data.sourceClass.yearEnd)
        throw new CodedException(
          "TARGET_YEAR_NOT_AFTER",
          "Năm học đích phải bắt đầu sau khi năm học nguồn kết thúc.",
        );
      const numbers = numberByClass(
        data.students.map((s) => ({
          ma_hoc_sinh: s.id,
          ma_lop: classId,
          ho_ten: s.name,
        })),
      );
      const graduating = data.sourceClass.grade === 12;
      const suggested = graduating
        ? null
        : (data.targetClasses.find(
            (c) =>
              c.grade === data.sourceClass.grade + 1 &&
              suffix(c.name) === suffix(data.sourceClass.name),
          )?.id ?? null);
      return {
        sourceClass: {
          id: data.sourceClass.id,
          name: data.sourceClass.name,
          grade: data.sourceClass.grade,
          yearId: data.sourceClass.yearId,
          yearName: data.sourceClass.yearName,
        },
        targetYear: data.targetYear,
        targetClasses: data.targetClasses,
        items: data.students
          .map((s) => ({
            studentId: s.id,
            studentName: s.name,
            order: numbers.get(s.id) ?? 0,
            suggestedAction: graduating ? "TOT_NGHIEP" : "LEN_LOP",
            suggestedTargetClassId: suggested,
            alreadyEnrolledInTargetYear: s.enrolledInTargetYear,
            processedStatus: s.processedStatus,
            targetClassName: s.targetClassName,
          }))
          .sort((a, b) => a.order - b.order),
      };
    });
  }

  promote(actor: Actor, classId: number, key: unknown, input: unknown) {
    pathId(classId);
    const idem = idempotencyKey(key);
    const body = exact(input, ["targetYearId", "items"]);
    const targetYearId = intId(body.targetYearId);
    if (
      !Array.isArray(body.items) ||
      !body.items.length ||
      body.items.length > 100
    )
      throw new BadRequestException();
    const items: PromotionItem[] = body.items.map((raw: unknown) => {
      const item = exact(
        raw,
        ["studentId", "action"],
        ["targetClassId", "reason"],
      );
      if (!ACTIONS.includes(item.action as PromotionAction))
        throw new BadRequestException();
      const target = item.targetClassId ?? null;
      const reason = item.reason ?? null;
      if (
        reason !== null &&
        (typeof reason !== "string" || reason.trim().length > 500)
      )
        throw new BadRequestException();
      return {
        studentId: intId(item.studentId),
        action: item.action as PromotionAction,
        targetClassId: target === null ? null : intId(target),
        reason: typeof reason === "string" ? reason.trim() || null : null,
      };
    });
    const idempotent = call(idem, { classId, targetYearId, items });
    return this.store.run(async (tx) => {
      await currentActor(tx.authorization, actor);
      administrator(actor);
      return tx.promote(
        actor.sessionHash,
        classId,
        targetYearId,
        items,
        idempotent,
      );
    });
  }

  list(actor: Actor, studentId: number) {
    pathId(studentId);
    return this.store.run(async (tx) => {
      await currentActor(tx.authorization, actor);
      if (actor.role === "HOC_SINH") throw new ForbiddenException();
      if (
        !(await tx.authorization.find("hoc_sinh", { ma_hoc_sinh: studentId }))
      )
        throw new NotFoundException();
      if (
        actor.role === "GIAO_VIEN" &&
        !(await tx.teacherMaySee(studentId, actor.id))
      )
        throw new ForbiddenException();
      return { items: await tx.enrollmentsOf(studentId) };
    });
  }

  transfer(actor: Actor, studentId: number, key: unknown, input: unknown) {
    pathId(studentId);
    const idem = idempotencyKey(key);
    const body = exact(input, ["targetClassId", "effectiveDate", "reason"]);
    const targetClassId = intId(body.targetClassId);
    const effectiveDate = isoDate(body.effectiveDate);
    const reason = text(body.reason);
    const idempotent = call(idem, {
      studentId,
      targetClassId,
      effectiveDate,
      reason,
    });
    return this.store.run(async (tx) => {
      await currentActor(tx.authorization, actor);
      administrator(actor);
      const done = await tx.transfer(
        actor.sessionHash,
        studentId,
        targetClassId,
        effectiveDate,
        reason,
        idempotent,
      );
      return {
        enrollment: (await tx.enrollment(done.enrollmentId))!,
        affectedGradebooks: done.affectedGradebooks,
      };
    });
  }

  withdraw(actor: Actor, studentId: number, key: unknown, input: unknown) {
    pathId(studentId);
    const idem = idempotencyKey(key);
    const body = exact(input, ["effectiveDate", "reason"]);
    const effectiveDate = isoDate(body.effectiveDate);
    const reason = text(body.reason);
    const idempotent = call(idem, { studentId, effectiveDate, reason });
    return this.store.run(async (tx) => {
      await currentActor(tx.authorization, actor);
      administrator(actor);
      const done = await tx.withdraw(
        actor.sessionHash,
        studentId,
        effectiveDate,
        reason,
        idempotent,
      );
      return { enrollment: (await tx.enrollment(done.enrollmentId))! };
    });
  }

  reenroll(actor: Actor, studentId: number, key: unknown, input: unknown) {
    pathId(studentId);
    const idem = idempotencyKey(key);
    const body = exact(input, ["classId", "effectiveDate", "reason"]);
    const classId = intId(body.classId);
    const effectiveDate = isoDate(body.effectiveDate);
    const reason = text(body.reason);
    const idempotent = call(idem, {
      studentId,
      classId,
      effectiveDate,
      reason,
    });
    return this.store.run(async (tx) => {
      await currentActor(tx.authorization, actor);
      administrator(actor);
      const done = await tx.reenroll(
        actor.sessionHash,
        studentId,
        classId,
        effectiveDate,
        reason,
        idempotent,
      );
      return { enrollment: (await tx.enrollment(done.enrollmentId))! };
    });
  }
}
