import { ForbiddenException, UnauthorizedException } from "@nestjs/common";
import type { Unit } from "../../../common/store.js";
export const roles = ["QUAN_TRI_VIEN", "GIAO_VIEN", "HOC_SINH"] as const;
export type Role = (typeof roles)[number];
export interface Actor {
  id: number;
  username: string;
  role: Role;
  sessionHash: string;
}
export async function currentActor(tx: Unit, actor: Actor) {
  authenticated(actor);
  const session = await tx.find("phien_lam_viec", {
    ma_bam: actor.sessionHash,
    ma_nguoi_dung: actor.id,
  });
  const user = await tx.find("nguoi_dung", { ma_nguoi_dung: actor.id });
  if (
    !session ||
    !user?.trang_thai ||
    user.vai_tro !== actor.role ||
    +(session.het_han as Date) <= Date.now() ||
    +(session.hoat_dong_cuoi as Date) + 1800000 <= Date.now()
  )
    throw new UnauthorizedException();
}
export function authenticated(
  actor: Actor | undefined,
): asserts actor is Actor {
  if (!actor) throw new UnauthorizedException();
}
export function administrator(
  actor: Actor | undefined,
): asserts actor is Actor {
  authenticated(actor);
  if (actor.role !== "QUAN_TRI_VIEN") throw new ForbiddenException();
}
