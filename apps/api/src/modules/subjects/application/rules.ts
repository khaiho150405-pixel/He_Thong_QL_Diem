import { ConflictException } from "@nestjs/common";
import type { Row, Unit } from "../../../common/store.js";
export async function validateSubject() {}
export async function validateComponent(
  tx: Unit,
  data: Row,
  previous: Row | null,
) {
  // Versioned coefficient snapshots belong to Phase 5; freeze already-used sets now.
  if (
    (await tx.count("bang_diem", { ma_mon: data.ma_mon })) ||
    (previous && (await tx.count("bang_diem", { ma_mon: previous.ma_mon })))
  )
    throw new ConflictException();
}
