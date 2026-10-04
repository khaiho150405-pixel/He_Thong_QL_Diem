import {
  Inject,
  Injectable,
  ConflictException,
  NotFoundException,
} from "@nestjs/common";
import { CatalogService } from "../../../common/catalog.js";
import {
  STORE,
  type Store,
  type Unit,
  type Row,
} from "../../../common/store.js";
export async function validateSemesterWeight(
  tx: Unit,
  data: Row,
  previous: Row | null,
) {
  for (const row of [data, ...(previous ? [previous] : [])]) {
    if (!["TX", "GK", "CK"].includes(String(row.loai_he_so)))
      throw new ConflictException("Nhóm hệ số phải là TX, GK hoặc CK.");
    if (!(await tx.find("hoc_ky", { ma_hoc_ky: row.ma_hoc_ky })))
      throw new NotFoundException();
    if (
      await tx.count("bang_diem", {
        ma_hoc_ky: row.ma_hoc_ky,
        OR: [{ trang_thai: "DA_CHOT" }, { chot_cot_rows: { some: {} } }],
      })
    )
      throw new ConflictException(
        "Học kỳ đã có bảng điểm chốt; không thể thay đổi hệ số.",
      );
  }
}
@Injectable()
export class SemesterWeightsService extends CatalogService {
  constructor(@Inject(STORE) store: Store) {
    super(store, {
      table: "he_so_hoc_ky_chung",
      id: "ma_he_so",
      fields: {
        loai_he_so: { kind: "text", max: 2 },
        ma_hoc_ky: { kind: "int" },
        he_so: { kind: "decimal" },
      },
      validate: validateSemesterWeight,
    });
  }
}
