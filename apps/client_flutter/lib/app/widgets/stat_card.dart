import 'package:flutter/material.dart';

import '../design_tokens.dart';

/// Tông màu của ô icon trong [StatCard] (`.kpi .ico`, `.ok`, `.warn`, `.bad`).
enum StatTone { primary, ok, warn, bad }

/// Thẻ chỉ số (`.kpi` của prototype): icon vuông 34 theo tông, nhãn, số lớn
/// 30px và dòng phụ. Giữ API cũ (`title`, `value`, `icon`, `subtitle`,
/// `onTap`); `tone` mặc định là `primary`.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.onTap,
    this.tone = StatTone.primary,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onTap;
  final StatTone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final base = Theme.of(context).textTheme;
    final (iconBg, iconFg) = switch (tone) {
      StatTone.primary => (t.priSoft, t.priLink),
      StatTone.ok => (t.okSoft, t.ok),
      StatTone.warn => (t.warnSoft, t.warn),
      StatTone.bad => (t.badSoft, t.bad),
    };
    final radius = BorderRadius.circular(AppRadius.md);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: radius,
        border: Border.all(color: t.line),
        boxShadow: t.shadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width < 360 ? 12 : 18,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: Icon(icon, size: 18, color: iconFg),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: base.bodyMedium?.copyWith(
                          color: t.ink2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: t.ink3,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Số lớn tự thu nhỏ khi cột hẹp để không tràn.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: base.headlineMedium?.copyWith(
                      fontSize: 30,
                      height: 38 / 30,
                      fontWeight: FontWeight.w700,
                      color: t.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: base.bodySmall?.copyWith(
                      color: t.ink3,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lưới thẻ chỉ số: từ breakpoint trở lên xếp một hàng, từ 340px xếp 2 cột,
/// dưới 340px xếp 1 cột; các thẻ cùng hàng cao bằng nhau.
class StatCardGrid extends StatelessWidget {
  const StatCardGrid({
    super.key,
    required this.children,
    this.breakpoint = 720,
  });

  final List<Widget> children;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns;
        if (constraints.maxWidth >= breakpoint) {
          columns = children.length;
        } else if (constraints.maxWidth >= 340) {
          columns = 2;
        } else {
          columns = 1;
        }
        final rows = <Widget>[];
        for (var start = 0; start < children.length; start += columns) {
          final cells = <Widget>[];
          for (var c = 0; c < columns; c++) {
            if (c > 0) cells.add(const SizedBox(width: AppSpacing.md));
            final index = start + c;
            cells.add(
              Expanded(
                child: index < children.length
                    ? children[index]
                    : const SizedBox.shrink(),
              ),
            );
          }
          if (rows.isNotEmpty) rows.add(const SizedBox(height: AppSpacing.md));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: cells,
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}
