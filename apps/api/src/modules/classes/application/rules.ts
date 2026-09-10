import { ConflictException } from "@nestjs/common";
import type { Row, Unit } from "../../../common/store.js";
export async function validateClass(tx: Unit, data: Row, previous: Row | null) {
  if (
    previous &&
    previous.ma_nam_hoc !== data.ma_nam_hoc &&
    ((await tx.count("hoc_sinh", { ma_lop: previous.ma_lop })) ||
      (await tx.count("phan_cong_giang_day", { ma_lop: previous.ma_lop })) ||
      (await tx.count("bang_diem", { ma_lop: previous.ma_lop })))
  )
    throw new ConflictException();
}
