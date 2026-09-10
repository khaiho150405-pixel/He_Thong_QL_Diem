import { Inject, Injectable } from "@nestjs/common";
import { CatalogService } from "../../../common/catalog.js";
import { STORE, type Store } from "../../../common/store.js";
import { validateYear } from "./rules.js";
@Injectable()
export class YearsService extends CatalogService {
  constructor(@Inject(STORE) store: Store) {
    super(store, {
      table: "nam_hoc",
      id: "ma_nam_hoc",
      fields: {
        ten: { kind: "text", max: 20 },
        ngay_bat_dau: { kind: "date" },
        ngay_ket_thuc: { kind: "date" },
        hien_hanh: { kind: "boolean" },
      },
      validate: validateYear,
    });
  }
}
