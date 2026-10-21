import type { Unit } from "../../../common/store.js";

export interface GradebookScope {
  classId: number;
  subjectId: number;
  termId: number;
}
export interface Gradebook extends GradebookScope {
  id: number;
  className: string;
  subjectName: string;
  termName: string;
  status: "DANG_NHAP_LIEU" | "DA_CHOT";
  version: number;
}
export interface GradeCell {
  id: string;
  studentId: number;
  studentName: string;
  /** STT trong lớp (common/student-order); null khi học sinh đã nghỉ/chuyển lớp. */
  stt: number | null;
  active: boolean;
  componentId: number;
  componentName: string;
  coefficient: string;
  required: boolean;
  displayOrder: number;
  openForInput?: boolean;
  columnLocked?: boolean;
  passFail?: boolean;
  opensAt?: string | null;
  closesAt?: string | null;
  deadlineVersion?: number;
  deadlineSource?: "RIENG" | "HOC_KY" | null;
  value: string | null;
  status: "CHUA_CO" | "CHO_DOI_CHIEU" | "DA_DUYET" | "MIEN";
  source: "NHAP_TAY" | "NHAN_DIEN";
  exemptionReason: string | null;
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
export interface GradebookHistoryEntry extends GradeHistoryEntry {
  studentName: string;
  componentName: string;
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
export interface MissingStudent {
  studentId: number;
  studentName: string;
}
export interface ExemptionResult {
  bookId: number;
  version: number;
  cellIds: string[];
}
export interface LateStudentResult {
  bookId: number;
  version: number;
  createdCells: number;
  exemptedCells: number;
}
export interface PublishIssue {
  code:
    | "GRADEBOOK_MISSING"
    | "GRADEBOOK_NOT_LOCKED"
    | "RECOGNITION_PENDING"
    | "STUDENT_NOT_IN_GRADEBOOK"
    | "RESULTS_MISSING"
    | "COLUMNS_WITHOUT_DEADLINE";
  severity: "BLOCKING" | "WARNING";
  classId: number;
  className: string;
  subjectId: number;
  subjectName: string;
  gradebookId: number | null;
  studentIds: number[] | null;
  count: number | null;
}
export interface PublishReadiness {
  ready: boolean;
  issues: PublishIssue[];
}
export type DeadlineType = "TX" | "GK" | "CK";
export interface SemesterDeadline {
  type: DeadlineType;
  opensAt: string | null;
  closesAt: string | null;
  version: number;
  expired: boolean;
}
export interface InitializeScope {
  classId: number;
  className: string;
  subjectId: number;
  subjectName: string;
}
export interface InitializeResult {
  created: Array<InitializeScope & { gradebookId: number }>;
  skipped: Array<
    InitializeScope & { reason: "EMPTY_ROSTER" | "NO_COMPONENTS" }
  >;
}
export interface GradebookUnit {
  authorization: Unit;
  setExemptions(
    sessionHash: string,
    bookId: number,
    version: number,
    changes: Array<{ cellId: string; exempt: boolean; reason: string }>,
    idempotencyKey: string,
    requestHash: string,
  ): Promise<ExemptionResult>;
  cellsByIds(bookId: number, ids: string[]): Promise<GradeCell[]>;
  missingStudents(bookId: number): Promise<MissingStudent[]>;
  addLateStudent(
    sessionHash: string,
    bookId: number,
    studentId: number,
    reason: string,
    idempotencyKey: string,
    requestHash: string,
  ): Promise<LateStudentResult>;
  publishReadiness(termId: number): Promise<PublishReadiness>;
  semesterDeadlines(termId: number): Promise<SemesterDeadline[]>;
  setSemesterDeadline(
    sessionHash: string,
    termId: number,
    type: DeadlineType,
    opensAt: string,
    closesAt: string,
    version: number,
  ): Promise<void>;
  initializeSemester(
    sessionHash: string,
    termId: number,
    idempotencyKey: string,
    requestHash: string,
  ): Promise<InitializeResult>;
  processDue(): Promise<number>;
  setDeadline(
    sessionHash: string,
    bookId: number,
    componentId: number,
    opensAt: string,
    closesAt: string,
    version: number,
  ): Promise<void>;
  createBlankGrid(
    sessionHash: string,
    scope: GradebookScope,
  ): Promise<Gradebook>;
  find(id: number): Promise<Gradebook | null>;
  list(
    teacherId: number | null,
    after: number,
    yearId: number | null,
  ): Promise<Gradebook[]>;
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
  lockColumn(
    sessionHash: string,
    bookId: number,
    componentId: number,
    expectedVersion: number,
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
  gradebookHistory(
    bookId: number,
    after: string,
  ): Promise<GradebookHistoryEntry[]>;
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
