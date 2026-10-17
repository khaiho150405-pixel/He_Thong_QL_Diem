export interface SemesterRange {
  ma_hoc_ky: number;
  thu_tu: number;
  ngay_bat_dau: Date;
  ngay_ket_thuc: Date;
}

/** Ngày hiện tại theo giờ Việt Nam (UTC+7) dạng YYYY-MM-DD; học kỳ chỉ lưu ngày, không lưu giờ. */
export function vietnamToday(now: Date = new Date()): string {
  return new Date(now.getTime() + 7 * 3_600_000).toISOString().slice(0, 10);
}

/**
 * Học kỳ mặc định của thời khóa biểu trong năm học hiện hành: học kỳ có ngày bắt đầu <= hôm nay <= ngày kết thúc;
 * không có (nghỉ hè, giữa hai học kỳ, chưa/đã qua) thì học kỳ đầu tiên theo thứ tự như trước đây.
 */
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
