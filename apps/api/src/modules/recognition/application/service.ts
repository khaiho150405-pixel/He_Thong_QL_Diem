import { createHash, randomUUID } from "node:crypto";
import {
  BadRequestException,
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
  declaredRows: unknown;
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
  constructor(
    @Inject(RECOGNITION_STORE) private readonly store: RecognitionStore,
    @Inject(OBJECT_STORAGE) private readonly storage: ObjectStorage,
  ) {}

  list(actor: Actor, gradebookIdInput: unknown): Promise<RecognitionTicket[]> {
    return this.store.list(actor, positiveInt(gradebookIdInput));
  }

  async detail(
    actor: Actor,
    gradebookIdInput: unknown,
    ticketIdInput: unknown,
  ) {
    const gradebookId = positiveInt(gradebookIdInput);
    if (
      typeof ticketIdInput !== "string" ||
      !/^[1-9][0-9]{0,18}$/.test(ticketIdInput) ||
      BigInt(ticketIdInput) > 9_223_372_036_854_775_807n
    )
      throw new BadRequestException();
    const ticket = await this.store.detail(actor, gradebookId, ticketIdInput);
    if (!ticket) throw new NotFoundException();
    const expiresInSeconds = 300;
    const [sourceImageUrl, rows] = await Promise.all([
      this.storage.signedGetUrl(ticket.sourceObjectKey, expiresInSeconds),
      Promise.all(
        ticket.rows.map(async (row) => {
          const [numericCropUrl, writtenCropUrl] = await Promise.all([
            row.numericCropKey
              ? this.storage.signedGetUrl(row.numericCropKey, expiresInSeconds)
              : Promise.resolve(null),
            row.writtenCropKey
              ? this.storage.signedGetUrl(row.writtenCropKey, expiresInSeconds)
              : Promise.resolve(null),
          ]);
          return {
            rowId: row.rowId,
            order: row.order,
            studentId: row.studentId,
            studentName: row.studentName,
            numericRaw: row.numericRaw,
            numericValue: row.numericValue,
            numericConfidence: row.numericConfidence,
            writtenRaw: row.writtenRaw,
            writtenValue: row.writtenValue,
            writtenConfidence: row.writtenConfidence,
            comparison: row.comparison,
            reviewLevel: row.reviewLevel,
            finalValue: row.finalValue,
            numericCropUrl,
            writtenCropUrl,
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
    const declaredRows = positiveInt(upload.declaredRows);
    if (
      typeof idempotencyKey !== "string" ||
      !/^[a-zA-Z0-9_-]{1,64}$/.test(idempotencyKey)
    )
      throw new BadRequestException();
    const image = inspectImage(upload.bytes, upload.claimedType);
    await this.store.authorizeUpload(actor, gradebookId, componentId);
    const checksum = createHash("sha256").update(upload.bytes).digest("hex");
    const requestHash = createHash("sha256")
      .update(
        JSON.stringify({ gradebookId, componentId, declaredRows, checksum }),
      )
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
        declaredRows,
        checksum,
        objectKey,
        idempotencyKey,
        requestHash,
      });
      if (stored.storedObjectKey !== objectKey) {
        try {
          await this.storage.remove(objectKey);
        } catch {
          // A replay is already durable; cleanup failure must not change its receipt.
        }
      }
      return {
        ticketId: stored.ticketId,
        jobId: stored.jobId,
        status: stored.status,
      };
    } catch (error) {
      try {
        await this.storage.remove(objectKey);
      } catch {
        // The deterministic checksum remains in PostgreSQL; orphan cleanup is operational.
      }
      throw error;
    }
  }
}
