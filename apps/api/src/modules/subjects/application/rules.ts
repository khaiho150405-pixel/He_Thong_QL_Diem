import { ConflictException } from "@nestjs/common";
import type { Row, Unit } from "../../../common/store.js";
export async function validateSubject(
  tx: Unit,
  data: Row,
  previous: Row | null,
) {
  if (
    previous &&
    data.danh_gia_dat !== undefined &&
    data.danh_gia_dat !== previous.danh_gia_dat &&
    (await tx.count("bang_diem", { ma_mon: previous.ma_mon }))
  )
    throw new ConflictException(
      "Môn đã có bảng điểm; không đổi hình thức đánh giá để tránh sai dữ liệu cũ.",
    );
}
export async function validateComponent(
  tx: Unit,
  data: Row,
  previous: Row | null,
) {
  if (
    data.loai_he_so !== undefined &&
    !["TX", "GK", "CK"].includes(String(data.loai_he_so))
  )
    throw new ConflictException("Nhóm hệ số không hợp lệ.");
  // Cho phép Admin mở/khóa cổng nhập điểm (cho_phep_nhap) mà không ảnh hưởng cấu trúc điểm
  if (previous) {
    const structuralChanged =
      (data.loai_he_so !== undefined &&
        data.loai_he_so !== previous.loai_he_so) ||
      data.ma_mon !== previous.ma_mon ||
      data.ten_thanh_phan !== previous.ten_thanh_phan ||
      (data.he_so !== undefined &&
        Number(String(data.he_so)) !== Number(String(previous.he_so))) ||
      data.bat_buoc !== previous.bat_buoc ||
      data.thu_tu_hien_thi !== previous.thu_tu_hien_thi;
    if (!structuralChanged) {
      return;
    }
  }
  // Versioned coefficient snapshots belong to Phase 5; freeze already-used sets now.
  if (
    (await tx.count("bang_diem", { ma_mon: data.ma_mon })) ||
    (previous && (await tx.count("bang_diem", { ma_mon: previous.ma_mon })))
  )
    throw new ConflictException();
}
