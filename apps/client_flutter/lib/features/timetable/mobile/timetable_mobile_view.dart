import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../../app/widgets/app_badge.dart';
import '../timetable_model.dart';
import '../timetable_slot_group.dart';
import '../timetable_week.dart';

enum TimetableMobileMode { day, week, month }

/// Chế độ và ngày đang xem; do màn hình giữ để tải lại dữ liệu không mất vị trí.
class TimetableMobileController extends ChangeNotifier {
  TimetableMobileMode mode = TimetableMobileMode.day;
  DateTime? date;

  void reset(TimetableSemester? semester, DateTime today) {
    mode = TimetableMobileMode.day;
    date = defaultDay(semester, today);
    notifyListeners();
  }

  void update({TimetableMobileMode? mode, DateTime? date}) {
    this.mode = mode ?? this.mode;
    this.date = date ?? this.date;
    notifyListeners();
  }
}

/// Giao diện thời khóa biểu cho màn hẹp: chế độ Ngày / Tuần / Tháng.
class TimetableMobileView extends StatelessWidget {
  const TimetableMobileView({
    super.key,
    required this.controller,
    required this.items,
    required this.semester,
    required this.role,
    required this.today,
    this.onSlotTap,
    this.adminBar,
  });

  final TimetableMobileController controller;
  final List<TimetableItem> items;
  final TimetableSemester? semester;
  final String role;
  final DateTime today;

  /// Chỉ QTV: bấm thẻ để sửa/chuyển/xóa.
  final ValueChanged<TimetableSlot>? onSlotTap;

  /// Chỉ QTV: hàng "Bộ lọc" và "Thêm môn", nhận ngày đang chọn.
  final Widget Function(DateTime selected)? adminBar;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final date = controller.date ?? defaultDay(semester, today);
        final mode = controller.mode;
        final head = <Widget>[
          _TopBar(
            mode: mode,
            date: date,
            semester: semester,
            today: today,
            onMode: (m) => controller.update(mode: m),
            onDate: (d) => controller.update(date: d),
          ),
          _NavRow(
            mode: mode,
            date: date,
            semester: semester,
            today: today,
            onDate: (d) => controller.update(date: d),
          ),
          if (adminBar != null) ...[
            adminBar!(date),
            const SizedBox(height: AppSpacing.sm),
          ],
        ];
        final content = GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v.abs() < 250) return;
            final next = _move(mode, date, semester, v < 0 ? 1 : -1);
            if (next != null) controller.update(date: next);
          },
          child: switch (mode) {
            TimetableMobileMode.day => _DayList(
              date: date,
              items: items,
              semester: semester,
              role: role,
              onSlotTap: onSlotTap,
            ),
            TimetableMobileMode.week => _WeekList(
              date: date,
              items: items,
              semester: semester,
              role: role,
              today: today,
              onSlotTap: onSlotTap,
              onOpenDay: (d) =>
                  controller.update(mode: TimetableMobileMode.day, date: d),
            ),
            TimetableMobileMode.month => _MonthGrid(
              date: date,
              items: items,
              semester: semester,
              today: today,
              onOpenDay: (d) =>
                  controller.update(mode: TimetableMobileMode.day, date: d),
            ),
          },
        );
        // Màn rất thấp (chữ lớn, bàn phím): cuộn cả khối thay vì tràn dọc.
        return LayoutBuilder(
          builder: (context, box) {
            if (box.maxHeight < 560) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...head,
                    SizedBox(height: 420, child: content),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...head,
                Expanded(child: content),
              ],
            );
          },
        );
      },
    );
  }
}

/// Ngày đích khi chuyển trước/sau theo [mode]; null nếu vượt biên học kỳ.
DateTime? _move(
  TimetableMobileMode mode,
  DateTime date,
  TimetableSemester? s,
  int dir,
) {
  final next = switch (mode) {
    TimetableMobileMode.day => date.add(Duration(days: dir)),
    TimetableMobileMode.week => date.add(Duration(days: 7 * dir)),
    TimetableMobileMode.month => addMonths(date, dir),
  };
  if (s == null) return next;
  final allowed = switch (mode) {
    TimetableMobileMode.day => inSemester(s, next),
    TimetableMobileMode.week =>
      !mondayOf(next).isBefore(firstWeekStart(s)!) &&
          !mondayOf(next).isAfter(lastWeekStart(s)!),
    TimetableMobileMode.month =>
      monthKey(next) >= monthKey(s.startDate) &&
          monthKey(next) <= monthKey(s.endDate),
  };
  if (!allowed) return null;
  if (next.isBefore(s.startDate)) return s.startDate;
  if (next.isAfter(s.endDate)) return s.endDate;
  return next;
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.mode,
    required this.date,
    required this.semester,
    required this.today,
    required this.onMode,
    required this.onDate,
  });

  final TimetableMobileMode mode;
  final DateTime date;
  final TimetableSemester? semester;
  final DateTime today;
  final ValueChanged<TimetableMobileMode> onMode;
  final ValueChanged<DateTime> onDate;

  Future<void> _pick(BuildContext context) async {
    DateTime local(DateTime d) => DateTime(d.year, d.month, d.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: local(date),
      firstDate: local(
        semester?.startDate ?? date.subtract(const Duration(days: 365)),
      ),
      lastDate: local(semester?.endDate ?? date.add(const Duration(days: 365))),
      helpText: 'Chọn ngày',
    );
    if (picked != null) onDate(dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(
          key: const ValueKey('tt-date-button'),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () => _pick(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '${thuShort(date)}, ${formatFullDate(date)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: t.heading,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: t.ink2),
              ],
            ),
          ),
        ),
        // Chữ phóng to quá mức thì thu nhỏ cả nút thay vì tràn ngang.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: t.line),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (m, label) in const [
                    (TimetableMobileMode.day, 'Ngày'),
                    (TimetableMobileMode.week, 'Tuần'),
                    (TimetableMobileMode.month, 'Tháng'),
                  ])
                    _Segment(
                      key: ValueKey('tt-mode-${m.name}'),
                      label: label,
                      selected: mode == m,
                      onTap: () => onMode(m),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? t.pri : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 38, minWidth: 52),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? t.onPri : t.ink2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.mode,
    required this.date,
    required this.semester,
    required this.today,
    required this.onDate,
  });

  final TimetableMobileMode mode;
  final DateTime date;
  final TimetableSemester? semester;
  final DateTime today;
  final ValueChanged<DateTime> onDate;

  String get _caption {
    final s = semester;
    final weekStart = mondayOf(date);
    final term = s == null || !inSemester(s, date)
        ? ''
        : 'Tuần ${weekNumber(s, weekStart)}';
    switch (mode) {
      case TimetableMobileMode.day:
        return [thuFull(date), if (term.isNotEmpty) term].join(' · ');
      case TimetableMobileMode.week:
        final range =
            '${formatDayMonth(weekStart)} – '
            '${formatFullDate(weekStart.add(const Duration(days: 6)))}';
        return [
          if (s != null) 'Tuần ${weekNumber(s, weekStart)}',
          range,
        ].join(' · ');
      case TimetableMobileMode.month:
        return 'Tháng ${date.month}/${date.year}';
    }
  }

  bool get _showToday {
    if (!inSemester(semester, today)) return false;
    return switch (mode) {
      TimetableMobileMode.day => date != today,
      TimetableMobileMode.week => mondayOf(date) != mondayOf(today),
      TimetableMobileMode.month => monthKey(date) != monthKey(today),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final prev = _move(mode, date, semester, -1);
    final next = _move(mode, date, semester, 1);
    return Row(
      children: [
        IconButton(
          tooltip: 'Trước',
          icon: const Icon(Icons.chevron_left),
          onPressed: prev == null ? null : () => onDate(prev),
        ),
        Expanded(
          child: Text(
            _caption,
            key: const ValueKey('tt-caption'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.ink2,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Sau',
          icon: const Icon(Icons.chevron_right),
          onPressed: next == null ? null : () => onDate(next),
        ),
        if (_showToday)
          TextButton(
            key: const ValueKey('tt-today'),
            onPressed: () => onDate(today),
            child: const Text('Hôm nay'),
          ),
      ],
    );
  }
}

List<TimetableSlot> _slotsOf(
  List<TimetableItem> items,
  TimetableSemester? s,
  DateTime day,
) => inSemester(s, day)
    ? groupSlots(items.where((i) => i.thu == day.weekday + 1))
    : const [];

class _DayList extends StatelessWidget {
  const _DayList({
    required this.date,
    required this.items,
    required this.semester,
    required this.role,
    required this.onSlotTap,
  });

  final DateTime date;
  final List<TimetableItem> items;
  final TimetableSemester? semester;
  final String role;
  final ValueChanged<TimetableSlot>? onSlotTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final slots = _slotsOf(items, semester, date);
    if (slots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_available_outlined, size: 40, color: t.ink3),
              const SizedBox(height: AppSpacing.sm),
              Text(
                inSemester(semester, date)
                    ? 'Không có tiết dạy/học trong ngày này'
                    : 'Ngày này nằm ngoài học kỳ',
                key: const ValueKey('tt-day-empty'),
                textAlign: TextAlign.center,
                style: TextStyle(color: t.ink2, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      key: const ValueKey('tt-day-list'),
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      itemCount: slots.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => _SlotCard(
        slot: slots[i],
        role: role,
        onTap: onSlotTap == null ? null : () => onSlotTap!(slots[i]),
      ),
    );
  }
}

class _WeekList extends StatelessWidget {
  const _WeekList({
    required this.date,
    required this.items,
    required this.semester,
    required this.role,
    required this.today,
    required this.onSlotTap,
    required this.onOpenDay,
  });

  final DateTime date;
  final List<TimetableItem> items;
  final TimetableSemester? semester;
  final String role;
  final DateTime today;
  final ValueChanged<TimetableSlot>? onSlotTap;
  final ValueChanged<DateTime> onOpenDay;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final start = mondayOf(date);
    return ListView(
      key: const ValueKey('tt-week-list'),
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: [
        for (var i = 0; i < 7; i++) ...[
          Builder(
            builder: (context) {
              final day = start.add(Duration(days: i));
              final isToday = day == today;
              final inTerm = inSemester(semester, day);
              final slots = _slotsOf(items, semester, day);
              final mutedStyle = TextStyle(fontSize: 12, color: t.ink3);
              return Column(
                key: ValueKey('tt-week-day-${i + 2}'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    onTap: inTerm ? () => onOpenDay(day) : null,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 40),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${thuFull(day)}, ${formatDayMonth(day)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isToday
                                    ? t.priLink
                                    : (inTerm ? t.heading : t.ink3),
                              ),
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: AppSpacing.sm),
                            const AppBadge.info('Hôm nay', dot: false),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (!inTerm)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text('Ngoài học kỳ', style: mutedStyle),
                    )
                  else if (slots.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text('Không có tiết', style: mutedStyle),
                    )
                  else
                    for (final slot in slots)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _SlotCard(
                          slot: slot,
                          role: role,
                          compact: true,
                          onTap: onSlotTap == null
                              ? null
                              : () => onSlotTap!(slot),
                        ),
                      ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.date,
    required this.items,
    required this.semester,
    required this.today,
    required this.onOpenDay,
  });

  final DateTime date;
  final List<TimetableItem> items;
  final TimetableSemester? semester;
  final DateTime today;
  final ValueChanged<DateTime> onOpenDay;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final first = DateTime.utc(date.year, date.month, 1);
    final lead = first.weekday - 1;
    final days = daysInMonth(date.year, date.month);
    final rows = ((lead + days) / 7).ceil();
    final cellHeight = MediaQuery.textScalerOf(context).scale(52).clamp(52, 84);
    // Số tiết khác nhau trong ngày (QTV xem nhiều lớp cùng tiết chỉ đếm một lần).
    int periods(int thu) =>
        items.where((i) => i.thu == thu).map((i) => i.tiet).toSet().length;

    Widget cell(int index) {
      final dayNo = index - lead + 1;
      if (dayNo < 1 || dayNo > days) return const Expanded(child: SizedBox());
      final day = DateTime.utc(date.year, date.month, dayNo);
      final inTerm = inSemester(semester, day);
      final count = inTerm ? periods(day.weekday + 1) : 0;
      final isToday = day == today;
      return Expanded(
        child: Opacity(
          opacity: inTerm ? 1 : .4,
          child: InkWell(
            key: ValueKey('tt-month-day-$dayNo'),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: inTerm ? () => onOpenDay(day) : null,
            child: SizedBox(
              height: cellHeight.toDouble(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday ? t.priSoft : null,
                      border: isToday ? Border.all(color: t.priLine) : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        '$dayNo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isToday ? t.priLink : t.ink,
                        ),
                      ),
                    ),
                  ),
                  if (count > 0)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: t.pri,
                              shape: BoxShape.circle,
                            ),
                            child: const SizedBox(width: 6, height: 6),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$count tiết',
                            style: TextStyle(fontSize: 10, color: t.ink2),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      key: const ValueKey('tt-month-grid'),
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              for (final label in const [
                'T2',
                'T3',
                'T4',
                'T5',
                'T6',
                'T7',
                'CN',
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: t.ink3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (var r = 0; r < rows; r++)
            Row(children: [for (var c = 0; c < 7; c++) cell(r * 7 + c)]),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.role,
    this.onTap,
    this.compact = false,
  });

  final TimetableSlot slot;
  final String role;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final item = slot.first;
    final morning = slot.isMorning;
    final isStudent = role == 'HOC_SINH';
    final isTeacher = role == 'GIAO_VIEN';
    final room = item.phongHoc?.trim() ?? '';
    final note = item.ghiChu?.trim() ?? '';
    final pad = compact ? AppSpacing.md : AppSpacing.lg;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
        boxShadow: t.shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sọc màu theo buổi: sáng = màu chính, chiều = màu "ok".
                SizedBox(
                  width: 4,
                  child: ColoredBox(color: morning ? t.pri : t.ok),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(pad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (!compact)
                              morning
                                  ? const AppBadge.info('Buổi sáng')
                                  : const AppBadge.ok('Buổi chiều'),
                            const Spacer(),
                            if (onTap != null)
                              Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: t.ink3,
                              ),
                          ],
                        ),
                        if (!compact) const SizedBox(height: AppSpacing.sm),
                        Text(
                          item.tenMon,
                          style: TextStyle(
                            fontSize: compact ? 16 : 20,
                            fontWeight: FontWeight.w700,
                            color: t.ink,
                          ),
                        ),
                        SizedBox(
                          height: compact ? AppSpacing.xs : AppSpacing.sm,
                        ),
                        _InfoRow(
                          'Tiết',
                          compact
                              ? '${slot.periodLabel} · ${morning ? 'Sáng' : 'Chiều'}'
                              : slot.periodLabel,
                        ),
                        if (!isStudent) _InfoRow('Lớp', item.tenLop),
                        if (!isTeacher) _InfoRow('Giáo viên', item.tenGiaoVien),
                        if (!isStudent && room.isNotEmpty)
                          _InfoRow('Phòng', room),
                        if (note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              'Ghi chú: $note',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: t.ink3,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 14, color: t.ink3),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
