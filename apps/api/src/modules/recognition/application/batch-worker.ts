import { createHash } from "node:crypto";
import type { ObjectStorage } from "../../files/application/port.js";
import {
  gradeKey,
  recognitionColumnsFor,
  type TemplateColumn,
} from "../../form-templates/public.js";
import {
  combineLevel,
  matchBatchRows,
  type BatchDetectedRow,
  type RosterEntry,
} from "../domain/row-matching.js";
import type {
  LayoutSignature,
  RecognitionV2Client,
  V2Layout,
  V2Result,
  V2Row,
} from "../infrastructure/http-model.js";
import type { BatchStatus } from "./batch-port.js";
import type { ChannelResult } from "./port.js";
import { isPipelineErrorCode } from "./port.js";
import { crop } from "./worker.js";

export interface BatchWorkerTicket {
  ticketId: string;
  status: "DANG_XU_LY" | "CHO_DOI_CHIEU" | "DA_DUYET" | "LOI" | "DA_HUY";
  templateColumnIndex: number;
}

export interface BatchWorkerJob {
  status: BatchStatus;
  signature: LayoutSignature;
  columns: TemplateColumn[];
  pages: Array<{ page: number; objectKey: string }>;
  tickets: BatchWorkerTicket[];
}

export interface RecognitionBatchWorkerStore {
  load(batchId: string): Promise<BatchWorkerJob | null>;
  roster(ticketId: string): Promise<RosterEntry[]>;
  complete(
    batchId: string,
    modelVersion: string,
    tickets: Array<{ ticketId: string; rows: unknown[] }>,
  ): Promise<void>;
  fail(batchId: string, code: string, page: number | null): Promise<void>;
}

function isBatchPipelineError(value: unknown): boolean {
  return (
    isPipelineErrorCode(value) ||
    value === "TEMPLATE_MISMATCH" ||
    value === "INVALID_LAYOUT"
  );
}

const MAX_ROW_PER_PAGE = 999;
const UPLOAD_CONCURRENCY = 8;
const BLANK_CHANNEL: ChannelResult = {
  rawOutput: null,
  value: null,
  confidence: null,
  isBlank: true,
};

function number(value: string | null): number | null {
  return value === null ? null : Number(value);
}

function detected(page: number, row: V2Row): BatchDetectedRow {
  return {
    page,
    rowIndex: row.rowIndex,
    struck: row.struck,
    sttValue: row.stt.value,
    sttConfidence: number(row.stt.confidence),
    nameRaw: row.name.raw,
    nameConfidence: number(row.name.confidence),
    hasGradeInk: row.grades.some(
      (grade) =>
        !grade.numeric.isBlank ||
        (grade.written !== null && !grade.written.isBlank),
    ),
    hasNameInk: !row.name.isBlank,
  };
}

export function assertResponseMatchesLayout(
  result: V2Result,
  expectedKeys: ReadonlySet<string>,
): void {
  for (const row of result.rows) {
    if (
      row.rowIndex > MAX_ROW_PER_PAGE ||
      row.grades.length !== expectedKeys.size
    )
      throw new Error("MALFORMED_RESPONSE");
    for (const grade of row.grades)
      if (!expectedKeys.has(grade.key)) throw new Error("MALFORMED_RESPONSE");
  }
}

async function inChunks<T>(
  items: readonly T[],
  size: number,
  work: (item: T) => Promise<void>,
): Promise<void> {
  for (let index = 0; index < items.length; index += size)
    await Promise.all(items.slice(index, index + size).map(work));
}

export class RecognitionBatchProcessor {
  constructor(
    private readonly store: RecognitionBatchWorkerStore,
    private readonly storage: ObjectStorage,
    private readonly model: RecognitionV2Client,
    private readonly options: { sttCheck?: boolean } = {},
  ) {}

  private logCancelled(batchId: string): void {
    console.log(
      JSON.stringify({ event: "recognition_batch_cancelled", batchId }),
    );
  }

  async process(batchId: string): Promise<void> {
    const job = await this.store.load(batchId);
    if (!job) throw new Error("BATCH_NOT_FOUND");
    if (job.status === "DA_HUY") {
      this.logCancelled(batchId);
      return;
    }
    if (job.status !== "DANG_XU_LY") return;
    const active = job.tickets.filter(
      (ticket) => ticket.status === "DANG_XU_LY",
    );
    if (!active.length) {
      this.logCancelled(batchId);
      return;
    }
    const keyOf = new Map<string, string>();
    for (const ticket of active) {
      const column = job.columns.find(
        (item) => item.index === ticket.templateColumnIndex,
      );
      if (!column || column.role !== "DIEM") {
        await this.store.fail(batchId, "COMPONENT_NOT_MAPPABLE", null);
        return;
      }
      keyOf.set(ticket.ticketId, gradeKey(column.group!, column.order!));
    }
    const expectedKeys = new Set(keyOf.values());
    const roster = await this.store.roster(active[0]!.ticketId);
    if (!roster.length) {
      await this.store.fail(batchId, "ROW_MATCH_FAILED", null);
      return;
    }
    const layout: V2Layout = {
      signature: job.signature,
      columns: recognitionColumnsFor(
        job.columns,
        active.map((ticket) => ticket.templateColumnIndex),
      ),
    };

    const pages: Array<{ page: number; result: V2Result }> = [];
    for (const page of [...job.pages].sort((a, b) => a.page - b.page)) {
      const image = await this.storage.get(page.objectKey);
      let result: V2Result;
      try {
        result = await this.model.recognize(image, layout);
      } catch (error) {
        if (error instanceof Error && isBatchPipelineError(error.message)) {
          await this.store.fail(batchId, error.message, page.page);
          return;
        }
        throw error;
      }
      assertResponseMatchesLayout(result, expectedKeys);
      pages.push({ page: page.page, result });
    }

    const matched = matchBatchRows(
      pages.flatMap(({ page, result }) =>
        result.rows.map((row) => detected(page, row)),
      ),
      roster,
      { sttCheck: this.options.sttCheck === true },
    );
    if (!matched.ok) {
      console.log(
        JSON.stringify({
          event: "recognition_batch_match_failed",
          batchId,
          reason: matched.reason,
        }),
      );
      await this.store.fail(batchId, matched.code, null);
      return;
    }
    if (matched.stt.enabled)
      for (const item of matched.stt.pages)
        console.log(
          JSON.stringify({
            event: "recognition_stt_model",
            batchId,
            page: item.page,
            model: item.model,
            evidence: item.evidence,
          }),
        );

    const rowAt = new Map<string, V2Row>();
    for (const { page, result } of pages)
      for (const row of result.rows) rowAt.set(`${page}:${row.rowIndex}`, row);

    const uploads: Array<{ ticketId: string; key: string; bytes: Uint8Array }> =
      [];
    const tickets = active.map((ticket) => {
      const key = keyOf.get(ticket.ticketId)!;
      const rows = matched.matches.map((match) => {
        const row = rowAt.get(`${match.page}:${match.rowIndex}`)!;
        const grade = row.grades.find((item) => item.key === key)!;
        const order = (match.page - 1) * 1000 + match.rowIndex;
        const prefix = `recognition/crops/${ticket.ticketId}/${order}`;
        const numericKey = `${prefix}-numeric.png`;
        const writtenKey =
          grade.writtenCropBase64 === null ? null : `${prefix}-written.png`;
        const nameKey = `${prefix}-name.png`;
        uploads.push(
          {
            ticketId: ticket.ticketId,
            key: numericKey,
            bytes: crop(grade.numericCropBase64),
          },
          {
            ticketId: ticket.ticketId,
            key: nameKey,
            bytes: crop(row.nameCropBase64),
          },
        );
        if (writtenKey !== null)
          uploads.push({
            ticketId: ticket.ticketId,
            key: writtenKey,
            bytes: crop(grade.writtenCropBase64!),
          });
        return {
          order,
          page: match.page,
          stt: match.stt,
          sttOnPaper: match.sttOnPaper,
          nameRead: match.nameRead,
          matchConfidence: match.matchConfidence,
          matchNote: match.note,
          numeric: grade.numeric,
          written: grade.written ?? BLANK_CHANNEL,
          numericCropKey: numericKey,
          writtenCropKey: writtenKey,
          nameCropKey: nameKey,
          comparison: grade.comparison,
          suggestedSource: grade.suggestedSource,
          matchLevel: match.matchLevel,
          reviewLevel: combineLevel(grade.reviewLevel, match.matchLevel),
        };
      });
      return { ticketId: ticket.ticketId, rows };
    });

    const uploaded: Array<{ ticketId: string; key: string }> = [];
    try {
      await inChunks(uploads, UPLOAD_CONCURRENCY, async (item) => {
        await this.storage.put({
          key: item.key,
          bytes: item.bytes,
          contentType: "image/png",
          checksum: createHash("sha256").update(item.bytes).digest("hex"),
        });
        uploaded.push({ ticketId: item.ticketId, key: item.key });
      });
      await this.store.complete(
        batchId,
        [...new Set(pages.map(({ result }) => result.modelVersion))]
          .join("+")
          .slice(0, 80),
        tickets,
      );
    } catch (error) {
      await Promise.allSettled(
        uploaded.map((item) => this.storage.remove(item.key)),
      );
      throw error;
    }
    const after = await this.store.load(batchId);
    const dropped = new Set(
      after?.status === "DA_HUY"
        ? uploaded.map((item) => item.ticketId)
        : (after?.tickets ?? [])
            .filter((ticket) => ticket.status === "DA_HUY")
            .map((ticket) => ticket.ticketId),
    );
    if (dropped.size) {
      await Promise.allSettled(
        uploaded
          .filter((item) => dropped.has(item.ticketId))
          .map((item) => this.storage.remove(item.key)),
      );
      this.logCancelled(batchId);
    }
  }
}
