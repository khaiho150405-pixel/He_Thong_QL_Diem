import 'timetable_model.dart';

class TimetableSlot {
  const TimetableSlot(this.items);

  final List<TimetableItem> items;

  TimetableItem get first => items.first;
  int get fromPeriod => items.first.tiet;
  int get toPeriod => items.last.tiet;
  bool get isMorning => fromPeriod <= 5;

  String get periodLabel =>
      fromPeriod == toPeriod ? '$fromPeriod' : '$fromPeriod - $toPeriod';
}

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
