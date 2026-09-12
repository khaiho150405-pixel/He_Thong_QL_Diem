import type {
  RecognitionModelClient,
  RecognitionResult,
} from "../application/worker.js";

type Fetch = typeof fetch;

function validDecimal(value: unknown, max: number): value is string | null {
  if (value === null) return true;
  return (
    typeof value === "string" &&
    /^(0|[1-9]|10)([.]\d)?$/.test(value) &&
    Number(value) <= max
  );
}

function validate(body: unknown): RecognitionResult {
  const value = body as Record<string, unknown>;
  if (
    !value ||
    !Number.isInteger(value.detectedRows) ||
    typeof value.modelVersion !== "string" ||
    !value.modelVersion ||
    !Array.isArray(value.rows)
  )
    throw new Error("MALFORMED_RESPONSE");
  for (const entry of value.rows) {
    const row = entry as Record<string, unknown>;
    if (!Number.isInteger(row.order)) throw new Error("MALFORMED_RESPONSE");
    for (const name of ["numeric", "written"] as const) {
      const channel = row[name] as Record<string, unknown>;
      if (
        !channel ||
        (channel.rawOutput !== null && typeof channel.rawOutput !== "string") ||
        (typeof channel.rawOutput === "string" &&
          channel.rawOutput.length > 1_000) ||
        !validDecimal(channel.value, 10) ||
        !validDecimal(channel.confidence, 1) ||
        typeof channel.isBlank !== "boolean" ||
        (channel.isBlank && channel.value !== null)
      )
        throw new Error("MALFORMED_RESPONSE");
    }
    if (
      typeof row.numericCropBase64 !== "string" ||
      typeof row.writtenCropBase64 !== "string" ||
      !["KHOP", "LECH", "MOT_KENH", "KHONG_DOC_DUOC"].includes(
        String(row.comparison),
      ) ||
      !["XANH", "VANG", "DO"].includes(String(row.reviewLevel))
    )
      throw new Error("MALFORMED_RESPONSE");
    const numeric = row.numeric as Record<string, unknown>;
    const written = row.written as Record<string, unknown>;
    const numericReadable = !numeric.isBlank && numeric.value !== null;
    const writtenReadable = !written.isBlank && written.value !== null;
    const comparison = String(row.comparison);
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
      (row.reviewLevel === "DO" && comparison === "KHONG_DOC_DUOC") ||
      (row.reviewLevel === "XANH" && comparison === "KHOP") ||
      (row.reviewLevel === "VANG" && comparison !== "KHONG_DOC_DUOC");
    if (!classificationConsistent || !levelConsistent)
      throw new Error("MALFORMED_RESPONSE");
  }
  return value as RecognitionResult;
}

export class HttpRecognitionModel implements RecognitionModelClient {
  constructor(
    private readonly url: string,
    private readonly request: Fetch = fetch,
    private readonly timeoutMs = 30_000,
  ) {}

  async recognize(image: Uint8Array, declaredRows: number) {
    const form = new FormData();
    form.set("declaredRows", String(declaredRows));
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
    if (!response.ok) throw new Error("RECOGNITION_SERVICE_ERROR");
    try {
      const body = await response.text();
      if (body.length > 25 * 1024 * 1024) throw new Error("MALFORMED_RESPONSE");
      return validate(JSON.parse(body));
    } catch (error) {
      if (error instanceof Error && error.message === "MALFORMED_RESPONSE")
        throw error;
      throw new Error("MALFORMED_RESPONSE");
    }
  }
}
