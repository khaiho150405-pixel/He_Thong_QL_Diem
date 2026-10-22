import type { Unit } from "../../../common/store.js";

export type AdjustmentStatus = "CHO_DUYET" | "DA_DUYET" | "TU_CHOI" | "DA_HUY";

export interface AdjustmentPerson {
  id: number;
  name: string;
}
export interface AdjustmentLine {
  cellId: string;
  studentId: number;
  studentName: string;
  componentId: number;
  componentName: string;
  oldValue: string | null;
  oldStatus: "CHUA_CO" | "CHO_DOI_CHIEU" | "DA_DUYET" | "MIEN";
  newValue: string | null;
  newExempt: boolean;
  note: string | null;
}
export interface Adjustment {
  id: string;
  gradebookId: number;
  className: string;
  subjectName: string;
  termName: string;
  status: AdjustmentStatus;
  reason: string;
  submittedBy: AdjustmentPerson;
  submittedAt: string;
  decidedBy: AdjustmentPerson | null;
  decidedAt: string | null;
  decisionReason: string | null;
  lineCount: number;
  version: number;
  lines?: AdjustmentLine[];
}
export interface AdjustmentChange {
  cellId: string;
  value: string | null;
  exempt: boolean;
  note: string | null;
}
export interface IdempotentCall {
  idempotencyKey: string;
  requestHash: string;
}

export interface AdjustmentUnit {
  authorization: Unit;
  submit(
    sessionHash: string,
    bookId: number,
    version: number,
    reason: string,
    changes: AdjustmentChange[],
    call: IdempotentCall,
  ): Promise<string>;
  approve(
    sessionHash: string,
    adjId: string,
    version: number,
    call: IdempotentCall,
  ): Promise<string>;
  reject(
    sessionHash: string,
    adjId: string,
    version: number,
    reason: string,
    call: IdempotentCall,
  ): Promise<string>;
  cancel(
    sessionHash: string,
    adjId: string,
    version: number,
    call: IdempotentCall,
  ): Promise<string>;
  detail(adjId: string): Promise<Adjustment | null>;
  listForBook(bookId: number): Promise<Adjustment[]>;
  list(status: AdjustmentStatus | null, before: string): Promise<Adjustment[]>;
}

export interface AdjustmentStore {
  run<T>(work: (tx: AdjustmentUnit) => Promise<T>): Promise<T>;
}

export const ADJUSTMENT_STORE = Symbol("ADJUSTMENT_STORE");
