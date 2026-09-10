import type { Unit } from "../../../common/store.js";

export interface GradebookScope {
  classId: number;
  subjectId: number;
  termId: number;
}
export interface Gradebook extends GradebookScope {
  id: number;
  status: "DANG_NHAP_LIEU" | "DA_CHOT";
  version: number;
}
export interface GradeCell {
  id: string;
  studentId: number;
  studentName: string;
  active: boolean;
  componentId: number;
  componentName: string;
  coefficient: string;
  required: boolean;
  displayOrder: number;
  value: string | null;
  status: "CHUA_CO" | "CHO_DOI_CHIEU" | "DA_DUYET";
  source: "NHAP_TAY" | "NHAN_DIEN";
}
export interface GradeHistoryEntry {
  id: string;
  cellId: string;
  editor: number;
  oldValue: string | null;
  newValue: string | null;
  reason: string;
  timestamp: string;
}
export interface IdempotencyRecord {
  key: string;
  userId: number;
  operation: string;
  requestHash: string;
  result: unknown;
}
export interface BatchResult {
  bookId: number;
  version: number;
  items: Array<Pick<GradeCell, "id" | "value" | "status" | "source">>;
}
export interface GradebookUnit {
  authorization: Unit;
  createBlankGrid(
    sessionHash: string,
    scope: GradebookScope,
  ): Promise<Gradebook>;
  find(id: number): Promise<Gradebook | null>;
  list(teacherId: number | null, after: number): Promise<Gradebook[]>;
  cells(bookId: number, after: string): Promise<GradeCell[]>;
  updateGrades(
    sessionHash: string,
    bookId: number,
    version: number,
    changes: Array<{ cellId: string; value: string | null; reason: string }>,
  ): Promise<BatchResult>;
  syncRoster(
    sessionHash: string,
    bookId: number,
    version: number,
  ): Promise<Gradebook>;
  lockGradebook(
    sessionHash: string,
    bookId: number,
    expectedVersion: number,
  ): Promise<Gradebook>;
  gradeHistory(
    bookId: number,
    cellId: string,
    after: string,
  ): Promise<GradeHistoryEntry[]>;
  findIdempotencyKey(
    key: string,
    userId: number,
    operation: string,
  ): Promise<IdempotencyRecord | null>;
  saveIdempotencyKey(
    key: string,
    userId: number,
    operation: string,
    requestHash: string,
    result: unknown,
  ): Promise<void>;
}
export interface GradebookStore {
  run<T>(work: (tx: GradebookUnit) => Promise<T>): Promise<T>;
}
export const GRADEBOOK_STORE = Symbol("GRADEBOOK_STORE");
