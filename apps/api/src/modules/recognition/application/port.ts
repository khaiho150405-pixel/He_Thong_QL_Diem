import type { Actor } from "../../authorization/application/policy.js";

export interface RecognitionReceipt {
  ticketId: string;
  jobId: string;
  status: "DANG_XU_LY";
}

export interface StoredRecognitionReceipt extends RecognitionReceipt {
  storedObjectKey: string;
}

export interface CreateRecognitionTicket {
  actor: Actor;
  gradebookId: number;
  componentId: number;
  declaredRows: number;
  checksum: string;
  objectKey: string;
  idempotencyKey: string;
  requestHash: string;
}

export interface RecognitionStore {
  authorizeUpload(
    actor: Actor,
    gradebookId: number,
    componentId: number,
  ): Promise<void>;
  createTicket(
    input: CreateRecognitionTicket,
  ): Promise<StoredRecognitionReceipt>;
}

export const RECOGNITION_STORE = Symbol("RECOGNITION_STORE");
