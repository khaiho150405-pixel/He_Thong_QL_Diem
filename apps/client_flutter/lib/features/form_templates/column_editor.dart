import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_select_field.dart';
import 'column_draft.dart';
import 'common.dart';

/// Danh sách cột của mẫu: tiêu đề đọc được, vai trò, nhóm TX/GK/CK, thứ tự và
/// "điểm chữ của cột …". Lỗi hiện ngay dưới cột sai; lỗi chung ở đầu danh sách.
/// Widget không giữ trạng thái: mọi thay đổi đi qua [onChanged].
class TemplateColumnEditor extends StatelessWidget {
  const TemplateColumnEditor({
    super.key,
    required this.columns,
    required this.validation,
    required this.onChanged,
    this.enabled = true,
  });

  final List<ColumnDraft> columns;
  final DraftValidation validation;
  final ValueChanged<List<ColumnDraft>> onChanged;
  final bool enabled;

  void _replace(ColumnDraft next) => onChanged([
    for (final c in columns)
      if (c.index == next.index) next else c,
  ]);

  Iterable<ColumnDraft> _others(ColumnDraft column) =>
      columns.where((c) => c.index != column.index);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final general = validation.general;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (general.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              key: const ValueKey('draft-general-errors'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final issue in general)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: TemplateNotice(
                      key: ValueKey('draft-general-${issue.rule.name}'),
                      message: issue.message,
                    ),
                  ),
              ],
            ),
          ),
        for (final column in columns)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _ColumnCard(
              key: ValueKey('column-card-${column.index}'),
              column: column,
              columns: columns,
              issues: validation.forColumn(column.index),
              enabled: enabled,
              onRole: (role) =>
                  _replace(column.withRole(role, others: _others(column))),
              onGroup: (group) =>
                  _replace(column.withGroup(group, others: _others(column))),
              onOrder: (order) => _replace(column.withOrder(order)),
              onPaired: (target) => _replace(column.withPairedWith(target)),
            ),
          ),
        Text(
          'Mỗi cột trong ảnh phải có một dòng khai báo; cột không cần đọc '
          '(mã học sinh, ngày sinh, ký tên…) để là "Bỏ qua".',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.ink3),
        ),
      ],
    );
  }
}

class _ColumnCard extends StatelessWidget {
  const _ColumnCard({
    super.key,
    required this.column,
    required this.columns,
    required this.issues,
    required this.enabled,
    required this.onRole,
    required this.onGroup,
    required this.onOrder,
    required this.onPaired,
  });

  final ColumnDraft column;
  final List<ColumnDraft> columns;
  final List<DraftIssue> issues;
  final bool enabled;
  final ValueChanged<Role> onRole;
  final ValueChanged<Group> onGroup;
  final ValueChanged<int?> onOrder;
  final ValueChanged<int?> onPaired;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final i = column.index;
    final header = column.headerText.trim();
    final grades = [
      for (final c in columns)
        if (c.role == Role.DIEM) c,
    ];
    return TemplateCard(
      key: ValueKey('column-frame-$i'),
      borderColor: issues.isEmpty ? null : t.bad,
      child: LayoutBuilder(
        builder: (context, box) {
          final fieldWidth = box.maxWidth < 520 ? box.maxWidth : 220.0;
          Widget field(Widget child) =>
              SizedBox(width: fieldWidth, child: child);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: t.subtle,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      border: Border.all(color: t.line),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      child: Text(
                        'Cột $i',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: t.ink2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      header.isEmpty ? 'Không đọc được tiêu đề' : header,
                      key: ValueKey('column-header-$i'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: header.isEmpty ? t.ink3 : t.heading,
                        fontStyle: header.isEmpty ? FontStyle.italic : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (column.suggested) ...[
                    const SizedBox(width: AppSpacing.sm),
                    AppBadge.info(
                      'Gợi ý',
                      key: ValueKey('column-suggested-$i'),
                      dot: false,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  field(
                    AppSelectField<Role>(
                      key: ValueKey('column-role-$i'),
                      label: 'Vai trò',
                      searchable: false,
                      enabled: enabled,
                      value: column.role,
                      items: [
                        for (final role in Role.values)
                          DropdownMenuItem(
                            value: role,
                            child: Text(roleLabel(role)),
                          ),
                      ],
                      onChanged: (role) {
                        if (role != null) onRole(role);
                      },
                    ),
                  ),
                  if (column.role == Role.DIEM) ...[
                    field(
                      AppSelectField<Group>(
                        key: ValueKey('column-group-$i'),
                        label: 'Nhóm hệ số',
                        searchable: false,
                        enabled: enabled,
                        value: column.group,
                        items: [
                          for (final group in Group.values)
                            DropdownMenuItem(
                              value: group,
                              child: Text(groupLabel(group)),
                            ),
                        ],
                        onChanged: (group) {
                          if (group != null) onGroup(group);
                        },
                      ),
                    ),
                    field(
                      AppSelectField<int>(
                        key: ValueKey('column-order-$i'),
                        label: 'Thứ tự trong nhóm',
                        searchable: false,
                        enabled: enabled,
                        value: column.order,
                        items: [
                          for (var n = 1; n <= kMaxOrderInGroup; n++)
                            DropdownMenuItem(value: n, child: Text('$n')),
                        ],
                        onChanged: onOrder,
                      ),
                    ),
                  ],
                  if (column.role == Role.DIEM_CHU)
                    field(
                      AppSelectField<int>(
                        key: ValueKey('column-paired-$i'),
                        label: 'Điểm chữ của cột…',
                        searchable: false,
                        enabled: enabled,
                        value: grades.any((c) => c.index == column.pairedWith)
                            ? column.pairedWith
                            : null,
                        hintText: 'Chọn cột điểm số',
                        items: [
                          for (final c in grades)
                            DropdownMenuItem(
                              value: c.index,
                              child: Text(
                                gradeKeyOf(c) == null
                                    ? 'Cột ${c.index}'
                                    : 'Cột ${c.index} · ${gradeKeyOf(c)}',
                              ),
                            ),
                        ],
                        onChanged: onPaired,
                      ),
                    ),
                ],
              ),
              if (issues.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Column(
                    key: ValueKey('column-error-$i'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final issue in issues)
                        Row(
                          key: ValueKey(
                            'column-error-$i-${issue.rule.name}'
                            '-${issue.field?.name}',
                          ),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline, size: 16, color: t.bad),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                issue.message,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: t.bad,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
