import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import 'common.dart';

/// Kết quả "Thử nhận dạng": từng dòng với STT đọc, họ tên đọc và từng cột điểm
/// tô màu theo mức Xanh/Vàng/Đỏ. Chỉ để xem; không có thao tác ghi điểm nào.
class TryResultView extends StatelessWidget {
  const TryResultView({super.key, required this.result});

  final TryResultDto result;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final score = (result.templateMatchScore * 100).round();
    return Column(
      key: const ValueKey('try-result'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            AppBadge('${result.rows.length} dòng', dot: false),
            AppBadge('Độ khớp mẫu $score%', dot: false),
            if (result.pageStartStt != null)
              AppBadge('Dòng đầu STT ${result.pageStartStt}', dot: false),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (result.rows.isEmpty)
          Text(
            'Không thấy dòng nào có dữ liệu trong ảnh.',
            key: const ValueKey('try-no-rows'),
            style: theme.textTheme.bodyMedium?.copyWith(color: t.ink2),
          ),
        for (final row in result.rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _RowCard(row: row),
          ),
      ],
    );
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({required this.row});

  final TryRowDto row;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final name = row.nameRead?.trim() ?? '';
    return TemplateCard(
      key: ValueKey('try-row-${row.rowIndex}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Dòng ${row.rowIndex}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: t.ink3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'STT đọc: ${row.sttRead ?? '—'}',
                key: ValueKey('try-stt-${row.rowIndex}'),
                style: theme.textTheme.bodyMedium?.copyWith(color: t.ink),
              ),
              if (row.struck) const AppBadge.warn('Gạch bỏ', dot: false),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Họ tên đọc: ${name.isEmpty ? '—' : name}',
            key: ValueKey('try-name-${row.rowIndex}'),
            style: theme.textTheme.bodyMedium?.copyWith(color: t.ink),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final grade in row.grades)
                _GradeCell(rowIndex: row.rowIndex, grade: grade),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradeCell extends StatelessWidget {
  const _GradeCell({required this.rowIndex, required this.grade});

  final num rowIndex;
  final TryGradeDto grade;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final (bg, fg, line, level) = switch (grade.reviewLevel) {
      TryGradeDtoReviewLevelEnum.XANH => (t.okSoft, t.ok, t.okLine, 'Xanh'),
      TryGradeDtoReviewLevelEnum.VANG => (
        t.warnSoft,
        t.warn,
        t.warnLine,
        'Vàng',
      ),
      TryGradeDtoReviewLevelEnum.DO => (t.badSoft, t.bad, t.badLine, 'Đỏ'),
    };
    final twoChannels = grade.comparison != TryGradeDtoComparisonEnum.MOT_KENH;
    final numeric = grade.numericValue ?? '—';
    final written = grade.writtenValue ?? '—';
    final source = switch (grade.suggestedSource) {
      TryGradeDtoSuggestedSourceEnum.SO => 'Lấy theo điểm số',
      TryGradeDtoSuggestedSourceEnum.CHU => 'Lấy theo điểm chữ',
      null => null,
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 260),
      child: DecoratedBox(
        key: ValueKey('try-grade-$rowIndex-${grade.key}'),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: Border.all(color: line),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${grade.key} · $level',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                twoChannels ? 'Số: $numeric · Chữ: $written' : 'Số: $numeric',
                style: theme.textTheme.bodyMedium?.copyWith(color: fg),
              ),
              if (source != null)
                Text(
                  source,
                  style: theme.textTheme.bodySmall?.copyWith(color: fg),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
