import type { Unit } from "../../../common/store.js";

export type PromotionAction = "LEN_LOP" | "LUU_BAN" | "TOT_NGHIEP" | "NGHI_HOC";

export interface Enrollment {
  id: string;
  classId: number;
  className: string;
  grade: number;
  yearId: number;
  yearName: string;
  fromDate: string;
  toDate: string | null;
  status:
    | "DANG_HOC"
    | "LEN_LOP"
    | "LUU_BAN"
    | "DA_CHUYEN_LOP"
    | "NGHI_HOC"
    | "TOT_NGHIEP";
  reason: string | null;
  actorName: string | null;
  createdAt: string;
}
export interface PromotionPreviewData {
  sourceClass: {
    id: number;
    name: string;
    grade: number;
    yearId: number;
    yearName: string;
    yearEnd: string;
  };
  targetYear: { id: number; name: string; startDate: string };
  targetClasses: Array<{ id: number; name: string; grade: number }>;
  students: Array<{ id: number; name: string; enrolledInTargetYear: boolean }>;
}
export interface PromotionItem {
  studentId: number;
  action: PromotionAction;
  targetClassId: number | null;
  reason: string | null;
}
export interface PromotionResult {
  processed: number;
  promoted: number;
  retained: number;
  graduated: number;
  withdrawn: number;
}
export interface IdempotentCall {
  idempotencyKey: string;
  requestHash: string;
}
export interface AffectedGradebook {
  id: number;
  subjectName: string;
  termName: string;
}

export interface EnrollmentUnit {
  authorization: Unit;
  preview(
    classId: number,
    targetYearId: number,
  ): Promise<PromotionPreviewData | null>;
  promote(
    sessionHash: string,
    classId: number,
    targetYearId: number,
    items: PromotionItem[],
    call: IdempotentCall,
  ): Promise<PromotionResult>;
  transfer(
    sessionHash: string,
    studentId: number,
    targetClassId: number,
    effectiveDate: string,
    reason: string,
    call: IdempotentCall,
  ): Promise<{ enrollmentId: string; affectedGradebooks: AffectedGradebook[] }>;
  withdraw(
    sessionHash: string,
    studentId: number,
    effectiveDate: string,
    reason: string,
    call: IdempotentCall,
  ): Promise<{ enrollmentId: string }>;
  reenroll(
    sessionHash: string,
    studentId: number,
    classId: number,
    effectiveDate: string,
    reason: string,
    call: IdempotentCall,
  ): Promise<{ enrollmentId: string }>;
  enrollment(id: string): Promise<Enrollment | null>;
  enrollmentsOf(studentId: number): Promise<Enrollment[]>;
  /** Giáo viên chủ nhiệm hoặc được phân công lớp mà em đang hoặc đã học. */
  teacherMaySee(studentId: number, teacherId: number): Promise<boolean>;
}

export interface EnrollmentStore {
  run<T>(work: (tx: EnrollmentUnit) => Promise<T>): Promise<T>;
}

export const ENROLLMENT_STORE = Symbol("ENROLLMENT_STORE");
