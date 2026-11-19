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
  checksum: string;
  objectKey: string;
  idempotencyKey: string;
  requestHash: string;
}

export interface CancelRecognitionTicket {
  actor: Actor;
  gradebookId: number;
  ticketId: string;
  expectedVersion: number;
  reason: string;
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
  list(
    actor: Actor,
    gradebookId: number,
    includeCancelled: boolean,
  ): Promise<RecognitionTicket[]>;
  detail(
    actor: Actor,
    gradebookId: number,
    ticketId: string,
  ): Promise<RecognitionTicketDetail | null>;
  cancel(input: CancelRecognitionTicket): Promise<{ objectKeys: string[] }>;
}

export type RecognitionStatus =
  | "DANG_XU_LY"
  | "CHO_DOI_CHIEU"
  | "DA_DUYET"
  | "LOI"
  | "DA_HUY";

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
  cancelReason: string | null;
  cancelledAt: string | null;
  greenRows: number;
  yellowRows: number;
  redRows: number;
}

export type SuggestedSource = "SO" | "CHU";

export interface RecognitionEvidenceRow {
  rowId: string;
  order: number;
  stt: number | null;
  sttOnPaper: number | null;
  studentId: number;
  studentName: string;
  exempt: boolean;
  nameRead: string | null;
  matchConfidence: string | null;
  matchNote: string | null;
  numericRaw: string | null;
  numericValue: string | null;
  numericConfidence: string | null;
  writtenRaw: string | null;
  writtenValue: string | null;
  writtenConfidence: string | null;
  comparison: "KHOP" | "LECH" | "MOT_KENH" | "KHONG_DOC_DUOC";
  reviewLevel: "XANH" | "VANG" | "DO";
  suggestedSource: SuggestedSource | null;
  matchLevel: "XANH" | "VANG" | "DO" | null;
  gradeLevel: "XANH" | "VANG" | "DO" | null;
  finalValue: string | null;
  numericCropKey: string | null;
  writtenCropKey: string | null;
  nameCropKey: string | null;
}

export interface RecognitionTicketDetail extends RecognitionTicket {
  sourceObjectKey: string;
  rows: RecognitionEvidenceRow[];
}

export const RECOGNITION_STORE = Symbol("RECOGNITION_STORE");

export type ChannelResult = {
  rawOutput: string | null;
  value: string | null;
  confidence: string | null;
  isBlank: boolean;
};

export type SttResult = {
  raw: string | null;
  value: number | null;
  confidence: string | null;
  isBlank: boolean;
};

export type NameResult = {
  raw: string | null;
  confidence: string | null;
  isBlank: boolean;
};

export type RecognitionRowResult = {
  rowIndex: number;
  struck: boolean;
  stt: SttResult;
  name: NameResult;
  numeric: ChannelResult;
  written: ChannelResult;
  numericCropBase64: string;
  writtenCropBase64: string;
  nameCropBase64: string;
  comparison: "KHOP" | "LECH" | "MOT_KENH" | "KHONG_DOC_DUOC";
  reviewLevel: "XANH" | "VANG" | "DO";
  suggestedSource: SuggestedSource | null;
};

export type RecognitionResult = {
  modelVersion: string;
  pageStartStt: number | null;
  rows: RecognitionRowResult[];
};

export const PIPELINE_ERROR_CODES = [
  "IMAGE_UNREADABLE",
  "IMAGE_QUALITY_LOW",
  "GRID_NOT_FOUND",
  "NOT_A_GRADEBOOK",
  "SCORE_COLUMN_NOT_FOUND",
] as const;
export type PipelineErrorCode = (typeof PIPELINE_ERROR_CODES)[number];

export function isPipelineErrorCode(
  value: unknown,
): value is PipelineErrorCode {
  return (
    typeof value === "string" &&
    (PIPELINE_ERROR_CODES as readonly string[]).includes(value)
  );
}

export interface RecognitionModelClient {
  recognize(image: Uint8Array): Promise<RecognitionResult>;
}
