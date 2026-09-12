export interface ReviewDecision {
  rowId: string;
  value: string | null;
  reason: string;
}

export interface ReviewApprovalResult {
  ticketId: string;
  ticketVersion: number;
  gradebookId: number;
  gradebookVersion: number;
  reviewedRows: number;
  machineMatchedRows: number;
  humanCorrectedRows: number;
  errorRows: number;
  status: "DA_DUYET";
}

export interface ApproveRecognitionInput {
  sessionHash: string;
  actorId: number;
  gradebookId: number;
  ticketId: string;
  expectedTicketVersion: number;
  expectedGradebookVersion: number;
  idempotencyKey: string;
  requestHash: string;
  decisions: ReviewDecision[];
}

export interface ReviewStore {
  approve(input: ApproveRecognitionInput): Promise<ReviewApprovalResult>;
}

export const REVIEW_STORE = Symbol("REVIEW_STORE");
