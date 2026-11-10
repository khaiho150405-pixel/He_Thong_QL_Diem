import 'timetable_model.dart';

DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

DateTime mondayOf(DateTime d) {
  final day = dateOnly(d);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

String formatDayMonth(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

String formatFullDate(DateTime d) => '${formatDayMonth(d)}/${d.year}';

DateTime? firstWeekStart(TimetableSemester? s) =>
    s == null ? null : mondayOf(s.startDate);
DateTime? lastWeekStart(TimetableSemester? s) =>
    s == null ? null : mondayOf(s.endDate);

DateTime defaultWeekStart(TimetableSemester? s, DateTime today) {
  final t = dateOnly(today);
  if (s == null) return mondayOf(t);
  if (t.isBefore(s.startDate)) return firstWeekStart(s)!;
  if (t.isAfter(s.endDate)) return lastWeekStart(s)!;
  return mondayOf(t);
}

int weekNumber(TimetableSemester s, DateTime weekStart) =>
    weekStart.difference(firstWeekStart(s)!).inDays ~/ 7 + 1;

bool inSemester(TimetableSemester? s, DateTime d) =>
    s == null || (!d.isBefore(s.startDate) && !d.isAfter(s.endDate));

DateTime defaultDay(TimetableSemester? s, DateTime today) {
  final t = dateOnly(today);
  if (s == null || inSemester(s, t)) return t;
  return t.isBefore(s.startDate) ? s.startDate : s.endDate;
}

String thuShort(DateTime d) =>
    d.weekday == DateTime.sunday ? 'CN' : 'Th ${d.weekday + 1}';

String thuFull(DateTime d) => const [
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ nhật',
][d.weekday - 1];

int daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

int monthKey(DateTime d) => d.year * 12 + d.month;

DateTime addMonths(DateTime d, int delta) {
  final target = DateTime.utc(d.year, d.month + delta, 1);
  final day = d.day > daysInMonth(target.year, target.month)
      ? daysInMonth(target.year, target.month)
      : d.day;
  return DateTime.utc(target.year, target.month, day);
}

String thuLabel(DateTime d) =>
    d.weekday == DateTime.sunday ? 'Chủ nhật' : 'Thứ ${d.weekday + 1}';
