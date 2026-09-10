import type { Unit } from "../../../common/store.js";
export async function audit(
  tx: Unit,
  actor: number | null,
  action: string,
  target: string,
) {
  await tx.create("nhat_ky_bao_mat", {
    ma_tac_nhan: actor,
    hanh_dong: action,
    doi_tuong: target,
  });
}
