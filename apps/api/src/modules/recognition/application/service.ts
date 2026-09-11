import { createHash, randomUUID } from "node:crypto";
import { BadRequestException, Inject, Injectable } from "@nestjs/common";
import type { ObjectStorage } from "../../files/application/port.js";
import { OBJECT_STORAGE } from "../../files/application/port.js";
import type { Actor } from "../../authorization/application/policy.js";
import { inspectImage } from "./image.js";
import {
  RECOGNITION_STORE,
  type RecognitionReceipt,
  type RecognitionStore,
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
