import 'package:flutter/material.dart';

import '../design_tokens.dart';

class AppTabItem {
  const AppTabItem({required this.label, this.count});

  final String label;

  /// Số đếm hiển thị trong chip nhỏ cạnh nhãn; null thì không có chip.
  final int? count;
}

/// Tab gạch chân (`.tabs`): mục chọn có gạch 2px màu `pri`, cuộn ngang được.
/// Mục thứ `i` có `ValueKey('app-tab-i')`, khung gạch chân có
/// `ValueKey('app-tab-box-i')`.
class AppTabs extends StatelessWidget {
  const AppTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<AppTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = Theme.of(context).textTheme.bodyMedium;
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 1,
          child: ColoredBox(color: t.line),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                _TabButton(
                  index: i,
                  item: tabs[i],
                  selected: i == selectedIndex,
                  style: style,
                  onTap: () => onChanged(i),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.index,
    required this.item,
    required this.selected,
    required this.style,
    required this.onTap,
  });

  final int index;
  final AppTabItem item;
  final bool selected;
  final TextStyle? style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        key: ValueKey('app-tab-$index'),
        onTap: onTap,
        child: DecoratedBox(
          key: ValueKey('app-tab-box-$index'),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? t.pri : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    softWrap: false,
                    style: style?.copyWith(
                      color: selected ? t.priLink : t.ink2,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (item.count != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.hover,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${item.count}',
                          style: style?.copyWith(
                            fontSize: 12,
                            color: t.ink2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
