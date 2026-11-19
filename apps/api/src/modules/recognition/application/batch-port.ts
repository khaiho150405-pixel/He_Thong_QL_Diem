import type { Actor } from "../../authorization/application/policy.js";

export const MAX_BATCH_PAGES = 4;
export const MAX_BATCH_COMPONENTS = 20;

export type BatchStatus = "DANG_XU_LY" | "XONG" | "LOI" | "DA_HUY";

export interface BatchComponentChoice {
  templateColumnIndex: number;
  componentId: number;
}

export interface BatchPageInput {
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
  errorCode: string | null;
  errorPage: number | null;
  modelVersion: string | null;
  version: number;
  createdAt: string;
  cancelReason: string | null;
  cancelledAt: string | null;
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
  authorizeUpload(actor: Actor, gradebookId: number): Promise<void>;
  create(input: CreateRecognitionBatch): Promise<StoredBatchReceipt>;
  detail(
    actor: Actor,
    gradebookId: number,
    batchId: string,
  ): Promise<RecognitionBatchView | null>;
  cancel(input: CancelRecognitionBatch): Promise<{ objectKeys: string[] }>;
}

export const RECOGNITION_BATCH_STORE = Symbol("RECOGNITION_BATCH_STORE");
