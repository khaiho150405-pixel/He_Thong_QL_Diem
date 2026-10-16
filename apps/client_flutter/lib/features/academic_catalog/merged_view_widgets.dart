import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import 'repository.dart';

/// Đọc đủ mọi trang của một danh mục bằng `CatalogRepository.list` có sẵn
/// (cùng cách `catalog_screen` đang làm); cursor lặp thì dừng để không treo.
Future<List<Json>> fetchAllCatalogRows(
  CatalogRepository repository,
  String resource,
) async {
  final items = <Json>[];
  String? cursor;
  final seen = <String>{};
  do {
    final page = await repository.list(resource, cursor: cursor);
    items.addAll(page.items);
    cursor = page.nextCursor;
    if (cursor != null && !seen.add(cursor)) break;
  } while (cursor != null);
  return items;
}

/// Một nút điều hướng sang màn danh mục hiện có (`/catalog/...`).
typedef MergedViewLink = ({String label, IconData icon, String route});

/// Đầu trang của màn gộp chỉ đọc: dòng mô tả và các nút sang màn quản lý.
class MergedViewHeader extends StatelessWidget {
  const MergedViewHeader({
    super.key,
    required this.description,
    required this.links,
  });

  final String description;
  final List<MergedViewLink> links;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.md,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: t.ink2),
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final link in links)
              OutlinedButton.icon(
                key: ValueKey('merged-link-${link.route}'),
                onPressed: () => context.go(link.route),
                icon: Icon(link.icon, size: 18),
                label: Text(link.label),
              ),
          ],
        ),
      ],
    );
  }
}

/// Cột của [MergedTable]: [flex] chia phần còn lại, [width] cố định.
class MergedColumn {
  const MergedColumn(
    this.label, {
    this.flex = 1,
    this.width,
    this.alignEnd = false,
  });

  final String label;
  final int flex;
  final double? width;
  final bool alignEnd;
}

/// Bảng chỉ đọc kiểu `.tbl` của prototype: thanh tiêu đề nền `subtle`, hàng
/// kẻ ngang bằng `line`, bo góc `AppRadius.md`. Mỗi hàng là danh sách ô đúng
/// thứ tự cột.
class MergedTable extends StatelessWidget {
  const MergedTable({super.key, required this.columns, required this.rows});

  final List<MergedColumn> columns;
  final List<List<Widget>> rows;

  Widget _cell(MergedColumn column, Widget child) {
    final aligned = Align(
      alignment: column.alignEnd
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: child,
    );
    return column.width != null
        ? SizedBox(width: column.width, child: aligned)
        : Expanded(flex: column.flex, child: aligned);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(AppRadius.md);
    final headStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: t.ink3,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: radius,
        border: Border.all(color: t.line),
        boxShadow: t.shadow,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: t.subtle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    for (final column in columns)
                      _cell(
                        column,
                        Text(
                          column.label.toUpperCase(),
                          style: headStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            for (final row in rows) ...[
              Divider(height: 1, thickness: 1, color: t.line),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < columns.length; i++)
                      _cell(columns[i], row[i]),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Thẻ cho màn hẹp: nền surface, viền `line`, bo góc `AppRadius.md`.
class MergedCard extends StatelessWidget {
  const MergedCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}

/// Chip nhỏ (`.chip.sm`): nền `subtle`, viền `line`, chữ `ink2`.
class MergedChip extends StatelessWidget {
  const MergedChip({super.key, required this.text, this.strongText});

  final String text;

  /// Phần in đậm đặt sau [text] (ví dụ hệ số).
  final String? strongText;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final base = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontSize: 12, color: t.ink2, height: 1.3);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.subtle,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: t.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text.rich(
          TextSpan(
            text: text,
            children: [
              if (strongText != null)
                TextSpan(
                  text: ' $strongText',
                  style: TextStyle(fontWeight: FontWeight.w700, color: t.ink),
                ),
            ],
          ),
          style: base,
        ),
      ),
    );
  }
}
