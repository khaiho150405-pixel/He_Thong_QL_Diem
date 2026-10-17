import {
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { CatalogService } from "../../../common/catalog.js";
import {
  STORE,
  type Row,
  type Store,
  type Unit,
} from "../../../common/store.js";
import {
  administrator,
  currentActor,
  type Actor,
} from "../../authorization/application/policy.js";
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

  /** Không xóa năm hiện hành: luôn phải có một năm hiện hành, muốn bỏ phải chuyển sang năm khác trước. */
  protected override async guardRemove(_tx: Unit, row: Row) {
    if (row.hien_hanh)
      throw new ConflictException(
        "Không thể xóa năm học hiện hành; hãy chuyển năm hiện hành sang năm khác trước.",
      );
  }

  /**
   * Việc còn dang dở của một năm học, để quản trị viên cân nhắc trước khi chuyển năm hiện hành:
   * bảng điểm chưa chốt, phiếu nhận dạng đang xử lý/chờ đối chiếu (phiếu đã hủy không tính), học kỳ chưa công bố.
   */
  async pendingSummary(actor: Actor, yearId: number) {
    administrator(actor);
    return this.store.run(async (tx) => {
      await currentActor(tx, actor);
      if (!(await tx.find("nam_hoc", { ma_nam_hoc: yearId })))
        throw new NotFoundException();
      const inYear = { ma_hoc_ky_ref: { ma_nam_hoc: yearId } };
      return {
        openGradebooks: await tx.count("bang_diem", {
          ...inYear,
          trang_thai: "DANG_NHAP_LIEU",
        }),
        pendingRecognitionTickets: await tx.count("phieu_nhan_dien", {
          ma_bang_diem_ref: inYear,
          trang_thai: { in: ["DANG_XU_LY", "CHO_DOI_CHIEU"] },
        }),
        unpublishedSemesters: await tx.count("hoc_ky", {
          ma_nam_hoc: yearId,
          da_cong_bo: false,
        }),
      };
    });
  }
}
