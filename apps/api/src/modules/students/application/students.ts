import { ForbiddenException, Inject, Injectable } from "@nestjs/common";
import { CatalogService } from "../../../common/catalog.js";
import type { Actor } from "../../authorization/application/policy.js";
import { STUDENT_REMOVAL_STORE, type StudentRemovalStore } from "./port.js";
import { STORE, type Store } from "../../../common/store.js";
import { validateStudent } from "./rules.js";
@Injectable()
export class StudentsService extends CatalogService {
  constructor(
    @Inject(STORE) store: Store,
    @Inject(STUDENT_REMOVAL_STORE)
    private readonly removal: StudentRemovalStore,
  ) {
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

  override async remove(actor: Actor, id: number) {
    if (actor.role !== "QUAN_TRI_VIEN") throw new ForbiddenException();
    await this.removal.remove(
      actor.sessionHash,
      id,
      "Quản trị viên xóa thông tin học sinh",
    );
  }
}
