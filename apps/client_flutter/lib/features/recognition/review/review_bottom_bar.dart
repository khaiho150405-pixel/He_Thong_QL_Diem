import 'package:flutter/material.dart';

import '../../../app/widgets/app_controls.dart';

/// Thanh dưới dính: ô xác nhận "Tôi đã đối chiếu ảnh" + nút "Duyệt phiếu (N dòng)".
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

  @override
  Widget build(BuildContext context) {
    if (!canApprove) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled =
        confirmed &&
        !busy &&
        hasGradebookVersion &&
        allRedHandled &&
        allSttWarningsConfirmed;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withAlpha(120)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CheckboxListTile(
              key: const ValueKey('review-confirm-all'),
              value: confirmed,
              onChanged: busy
                  ? null
                  : (val) => onConfirmedChanged(val ?? false),
              title: const Text(
                'Tôi đã kiểm tra kỹ ảnh ô cắt và xác nhận các giá trị trên.',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const SizedBox(height: 4),
            SizedBox(
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
            ),
            if (busy) ...[
              const SizedBox(height: 6),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
