import type { Unit } from "../../../common/store.js";

export interface FinalResult {
  id: string;
  studentId: number;
  studentName: string;
  finalScore: string;
  classification: string;
  weightVersion: string;
  policyVersion: string;
  calculatedAt: string;
}

export interface MissingComponent {
  componentId: number;
  name: string;
}

export interface SkippedStudent {
  studentId: number;
  studentName: string;
  missingComponents: MissingComponent[];
}

export interface CalculationResult {
  gradebookId: number;
  gradebookVersion: number;
  weightVersion: string;
  policyVersion: string;
  calculatedStudents: number;
  skippedStudents: number;
  results: FinalResult[];
  skipped: SkippedStudent[];
}

export interface CalculationHistory {
  id: string;
  resultId: string;
  calculatorId: number;
  oldScore: string | null;
  oldClassification: string | null;
  newScore: string;
  newClassification: string;
  reason: string;
  calculatedAt: string;
}

export interface FinalResultBook {
  id: number;
  classId: number;
  subjectId: number;
  termId: number;
  status: "DANG_NHAP_LIEU" | "DA_CHOT";
  version: number;
}

export interface CalculateInput {
  sessionHash: string;
  gradebookId: number;
  expectedVersion: number;
  reason: string;
  idempotencyKey: string;
  requestHash: string;
}

export interface ClassificationCriterion {
  code: string;
  minimum: string;
  passing: boolean;
  order: number;
}

export interface ClassificationPolicy {
  version: string;
  name: string;
  roundingDigits: number;
  active: boolean;
  criteria: ClassificationCriterion[];
}

export interface ActivatePolicyInput {
  sessionHash: string;
  version: string;
  name: string;
  roundingDigits: number;
  criteria: ClassificationCriterion[];
  idempotencyKey: string;
  requestHash: string;
}

export interface StudentApprovedComponent {
  componentId: number;
  componentName: string;
  coefficient: string;
  value: string;
}

export interface StudentSubjectResult {
  gradebookId: number;
  subjectId: number;
  subjectName: string;
  termId: number;
  termName: string;
  components: StudentApprovedComponent[];
  finalScore: string | null;
  classification: string | null;
  calculatedAt: string | null;
}

export interface FinalResultUnit {
  authorization: Unit;
  findBook(id: number): Promise<FinalResultBook | null>;
  calculate(input: CalculateInput): Promise<CalculationResult>;
  list(gradebookId: number, after: string): Promise<FinalResult[]>;
  history(
    gradebookId: number,
    resultId: string,
    after: string,
  ): Promise<CalculationHistory[]>;
  activePolicy(): Promise<ClassificationPolicy | null>;
  activatePolicy(input: ActivatePolicyInput): Promise<ClassificationPolicy>;
  studentResults(
    userId: number,
    termId: number | null,
  ): Promise<StudentSubjectResult[]>;
}

export interface FinalResultStore {
  run<T>(work: (unit: FinalResultUnit) => Promise<T>): Promise<T>;
}

export const FINAL_RESULT_STORE = Symbol("FINAL_RESULT_STORE");
