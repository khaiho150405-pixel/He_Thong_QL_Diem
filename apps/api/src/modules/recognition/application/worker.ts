import { createHash } from "node:crypto";
import type { ObjectStorage } from "../../files/application/port.js";
import {
  combineLevel,
  matchRows,
  type DetectedRow,
  type RosterEntry,
} from "../domain/row-matching.js";
import {
  isPipelineErrorCode,
  type RecognitionModelClient,
  type RecognitionRowResult,
} from "./port.js";

export type {
  ChannelResult,
  NameResult,
  RecognitionModelClient,
  RecognitionResult,
  RecognitionRowResult,
  SttResult,
} from "./port.js";

export interface RecognitionWorkerStore {
  load(ticketId: string): Promise<{
    status: "DANG_XU_LY" | "CHO_DOI_CHIEU" | "DA_DUYET" | "LOI" | "DA_HUY";
    objectKey: string;
  } | null>;
  roster(ticketId: string): Promise<RosterEntry[]>;
  complete(
    ticketId: string,
    modelVersion: string,
    rows: unknown[],
  ): Promise<void>;
  fail(ticketId: string, code: string): Promise<void>;
}

export function crop(value: string): Uint8Array {
  if (!/^[A-Za-z0-9+/]+={0,2}$/.test(value))
    throw new Error("MALFORMED_RESPONSE");
  const bytes = Buffer.from(value, "base64");
  if (!bytes.length || bytes.byteLength > 2 * 1024 * 1024)
    throw new Error("MALFORMED_RESPONSE");
  return bytes;
}

function number(value: string | null): number | null {
  return value === null ? null : Number(value);
}

function detected(row: RecognitionRowResult): DetectedRow {
  return {
    rowIndex: row.rowIndex,
    struck: row.struck,
    sttValue: row.stt.value,
    sttConfidence: number(row.stt.confidence),
    nameRaw: row.name.raw,
    nameConfidence: number(row.name.confidence),
    hasGradeInk: !row.numeric.isBlank || !row.written.isBlank,
    hasNameInk: !row.name.isBlank,
  };
}

export class RecognitionJobProcessor {
  constructor(
    private readonly store: RecognitionWorkerStore,
    private readonly storage: ObjectStorage,
    private readonly model: RecognitionModelClient,
    private readonly options: { sttCheck?: boolean } = {},
  ) {}

  private logCancelled(ticketId: string): void {
    console.log(
      JSON.stringify({ event: "recognition_ticket_cancelled", ticketId }),
    );
  }

  async process(ticketId: string): Promise<void> {
    const ticket = await this.store.load(ticketId);
    if (!ticket) throw new Error("TICKET_NOT_FOUND");
    if (ticket.status === "DA_HUY") {
      this.logCancelled(ticketId);
      return;
    }
    if (["CHO_DOI_CHIEU", "DA_DUYET"].includes(ticket.status)) return;
    if (ticket.status === "LOI") return;
    const roster = await this.store.roster(ticketId);
    if (!roster.length) {
      await this.store.fail(ticketId, "ROW_MATCH_FAILED");
      return;
    }
    const image = await this.storage.get(ticket.objectKey);
    let result;
    try {
      result = await this.model.recognize(image);
    } catch (error) {
      if (error instanceof Error && isPipelineErrorCode(error.message)) {
        await this.store.fail(ticketId, error.message);
        return;
      }
      throw error;
    }
    const matched = matchRows(result.rows.map(detected), roster, {
      sttCheck: this.options.sttCheck === true,
    });
    if (!matched.ok) {
      await this.store.fail(ticketId, matched.code);
      return;
    }
    if (matched.stt.enabled)
      console.log(
        JSON.stringify({
          event: "recognition_stt_model",
          ticketId,
          model: matched.stt.model,
          evidence: matched.stt.evidence,
        }),
      );
    const byIndex = new Map(result.rows.map((row) => [row.rowIndex, row]));
    const stored: unknown[] = [];
    const uploaded: string[] = [];
    try {
      for (const match of matched.matches) {
        const row = byIndex.get(match.rowIndex)!;
        const prefix = `recognition/crops/${ticketId}/${row.rowIndex}`;
        const numericKey = `${prefix}-numeric.png`;
        const writtenKey = `${prefix}-written.png`;
        const nameKey = `${prefix}-name.png`;
        for (const [key, value] of [
          [numericKey, row.numericCropBase64],
          [writtenKey, row.writtenCropBase64],
          [nameKey, row.nameCropBase64],
        ] as const) {
          const bytes = crop(value);
          await this.storage.put({
            key,
            bytes,
            contentType: "image/png",
            checksum: createHash("sha256").update(bytes).digest("hex"),
          });
          uploaded.push(key);
        }
        stored.push({
          order: row.rowIndex,
          stt: match.stt,
          sttOnPaper: match.sttOnPaper,
          nameRead: match.nameRead,
          matchConfidence: match.matchConfidence,
          matchNote: match.note,
          numeric: row.numeric,
          written: row.written,
          numericCropKey: numericKey,
          writtenCropKey: writtenKey,
          nameCropKey: nameKey,
          comparison: row.comparison,
          suggestedSource: row.suggestedSource,
          matchLevel: match.matchLevel,
          reviewLevel: combineLevel(row.reviewLevel, match.matchLevel),
        });
      }
      await this.store.complete(ticketId, result.modelVersion, stored);
    } catch (error) {
      await Promise.allSettled(uploaded.map((key) => this.storage.remove(key)));
      throw error;
    }
    if ((await this.store.load(ticketId))?.status === "DA_HUY") {
      await Promise.allSettled(uploaded.map((key) => this.storage.remove(key)));
      this.logCancelled(ticketId);
    }
  }
}
