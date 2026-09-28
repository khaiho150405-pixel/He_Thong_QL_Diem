import { BadRequestException, ConflictException } from "@nestjs/common";
import type { Row, Unit } from "../../../common/store.js";
export async function validateTeacher(
  tx: Unit,
  data: Row,
  previous: Row | null,
) {
  if (
    data.email != null &&
    !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(data.email))
  )
    throw new BadRequestException();
  const user = await tx.find("nguoi_dung", {
    ma_nguoi_dung: data.ma_giao_vien,
  });
  if (
    !user ||
    user.vai_tro !== "GIAO_VIEN" ||
    (previous && data.ma_giao_vien !== previous.ma_giao_vien)
  )
    throw new BadRequestException();

  if (!previous) {
    const existingTeacher = await tx.find("giao_vien", {
      ma_giao_vien: data.ma_giao_vien,
    });
    if (existingTeacher) {
      throw new ConflictException(
        "Tài khoản này đã có hồ sơ giáo viên trong hệ thống.",
      );
    }
  }
}
export async function validateAssignment(
  tx: Unit,
  data: Row,
  previous: Row | null,
) {
  const classroom = await tx.find("lop", { ma_lop: data.ma_lop });
  const semester = await tx.find("hoc_ky", { ma_hoc_ky: data.ma_hoc_ky });
  if (!classroom || !semester || classroom.ma_nam_hoc !== semester.ma_nam_hoc)
    throw new BadRequestException();

  // Check duplicate assignment: 1 class, 1 subject in 1 term can only have 1 teacher
  const existing = await tx.find("phan_cong_giang_day", {
    ma_lop: data.ma_lop,
    ma_mon: data.ma_mon,
    ma_hoc_ky: data.ma_hoc_ky,
  });
  if (
    existing &&
    (!previous || existing.ma_phan_cong !== previous.ma_phan_cong)
  ) {
    throw new ConflictException(
      "Lớp học này đã được phân công giáo viên cho môn học và học kỳ đã chọn. Vui lòng chỉnh sửa phân công đã có thay vì tạo trùng lặp.",
    );
  }

  if (
    previous &&
    ["ma_lop", "ma_mon", "ma_hoc_ky"].some(
      (key) => previous[key] !== data[key],
    ) &&
    (await tx.count("bang_diem", {
      ma_lop: previous.ma_lop,
      ma_mon: previous.ma_mon,
      ma_hoc_ky: previous.ma_hoc_ky,
    }))
  )
    throw new ConflictException();
}
