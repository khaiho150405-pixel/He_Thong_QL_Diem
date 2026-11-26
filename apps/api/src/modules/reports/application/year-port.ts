import type { Unit } from "../../../common/store.js";

export interface LevelCounts {
  TOT: number;
  KHA: number;
  DAT: number;
  CHUA_DAT: number;
  CHUA_DU_MON: number;
}

export interface StatisticsGroup {
  key: number;
  label: string;
  students: number;
  average: string | null;
  fromEight: number;
  fromSixHalf: number;
  fromFive: number;
  belowFive: number;
  passed: number;
  failed: number;
  missing: number;
  levels: LevelCounts | null;
}

export type DataSource = "BAN_CHOT" | "HIEN_TAI";

export interface YearStatistics {
  yearId: number;
  yearName: string;
  source: DataSource;
  snapshotVersion: number | null;
  snapshotAt: string | null;
  schoolName: string | null;
  total: StatisticsGroup | null;
  grades: StatisticsGroup[];
  classes: StatisticsGroup[];
  subjects: StatisticsGroup[];
}

export interface YearComparisonItem extends StatisticsGroup {
  yearId: number;
  yearName: string;
  source: DataSource;
}

export interface YearStudentRow {
  termId: number;
  termName: string;
  studentId: number;
  studentName: string;
  birthDate: string;
  classId: number;
  className: string;
  grade: number;
  homeroomTeacher: string;
  level: string | null;
}

export interface YearSubjectRow {
  termId: number;
  studentId: number;
  subjectId: number;
  subjectName: string;
  passFail: boolean;
  teacher: string | null;
  finalScore: string | null;
  classification: string | null;
  components: Array<{
    name: string;
    value: string | null;
    exempt: boolean;
  }>;
}

export interface YearReportUnit {
  authorization: Unit;
  statistics(yearId: number, term: number): Promise<YearStatistics>;
  comparison(term: number): Promise<YearComparisonItem[]>;
  students(yearId: number, term: number): Promise<YearStudentRow[]>;
  subjects(yearId: number, term: number): Promise<YearSubjectRow[]>;
  recordExport(actorId: number, yearId: number): Promise<void>;
}

export interface YearReportStore {
  run<T>(work: (unit: YearReportUnit) => Promise<T>): Promise<T>;
}

export const YEAR_REPORT_STORE = Symbol("YEAR_REPORT_STORE");
