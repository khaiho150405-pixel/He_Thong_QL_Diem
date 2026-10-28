import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../../app/widgets/app_badge.dart';

/// Thanh công cụ gộp: tiêu đề + học kỳ/tuần ở trái, chọn ngày/chuyển tuần ở phải.
class TimetableToolbar extends StatelessWidget {
  const TimetableToolbar({
    super.key,
    required this.title,
    required this.semesterLabel,
    required this.weekNumberLabel,
    required this.weekLabel,
    required this.dateLabel,
    required this.tabs,
    this.extras = const [],
    this.below,
    this.onPickDate,
    this.onToday,
    this.onPrev,
    this.onNext,
  });

  final String title;

  /// Tên học kỳ và năm học (ví dụ "Học kỳ I · 2031-2032"); null khi chưa rõ.
  final String? semesterLabel;

  /// Nhãn số tuần (ví dụ "Tuần 2"); null khi chưa rõ học kỳ.
  final String? weekNumberLabel;

  /// "dd/MM – dd/MM/yyyy" của tuần đang xem.
  final String? weekLabel;

  /// Ngày đang chọn, dạng dd/MM/yyyy.
  final String? dateLabel;
  final Widget tabs;
  final List<Widget> extras;

  /// Hàng thứ hai (bộ lọc của QTV).
  final Widget? below;
  final VoidCallback? onPickDate;
  final VoidCallback? onToday;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
        boxShadow: t.shadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.md,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: t.heading,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (semesterLabel != null)
                            Text(
                              semesterLabel!,
                              style: TextStyle(fontSize: 12, color: t.ink2),
                            ),
                          if (weekNumberLabel != null)
                            AppBadge.info(weekNumberLabel!, dot: false),
                          if (weekLabel != null)
                            Text(
                              weekLabel!,
                              key: const ValueKey('timetable-week-label'),
                              style: TextStyle(fontSize: 12, color: t.ink3),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(width: 320, child: tabs),
                    ...extras,
                    OutlinedButton.icon(
                      key: const ValueKey('timetable-date-button'),
                      onPressed: onPickDate,
                      icon: const Icon(Icons.calendar_month_outlined, size: 18),
                      label: Text(dateLabel ?? '--/--/----'),
                    ),
                    TextButton(
                      onPressed: onToday,
                      child: const Text('Hôm nay'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onPrev,
                      icon: const Icon(Icons.chevron_left, size: 18),
                      label: const Text('Tuần trước'),
                    ),
                    OutlinedButton(
                      onPressed: onNext,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Tuần sau'),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (below != null) ...[
              const SizedBox(height: AppSpacing.md),
              below!,
            ],
          ],
        ),
      ),
    );
  }
}
