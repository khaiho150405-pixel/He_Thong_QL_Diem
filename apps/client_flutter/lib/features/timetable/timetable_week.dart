import 'timetable_model.dart';

/// Ngày thuần (không giờ) ở UTC để cộng/trừ ngày không lệch do múi giờ.
DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// Thứ Hai của tuần chứa [d].
DateTime mondayOf(DateTime d) {
  final day = dateOnly(d);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

/// dd/MM
String formatDayMonth(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// dd/MM/yyyy
String formatFullDate(DateTime d) => '${formatDayMonth(d)}/${d.year}';

/// Thứ Hai của tuần 1 và của tuần cuối; null khi chưa biết học kỳ.
DateTime? firstWeekStart(TimetableSemester? s) =>
    s == null ? null : mondayOf(s.startDate);
DateTime? lastWeekStart(TimetableSemester? s) =>
    s == null ? null : mondayOf(s.endDate);

/// Tuần mặc định: chứa hôm nay nếu hôm nay trong học kỳ; trước học kỳ → tuần 1;
/// sau học kỳ → tuần cuối. Không có học kỳ → tuần chứa hôm nay.
DateTime defaultWeekStart(TimetableSemester? s, DateTime today) {
  final t = dateOnly(today);
  if (s == null) return mondayOf(t);
  if (t.isBefore(s.startDate)) return firstWeekStart(s)!;
  if (t.isAfter(s.endDate)) return lastWeekStart(s)!;
  return mondayOf(t);
}

/// Số thứ tự tuần (tuần 1 = tuần chứa ngày bắt đầu học kỳ).
int weekNumber(TimetableSemester s, DateTime weekStart) =>
    weekStart.difference(firstWeekStart(s)!).inDays ~/ 7 + 1;

/// TKB chỉ áp dụng trong học kỳ; chưa biết học kỳ thì coi mọi ngày đều hợp lệ.
bool inSemester(TimetableSemester? s, DateTime d) =>
    s == null || (!d.isBefore(s.startDate) && !d.isAfter(s.endDate));

/// Ngày mặc định khi mở: hôm nay nếu nằm trong học kỳ, ngoài thì kẹp vào biên.
DateTime defaultDay(TimetableSemester? s, DateTime today) {
  final t = dateOnly(today);
  if (s == null || inSemester(s, t)) return t;
  return t.isBefore(s.startDate) ? s.startDate : s.endDate;
}

/// "Th 2" … "Th 7", "CN".
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

/// Số tháng tuyệt đối, để so sánh tháng của hai ngày.
int monthKey(DateTime d) => d.year * 12 + d.month;

/// Cộng [delta] tháng, giữ ngày trong tháng (kẹp theo số ngày của tháng đích).
DateTime addMonths(DateTime d, int delta) {
  final target = DateTime.utc(d.year, d.month + delta, 1);
  final day = d.day > daysInMonth(target.year, target.month)
      ? daysInMonth(target.year, target.month)
      : d.day;
  return DateTime.utc(target.year, target.month, day);
}

/// "Thứ 2" … "Thứ 7", "Chủ nhật" (tiêu đề cột lưới web).
String thuLabel(DateTime d) =>
    d.weekday == DateTime.sunday ? 'Chủ nhật' : 'Thứ ${d.weekday + 1}';
