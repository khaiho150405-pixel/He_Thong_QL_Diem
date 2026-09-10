import { BadRequestException, ConflictException } from "@nestjs/common";
import type { Row, Unit } from "../../../common/store.js";
export async function validateStudent(
  tx: Unit,
  data: Row,
  previous: Row | null,
) {
  if (data.ma_nguoi_dung != null) {
    const account = await tx.find("nguoi_dung", {
      ma_nguoi_dung: data.ma_nguoi_dung,
    });
    if (!account || account.vai_tro !== "HOC_SINH")
      throw new BadRequestException();
  }
  if (
    previous &&
    previous.ma_lop !== data.ma_lop &&
    (await tx.count("diem_thanh_phan", { ma_hoc_sinh: previous.ma_hoc_sinh }))
  )
    throw new ConflictException();
}
