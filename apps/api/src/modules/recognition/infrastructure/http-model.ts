import {
  isPipelineErrorCode,
  type ChannelResult,
  type NameResult,
  type RecognitionModelClient,
  type RecognitionResult,
  type RecognitionRowResult,
  type SttResult,
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

function cropBase64(value: unknown): string {
  if (
    typeof value !== "string" ||
    !value ||
    value.length % 4 !== 0 ||
    !/^[A-Za-z0-9+/]+={0,2}$/.test(value)
  )
    return malformed();
  const bytes = Buffer.from(value, "base64");
  if (!bytes.length || bytes.byteLength > MAX_CROP_BYTES) return malformed();
  return value;
}

function row(value: unknown): RecognitionRowResult {
  const input = record(value);
  const numeric = channel(input.numeric);
  const written = channel(input.written);
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
  const levelConsistent =
    (reviewLevel === "DO" && comparison === "KHONG_DOC_DUOC") ||
    (reviewLevel === "XANH" && comparison === "KHOP") ||
    (reviewLevel === "VANG" && comparison !== "KHONG_DOC_DUOC");
  if (!classificationConsistent || !levelConsistent) return malformed();
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
    comparison: comparison as RecognitionRowResult["comparison"],
    reviewLevel: reviewLevel as RecognitionRowResult["reviewLevel"],
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
