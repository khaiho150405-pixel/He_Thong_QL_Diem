import { Inject, Injectable } from "@nestjs/common";
import { CatalogService } from "../../../common/catalog.js";
import { CodedException } from "../../../common/coded-error.js";
import type { Actor } from "../../authorization/application/policy.js";
import { GradebooksService } from "../../gradebooks/application/service.js";
import { STORE, type Store } from "../../../common/store.js";
import { validateSemester } from "./rules.js";
@Injectable()
export class SemestersService extends CatalogService {
  constructor(
    @Inject(STORE) store: Store,
    @Inject(GradebooksService) private readonly gradebooks: GradebooksService,
  ) {
    super(store, {
      table: "hoc_ky",
      id: "ma_hoc_ky",
      fields: {
        da_cong_bo: { kind: "boolean", optional: true },
        ma_nam_hoc: { kind: "int" },
        ten: { kind: "text", max: 20 },
        thu_tu: { kind: "int", max: 3 },
        ngay_bat_dau: { kind: "date" },
        ngay_ket_thuc: { kind: "date" },
      },
      validate: validateSemester,
    });
  }

  /**
   * Bật da_cong_bo bị trigger chặn (TERM_RESULTS_INCOMPLETE): lỗi Prisma của update theo model không mang DETAIL của
   * PostgreSQL, nên danh sách mục cần xử lý được dựng lại bằng kiem_san_sang_cong_bo (cùng nguồn với trigger).
   */
  override async save(actor: Actor, input: unknown, id?: number) {
    try {
      return await super.save(actor, input, id);
    } catch (error) {
      if (
        id &&
        error instanceof CodedException &&
        error.code === "TERM_RESULTS_INCOMPLETE"
      ) {
        const readiness = await this.gradebooks.publishReadiness(actor, id);
        throw new CodedException(error.code, error.message, {
          issues: readiness.issues
            .filter((issue) => issue.severity === "BLOCKING")
            .slice(0, 50),
        });
      }
      throw error;
    }
  }
}
