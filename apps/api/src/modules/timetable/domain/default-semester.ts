export interface SemesterRange {
  ma_hoc_ky: number;
  thu_tu: number;
  ngay_bat_dau: Date;
  ngay_ket_thuc: Date;
}

export function vietnamToday(now: Date = new Date()): string {
  return new Date(now.getTime() + 7 * 3_600_000).toISOString().slice(0, 10);
}

export function pickDefaultSemester(
  semesters: SemesterRange[],
  today: string,
): number | undefined {
  const ordered = [...semesters].sort((a, b) => a.thu_tu - b.thu_tu);
  const day = (value: Date) => value.toISOString().slice(0, 10);
  const running = ordered.find(
    (semester) =>
      day(semester.ngay_bat_dau) <= today &&
      today <= day(semester.ngay_ket_thuc),
  );
  return (running ?? ordered[0])?.ma_hoc_ky;
}
