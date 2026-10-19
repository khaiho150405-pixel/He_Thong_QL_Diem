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
  /** `chi_so_cot` của cột điểm trong mẫu mà phiếu đọc. */
  templateColumnIndex: number;
}

export interface BatchWorkerJob {
  status: BatchStatus;
  signature: LayoutSignature;
  /** Cột của mẫu đã dùng khi tạo lô (mẫu đã dùng thì không sửa được: ADR-0016 mục 1). */
  columns: TemplateColumn[];
  pages: Array<{ page: number; objectKey: string }>;
  tickets: BatchWorkerTicket[];
}

export interface RecognitionBatchWorkerStore {
  load(batchId: string): Promise<BatchWorkerJob | null>;
  /** Danh sách lớp đã chốt khi tạo lô (giống nhau cho mọi phiếu của lô). */
  roster(ticketId: string): Promise<RosterEntry[]>;
  complete(
    batchId: string,
    modelVersion: string,
    tickets: Array<{ ticketId: string; rows: unknown[] }>,
  ): Promise<void>;
  fail(batchId: string, code: string, page: number | null): Promise<void>;
}

/**
 * Mã lỗi xác định (HTTP 422) của `/v2/recognize`: ảnh hoặc mẫu không dùng được, thử lại vô ích. Cộng mã v1 với
 * TEMPLATE_MISMATCH (ảnh không khớp lưới mẫu) và INVALID_LAYOUT (layout dựng từ mẫu bị từ chối).
 */
function isBatchPipelineError(value: unknown): boolean {
  return (
    isPipelineErrorCode(value) ||
    value === "TEMPLATE_MISMATCH" ||
    value === "INVALID_LAYOUT"
  );
}

/** Vị trí dòng trên trang phải < 1000 để `order` = (trang-1)*1000 + vị trí duy nhất trong phiếu. */
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

/**
 * Phản hồi phải đúng những gì đã yêu cầu: mỗi dòng có đúng các `key` của layout (không thiếu, không thừa, không cột khác),
 * vị trí dòng nằm trong giới hạn của `order`. Sai thì MALFORMED_RESPONSE (retry; hết lượt thì phiếu LOI).
 */
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

/**
 * Worker cho sự kiện lô (ADR-0016 mục 3): gọi `/v2/recognize` cho từng trang với CÙNG một layout dựng từ cột mẫu, gom dòng mọi
 * trang, ghép học sinh MỘT lần cho cả lô, tách kết quả theo `key` ghi từng phiếu trong một giao dịch. Máy chỉ đề xuất: không
 * bao giờ ghi điểm chính thức (bất biến 1). Log không chứa họ tên.
 */
export class RecognitionBatchProcessor {
  constructor(
    private readonly store: RecognitionBatchWorkerStore,
    private readonly storage: ObjectStorage,
    private readonly model: RecognitionV2Client,
    /** Lớp xác nhận STT (RECOGNITION_STT_CHECK): chỉ hạ mức dòng, không gán học sinh. */
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
    // Phiếu đã hủy riêng lẻ không đọc nữa; hủy hết thì không còn gì để làm.
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
      // Không có danh sách lớp đã chốt thì không thể xác định học sinh: không đoán.
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
        // Một trang bị từ chối (mờ, lệch lưới mẫu...): lỗi xác định → CẢ LÔ LOI cùng mã kèm số trang, không ghi dòng nào.
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
        // `order` = (trang-1)*1000 + vị trí dòng: duy nhất trong phiếu qua mọi trang, giữ thứ tự trang rồi dòng.
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
          // Hai kênh giữ riêng giá trị và độ tin cậy (bất biến 2); cột một kênh có kênh chữ trống.
          numeric: grade.numeric,
          written: grade.written ?? BLANK_CHANNEL,
          numericCropKey: numericKey,
          writtenCropKey: writtenKey,
          nameCropKey: nameKey,
          comparison: grade.comparison,
          suggestedSource: grade.suggestedSource,
          // Mức ghép học sinh tách riêng khỏi mức điểm; mức cuối là mức thấp hơn của hai mức (bất biến 4, 5).
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
    // Lô/phiếu có thể bị hủy trong lúc nhận dạng: SQL bỏ qua kết quả nên ảnh ô vừa tải lên thành mồ côi → dọn lại.
    // Đặt ngoài try: lỗi ở bước này không được xóa ảnh ô của kết quả đã ghi.
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
