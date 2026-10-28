import 'timetable_model.dart';

/// Các tiết liền nhau (cùng buổi) của một môn/lớp/giáo viên/phòng, gộp một thẻ.
class TimetableSlot {
  const TimetableSlot(this.items);

  /// Đã sắp theo tiết, liên tục.
  final List<TimetableItem> items;

  TimetableItem get first => items.first;
  int get fromPeriod => items.first.tiet;
  int get toPeriod => items.last.tiet;
  bool get isMorning => fromPeriod <= 5;

  /// "1 - 3", hoặc "1" khi chỉ một tiết.
  String get periodLabel =>
      fromPeriod == toPeriod ? '$fromPeriod' : '$fromPeriod - $toPeriod';
}

/// Gộp các tiết của một ngày thành thẻ, xếp theo tiết rồi theo lớp.
List<TimetableSlot> groupSlots(Iterable<TimetableItem> dayItems) {
  final sorted = dayItems.toList()
    ..sort((a, b) {
      final byPeriod = a.tiet.compareTo(b.tiet);
      return byPeriod != 0 ? byPeriod : a.tenLop.compareTo(b.tenLop);
    });
  final open = <String, List<TimetableItem>>{};
  final runs = <List<TimetableItem>>[];
  for (final item in sorted) {
    final key =
        '${item.maMon}|${item.maLop}|${item.maGiaoVien}|'
        '${item.phongHoc ?? ''}';
    final run = open[key];
    if (run != null &&
        run.last.tiet + 1 == item.tiet &&
        (run.last.tiet <= 5) == (item.tiet <= 5)) {
      run.add(item);
    } else {
      final fresh = [item];
      open[key] = fresh;
      runs.add(fresh);
    }
  }
  return [for (final run in runs) TimetableSlot(run)];
}
