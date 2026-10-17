import { BadRequestException, ConflictException } from "@nestjs/common";
import type { Row, Unit } from "../../../common/store.js";
import { audit } from "../../audit/application/write.js";
export async function validateYear(
  tx: Unit,
  data: Row,
  previous: Row | null,
  actorId?: number,
) {
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
  // Luôn phải có một năm học hiện hành: không tắt trực tiếp năm hiện hành duy nhất, chỉ chuyển bằng cách bật năm khác.
  if (previous?.hien_hanh && !data.hien_hanh)
    throw new ConflictException(
      "Phải có một năm học hiện hành; hãy bật năm khác để chuyển.",
    );
  if (data.hien_hanh) {
    // Chuyển năm hiện hành: tắt năm đang hiện hành rồi bật năm này trong cùng giao dịch (validate chạy trong giao dịch lưu;
    // chỉ mục duy nhất một phần nam_hoc_mot_hien_hanh không bao giờ thấy hai năm cùng hiện hành).
    const others = await tx.list(
      "nam_hoc",
      {
        hien_hanh: true,
        ...(previous ? { ma_nam_hoc: { not: previous.ma_nam_hoc } } : {}),
      },
      "ma_nam_hoc",
    );
    for (const other of others) {
      await tx.update(
        "nam_hoc",
        { ma_nam_hoc: other.ma_nam_hoc },
        { hien_hanh: false },
      );
      await audit(
        tx,
        actorId ?? null,
        "ACADEMIC_YEAR_SWITCHED",
        `nam_hoc:${other.ma_nam_hoc}`,
      );
    }
  }
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
