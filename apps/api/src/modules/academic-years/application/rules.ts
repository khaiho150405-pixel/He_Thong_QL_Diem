import { BadRequestException, ConflictException } from "@nestjs/common";
import type { Row, Unit } from "../../../common/store.js";
export async function validateYear(tx: Unit, data: Row, previous: Row | null) {
  if (+(data.ngay_bat_dau as Date) >= +(data.ngay_ket_thuc as Date))
    throw new BadRequestException();
  if (
    previous &&
    (await tx.count("hoc_ky", {
      ma_nam_hoc: previous.ma_nam_hoc,
      OR: [
        { ngay_bat_dau: { lt: data.ngay_bat_dau } },
        { ngay_ket_thuc: { gt: data.ngay_ket_thuc } },
      ],
    }))
  )
    throw new ConflictException();
  if (
    data.hien_hanh &&
    (await tx.count("nam_hoc", {
      hien_hanh: true,
      ...(previous ? { ma_nam_hoc: { not: previous.ma_nam_hoc } } : {}),
    }))
  )
    throw new ConflictException();
}
export async function validateSemester(
  tx: Unit,
  data: Row,
  previous: Row | null,
) {
  const year = await tx.find("nam_hoc", { ma_nam_hoc: data.ma_nam_hoc });
  if (
    !year ||
    +(data.ngay_bat_dau as Date) >= +(data.ngay_ket_thuc as Date) ||
    +(data.ngay_bat_dau as Date) < +(year.ngay_bat_dau as Date) ||
    +(data.ngay_ket_thuc as Date) > +(year.ngay_ket_thuc as Date)
  )
    throw new BadRequestException();
  if (
    previous &&
    previous.ma_nam_hoc !== data.ma_nam_hoc &&
    ((await tx.count("phan_cong_giang_day", {
      ma_hoc_ky: previous.ma_hoc_ky,
    })) ||
      (await tx.count("bang_diem", { ma_hoc_ky: previous.ma_hoc_ky })))
  )
    throw new ConflictException();
}
