import { Inject, Injectable } from "@nestjs/common";
import { CatalogService } from "../../../common/catalog.js";
import { STORE, type Store } from "../../../common/store.js";
import { validateSubject } from "./rules.js";
@Injectable()
export class SubjectsService extends CatalogService {
  constructor(@Inject(STORE) store: Store) {
    super(store, {
      table: "mon_hoc",
      id: "ma_mon",
      fields: {
        ten_mon: { kind: "text", max: 80 },
        so_tiet_tuan: { kind: "int", max: 50 },
      },
      validate: validateSubject,
    });
  }
}
