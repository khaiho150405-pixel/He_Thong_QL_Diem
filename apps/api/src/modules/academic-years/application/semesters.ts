import { Inject, Injectable } from "@nestjs/common";
import { CatalogService } from "../../../common/catalog.js";
import { STORE, type Store } from "../../../common/store.js";
import { validateSemester } from "./rules.js";
@Injectable()
export class SemestersService extends CatalogService {
  constructor(@Inject(STORE) store: Store) {
    super(store, {
      table: "hoc_ky",
      id: "ma_hoc_ky",
      fields: {
        ma_nam_hoc: { kind: "int" },
        ten: { kind: "text", max: 20 },
        thu_tu: { kind: "int", max: 3 },
        ngay_bat_dau: { kind: "date" },
        ngay_ket_thuc: { kind: "date" },
      },
      validate: validateSemester,
    });
  }
}
