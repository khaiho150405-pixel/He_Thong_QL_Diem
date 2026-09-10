import { Inject, Injectable } from "@nestjs/common";
import { CatalogService } from "../../../common/catalog.js";
import { STORE, type Store } from "../../../common/store.js";
import { validateStudent } from "./rules.js";
@Injectable()
export class StudentsService extends CatalogService {
  constructor(@Inject(STORE) store: Store) {
    super(store, {
      table: "hoc_sinh",
      id: "ma_hoc_sinh",
      fields: {
        ma_nguoi_dung: { kind: "int", nullable: true },
        ma_lop: { kind: "int" },
        ho_ten: { kind: "text", max: 100 },
        ngay_sinh: { kind: "date" },
        dang_theo_hoc: { kind: "boolean" },
      },
      validate: validateStudent,
    });
  }
}
