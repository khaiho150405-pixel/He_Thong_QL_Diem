import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../timetable_slot_group.dart';

/// Bộ màu của một khối môn: nền nhạt, viền cùng tông, chữ tiêu đề đậm hơn.
class SubjectColor {
  const SubjectColor(this.bg, this.line, this.fg);
  final Color bg;
  final Color line;
  final Color fg;
}

/// Màu ổn định theo môn (cùng `subjectId` luôn cùng màu), lấy từ token.
SubjectColor subjectColor(AppTokens t, int subjectId) {
  final bases = [
    t.pri,
    t.ok,
    t.warn,
    t.acc,
    t.bad,
    t.neu,
    Color.lerp(t.pri, t.ok, .5)!,
    Color.lerp(t.warn, t.bad, .5)!,
  ];
  final base = bases[subjectId.abs() % bases.length];
  final dark = t.brightness == Brightness.dark;
  return SubjectColor(
    Color.alphaBlend(base.withValues(alpha: dark ? .24 : .13), t.surface),
    base.withValues(alpha: .5),
    Color.lerp(base, t.ink, dark ? .35 : .55)!,
  );
}

/// Giờ học của cả khối: đầu của tiết đầu đến cuối của tiết cuối, null nếu không rõ.
String? slotTimeRange(TimetableSlot slot) {
  final start = slot.items.first.timeSlotLabel.split(' - ');
  final end = slot.items.last.timeSlotLabel.split(' - ');
  if (start.length != 2 || end.length != 2) return null;
  return '${start.first} - ${end.last}';
}

/// Khối môn trong lưới tuần/danh sách ngày trên web.
class TimetableBlock extends StatelessWidget {
  const TimetableBlock({
    super.key,
    required this.slot,
    required this.showClass,
    required this.showTeacher,
    required this.showRoom,
    this.onTap,
  });

  final TimetableSlot slot;
  final bool showClass;
  final bool showTeacher;
  final bool showRoom;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final item = slot.first;
    final color = subjectColor(t, item.maMon);
    final room = item.phongHoc?.trim() ?? '';
    final note = item.ghiChu?.trim() ?? '';

    Widget line(String label, String value) => Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(color: t.ink3),
          ),
          TextSpan(
            text: value,
            style: TextStyle(color: t.ink, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      style: const TextStyle(fontSize: 11.5, height: 1.35),
    );

    return Tooltip(
      message: [
        item.tenMon,
        if (showClass) 'Lớp: ${item.tenLop}',
        if (showTeacher) 'GV: ${item.tenGiaoVien}',
        'Tiết: ${slot.periodLabel}',
        if (showRoom && room.isNotEmpty) 'Phòng: $room',
        if (note.isNotEmpty) note,
      ].join('\n'),
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        key: ValueKey('tt-block-${item.maTietHoc}'),
        color: color.bg,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: color.line),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.tenMon,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color.fg,
                  ),
                ),
                const SizedBox(height: 2),
                if (showClass) line('Lớp', item.tenLop),
                if (showTeacher) line('GV', item.tenGiaoVien),
                line('Tiết', slot.periodLabel),
                if (showRoom && room.isNotEmpty) line('Phòng', room),
                if (note.isNotEmpty)
                  Text(
                    note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: t.ink3,
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

/// Hộp thông tin chỉ xem (giáo viên/học sinh bấm vào khối).
Future<void> showTimetableSlotInfo(
  BuildContext context,
  TimetableSlot slot, {
  required bool showRoom,
}) {
  final item = slot.first;
  final range = slotTimeRange(slot);
  final room = item.phongHoc?.trim() ?? '';
  final note = item.ghiChu?.trim() ?? '';
  final rows = <(String, String)>[
    ('Thứ', item.thuLabel),
    ('Tiết', slot.periodLabel + (range == null ? '' : ' ($range)')),
    ('Lớp', item.tenLop),
    ('Giáo viên', item.tenGiaoVien),
    if (showRoom && room.isNotEmpty) ('Phòng', room),
    if (note.isNotEmpty) ('Ghi chú', note),
  ];
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final t = dialogContext.tokens;
      return AlertDialog(
        title: Text(item.tenMon),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (label, value) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 84,
                        child: Text(label, style: TextStyle(color: t.ink3)),
                      ),
                      Expanded(
                        child: Text(
                          value,
                          style: TextStyle(
                            color: t.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      );
    },
  );
}
