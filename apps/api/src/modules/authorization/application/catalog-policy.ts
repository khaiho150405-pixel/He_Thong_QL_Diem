import { ForbiddenException } from "@nestjs/common";
import { authenticated, currentActor, type Actor } from "./policy.js";
import type { Row, Table, Unit } from "../../../common/store.js";
// Public query policy: homeroom access never grants grade write access.
export async function catalogScope(
  tx: Unit,
  actor: Actor,
  table: Table,
): Promise<Row> {
  authenticated(actor);
  await currentActor(tx, actor);
  if (actor.role === "QUAN_TRI_VIEN") return {};
  if (actor.role === "HOC_SINH") {
    if (table === "hoc_sinh") return { ma_nguoi_dung: actor.id };
    throw new ForbiddenException();
  }
  switch (table) {
    case "lop":
      return {
        OR: [
          { ma_gv_chu_nhiem: actor.id },
          { phan_cong_giang_day_rows: { some: { ma_giao_vien: actor.id } } },
        ],
      };
    case "hoc_sinh":
      return {
        ma_lop_ref: {
          phan_cong_giang_day_rows: { some: { ma_giao_vien: actor.id } },
        },
      };
    case "giao_vien":
      return { ma_giao_vien: actor.id };
    case "phan_cong_giang_day":
      return { ma_giao_vien: actor.id };
    case "nam_hoc":
    case "hoc_ky":
    case "mon_hoc":
    case "thanh_phan_diem":
      return {};
    default:
      throw new ForbiddenException();
  }
}
