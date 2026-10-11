import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

/// Thanh tóm tắt dính đầu: tên phiếu + thành phần điểm, chip lọc Đỏ/Vàng/Xanh,
/// tiến độ "Còn X/Y dòng cần xem" + thanh tiến độ.
class ReviewHeader extends StatelessWidget {
  const ReviewHeader({
    super.key,
    required this.ticket,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.totalNeedReview,
    required this.reviewedCount,
  });

  final RecognitionTicketDetailDto ticket;
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;
  final int totalNeedReview;
  final int reviewedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final redCount = ticket.redRows;
    final yellowCount = ticket.yellowRows;
    final greenCount = ticket.greenRows;
    final totalRows = ticket.detectedRows ?? ticket.rows.length;
    final sttDiffCount = ticket.rows
        .where(
          (r) =>
              r.sttOnPaper != null &&
              r.stt != null &&
              r.sttOnPaper!.toInt() != r.stt,
        )
        .length;

    final remainingCount = (totalNeedReview - reviewedCount).clamp(
      0,
      totalNeedReview,
    );
    final progress = totalNeedReview == 0
        ? 1.0
        : (reviewedCount / totalNeedReview).clamp(0.0, 1.0);

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Phiếu #${ticket.ticketId}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '·  ${ticket.componentName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    switch (ticket.status.value) {
                      'DANG_XU_LY' => 'Đang xử lý',
                      'CHO_DOI_CHIEU' => 'Chờ đối chiếu',
                      'DA_DUYET' => 'Đã duyệt',
                      'LOI' => 'Xử lý thất bại',
                      _ => ticket.status.value,
                    },
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(
                    key: const ValueKey('ALL'),
                    label: 'Tất cả ($totalRows)',
                    icon: Icons.filter_list_rounded,
                    isSelected: currentFilter == 'ALL',
                    color: colorScheme.primary,
                    onTap: () => onFilterChanged('ALL'),
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    key: const ValueKey('DO'),
                    label: 'Đỏ ($redCount)',
                    icon: Icons.error_outline_rounded,
                    isSelected: currentFilter == 'DO',
                    color: Colors.red.shade900,
                    onTap: () =>
                        onFilterChanged(currentFilter == 'DO' ? 'ALL' : 'DO'),
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    key: const ValueKey('VANG'),
                    label: 'Vàng ($yellowCount)',
                    icon: Icons.warning_amber_rounded,
                    isSelected: currentFilter == 'VANG',
                    color: Colors.amber.shade900,
                    onTap: () => onFilterChanged(
                      currentFilter == 'VANG' ? 'ALL' : 'VANG',
                    ),
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    key: const ValueKey('XANH'),
                    label: 'Xanh ($greenCount)',
                    icon: Icons.check_circle_rounded,
                    isSelected: currentFilter == 'XANH',
                    color: Colors.green.shade800,
                    onTap: () => onFilterChanged(
                      currentFilter == 'XANH' ? 'ALL' : 'XANH',
                    ),
                  ),
                  if (sttDiffCount > 0) ...[
                    const SizedBox(width: 8),
                    _filterChip(
                      key: const ValueKey('STT_DIFF'),
                      label: '⇄ STT khác: $sttDiffCount',
                      icon: Icons.swap_horiz_rounded,
                      isSelected: currentFilter == 'STT_DIFF',
                      color: Colors.indigo.shade800,
                      onTap: () => onFilterChanged(
                        currentFilter == 'STT_DIFF' ? 'ALL' : 'STT_DIFF',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    totalNeedReview == 0
                        ? '0/0 dòng cần xem (tất cả đều Xanh)'
                        : 'Còn $remainingCount/$totalNeedReview dòng cần xem',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: remainingCount > 0
                          ? colorScheme.error
                          : Colors.green.shade800,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  remainingCount == 0
                      ? Colors.green.shade600
                      : colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required Key key,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      key: key,
      selected: isSelected,
      onSelected: (_) => onTap(),
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: isSelected ? Colors.white : color,
        ),
      ),
      backgroundColor: Colors.white,
      selectedColor: color,
      checkmarkColor: Colors.white,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? color : color.withAlpha(120),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
    );
  }
}
