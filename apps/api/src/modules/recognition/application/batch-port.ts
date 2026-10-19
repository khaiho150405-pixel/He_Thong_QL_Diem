import type { Actor } from "../../authorization/application/policy.js";

// Lô nhận dạng nhiều trang, nhiều thành phần theo mẫu (ADR-0016 mục 3).

export const MAX_BATCH_PAGES = 4;
export const MAX_BATCH_COMPONENTS = 20;

export type BatchStatus = "DANG_XU_LY" | "XONG" | "LOI" | "DA_HUY";

export interface BatchComponentChoice {
  /** `chi_so_cot` của cột DIEM trong mẫu. */
  templateColumnIndex: number;
  componentId: number;
}

export interface BatchPageInput {
  /** 1..n theo thứ tự giáo viên sắp xếp. */
  page: number;
  checksum: string;
  objectKey: string;
}

export interface CreateRecognitionBatch {
  actor: Actor;
  gradebookId: number;
  templateId: number;
  components: BatchComponentChoice[];
  pages: BatchPageInput[];
  idempotencyKey: string;
  requestHash: string;
}

export interface StoredBatchReceipt {
  batchId: string;
  jobId: string;
  status: "DANG_XU_LY";
  /** Khóa object ảnh các trang đã lưu; lần phát lại (replay) trả khóa của lần đầu. */
  storedObjectKeys: string[];
  tickets: Array<{
    ticketId: string;
    componentId: number;
    templateColumnIndex: number;
  }>;
}

export interface BatchTicketView {
  ticketId: string;
  componentId: number;
  componentName: string;
  templateColumnIndex: number;
  status: "DANG_XU_LY" | "CHO_DOI_CHIEU" | "DA_DUYET" | "LOI" | "DA_HUY";
  errorCode: string | null;
  version: number;
  greenRows: number;
  yellowRows: number;
  redRows: number;
}

export interface RecognitionBatchView {
  batchId: string;
  gradebookId: number;
  templateId: number;
  pageCount: number;
  status: BatchStatus;
  /** Mã lỗi chung của lô (mọi phiếu LOI mang cùng mã); null khi chưa lỗi. */
  errorCode: string | null;
  /** Trang gây lỗi (1..pageCount); null khi lỗi không gắn với một trang. */
  errorPage: number | null;
  modelVersion: string | null;
  version: number;
  createdAt: string;
  cancelReason: string | null;
  cancelledAt: string | null;
  /** Khóa object ảnh từng trang; service ký URL ngắn hạn, không lộ khóa ra API. */
  pages: Array<{ page: number; objectKey: string }>;
  tickets: BatchTicketView[];
}

export interface CancelRecognitionBatch {
  actor: Actor;
  gradebookId: number;
  batchId: string;
  reason: string;
  idempotencyKey: string;
  requestHash: string;
}

export interface RecognitionBatchStore {
  /** Phiên, quyền ghi (giáo viên được phân công) và hạn mức tải ảnh; chưa ghi gì. */
  authorizeUpload(actor: Actor, gradebookId: number): Promise<void>;
  create(input: CreateRecognitionBatch): Promise<StoredBatchReceipt>;
  detail(
    actor: Actor,
    gradebookId: number,
    batchId: string,
  ): Promise<RecognitionBatchView | null>;
  /**
   * Hủy mềm lô (huy_lo_nhan_dien). Trả khóa object cần xóa sau khi giao dịch commit: ảnh ô của các phiếu vừa hủy và, chỉ khi
   * mọi phiếu của lô đã hủy, ảnh các trang. Phiếu đã duyệt giữ nguyên cùng ảnh trang (bằng chứng).
   */
  cancel(input: CancelRecognitionBatch): Promise<{ objectKeys: string[] }>;
}

export const RECOGNITION_BATCH_STORE = Symbol("RECOGNITION_BATCH_STORE");
