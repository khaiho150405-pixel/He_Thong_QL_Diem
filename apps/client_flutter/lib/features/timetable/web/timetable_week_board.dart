import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../app/design_tokens.dart';
import '../timetable_model.dart';
import '../timetable_slot_group.dart';
import '../timetable_week.dart';
import 'timetable_block.dart';

/// Buổi trong ngày: (nhãn, tiết đầu, tiết cuối).
const _sessions = [('Sáng', 1, 5), ('Chiều', 6, 10)];

/// Lưới tuần theo buổi: 2 hàng (Sáng/Chiều) × 7 ngày, mỗi ô là các khối môn.
class TimetableWeekBoard extends StatelessWidget {
  const TimetableWeekBoard({
    super.key,
    required this.items,
    required this.weekStart,
    required this.semester,
    required this.today,
    required this.showClass,
    required this.showTeacher,
    required this.showRoom,
    this.onBlockTap,
    this.onAdd,
  });

  final List<TimetableItem> items;
  final DateTime weekStart;
  final TimetableSemester? semester;
  final DateTime today;
  final bool showClass;
  final bool showTeacher;
  final bool showRoom;
  final ValueChanged<TimetableSlot>? onBlockTap;

  /// Chỉ QTV: thêm tiết vào (thứ, tiết đầu tiên còn trống của buổi).
  final void Function(int thu, int period)? onAdd;

  static const _labelWidth = 84.0;
  static const _minDayWidth = 124.0;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final days = [for (var thu = 2; thu <= 8; thu++) thu];

    Widget header(String text, {Color? bg}) => ColoredBox(
      color: bg ?? t.subtle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: t.ink3,
            ),
          ),
        ),
      ),
    );

    Widget dayHeader(int thu) {
      final date = weekStart.add(Duration(days: thu - 2));
      final isToday = date == today;
      return ColoredBox(
        color: isToday ? t.priSoft : t.subtle,
        child: Opacity(
          opacity: inSemester(semester, date) ? 1 : .45,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  thuLabel(date),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isToday ? t.priLink : t.heading,
                  ),
                ),
                Text(
                  formatFullDate(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: isToday ? t.priLink : t.ink3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget sessionLabel(int index) {
      final morning = index == 0;
      return ColoredBox(
        color: morning ? t.warnSoft : t.priSoft,
        child: Center(
          child: Text(
            _sessions[index].$1,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: morning ? t.warn : t.priLink,
            ),
          ),
        ),
      );
    }

    Widget cell(int thu, int sessionIndex) {
      final (_, from, to) = _sessions[sessionIndex];
      final date = weekStart.add(Duration(days: thu - 2));
      final inTerm = inSemester(semester, date);
      final inSession = items
          .where((i) => i.thu == thu && i.tiet >= from && i.tiet <= to)
          .toList();
      final occupied = {for (final i in inSession) i.tiet};
      final firstFree = [
        for (var p = from; p <= to; p++) p,
      ].firstWhere((p) => !occupied.contains(p), orElse: () => from);
      return _BoardCell(
        key: ValueKey('tt-cell-$thu-$sessionIndex'),
        slots: inTerm ? groupSlots(inSession) : const [],
        dimmed: !inTerm,
        showClass: showClass,
        showTeacher: showTeacher,
        showRoom: showRoom,
        onBlockTap: onBlockTap,
        onAdd: onAdd == null || !inTerm ? null : () => onAdd!(thu, firstFree),
        addKey: ValueKey('tt-add-$thu-$sessionIndex'),
      );
    }

    final table = Table(
      columnWidths: {
        0: const FixedColumnWidth(_labelWidth),
        for (var i = 1; i <= 7; i++) i: const FlexColumnWidth(),
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: t.line),
        verticalInside: BorderSide(color: t.line),
      ),
      children: [
        TableRow(
          children: [header('Buổi'), for (final thu in days) dayHeader(thu)],
        ),
        for (var s = 0; s < _sessions.length; s++)
          TableRow(
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.fill,
                child: sessionLabel(s),
              ),
              for (final thu in days) cell(thu, s),
            ],
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, box) {
        const minTotal = _labelWidth + 7 * _minDayWidth;
        // 720–1100 px: cuộn ngang trong khung lưới.
        if (box.maxWidth >= minTotal) return table;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minTotal, child: table),
        );
      },
    );
  }
}

class _BoardCell extends StatefulWidget {
  const _BoardCell({
    super.key,
    required this.slots,
    required this.dimmed,
    required this.showClass,
    required this.showTeacher,
    required this.showRoom,
    required this.onBlockTap,
    required this.onAdd,
    required this.addKey,
  });

  final List<TimetableSlot> slots;
  final bool dimmed;
  final bool showClass;
  final bool showTeacher;
  final bool showRoom;
  final ValueChanged<TimetableSlot>? onBlockTap;
  final VoidCallback? onAdd;
  final Key addKey;

  @override
  State<_BoardCell> createState() => _BoardCellState();
}

class _BoardCellState extends State<_BoardCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Không có chuột (cảm ứng) thì không có hover: luôn hiện nút "+".
    final showAdd =
        _hover || !RendererBinding.instance.mouseTracker.mouseIsConnected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        constraints: const BoxConstraints(minHeight: 84),
        color: widget.dimmed ? t.subtle.withValues(alpha: .5) : null,
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final slot in widget.slots) ...[
              TimetableBlock(
                slot: slot,
                showClass: widget.showClass,
                showTeacher: widget.showTeacher,
                showRoom: widget.showRoom,
                onTap: widget.onBlockTap == null
                    ? null
                    : () => widget.onBlockTap!(slot),
              ),
              const SizedBox(height: 6),
            ],
            if (widget.onAdd != null)
              Align(
                alignment: Alignment.centerRight,
                child: IgnorePointer(
                  ignoring: !showAdd,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: showAdd ? 1 : 0,
                    child: IconButton(
                      key: widget.addKey,
                      tooltip: 'Thêm tiết',
                      iconSize: 16,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 28,
                        height: 28,
                      ),
                      padding: EdgeInsets.zero,
                      color: t.priLink,
                      style: IconButton.styleFrom(
                        backgroundColor: t.priSoft,
                        side: BorderSide(color: t.priLine),
                      ),
                      icon: const Icon(Icons.add),
                      onPressed: widget.onAdd,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Danh sách khối môn của một ngày, chia theo buổi (tab "Theo ngày" trên web).
class TimetableDayList extends StatelessWidget {
  const TimetableDayList({
    super.key,
    required this.slots,
    required this.emptyMessage,
    required this.showClass,
    required this.showTeacher,
    required this.showRoom,
    this.onBlockTap,
  });

  final List<TimetableSlot> slots;
  final String emptyMessage;
  final bool showClass;
  final bool showTeacher;
  final bool showRoom;
  final ValueChanged<TimetableSlot>? onBlockTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (slots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.weekend_outlined, size: 40, color: t.ink3),
            const SizedBox(height: AppSpacing.sm),
            Text(emptyMessage, style: TextStyle(color: t.ink2, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: [
        for (final (label, from, to) in _sessions)
          if (slots.any((s) => s.fromPeriod >= from && s.fromPeriod <= to)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'Buổi ${label.toLowerCase()}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: t.ink2,
                ),
              ),
            ),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final slot in slots.where(
                  (s) => s.fromPeriod >= from && s.fromPeriod <= to,
                ))
                  SizedBox(
                    width: 280,
                    child: TimetableBlock(
                      slot: slot,
                      showClass: showClass,
                      showTeacher: showTeacher,
                      showRoom: showRoom,
                      onTap: onBlockTap == null
                          ? null
                          : () => onBlockTap!(slot),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
      ],
    );
  }
}
