import { Inject, Injectable } from "@nestjs/common";
import { CatalogService } from "../../../common/catalog.js";
import { STORE, type Store } from "../../../common/store.js";
import { validateAssignment } from "./rules.js";
@Injectable()
export class AssignmentsService extends CatalogService {
  constructor(@Inject(STORE) store: Store) {
    super(store, {
      table: "phan_cong_giang_day",
      id: "ma_phan_cong",
      fields: {
        ma_giao_vien: { kind: "int" },
        ma_lop: { kind: "int" },
        ma_mon: { kind: "int" },
        ma_hoc_ky: { kind: "int" },
        ngay_phan_cong: { kind: "date" },
      },
      validate: validateAssignment,
    });
  }
}
