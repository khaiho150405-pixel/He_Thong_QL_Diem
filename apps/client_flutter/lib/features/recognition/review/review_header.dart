import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

/// Thanh tóm tắt dính đầu: tên phiếu + thành phần điểm, chip lọc Đỏ/Vàng/Xanh/STT khác.
class ReviewHeader extends StatelessWidget {
  const ReviewHeader({
    super.key,
    required this.ticket,
    required this.currentFilter,
    required this.onFilterChanged,
    this.canCancel = false,
    this.onCancel,
  });

  final RecognitionTicketDetailDto ticket;
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;
  final bool canCancel;
  final VoidCallback? onCancel;

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
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
                            'DA_HUY' => 'Đã hủy',
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
                ),
                if (canCancel) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    key: const ValueKey('review-cancel-ticket-button'),
                    onPressed: onCancel,
                    icon: Icon(
                      Icons.cancel_outlined,
                      size: 18,
                      color: colorScheme.error,
                    ),
                    label: Text(
                      'Hủy phiếu',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                      minimumSize: const Size(100, 38),
                    ),
                  ),
                ],
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
