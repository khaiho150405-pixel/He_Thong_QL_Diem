import { ConflictException } from "@nestjs/common";
import type { Row, Unit } from "../../../common/store.js";
export async function validateSubject() {}
export async function validateComponent(
  tx: Unit,
  data: Row,
  previous: Row | null,
) {
  // Cho phép Admin mở/khóa cổng nhập điểm (cho_phep_nhap) mà không ảnh hưởng cấu trúc điểm
  if (previous) {
    const structuralChanged =
      data.ma_mon !== previous.ma_mon ||
      data.ten_thanh_phan !== previous.ten_thanh_phan ||
      Number(String(data.he_so)) !== Number(String(previous.he_so)) ||
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
