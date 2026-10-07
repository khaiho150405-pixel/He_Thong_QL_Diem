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
  /** Số dòng theo mức cuối (điểm + ghép học sinh); 0 khi chưa có kết quả. */
  greenRows: number;
  yellowRows: number;
  redRows: number;
}

export type SuggestedSource = "SO" | "CHU";

export interface RecognitionEvidenceRow {
  rowId: string;
  /** Vị trí dòng trên ảnh. */
  order: number;
  /** STT hệ thống trong danh sách lớp đã chốt của phiếu; null với phiếu cũ không có snapshot. */
  stt: number | null;
  /** STT in trên giấy đọc được. */
  sttOnPaper: number | null;
  studentId: number;
  studentName: string;
  /** Họ tên máy đọc được trên giấy (để so với studentName). */
  nameRead: string | null;
  /** 0..1, 4 chữ số thập phân. */
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
  /** Kênh cho giá trị gợi ý (SO = điểm số, CHU = điểm chữ); null khi Đỏ: không gợi ý giá trị. */
  suggestedSource: SuggestedSource | null;
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

// Contract with the recognition service (POST /v1/recognize, ADR-0015). The service
// never receives the class roster; the API matches rows to students itself.
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
  /** Position of the row on the photo, starting at 1. */
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
  /** Kênh có giá trị được gợi ý theo luật hợp nhất hai kênh; null khi Đỏ. */
  suggestedSource: SuggestedSource | null;
};

export type RecognitionResult = {
  modelVersion: string;
  /** First STT printed on this page, when the model could infer it. */
  pageStartStt: number | null;
  rows: RecognitionRowResult[];
};

/**
 * Mã lỗi ổn định khi dịch vụ nhận dạng từ chối ảnh (HTTP 422): ảnh không dùng được, phải chụp lại.
 * Khác lỗi hạ tầng (MODEL_UNAVAILABLE, RECOGNITION_TIMEOUT, ...) có thể thử lại.
 */
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
