import { Inject, Injectable } from "@nestjs/common";
import { CatalogService } from "../../../common/catalog.js";
import { STORE, type Store } from "../../../common/store.js";
import { validateClass } from "./rules.js";
@Injectable()
export class ClassesService extends CatalogService {
  constructor(@Inject(STORE) store: Store) {
    super(store, {
      table: "lop",
      id: "ma_lop",
      fields: {
        ma_nam_hoc: { kind: "int" },
        ma_gv_chu_nhiem: { kind: "int" },
        ten_lop: { kind: "text", max: 20 },
        khoi: { kind: "int", max: 12 },
      },
      validate: validateClass,
    });
  }
}
