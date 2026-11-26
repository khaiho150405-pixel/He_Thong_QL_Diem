export interface YearClosingIssue {
  code: string;
  severity: "BLOCKING" | "WARNING";
  label: string;
  count: number;
}

export interface YearClosingEvent {
  action: "DONG" | "MO_LAI";
  reason: string;
  actor: string;
  at: string;
}

export interface YearClosingStatus {
  yearId: number;
  closedAt: string | null;
  ready: boolean;
  issues: YearClosingIssue[];
  history: YearClosingEvent[];
}

export interface YearClosingStore {
  status(yearId: number): Promise<YearClosingStatus>;
  change(
    sessionHash: string,
    yearId: number,
    close: boolean,
    reason: string,
  ): Promise<void>;
}

export const YEAR_CLOSING_STORE = Symbol("YEAR_CLOSING_STORE");
