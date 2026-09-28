import type { Unit } from "../../../common/store.js";

export interface ReportBook {
  id: number;
  classId: number;
  subjectId: number;
  termId: number;
  status: "DANG_NHAP_LIEU" | "DA_CHOT";
  version: number;
  className: string;
  subjectName: string;
  termName: string;
}

export interface DistributionItem {
  classification: string;
  students: number;
}

export interface GradebookSummary {
  gradebookId: number;
  students: number;
  average: string | null;
  highest: string | null;
  lowest: string | null;
  passed: number;
  failed: number;
  distribution: DistributionItem[];
}

export interface ExportComponent {
  name: string;
  coefficient: string;
  value: string | null;
}

export interface ExportRow {
  studentId: number;
  studentName: string;
  components: ExportComponent[];
  finalScore: string | null;
  classification: string | null;
}

export interface AdminOverview {
  kpi: {
    totalStudents: number;
    totalClasses: number;
    totalTeachers: number;
    lockedGradebooks: number;
    totalGradebooks: number;
    completionRate: number;
    pendingOcrTickets: number;
  };
  gradeDistribution: {
    label: string;
    code: string;
    count: number;
    percentage: number;
    color: string;
  }[];
  gradeLevelProgress: {
    grade: number;
    title: string;
    lockedClasses: number;
    totalClasses: number;
    percentage: number;
  }[];
  ocrAccuracy: {
    totalCells: number;
    greenCount: number;
    yellowCount: number;
    redCount: number;
    accuracyRate: number;
  };
  recentActivities: {
    className: string;
    subjectName: string;
    teacherName: string;
    status: string;
    updatedAt: string;
  }[];
}

export interface ReportUnit {
  authorization: Unit;
  findBook(id: number): Promise<ReportBook | null>;
  summary(gradebookId: number): Promise<GradebookSummary>;
  exportRows(gradebookId: number): Promise<ExportRow[]>;
  recordExport(actorId: number, gradebookId: number): Promise<void>;
  adminOverview(): Promise<AdminOverview>;
}

export interface ReportStore {
  run<T>(work: (unit: ReportUnit) => Promise<T>): Promise<T>;
}

export const REPORT_STORE = Symbol("REPORT_STORE");
