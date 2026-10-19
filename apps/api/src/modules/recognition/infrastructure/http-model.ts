import {
  isPipelineErrorCode,
  type ChannelResult,
  type NameResult,
  type RecognitionModelClient,
  type RecognitionResult,
  type RecognitionRowResult,
  type SttResult,
  type SuggestedSource,
} from "../application/port.js";

type Fetch = typeof fetch;

const MALFORMED = "MALFORMED_RESPONSE";
const MAX_ROWS = 2_000;
const MAX_ROW_INDEX = 9_999;
const MAX_CROP_BYTES = 2 * 1024 * 1024;
const DEFAULT_TIMEOUT_MS = 120_000;

function malformed(): never {
  throw new Error(MALFORMED);
}

function record(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value))
    return malformed();
  return value as Record<string, unknown>;
}

function nullableText(value: unknown, max: number): string | null {
  if (value === null) return null;
  if (typeof value !== "string" || value.length > max) return malformed();
  return value;
}

// Grades are decimal strings with at most one fractional digit, 0.0–10.0.
function grade(value: unknown): string | null {
  if (value === null) return null;
  if (typeof value !== "string" || !/^(10(\.0)?|[0-9](\.[0-9])?)$/.test(value))
    return malformed();
  return value;
}

// Confidence is a decimal string in 0..1 with up to four fractional digits.
function confidence(value: unknown): string | null {
  if (value === null) return null;
  if (
    typeof value !== "string" ||
    !/^(0(\.[0-9]{1,4})?|1(\.0{1,4})?)$/.test(value)
  )
    return malformed();
  return value;
}

function flag(value: unknown): boolean {
  if (typeof value !== "boolean") return malformed();
  return value;
}

function integer(value: unknown, min: number, max: number): number {
  if (!Number.isInteger(value)) return malformed();
  const number = value as number;
  if (number < min || number > max) return malformed();
  return number;
}

function channel(value: unknown): ChannelResult {
  const input = record(value);
  const result: ChannelResult = {
    rawOutput: nullableText(input.rawOutput, 1_000),
    value: grade(input.value),
    confidence: confidence(input.confidence),
    isBlank: flag(input.isBlank),
  };
  if (result.isBlank && result.value !== null) return malformed();
  return result;
}

function stt(value: unknown): SttResult {
  const input = record(value);
  const result: SttResult = {
    raw: nullableText(input.raw, 32),
    value: input.value === null ? null : integer(input.value, 1, 999_999_999),
    confidence: confidence(input.confidence),
    isBlank: flag(input.isBlank),
  };
  if (result.isBlank && result.value !== null) return malformed();
  return result;
}

function name(value: unknown): NameResult {
  const input = record(value);
  return {
    raw: nullableText(input.raw, 150),
    confidence: confidence(input.confidence),
    isBlank: flag(input.isBlank),
  };
}

// Ảnh xem trước trang (/v2/layout/analyze) là cả trang rộng 1400 px; ảnh điện thoại có thể 4–5 MiB PNG,
// nên có giới hạn riêng, lớn hơn giới hạn ảnh ô cắt.
const MAX_PREVIEW_BYTES = 12 * 1024 * 1024;

function cropBase64(value: unknown, maxBytes: number = MAX_CROP_BYTES): string {
  if (
    typeof value !== "string" ||
    !value ||
    value.length % 4 !== 0 ||
    !/^[A-Za-z0-9+/]+={0,2}$/.test(value)
  )
    return malformed();
  const bytes = Buffer.from(value, "base64");
  if (!bytes.length || bytes.byteLength > maxBytes) return malformed();
  return value;
}

/**
 * Kiểm phân loại của một ô khớp luật hợp nhất hai kênh (ADR-0015) với giá trị hai kênh; dùng chung cho v1 (`row`) và v2
 * (`gradeCell`). Ném MALFORMED_RESPONSE khi không khớp. Kênh chữ vắng (cột một kênh v2) truyền vào là kênh trống.
 */
function checkedClassification(
  input: Record<string, unknown>,
  numeric: ChannelResult,
  written: ChannelResult,
): {
  comparison: RecognitionRowResult["comparison"];
  reviewLevel: RecognitionRowResult["reviewLevel"];
  suggestedSource: SuggestedSource | null;
} {
  const comparison = input.comparison;
  const reviewLevel = input.reviewLevel;
  if (
    typeof comparison !== "string" ||
    !["KHOP", "LECH", "MOT_KENH", "KHONG_DOC_DUOC"].includes(comparison) ||
    typeof reviewLevel !== "string" ||
    !["XANH", "VANG", "DO"].includes(reviewLevel)
  )
    return malformed();
  const numericReadable = !numeric.isBlank && numeric.value !== null;
  const writtenReadable = !written.isBlank && written.value !== null;
  const classificationConsistent =
    (comparison === "KHOP" &&
      numericReadable &&
      writtenReadable &&
      numeric.value === written.value) ||
    (comparison === "LECH" &&
      numericReadable &&
      writtenReadable &&
      numeric.value !== written.value) ||
    (comparison === "MOT_KENH" && numericReadable !== writtenReadable) ||
    (comparison === "KHONG_DOC_DUOC" && !numericReadable && !writtenReadable);
  // Luật hợp nhất hai kênh: Xanh chỉ khi hai kênh đồng thuận; Đỏ không gợi ý giá trị; Xanh/Vàng gợi ý giá trị của một
  // kênh ĐỌC ĐƯỢC (SO = điểm số, CHU = điểm chữ).
  const suggestedSource = input.suggestedSource as SuggestedSource | null;
  if (
    suggestedSource !== null &&
    suggestedSource !== "SO" &&
    suggestedSource !== "CHU"
  )
    return malformed();
  const suggestionConsistent =
    reviewLevel === "DO"
      ? suggestedSource === null
      : (suggestedSource === "SO" && numericReadable) ||
        (suggestedSource === "CHU" && writtenReadable);
  const levelConsistent =
    (comparison === "KHONG_DOC_DUOC" && reviewLevel === "DO") ||
    (comparison !== "KHONG_DOC_DUOC" &&
      (reviewLevel === "VANG" ||
        (reviewLevel === "XANH" && comparison === "KHOP") ||
        (reviewLevel === "DO" && comparison !== "KHOP")));
  if (!classificationConsistent || !levelConsistent || !suggestionConsistent)
    return malformed();
  return {
    comparison: comparison as RecognitionRowResult["comparison"],
    reviewLevel: reviewLevel as RecognitionRowResult["reviewLevel"],
    suggestedSource,
  };
}

function row(value: unknown): RecognitionRowResult {
  const input = record(value);
  const numeric = channel(input.numeric);
  const written = channel(input.written);
  const { comparison, reviewLevel, suggestedSource } = checkedClassification(
    input,
    numeric,
    written,
  );
  return {
    rowIndex: integer(input.rowIndex, 1, MAX_ROW_INDEX),
    struck: flag(input.struck),
    stt: stt(input.stt),
    name: name(input.name),
    numeric,
    written,
    numericCropBase64: cropBase64(input.numericCropBase64),
    writtenCropBase64: cropBase64(input.writtenCropBase64),
    nameCropBase64: cropBase64(input.nameCropBase64),
    comparison,
    reviewLevel,
    suggestedSource,
  };
}

export function parseRecognitionResponse(body: unknown): RecognitionResult {
  const input = record(body);
  if (
    typeof input.modelVersion !== "string" ||
    !input.modelVersion ||
    input.modelVersion.length > 80 ||
    !Array.isArray(input.rows) ||
    input.rows.length > MAX_ROWS
  )
    return malformed();
  const rows = input.rows.map(row);
  if (new Set(rows.map((item) => item.rowIndex)).size !== rows.length)
    return malformed();
  return {
    modelVersion: input.modelVersion,
    pageStartStt:
      input.pageStartStt === null
        ? null
        : integer(input.pageStartStt, 1, 999_999_999),
    rows,
  };
}

export class HttpRecognitionModel implements RecognitionModelClient {
  constructor(
    private readonly url: string,
    private readonly request: Fetch = fetch,
    private readonly timeoutMs = DEFAULT_TIMEOUT_MS,
  ) {}

  async recognize(image: Uint8Array) {
    // The service only receives the photo: no class roster and no declared row count.
    const form = new FormData();
    form.set(
      "image",
      new Blob([image as Uint8Array<ArrayBuffer>]),
      "sheet.png",
    );
    let response: Response;
    try {
      response = await this.request(`${this.url}/v1/recognize`, {
        method: "POST",
        body: form,
        signal: AbortSignal.timeout(this.timeoutMs),
      });
    } catch {
      throw new Error("RECOGNITION_TIMEOUT");
    }
    if (response.status === 503) throw new Error("MODEL_UNAVAILABLE");
    if (response.status === 422) {
      // Ảnh bị từ chối kèm mã ổn định: {"detail": {"code": "...", "message": "..."}}.
      let code: unknown;
      try {
        code = (
          JSON.parse(await response.text()) as { detail?: { code?: unknown } }
        ).detail?.code;
      } catch {
        code = undefined;
      }
      throw new Error(
        isPipelineErrorCode(code) ? code : "RECOGNITION_SERVICE_ERROR",
      );
    }
    if (!response.ok) throw new Error("RECOGNITION_SERVICE_ERROR");
    try {
      const body = await response.text();
      if (body.length > 25 * 1024 * 1024) return malformed();
      return parseRecognitionResponse(JSON.parse(body));
    } catch (error) {
      if (error instanceof Error && error.message === MALFORMED) throw error;
      throw new Error(MALFORMED);
    }
  }
}

// ── Contract v2 (ADR-0016): phân tích bố cục và đọc nhiều cột theo mẫu. v1 ở trên không đổi. ──

export type LayoutSignature = {
  version: 1;
  columnWidths: number[];
  headerTexts: string[];
  headerRows: number;
  rowHeightMm: number;
  tableWidthMm: number;
};

export type SuggestedRole = "STT" | "HO_TEN" | "DIEM" | "DIEM_CHU" | "BO_QUA";
export type GradeGroup = "TX" | "GK" | "CK";

export type AnalyzedColumn = {
  index: number;
  /** Tỉ lệ 0–1 theo bề rộng bảng. */
  x0: number;
  x1: number;
  widthMm: number;
  headerText: string;
  /** null khi không đọc được tiêu đề. */
  suggestedRole: SuggestedRole | null;
  suggestedGroup: GradeGroup | null;
  suggestedOrder: number | null;
};

export type LayoutAnalysis = {
  signature: LayoutSignature;
  columns: AnalyzedColumn[];
  previewPngBase64: string;
};

/** `layout` gửi tới POST /v2/recognize: `index` là chỉ số cột của MẪU, chỉ gồm cột cần đọc. */
export type V2Layout = {
  signature: LayoutSignature;
  columns: Array<{
    index: number;
    role: "STT" | "HO_TEN" | "DIEM" | "DIEM_CHU";
    key?: string;
    writtenIndex?: number | null;
  }>;
};

export type V2Grade = {
  key: string;
  numeric: ChannelResult;
  /** null với cột chỉ có kênh số (tối đa Vàng, D-01). */
  written: ChannelResult | null;
  numericCropBase64: string;
  writtenCropBase64: string | null;
  comparison: RecognitionRowResult["comparison"];
  reviewLevel: RecognitionRowResult["reviewLevel"];
  suggestedSource: SuggestedSource | null;
};

export type V2Row = {
  rowIndex: number;
  struck: boolean;
  stt: SttResult;
  name: NameResult;
  nameCropBase64: string;
  sttRead: number | null;
  sttFromPosition: number | null;
  grades: V2Grade[];
};

export type V2Result = {
  modelVersion: string;
  pageStartStt: number | null;
  templateMatch: { score: number; columnMap: Record<number, number> };
  rows: V2Row[];
};

/** Mã lỗi 422 của contract v2: mã v1 cộng TEMPLATE_MISMATCH (kèm details) và INVALID_LAYOUT. */
const V2_ERROR_CODES = new Set<string>([
  "IMAGE_UNREADABLE",
  "IMAGE_QUALITY_LOW",
  "GRID_NOT_FOUND",
  "NOT_A_GRADEBOOK",
  "SCORE_COLUMN_NOT_FOUND",
  "TEMPLATE_MISMATCH",
  "INVALID_LAYOUT",
]);

/** Lỗi của dịch vụ nhận dạng v2. `code` ổn định; `details` chỉ có ở TEMPLATE_MISMATCH. */
export class RecognitionV2Error extends Error {
  constructor(
    readonly code: string,
    readonly details: Record<string, unknown> | null = null,
  ) {
    super(code);
  }
}

function finiteNumber(value: unknown, min: number, max: number): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return malformed();
  if (value < min || value > max) return malformed();
  return value;
}

function optionalInteger(
  value: unknown,
  min: number,
  max: number,
): number | null {
  return value === null || value === undefined
    ? null
    : integer(value, min, max);
}

function layoutSignature(value: unknown): LayoutSignature {
  const input = record(value);
  if (input.version !== 1) return malformed();
  if (
    !Array.isArray(input.columnWidths) ||
    input.columnWidths.length < 2 ||
    input.columnWidths.length > 64 ||
    !Array.isArray(input.headerTexts) ||
    input.headerTexts.length > 64
  )
    return malformed();
  return {
    version: 1,
    columnWidths: input.columnWidths.map((item) =>
      finiteNumber(item, Number.MIN_VALUE, 1_000_000),
    ),
    headerTexts: input.headerTexts.map((item) => {
      if (typeof item !== "string" || item.length > 200) return malformed();
      return item;
    }),
    headerRows: integer(input.headerRows, 0, 100),
    rowHeightMm: finiteNumber(input.rowHeightMm, 0, 10_000),
    tableWidthMm: finiteNumber(input.tableWidthMm, 0, 100_000),
  };
}

const SUGGESTED_ROLES = ["STT", "HO_TEN", "DIEM", "DIEM_CHU", "BO_QUA"];
const GRADE_GROUPS = ["TX", "GK", "CK"];

function analyzedColumn(value: unknown): AnalyzedColumn {
  const input = record(value);
  const suggestedRole = input.suggestedRole ?? null;
  const suggestedGroup = input.suggestedGroup ?? null;
  if (
    suggestedRole !== null &&
    (typeof suggestedRole !== "string" ||
      !SUGGESTED_ROLES.includes(suggestedRole))
  )
    return malformed();
  if (
    suggestedGroup !== null &&
    (typeof suggestedGroup !== "string" ||
      !GRADE_GROUPS.includes(suggestedGroup))
  )
    return malformed();
  const headerText = input.headerText;
  if (typeof headerText !== "string" || headerText.length > 200)
    return malformed();
  return {
    index: integer(input.index, 0, 63),
    x0: finiteNumber(input.x0, 0, 1),
    x1: finiteNumber(input.x1, 0, 1),
    widthMm: finiteNumber(input.widthMm, 0, 100_000),
    headerText,
    suggestedRole: suggestedRole as SuggestedRole | null,
    suggestedGroup: suggestedGroup as GradeGroup | null,
    suggestedOrder: optionalInteger(input.suggestedOrder, 1, 99),
  };
}

export function parseLayoutAnalysis(body: unknown): LayoutAnalysis {
  const input = record(body);
  if (!Array.isArray(input.columns) || input.columns.length > 64)
    return malformed();
  const signature = layoutSignature(input.signature);
  const columns = input.columns.map(analyzedColumn);
  if (
    columns.length !== signature.columnWidths.length ||
    columns.some((column, position) => column.index !== position)
  )
    return malformed();
  return {
    signature,
    columns,
    previewPngBase64: cropBase64(input.previewPngBase64, MAX_PREVIEW_BYTES),
  };
}

function gradeCell(value: unknown): V2Grade {
  const input = record(value);
  if (typeof input.key !== "string" || !/^[A-Za-z0-9_-]{1,32}$/.test(input.key))
    return malformed();
  const numeric = channel(input.numeric);
  const written = input.written === null ? null : channel(input.written);
  const writtenCrop =
    input.writtenCropBase64 === null
      ? null
      : cropBase64(input.writtenCropBase64);
  // Ô một kênh: không có kênh chữ lẫn ảnh cắt chữ; ô hai kênh có cả hai.
  if ((written === null) !== (writtenCrop === null)) return malformed();
  const { comparison, reviewLevel, suggestedSource } = checkedClassification(
    input,
    numeric,
    written ?? {
      rawOutput: null,
      value: null,
      confidence: null,
      isBlank: true,
    },
  );
  // Cột một kênh không bao giờ Xanh và chỉ gợi ý từ kênh số (D-01).
  if (written === null && (reviewLevel === "XANH" || suggestedSource === "CHU"))
    return malformed();
  return {
    key: input.key,
    numeric,
    written,
    numericCropBase64: cropBase64(input.numericCropBase64),
    writtenCropBase64: writtenCrop,
    comparison,
    reviewLevel,
    suggestedSource,
  };
}

function rowV2(value: unknown): V2Row {
  const input = record(value);
  if (!Array.isArray(input.grades) || input.grades.length > 64)
    return malformed();
  const grades = input.grades.map(gradeCell);
  if (new Set(grades.map((item) => item.key)).size !== grades.length)
    return malformed();
  return {
    rowIndex: integer(input.rowIndex, 1, MAX_ROW_INDEX),
    struck: flag(input.struck),
    stt: stt(input.stt),
    name: name(input.name),
    nameCropBase64: cropBase64(input.nameCropBase64),
    sttRead: optionalInteger(input.sttRead, 1, 999_999_999),
    sttFromPosition: optionalInteger(input.sttFromPosition, 1, 999_999_999),
    grades,
  };
}

export function parseRecognitionV2Response(body: unknown): V2Result {
  const input = record(body);
  if (
    typeof input.modelVersion !== "string" ||
    !input.modelVersion ||
    input.modelVersion.length > 80 ||
    !Array.isArray(input.rows) ||
    input.rows.length > MAX_ROWS
  )
    return malformed();
  const match = record(input.templateMatch);
  const columnMap = record(match.columnMap);
  const rows = input.rows.map(rowV2);
  if (new Set(rows.map((item) => item.rowIndex)).size !== rows.length)
    return malformed();
  return {
    modelVersion: input.modelVersion,
    pageStartStt: optionalInteger(input.pageStartStt, 1, 999_999_999),
    templateMatch: {
      score: finiteNumber(match.score, 0, 1),
      columnMap: Object.fromEntries(
        Object.entries(columnMap).map(([from, to]) => {
          if (!/^[0-9]{1,2}$/.test(from)) return malformed();
          return [Number(from), integer(to, 0, 63)];
        }),
      ),
    },
    rows,
  };
}

export interface RecognitionV2Client {
  /** POST /v2/layout/analyze: không lưu gì, không đọc điểm. */
  analyzeLayout(image: Uint8Array): Promise<LayoutAnalysis>;
  /** POST /v2/recognize đồng bộ với `layout` dựng từ cột mẫu. */
  recognize(image: Uint8Array, layout: V2Layout): Promise<V2Result>;
}

/** Client v2 chưa cấu hình dịch vụ nhận dạng (export OpenAPI, test): mọi lời gọi báo MODEL_UNAVAILABLE. */
export class UnconfiguredRecognitionV2Client implements RecognitionV2Client {
  async analyzeLayout(): Promise<LayoutAnalysis> {
    throw new RecognitionV2Error("MODEL_UNAVAILABLE");
  }
  async recognize(): Promise<V2Result> {
    throw new RecognitionV2Error("MODEL_UNAVAILABLE");
  }
}

export class HttpRecognitionV2Client implements RecognitionV2Client {
  /**
   * @param analyzeTimeoutMs chờ `/v2/layout/analyze` (cấu hình chung của dịch vụ nhận dạng)
   * @param recognizeTimeoutMs chờ `/v2/recognize` đồng bộ của "thử mẫu" (mặc định 90 s, cấu hình được)
   */
  constructor(
    private readonly url: string,
    private readonly request: Fetch = fetch,
    private readonly analyzeTimeoutMs = DEFAULT_TIMEOUT_MS,
    private readonly recognizeTimeoutMs = 90_000,
  ) {}

  analyzeLayout(image: Uint8Array): Promise<LayoutAnalysis> {
    const form = new FormData();
    form.set(
      "image",
      new Blob([image as Uint8Array<ArrayBuffer>]),
      "template.png",
    );
    return this.post(
      "/v2/layout/analyze",
      form,
      this.analyzeTimeoutMs,
      parseLayoutAnalysis,
    );
  }

  recognize(image: Uint8Array, layout: V2Layout): Promise<V2Result> {
    const form = new FormData();
    form.set(
      "image",
      new Blob([image as Uint8Array<ArrayBuffer>]),
      "sheet.png",
    );
    form.set("layout", JSON.stringify(layout));
    return this.post(
      "/v2/recognize",
      form,
      this.recognizeTimeoutMs,
      parseRecognitionV2Response,
    );
  }

  private async post<T>(
    path: string,
    form: FormData,
    timeoutMs: number,
    parse: (body: unknown) => T,
  ): Promise<T> {
    const signal = AbortSignal.timeout(timeoutMs);
    // Hết hạn có thể xảy ra khi chờ header lẫn khi đọc body: cả hai đều là RECOGNITION_TIMEOUT.
    const timedOut = (error: unknown) =>
      signal.aborted ||
      (error instanceof Error &&
        (error.name === "TimeoutError" || error.name === "AbortError"));
    let response: Response;
    try {
      response = await this.request(`${this.url}${path}`, {
        method: "POST",
        body: form,
        signal,
      });
    } catch (error) {
      throw new RecognitionV2Error(
        timedOut(error) ? "RECOGNITION_TIMEOUT" : "MODEL_UNAVAILABLE",
      );
    }
    if (response.status === 503)
      throw new RecognitionV2Error("MODEL_UNAVAILABLE");
    if (response.status === 422) {
      // {"detail": {"code": "...", "message": "...", "details": {...}}}: chỉ chuyển tiếp mã đã biết và `details` của
      // TEMPLATE_MISMATCH; bỏ message tự do.
      let code: unknown;
      let details: unknown;
      try {
        const detail = (
          JSON.parse(await response.text()) as {
            detail?: { code?: unknown; details?: unknown };
          }
        ).detail;
        code = detail?.code;
        details = detail?.details;
      } catch (error) {
        if (timedOut(error))
          throw new RecognitionV2Error("RECOGNITION_TIMEOUT");
        code = undefined;
      }
      if (typeof code !== "string" || !V2_ERROR_CODES.has(code))
        throw new RecognitionV2Error("RECOGNITION_SERVICE_ERROR");
      throw new RecognitionV2Error(
        code,
        code === "TEMPLATE_MISMATCH" &&
        details &&
        typeof details === "object" &&
        !Array.isArray(details)
          ? (details as Record<string, unknown>)
          : null,
      );
    }
    if (!response.ok) throw new RecognitionV2Error("RECOGNITION_SERVICE_ERROR");
    try {
      const body = await response.text();
      if (body.length > 25 * 1024 * 1024) return malformed();
      return parse(JSON.parse(body));
    } catch (error) {
      if (timedOut(error)) throw new RecognitionV2Error("RECOGNITION_TIMEOUT");
      throw new RecognitionV2Error(MALFORMED);
    }
  }
}
