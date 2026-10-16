import 'package:flutter/material.dart';

import '../design_tokens.dart';

/// Thanh phân trang (`.pager`): chữ "Trang p / n" và các nút số trang.
/// `page` tính từ 1. Không giữ trạng thái: gọi [onChanged] để màn cha đổi trang.
/// Nút số trang `p` có `ValueKey('app-pager-p')`.
class AppPager extends StatelessWidget {
  const AppPager({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onChanged,
    this.maxButtons = 7,
  });

  final int page;
  final int pageCount;
  final ValueChanged<int> onChanged;

  /// Số nút số tối đa trước khi rút gọn bằng dấu "…" (tối thiểu 5).
  final int maxButtons;

  /// Danh sách mục hiển thị; null là dấu "…".
  static List<int?> pagesToShow(int page, int count, int maxButtons) {
    final max = maxButtons < 5 ? 5 : maxButtons;
    if (count <= max) return [for (var i = 1; i <= count; i++) i];
    final inner = max - 2;
    final start = (page - inner ~/ 2).clamp(2, count - inner);
    final end = start + inner - 1;
    return [
      1,
      if (start > 2) null,
      for (var i = start; i <= end; i++) i,
      if (end < count - 1) null,
      count,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final total = pageCount < 1 ? 1 : pageCount;
    final current = page.clamp(1, total);
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          Text('Trang $current / $total', style: textStyle),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _PageButton(
                key: const ValueKey('app-pager-prev'),
                semantic: 'Trang trước',
                onTap: current > 1 ? () => onChanged(current - 1) : null,
                child: Icon(Icons.chevron_left, size: 18, color: t.ink2),
              ),
              for (final p in pagesToShow(current, total, maxButtons))
                if (p == null)
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: Center(child: Text('…', style: textStyle)),
                  )
                else
                  _PageButton(
                    key: ValueKey('app-pager-$p'),
                    selected: p == current,
                    onTap: () => onChanged(p),
                    child: Text(
                      '$p',
                      style: textStyle?.copyWith(
                        color: p == current ? t.onPri : t.ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              _PageButton(
                key: const ValueKey('app-pager-next'),
                semantic: 'Trang sau',
                onTap: current < total ? () => onChanged(current + 1) : null,
                child: Icon(Icons.chevron_right, size: 18, color: t.ink2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    super.key,
    required this.child,
    required this.onTap,
    this.selected = false,
    this.semantic,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final String? semantic;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(AppRadius.sm);
    return Semantics(
      button: true,
      selected: selected,
      label: semantic,
      enabled: onTap != null,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Material(
          color: selected ? t.pri : t.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: selected ? t.pri : t.line),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
