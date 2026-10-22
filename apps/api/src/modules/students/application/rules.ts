import { BadRequestException } from "@nestjs/common";
import { CodedException } from "../../../common/coded-error.js";
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
  // Lớp và trạng thái đang học thay đổi theo ghi danh (hoc_sinh_lop), không sửa trực tiếp từ danh mục học sinh.
  if (
    previous &&
    (Number(previous.ma_lop) !== Number(data.ma_lop) ||
      previous.dang_theo_hoc !== data.dang_theo_hoc)
  )
    throw new CodedException(
      "STUDENT_CLASS_VIA_ENROLLMENT",
      "Đổi lớp hoặc trạng thái đang học của học sinh phải thực hiện qua ghi danh, không sửa trực tiếp ở danh mục học sinh.",
    );
}
