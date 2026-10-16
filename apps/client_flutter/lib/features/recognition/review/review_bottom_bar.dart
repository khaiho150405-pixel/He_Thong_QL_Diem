import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../../app/widgets/app_controls.dart';
import '../../../app/widgets/app_progress.dart';

/// Thanh dưới dính: tiến độ "Đã xử lý n/m" (khi có số đếm), ô xác nhận
/// "Tôi đã kiểm tra kỹ ảnh ô cắt…" + nút "Duyệt phiếu (N dòng)".
class ReviewBottomBar extends StatelessWidget {
  const ReviewBottomBar({
    super.key,
    required this.confirmed,
    required this.onConfirmedChanged,
    required this.onApprove,
    required this.totalRows,
    required this.canApprove,
    required this.allRedHandled,
    required this.hasGradebookVersion,
    required this.busy,
    this.allSttWarningsConfirmed = true,
    this.processedCount,
    this.processedTotal,
  });

  final bool confirmed;
  final ValueChanged<bool> onConfirmedChanged;
  final VoidCallback onApprove;
  final int totalRows;
  final bool canApprove;
  final bool allRedHandled;
  final bool hasGradebookVersion;
  final bool busy;
  final bool allSttWarningsConfirmed;

  /// Số dòng cần xem đã xử lý / tổng số dòng cần xem (dữ liệu đếm của màn);
  /// null hoặc tổng bằng 0 thì không hiện tiến độ.
  final int? processedCount;
  final int? processedTotal;

  @override
  Widget build(BuildContext context) {
    if (!canApprove) return const SizedBox.shrink();

    final t = context.tokens;
    final isEnabled =
        confirmed &&
        !busy &&
        hasGradebookVersion &&
        allRedHandled &&
        allSttWarningsConfirmed;

    final total = processedTotal ?? 0;
    final done = (processedCount ?? 0).clamp(0, total).toInt();
    final progress = total > 0
        ? Column(
            key: const ValueKey('review-progress'),
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Đã xử lý $done/$total',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: t.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: AppProgress(
                  value: done / total,
                  tone: done >= total
                      ? AppProgressTone.ok
                      : AppProgressTone.primary,
                ),
              ),
            ],
          )
        : null;

    final checkbox = CheckboxListTile(
      key: const ValueKey('review-confirm-all'),
      value: confirmed,
      onChanged: busy ? null : (val) => onConfirmedChanged(val ?? false),
      title: Text(
        'Tôi đã kiểm tra kỹ ảnh ô cắt và xác nhận các giá trị trên.',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: t.ink,
        ),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );

    final approve = SizedBox(
      height: AppControlMetrics.height,
      child: FilledButton.icon(
        key: const ValueKey('review-approve'),
        onPressed: isEnabled ? onApprove : null,
        icon: const Icon(Icons.check_circle_rounded, size: 20),
        label: Text(
          'Duyệt phiếu ($totalRows dòng)',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.line)),
        boxShadow: [
          BoxShadow(
            color: t.ink.withAlpha(14),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Ô xác nhận nằm trên cùng; tiến độ và nút Duyệt nằm cùng một
            // hàng khi đủ rộng, xếp dọc khi hẹp.
            final wide = constraints.maxWidth >= 720;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                checkbox,
                const SizedBox(height: 4),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: progress ?? const SizedBox.shrink()),
                      const SizedBox(width: AppSpacing.lg),
                      approve,
                    ],
                  )
                else ...[
                  if (progress != null) ...[
                    progress,
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  approve,
                ],
                if (busy) ...[
                  const SizedBox(height: 6),
                  const LinearProgressIndicator(),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
