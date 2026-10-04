import { Inject, Injectable } from "@nestjs/common";
import { CatalogService } from "../../../common/catalog.js";
import { STORE, type Store } from "../../../common/store.js";
import { validateComponent } from "./rules.js";
@Injectable()
export class ComponentsService extends CatalogService {
  constructor(@Inject(STORE) store: Store) {
    super(store, {
      table: "thanh_phan_diem",
      id: "ma_thanh_phan",
      fields: {
        loai_he_so: { kind: "text", optional: true },
        ma_mon: { kind: "int" },
        ten_thanh_phan: { kind: "text", max: 50 },
        he_so: { kind: "decimal", optional: true },
        bat_buoc: { kind: "boolean" },
        thu_tu_hien_thi: { kind: "int", max: 100 },
        cho_phep_nhap: { kind: "boolean", optional: true },
      },
      validate: validateComponent,
    });
  }
}
