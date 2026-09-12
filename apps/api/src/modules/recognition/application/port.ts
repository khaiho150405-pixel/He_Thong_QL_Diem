import type { Actor } from "../../authorization/application/policy.js";

export interface RecognitionReceipt {
  ticketId: string;
  jobId: string;
  status: "DANG_XU_LY";
}

export interface StoredRecognitionReceipt extends RecognitionReceipt {
  storedObjectKey: string;
}

export interface CreateRecognitionTicket {
  actor: Actor;
  gradebookId: number;
  componentId: number;
  declaredRows: number;
  checksum: string;
  objectKey: string;
  idempotencyKey: string;
  requestHash: string;
}

export interface RecognitionStore {
  authorizeUpload(
    actor: Actor,
    gradebookId: number,
    componentId: number,
  ): Promise<void>;
  createTicket(
    input: CreateRecognitionTicket,
  ): Promise<StoredRecognitionReceipt>;
  list(actor: Actor, gradebookId: number): Promise<RecognitionTicket[]>;
  detail(
    actor: Actor,
    gradebookId: number,
    ticketId: string,
  ): Promise<RecognitionTicketDetail | null>;
}

export type RecognitionStatus =
  | "DANG_XU_LY"
  | "CHO_DOI_CHIEU"
  | "DA_DUYET"
  | "LOI";

export interface RecognitionTicket {
  ticketId: string;
  gradebookId: number;
  componentId: number;
  componentName: string;
  declaredRows: number;
  detectedRows: number | null;
  status: RecognitionStatus;
  errorCode: string | null;
  modelVersion: string | null;
  version: number;
  createdAt: string;
}

export interface RecognitionEvidenceRow {
  rowId: string;
  order: number;
  studentId: number;
  studentName: string;
  numericRaw: string | null;
  numericValue: string | null;
  numericConfidence: string | null;
  writtenRaw: string | null;
  writtenValue: string | null;
  writtenConfidence: string | null;
  comparison: "KHOP" | "LECH" | "MOT_KENH" | "KHONG_DOC_DUOC";
  reviewLevel: "XANH" | "VANG" | "DO";
  finalValue: string | null;
  numericCropKey: string | null;
  writtenCropKey: string | null;
}

export interface RecognitionTicketDetail extends RecognitionTicket {
  sourceObjectKey: string;
  rows: RecognitionEvidenceRow[];
}

export const RECOGNITION_STORE = Symbol("RECOGNITION_STORE");
