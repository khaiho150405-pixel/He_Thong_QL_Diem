import { createHash } from "node:crypto";
import type { ObjectStorage } from "../../files/application/port.js";

export type ChannelResult = {
  rawOutput: string | null;
  value: string | null;
  confidence: string | null;
  isBlank: boolean;
};

export type RecognitionRowResult = {
  order: number;
  numeric: ChannelResult;
  written: ChannelResult;
  numericCropBase64: string;
  writtenCropBase64: string;
  comparison: "KHOP" | "LECH" | "MOT_KENH" | "KHONG_DOC_DUOC";
  reviewLevel: "XANH" | "VANG" | "DO";
};

export type RecognitionResult = {
  detectedRows: number;
  modelVersion: string;
  rows: RecognitionRowResult[];
};

export interface RecognitionModelClient {
  recognize(
    image: Uint8Array,
    declaredRows: number,
  ): Promise<RecognitionResult>;
}

export interface RecognitionWorkerStore {
  load(ticketId: string): Promise<{
    status: "DANG_XU_LY" | "CHO_DOI_CHIEU" | "DA_DUYET" | "LOI";
    objectKey: string;
    declaredRows: number;
  } | null>;
  complete(
    ticketId: string,
    modelVersion: string,
    rows: unknown[],
  ): Promise<void>;
  fail(ticketId: string, code: string): Promise<void>;
}

function crop(value: string): Uint8Array {
  if (!/^[A-Za-z0-9+/]+={0,2}$/.test(value))
    throw new Error("MALFORMED_RESPONSE");
  const bytes = Buffer.from(value, "base64");
  if (!bytes.length || bytes.byteLength > 2 * 1024 * 1024)
    throw new Error("MALFORMED_RESPONSE");
  return bytes;
}

export class RecognitionJobProcessor {
  constructor(
    private readonly store: RecognitionWorkerStore,
    private readonly storage: ObjectStorage,
    private readonly model: RecognitionModelClient,
  ) {}

  async process(ticketId: string): Promise<void> {
    const ticket = await this.store.load(ticketId);
    if (!ticket) throw new Error("TICKET_NOT_FOUND");
    if (["CHO_DOI_CHIEU", "DA_DUYET"].includes(ticket.status)) return;
    if (ticket.status === "LOI") return;
    const image = await this.storage.get(ticket.objectKey);
    const result = await this.model.recognize(image, ticket.declaredRows);
    if (
      result.detectedRows !== ticket.declaredRows ||
      result.rows.length !== ticket.declaredRows ||
      result.rows.some((row, index) => row.order !== index + 1)
    ) {
      await this.store.fail(ticketId, "GRID_ROW_COUNT_MISMATCH");
      return;
    }
    const stored: unknown[] = [];
    const uploaded: string[] = [];
    try {
      for (const row of result.rows) {
        const numberBytes = crop(row.numericCropBase64);
        const writtenBytes = crop(row.writtenCropBase64);
        const prefix = `recognition/crops/${ticketId}/${row.order}`;
        const numericKey = `${prefix}-numeric.png`;
        const writtenKey = `${prefix}-written.png`;
        for (const [key, bytes] of [
          [numericKey, numberBytes],
          [writtenKey, writtenBytes],
        ] as const) {
          await this.storage.put({
            key,
            bytes,
            contentType: "image/png",
            checksum: createHash("sha256").update(bytes).digest("hex"),
          });
          uploaded.push(key);
        }
        stored.push({
          order: row.order,
          numeric: row.numeric,
          written: row.written,
          numericCropKey: numericKey,
          writtenCropKey: writtenKey,
          comparison: row.comparison,
          reviewLevel: row.reviewLevel,
        });
      }
      await this.store.complete(ticketId, result.modelVersion, stored);
    } catch (error) {
      await Promise.allSettled(uploaded.map((key) => this.storage.remove(key)));
      throw error;
    }
  }
}
