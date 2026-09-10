import { ForbiddenException } from "@nestjs/common";
import type { Unit } from "../../../common/store.js";
import { currentActor, type Actor } from "./policy.js";

export async function gradebookActor(tx: Unit, actor: Actor, write = false) {
  await currentActor(tx, actor);
  if (actor.role === "HOC_SINH" || (write && actor.role !== "GIAO_VIEN"))
    throw new ForbiddenException();
}

export async function gradebookAccess(
  tx: Unit,
  actor: Actor,
  scope: { classId: number; subjectId: number; termId: number },
  write = false,
) {
  await gradebookActor(tx, actor, write);
  if (actor.role === "QUAN_TRI_VIEN") return;
  const assignment = await tx.find("phan_cong_giang_day", {
    ma_giao_vien: actor.id,
    ma_lop: scope.classId,
    ma_mon: scope.subjectId,
    ma_hoc_ky: scope.termId,
  });
  if (!assignment) throw new ForbiddenException();
}
