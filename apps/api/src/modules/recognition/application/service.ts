import { createHash, randomUUID } from "node:crypto";
import {
  BadRequestException,
  Logger,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import type { ObjectStorage } from "../../files/application/port.js";
import { OBJECT_STORAGE } from "../../files/application/port.js";
import type { Actor } from "../../authorization/application/policy.js";
import { inspectImage } from "./image.js";
import {
  RECOGNITION_STORE,
  type RecognitionReceipt,
  type RecognitionStore,
  type RecognitionTicket,
} from "./port.js";

export interface RecognitionUpload {
  bytes: Uint8Array;
  claimedType: string;
  componentId: unknown;
}

function ticketIdOf(value: unknown): string {
  if (
    typeof value !== "string" ||
    !/^[1-9][0-9]{0,18}$/.test(value) ||
    BigInt(value) > 9_223_372_036_854_775_807n
  )
    throw new BadRequestException();
  return value;
}

function positiveInt(value: unknown): number {
  const text = typeof value === "number" ? String(value) : value;
  if (typeof text !== "string" || !/^[1-9][0-9]{0,9}$/.test(text))
    throw new BadRequestException();
  const parsed = Number(text);
  if (!Number.isSafeInteger(parsed) || parsed > 2_147_483_647)
    throw new BadRequestException();
  return parsed;
}

@Injectable()
export class RecognitionService {
  private readonly logger = new Logger(RecognitionService.name);

  constructor(
    @Inject(RECOGNITION_STORE) private readonly store: RecognitionStore,
    @Inject(OBJECT_STORAGE) private readonly storage: ObjectStorage,
  ) {}

  list(
    actor: Actor,
    gradebookIdInput: unknown,
    includeCancelledInput?: unknown,
  ): Promise<RecognitionTicket[]> {
    if (
      includeCancelledInput !== undefined &&
      includeCancelledInput !== "true" &&
      includeCancelledInput !== "false"
    )
      throw new BadRequestException();
    return this.store.list(
      actor,
      positiveInt(gradebookIdInput),
      includeCancelledInput === "true",
    );
  }

  async cancel(
    actor: Actor,
    gradebookIdInput: unknown,
    ticketIdInput: unknown,
    idempotencyKey: unknown,
    bodyInput: unknown,
  ) {
    const gradebookId = positiveInt(gradebookIdInput);
    const ticketId = ticketIdOf(ticketIdInput);
    if (
      typeof idempotencyKey !== "string" ||
      !/^[a-zA-Z0-9_-]{1,64}$/.test(idempotencyKey)
    )
      throw new BadRequestException();
    if (
      !bodyInput ||
      typeof bodyInput !== "object" ||
      Array.isArray(bodyInput) ||
      Object.keys(bodyInput).length !== 2 ||
      !Object.hasOwn(bodyInput, "expectedVersion") ||
      !Object.hasOwn(bodyInput, "reason")
    )
      throw new BadRequestException();
    const body = bodyInput as Record<string, unknown>;
    if (
      typeof body.expectedVersion !== "number" ||
      !Number.isSafeInteger(body.expectedVersion) ||
      body.expectedVersion < 0 ||
      body.expectedVersion > 2_147_483_647 ||
      typeof body.reason !== "string"
    )
      throw new BadRequestException();
    const reason = body.reason.trim();
    if (reason.length < 1 || reason.length > 200)
      throw new BadRequestException();
    const requestHash = createHash("sha256")
      .update(
        JSON.stringify({
          gradebookId,
          ticketId,
          expectedVersion: body.expectedVersion,
          reason,
        }),
      )
      .digest("hex");
    const { objectKeys } = await this.store.cancel({
      actor,
      gradebookId,
      ticketId,
      expectedVersion: body.expectedVersion,
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
          event: "recognition_cancel_cleanup_failed",
          ticketId,
          failed: failed.length,
          total: objectKeys.length,
        }),
      );
    return this.detail(actor, gradebookId, ticketId);
  }

  async detail(
    actor: Actor,
    gradebookIdInput: unknown,
    ticketIdInput: unknown,
  ) {
    const gradebookId = positiveInt(gradebookIdInput);
    const ticketId = ticketIdOf(ticketIdInput);
    const ticket = await this.store.detail(actor, gradebookId, ticketId);
    if (!ticket) throw new NotFoundException();
    const expiresInSeconds = 300;
    const imagesRemoved = ticket.status === "DA_HUY";
    const [sourceImageUrl, rows] = await Promise.all([
      imagesRemoved
        ? Promise.resolve("")
        : this.storage.signedGetUrl(ticket.sourceObjectKey, expiresInSeconds),
      Promise.all(
        ticket.rows.map(async (row) => {
          const [numericCropUrl, writtenCropUrl, nameCropUrl] =
            await Promise.all([
              row.numericCropKey && !imagesRemoved
                ? this.storage.signedGetUrl(
                    row.numericCropKey,
                    expiresInSeconds,
                  )
                : Promise.resolve(null),
              row.writtenCropKey && !imagesRemoved
                ? this.storage.signedGetUrl(
                    row.writtenCropKey,
                    expiresInSeconds,
                  )
                : Promise.resolve(null),
              row.nameCropKey && !imagesRemoved
                ? this.storage.signedGetUrl(row.nameCropKey, expiresInSeconds)
                : Promise.resolve(null),
            ]);
          return {
            rowId: row.rowId,
            order: row.order,
            stt: row.stt,
            sttOnPaper: row.sttOnPaper,
            studentId: row.studentId,
            studentName: row.studentName,
            exempt: row.exempt,
            nameRead: row.nameRead,
            matchConfidence: row.matchConfidence,
            matchNote: row.matchNote,
            numericRaw: row.numericRaw,
            numericValue: row.numericValue,
            numericConfidence: row.numericConfidence,
            writtenRaw: row.writtenRaw,
            writtenValue: row.writtenValue,
            writtenConfidence: row.writtenConfidence,
            comparison: row.comparison,
            reviewLevel: row.reviewLevel,
            suggestedSource: row.suggestedSource,
            matchLevel: row.matchLevel,
            gradeLevel: row.gradeLevel,
            finalValue: row.finalValue,
            numericCropUrl,
            writtenCropUrl,
            nameCropUrl,
          };
        }),
      ),
    ]);
    return {
      ticketId: ticket.ticketId,
      gradebookId: ticket.gradebookId,
      componentId: ticket.componentId,
      componentName: ticket.componentName,
      declaredRows: ticket.declaredRows,
      detectedRows: ticket.detectedRows,
      status: ticket.status,
      errorCode: ticket.errorCode,
      modelVersion: ticket.modelVersion,
      version: ticket.version,
      createdAt: ticket.createdAt,
      cancelReason: ticket.cancelReason,
      cancelledAt: ticket.cancelledAt,
      greenRows: ticket.greenRows,
      yellowRows: ticket.yellowRows,
      redRows: ticket.redRows,
      sourceImageUrl,
      imageUrlExpiresInSeconds: expiresInSeconds,
      rows,
    };
  }

  async upload(
    actor: Actor,
    gradebookIdInput: unknown,
    idempotencyKey: unknown,
    upload: RecognitionUpload,
  ): Promise<RecognitionReceipt> {
    const gradebookId = positiveInt(gradebookIdInput);
    const componentId = positiveInt(upload.componentId);
    if (
      typeof idempotencyKey !== "string" ||
      !/^[a-zA-Z0-9_-]{1,64}$/.test(idempotencyKey)
    )
      throw new BadRequestException();
    const image = inspectImage(upload.bytes, upload.claimedType);
    await this.store.authorizeUpload(actor, gradebookId, componentId);
    const checksum = createHash("sha256").update(upload.bytes).digest("hex");
    const requestHash = createHash("sha256")
      .update(JSON.stringify({ gradebookId, componentId, checksum }))
      .digest("hex");
    const objectKey = `recognition/original/${randomUUID()}.${image.extension}`;
    await this.storage.put({
      key: objectKey,
      bytes: upload.bytes,
      contentType: image.contentType,
      checksum,
    });
    try {
      const stored = await this.store.createTicket({
        actor,
        gradebookId,
        componentId,
        checksum,
        objectKey,
        idempotencyKey,
        requestHash,
      });
      if (stored.storedObjectKey !== objectKey) {
        try {
          await this.storage.remove(objectKey);
        } catch {}
      }
      return {
        ticketId: stored.ticketId,
        jobId: stored.jobId,
        status: stored.status,
      };
    } catch (error) {
      try {
        await this.storage.remove(objectKey);
      } catch {}
      throw error;
    }
  }
}
