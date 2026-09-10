import { Inject, Injectable } from "@nestjs/common";
import { CatalogService } from "../../../common/catalog.js";
import { STORE, type Store } from "../../../common/store.js";
import { validateTeacher } from "./rules.js";
@Injectable()
export class TeachersService extends CatalogService {
  constructor(@Inject(STORE) store: Store) {
    super(store, {
      table: "giao_vien",
      id: "ma_giao_vien",
      fields: {
        ma_giao_vien: { kind: "int" },
        ho_ten: { kind: "text", max: 100 },
        to_chuyen_mon: { kind: "text", max: 50, nullable: true },
        email: { kind: "text", max: 254, nullable: true },
        dien_thoai: { kind: "text", max: 20, nullable: true },
      },
      validate: validateTeacher,
    });
  }
}
