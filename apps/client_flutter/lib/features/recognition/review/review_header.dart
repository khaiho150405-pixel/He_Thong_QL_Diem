import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../../app/widgets/app_badge.dart';
import '../../../app/widgets/stat_card.dart';

/// Thanh tóm tắt đầu trang: dải 3 chỉ số Xanh / Vàng / Đỏ (số dòng của phiếu),
/// tên phiếu + thành phần điểm + trạng thái, và chip lọc
/// Tất cả / Đỏ / Vàng / Xanh / STT khác kèm số đếm.
class ReviewHeader extends StatelessWidget {
  const ReviewHeader({
    super.key,
    required this.ticket,
    required this.currentFilter,
    required this.onFilterChanged,
    this.canCancel = false,
    this.onCancel,
    this.showSummary = true,
  });

  final RecognitionTicketDetailDto ticket;
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;
  final bool canCancel;
  final VoidCallback? onCancel;

  /// Hiện dải 3 chỉ số phía trên (tắt ở chế độ trượt trên điện thoại cho đỡ
  /// chiếm chỗ; số đếm vẫn nằm trên các chip lọc).
  final bool showSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;

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

    final statusTone = switch (ticket.status.value) {
      'DANG_XU_LY' => AppBadgeTone.info,
      'CHO_DOI_CHIEU' => AppBadgeTone.warn,
      'DA_DUYET' => AppBadgeTone.ok,
      'LOI' => AppBadgeTone.bad,
      _ => AppBadgeTone.neutral,
    };
    final statusLabel = switch (ticket.status.value) {
      'DANG_XU_LY' => 'Đang xử lý',
      'CHO_DOI_CHIEU' => 'Chờ đối chiếu',
      'DA_DUYET' => 'Đã duyệt',
      'LOI' => 'Xử lý thất bại',
      'DA_HUY' => 'Đã hủy',
      _ => ticket.status.value,
    };

    final card = Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
        boxShadow: t.shadow,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
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
                        color: t.ink,
                      ),
                    ),
                    Text(
                      '·  ${ticket.componentName}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: t.ink2,
                      ),
                    ),
                    AppBadge(statusLabel, tone: statusTone),
                  ],
                ),
              ),
              if (canCancel) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  key: const ValueKey('review-cancel-ticket-button'),
                  onPressed: onCancel,
                  icon: Icon(Icons.cancel_outlined, size: 18, color: t.bad),
                  label: Text(
                    'Hủy phiếu',
                    style: TextStyle(color: t.bad, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.bad,
                    side: BorderSide(color: t.badLine),
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
                  context,
                  key: const ValueKey('ALL'),
                  label: 'Tất cả ($totalRows)',
                  icon: Icons.filter_list_rounded,
                  isSelected: currentFilter == 'ALL',
                  fg: t.priLink,
                  soft: t.priSoft,
                  line: t.priLine,
                  onTap: () => onFilterChanged('ALL'),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  context,
                  key: const ValueKey('DO'),
                  label: 'Đỏ ($redCount)',
                  icon: Icons.error_outline_rounded,
                  isSelected: currentFilter == 'DO',
                  fg: t.bad,
                  soft: t.badSoft,
                  line: t.badLine,
                  onTap: () =>
                      onFilterChanged(currentFilter == 'DO' ? 'ALL' : 'DO'),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  context,
                  key: const ValueKey('VANG'),
                  label: 'Vàng ($yellowCount)',
                  icon: Icons.warning_amber_rounded,
                  isSelected: currentFilter == 'VANG',
                  fg: t.warn,
                  soft: t.warnSoft,
                  line: t.warnLine,
                  onTap: () =>
                      onFilterChanged(currentFilter == 'VANG' ? 'ALL' : 'VANG'),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  context,
                  key: const ValueKey('XANH'),
                  label: 'Xanh ($greenCount)',
                  icon: Icons.check_circle_rounded,
                  isSelected: currentFilter == 'XANH',
                  fg: t.ok,
                  soft: t.okSoft,
                  line: t.okLine,
                  onTap: () =>
                      onFilterChanged(currentFilter == 'XANH' ? 'ALL' : 'XANH'),
                ),
                if (sttDiffCount > 0) ...[
                  const SizedBox(width: 8),
                  _filterChip(
                    context,
                    key: const ValueKey('STT_DIFF'),
                    label: '⇄ STT khác: $sttDiffCount',
                    icon: Icons.swap_horiz_rounded,
                    isSelected: currentFilter == 'STT_DIFF',
                    fg: t.priLink,
                    soft: t.priSoft,
                    line: t.priLine,
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
    );

    if (!showSummary) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ReviewSummaryStrip(
          green: greenCount.toInt(),
          yellow: yellowCount.toInt(),
          red: redCount.toInt(),
        ),
        const SizedBox(height: AppSpacing.md),
        card,
      ],
    );
  }

  Widget _filterChip(
    BuildContext context, {
    required Key key,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color fg,
    required Color soft,
    required Color line,
    required VoidCallback onTap,
  }) {
    final t = context.tokens;
    return FilterChip(
      key: key,
      selected: isSelected,
      onSelected: (_) => onTap(),
      avatar: Icon(icon, size: 16, color: isSelected ? fg : t.ink3),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: isSelected ? fg : t.ink2,
        ),
      ),
      backgroundColor: t.surface,
      selectedColor: soft,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: StadiumBorder(side: BorderSide(color: isSelected ? line : t.line)),
    );
  }
}

/// Dải 3 chỉ số Xanh / Vàng / Đỏ (số dòng của phiếu, lấy từ dữ liệu phiếu).
/// Từ 560 px là ba [StatCard] trên một hàng; hẹp hơn là ba ô gọn với
/// [AppBadge] và số dòng.
class _ReviewSummaryStrip extends StatelessWidget {
  const _ReviewSummaryStrip({
    required this.green,
    required this.yellow,
    required this.red,
  });

  final int green;
  final int yellow;
  final int red;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 560) {
          return StatCardGrid(
            breakpoint: 560,
            children: [
              StatCard(
                title: 'Xanh',
                value: '$green',
                icon: Icons.check_circle_rounded,
                tone: StatTone.ok,
                subtitle: 'Hai kênh đồng thuận',
              ),
              StatCard(
                title: 'Vàng',
                value: '$yellow',
                icon: Icons.warning_amber_rounded,
                tone: StatTone.warn,
                subtitle: 'Một kênh đủ tin cậy, có gợi ý',
              ),
              StatCard(
                title: 'Đỏ',
                value: '$red',
                icon: Icons.error_outline_rounded,
                tone: StatTone.bad,
                subtitle: 'Mâu thuẫn hoặc đều yếu',
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: _CompactCount(
                label: 'Xanh',
                count: green,
                tone: AppBadgeTone.ok,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CompactCount(
                label: 'Vàng',
                count: yellow,
                tone: AppBadgeTone.warn,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CompactCount(
                label: 'Đỏ',
                count: red,
                tone: AppBadgeTone.bad,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CompactCount extends StatelessWidget {
  const _CompactCount({
    required this.label,
    required this.count,
    required this.tone,
  });

  final String label;
  final int count;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = switch (tone) {
      AppBadgeTone.ok => t.ok,
      AppBadgeTone.warn => t.warn,
      AppBadgeTone.bad => t.bad,
      AppBadgeTone.info => t.priLink,
      AppBadgeTone.neutral => t.neu,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
        boxShadow: t.shadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBadge(label, tone: tone, dot: false),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: fg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
