import { createHash, randomUUID } from "node:crypto";
import {
  BadRequestException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from "@nestjs/common";
import type { ObjectStorage } from "../../files/application/port.js";
import { OBJECT_STORAGE } from "../../files/application/port.js";
import type { Actor } from "../../authorization/application/policy.js";
import { batchError } from "./batch-errors.js";
import {
  MAX_BATCH_COMPONENTS,
  MAX_BATCH_PAGES,
  RECOGNITION_BATCH_STORE,
  type BatchComponentChoice,
  type BatchPageInput,
  type RecognitionBatchStore,
} from "./batch-port.js";
import { inspectImage } from "./image.js";

export interface BatchPageUpload {
  bytes: Uint8Array;
  claimedType: string;
}

export interface BatchUpload {
  templateId: unknown;
  /** Chuỗi JSON `[{templateColumnIndex, componentId}]` (multipart) hoặc mảng đã phân tích. */
  components: unknown;
  /** Ảnh các trang theo thứ tự giáo viên sắp xếp (trang 1 đứng đầu). */
  pages: BatchPageUpload[];
}

const IMAGE_URL_TTL_SECONDS = 300;

function positiveInt(value: unknown, max = 2_147_483_647): number {
  const text = typeof value === "number" ? String(value) : value;
  if (typeof text !== "string" || !/^[1-9][0-9]{0,9}$/.test(text))
    throw new BadRequestException();
  const parsed = Number(text);
  if (!Number.isSafeInteger(parsed) || parsed > max)
    throw new BadRequestException();
  return parsed;
}

function batchIdOf(value: unknown): string {
  if (
    typeof value !== "string" ||
    !/^[1-9][0-9]{0,18}$/.test(value) ||
    BigInt(value) > 9_223_372_036_854_775_807n
  )
    throw new BadRequestException();
  return value;
}

function idempotencyKeyOf(value: unknown): string {
  if (typeof value !== "string" || !/^[a-zA-Z0-9_-]{1,64}$/.test(value))
    throw new BadRequestException();
  return value;
}

/** `components` của multipart: JSON `[{templateColumnIndex, componentId}]`, 1..20 mục, không trùng cột mẫu hay thành phần. */
export function parseComponentChoices(raw: unknown): BatchComponentChoice[] {
  let value = raw;
  if (typeof raw === "string") {
    if (raw.length > 4096) throw new BadRequestException();
    try {
      value = JSON.parse(raw);
    } catch {
      throw new BadRequestException();
    }
  }
  if (
    !Array.isArray(value) ||
    value.length < 1 ||
    value.length > MAX_BATCH_COMPONENTS
  )
    throw new BadRequestException();
  const choices = value.map((item): BatchComponentChoice => {
    if (
      !item ||
      typeof item !== "object" ||
      Array.isArray(item) ||
      Object.keys(item).length !== 2 ||
      !Object.hasOwn(item, "templateColumnIndex") ||
      !Object.hasOwn(item, "componentId")
    )
      throw new BadRequestException();
    const entry = item as Record<string, unknown>;
    const index = entry.templateColumnIndex;
    if (
      typeof index !== "number" ||
      !Number.isInteger(index) ||
      index < 0 ||
      index > 63
    )
      throw new BadRequestException();
    if (typeof entry.componentId !== "number") throw new BadRequestException();
    return {
      templateColumnIndex: index,
      componentId: positiveInt(entry.componentId),
    };
  });
  if (
    new Set(choices.map((choice) => choice.templateColumnIndex)).size !==
      choices.length ||
    new Set(choices.map((choice) => choice.componentId)).size !== choices.length
  )
    throw new BadRequestException();
  return choices.sort((a, b) => a.templateColumnIndex - b.templateColumnIndex);
}

@Injectable()
export class RecognitionBatchService {
  private readonly logger = new Logger(RecognitionBatchService.name);

  constructor(
    @Inject(RECOGNITION_BATCH_STORE)
    private readonly store: RecognitionBatchStore,
    @Inject(OBJECT_STORAGE) private readonly storage: ObjectStorage,
  ) {}

  /**
   * Tạo lô: kiểm ảnh từng trang (ADR-0008), kiểm quyền, tải ảnh lên object storage TRƯỚC giao dịch rồi tạo lô + phiếu trong
   * một giao dịch SQL. Lỗi (hoặc phát lại cùng khóa idempotency) thì dọn các object vừa tải.
   */
  async upload(
    actor: Actor,
    gradebookIdInput: unknown,
    idempotencyKeyInput: unknown,
    upload: BatchUpload,
  ) {
    const gradebookId = positiveInt(gradebookIdInput);
    const idempotencyKey = idempotencyKeyOf(idempotencyKeyInput);
    const templateId = positiveInt(upload.templateId);
    const components = parseComponentChoices(upload.components);
    if (upload.pages.length > MAX_BATCH_PAGES)
      throw batchError("TOO_MANY_PAGES");
    if (upload.pages.length < 1) throw new BadRequestException();
    const inspected = upload.pages.map((page) =>
      inspectImage(page.bytes, page.claimedType),
    );
    const checksums = upload.pages.map((page) =>
      createHash("sha256").update(page.bytes).digest("hex"),
    );
    // Cùng một ảnh cho hai trang của một lô là nhầm lẫn: từ chối sớm, trước khi tải gì lên.
    if (new Set(checksums).size !== checksums.length)
      throw batchError("DUPLICATE_FILE");
    await this.store.authorizeUpload(actor, gradebookId);
    const requestHash = createHash("sha256")
      .update(
        JSON.stringify({ gradebookId, templateId, components, checksums }),
      )
      .digest("hex");
    const pages: BatchPageInput[] = upload.pages.map((_, index) => ({
      page: index + 1,
      checksum: checksums[index]!,
      objectKey: `recognition/original/${randomUUID()}.${inspected[index]!.extension}`,
    }));
    const uploaded: string[] = [];
    try {
      for (const [index, page] of pages.entries()) {
        await this.storage.put({
          key: page.objectKey,
          bytes: upload.pages[index]!.bytes,
          contentType: inspected[index]!.contentType,
          checksum: page.checksum,
        });
        uploaded.push(page.objectKey);
      }
      const stored = await this.store.create({
        actor,
        gradebookId,
        templateId,
        components,
        pages,
        idempotencyKey,
        requestHash,
      });
      // Phát lại cùng khóa: lô đã bền vững với ảnh của lần đầu; ảnh vừa tải lên là thừa.
      if (stored.storedObjectKeys[0] !== pages[0]!.objectKey)
        await this.discard(uploaded);
      return {
        batchId: stored.batchId,
        jobId: stored.jobId,
        status: stored.status,
        tickets: stored.tickets.map((ticket) => ({
          ticketId: ticket.ticketId,
          componentId: ticket.componentId,
        })),
      };
    } catch (error) {
      await this.discard(uploaded);
      throw error;
    }
  }

  async detail(actor: Actor, gradebookIdInput: unknown, batchIdInput: unknown) {
    const batch = await this.store.detail(
      actor,
      positiveInt(gradebookIdInput),
      batchIdOf(batchIdInput),
    );
    if (!batch) throw new NotFoundException();
    // Lô đã hủy hoàn toàn: ảnh các trang đã bị xóa khỏi object storage nên không ký URL (chuỗi rỗng), như phiếu đã hủy.
    const imagesRemoved = batch.tickets.every(
      (ticket) => ticket.status === "DA_HUY",
    );
    const { pages, ...rest } = batch;
    return {
      ...rest,
      imageUrlExpiresInSeconds: IMAGE_URL_TTL_SECONDS,
      pages: await Promise.all(
        pages.map(async (page) => ({
          page: page.page,
          imageUrl: imagesRemoved
            ? ""
            : await this.storage.signedGetUrl(
                page.objectKey,
                IMAGE_URL_TTL_SECONDS,
              ),
        })),
      ),
    };
  }

  /** Hủy mềm lô; ảnh bị xóa khỏi object storage sau khi commit (best-effort, gọi lại cùng khóa sẽ dọn tiếp). */
  async cancel(
    actor: Actor,
    gradebookIdInput: unknown,
    batchIdInput: unknown,
    idempotencyKeyInput: unknown,
    bodyInput: unknown,
  ) {
    const gradebookId = positiveInt(gradebookIdInput);
    const batchId = batchIdOf(batchIdInput);
    const idempotencyKey = idempotencyKeyOf(idempotencyKeyInput);
    if (
      !bodyInput ||
      typeof bodyInput !== "object" ||
      Array.isArray(bodyInput) ||
      Object.keys(bodyInput).length !== 1 ||
      !Object.hasOwn(bodyInput, "reason")
    )
      throw new BadRequestException();
    const reasonInput = (bodyInput as { reason?: unknown }).reason;
    if (typeof reasonInput !== "string") throw new BadRequestException();
    const reason = reasonInput.trim();
    if (reason.length < 1 || reason.length > 200)
      throw new BadRequestException();
    const requestHash = createHash("sha256")
      .update(JSON.stringify({ gradebookId, batchId, reason }))
      .digest("hex");
    const { objectKeys } = await this.store.cancel({
      actor,
      gradebookId,
      batchId,
      reason,
      idempotencyKey,
      requestHash,
    });
    const results = await Promise.allSettled(
      objectKeys.map((key) => this.storage.remove(key)),
    );
    const failed = results.filter((result) => result.status === "rejected");
    if (failed.length)
      this.logger.warn(
        JSON.stringify({
          event: "recognition_batch_cancel_cleanup_failed",
          batchId,
          failed: failed.length,
          total: objectKeys.length,
        }),
      );
    return this.detail(actor, gradebookId, batchId);
  }

  private async discard(keys: string[]): Promise<void> {
    const results = await Promise.allSettled(
      keys.map((key) => this.storage.remove(key)),
    );
    // Ảnh mồ côi không chứa họ tên; dọn dẹp là việc vận hành, không đổi kết quả lỗi gốc.
    if (results.some((result) => result.status === "rejected"))
      this.logger.warn(
        JSON.stringify({ event: "recognition_batch_cleanup_failed" }),
      );
  }
}
