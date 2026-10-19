import type { Actor } from "../../authorization/application/policy.js";
import type { LayoutSignature } from "../../recognition/public.js";
import type { TemplateColumn } from "../domain/definition.js";

export type TemplateStatus = "NHAP" | "DANG_DUNG" | "NGUNG";

export interface TemplateSummary {
  id: number;
  name: string;
  description: string | null;
  status: TemplateStatus;
  /** Số phiên bản của chuỗi mẫu, từ 1 (cột phien_ban). */
  revision: number;
  /** Mẫu gốc của chuỗi phiên bản; null với bản đầu tiên. */
  rootTemplateId: number | null;
  columnCount: number;
  gradeColumnCount: number;
  /** Số dùng cho khóa lạc quan (expectedVersion). */
  version: number;
  createdAt: string;
}

export interface TemplateDetail extends TemplateSummary {
  columns: TemplateColumn[];
  imageKey: string;
}

export interface TemplateForTry {
  id: number;
  signature: LayoutSignature;
  columns: TemplateColumn[];
}

export interface TemplatePage {
  items: TemplateSummary[];
  nextCursor: string | null;
}

export type SaveMode = "TAO" | "SUA" | "PHIEN_BAN";

export interface SaveTemplate {
  actor: Actor;
  mode: SaveMode;
  /** Mẫu được sửa / làm gốc cho phiên bản mới; null khi tạo. */
  templateId: number | null;
  expectedVersion: number | null;
  name: string;
  description: string | null;
  columns: TemplateColumn[];
  /** Chỉ khi tạo. */
  image?: {
    signature: LayoutSignature;
    objectKey: string;
    checksum: string;
  };
}

/** Thành phần điểm của môn trong một bảng điểm, kèm trạng thái khóa/chờ để giáo viên chọn ánh xạ. */
export interface MappingComponent {
  id: number;
  name: string;
  group: string;
  displayOrder: number;
  /** Cột đã chốt, ngoài thời gian nhập, bảng đã chốt hoặc môn Đạt/Không đạt (không dùng OCR điểm số). */
  locked: boolean;
  /** Đang có phiếu DANG_XU_LY hoặc CHO_DOI_CHIEU cho thành phần này. */
  pending: boolean;
}

export interface MappingContext {
  gradebookId: number;
  templateId: number;
  templateStatus: TemplateStatus;
  columns: TemplateColumn[];
  components: MappingComponent[];
}

/** Cổng đọc cho gợi ý ánh xạ cột mẫu -> thành phần (tách khỏi FormTemplateStore: chỉ phục vụ giáo viên của một bảng điểm). */
export interface FormTemplateMappingStore {
  /**
   * Dữ liệu để gợi ý ánh xạ cho một bảng điểm; chỉ giáo viên được phân công (ném Forbidden nếu không). null khi mẫu không
   * tồn tại.
   */
  mappingContext(
    actor: Actor,
    gradebookId: number,
    templateId: number,
  ): Promise<MappingContext | null>;
}

export interface FormTemplateStore {
  /** Quản trị viên thấy mọi trạng thái; giáo viên chỉ DANG_DUNG; học sinh bị từ chối ở policy. */
  list(
    actor: Actor,
    cursor: number | null,
    status: TemplateStatus | null,
  ): Promise<TemplatePage>;
  detail(actor: Actor, id: number): Promise<TemplateDetail | null>;
  /** Mẫu (chữ ký + cột) cho "thử nhận dạng"; chỉ quản trị viên. */
  forTry(actor: Actor, id: number): Promise<TemplateForTry | null>;
  save(input: SaveTemplate): Promise<{ templateId: number }>;
  setStatus(
    actor: Actor,
    id: number,
    expectedVersion: number,
    status: "DANG_DUNG" | "NGUNG",
  ): Promise<void>;
  /**
   * Tiêu thụ hạn mức thao tác (tieu_thu_han_muc_tac_vu, cùng cấu hình UPLOAD_RATE_LIMIT_PER_MINUTE với upload ảnh);
   * false khi vượt hạn mức.
   */
  consumeRateLimit(
    actor: Actor,
    operation: "FORM_TEMPLATE_TRY" | "FORM_TEMPLATE_ANALYZE",
  ): Promise<boolean>;
  /** Ghi một dòng nhật ký bảo mật; không ghi gì khác. */
  recordAudit(actor: Actor, action: string, target: string): Promise<void>;
}

export const FORM_TEMPLATE_STORE = Symbol("FORM_TEMPLATE_STORE");
export const FORM_TEMPLATE_MAPPING_STORE = Symbol(
  "FORM_TEMPLATE_MAPPING_STORE",
);
export const FORM_TEMPLATE_RECOGNIZER = Symbol("FORM_TEMPLATE_RECOGNIZER");
