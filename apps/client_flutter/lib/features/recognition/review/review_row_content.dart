import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

import 'review_crop_image.dart';
import 'review_models.dart';
import 'review_stt_mismatch_box.dart';

/// Kiểu bố cục hiển thị một dòng:
/// - [wide]: Web/Tablet ngang (4 cột trong Row)
/// - [narrow]: Mobile / Danh sách hẹp (xếp dọc, ảnh và nút full-width)
enum ReviewRowLayout { wide, narrow }

/// Widget dùng chung hiển thị toàn bộ nội dung của một dòng đối chiếu:
/// Tiêu đề + chip STT, khung STT khác, huy hiệu mức & lý do, ảnh họ tên,
/// ảnh ô Điểm số, ảnh ô Điểm chữ, ô nhập Điểm cuối / Không ghi điểm / Chỉ xem,
/// nút Đồng ý và menu ⋮.
class ReviewRowContent extends StatelessWidget {
  final RecognitionEvidenceRowDto row;
  final TextEditingController valueController;
  final TextEditingController reasonController;
  final bool isLeavingEmpty;
  final bool isAgreedYellow;
  final bool enabled;
  final ValueChanged<String> onGradeChanged;
  final ValueChanged<String>? onReasonChanged;
  final VoidCallback onLeaveEmpty;
  final VoidCallback onCancelLeaveEmpty;
  final VoidCallback onAgreeYellow;
  final FocusNode? focusNode;
  final VoidCallback? onFocusNext;
  final VoidCallback? onRefresh;
  final bool readOnly;
  final bool isSttConfirmed;
  final ValueChanged<bool>? onSttConfirmedChanged;
  final ReviewRowLayout layout;
  final bool showInlineAgreeButton;
  final bool isCancelled;

  const ReviewRowContent({
    super.key,
    required this.row,
    required this.valueController,
    required this.reasonController,
    required this.isLeavingEmpty,
    required this.isAgreedYellow,
    required this.enabled,
    required this.onGradeChanged,
    this.onReasonChanged,
    required this.onLeaveEmpty,
    required this.onCancelLeaveEmpty,
    required this.onAgreeYellow,
    this.focusNode,
    this.onFocusNext,
    this.onRefresh,
    this.readOnly = false,
    this.isSttConfirmed = false,
    this.onSttConfirmedChanged,
    this.layout = ReviewRowLayout.wide,
    this.showInlineAgreeButton = true,
    this.isCancelled = false,
  });

  @override
  Widget build(BuildContext context) {
    final shortReason = getRowShortReason(row);
    final showNameCrop = shouldShowNameCrop(row);
    final showPaperStt =
        row.sttOnPaper != null &&
        row.stt != null &&
        row.sttOnPaper!.toInt() != row.stt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tiêu đề dòng + Menu ⋮
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildTitle(context, showPaperStt)),
            if (!readOnly) _buildMenu(context),
          ],
        ),

        // Khung ghi chú riêng khi STT khác nhau (full width)
        if (showPaperStt)
          ReviewSttMismatchBox(
            row: row,
            isConfirmed: isSttConfirmed,
            onConfirmedChanged: onSttConfirmedChanged,
            readOnly: readOnly,
            onRefresh: onRefresh,
            isCancelled: isCancelled,
          ),

        const SizedBox(height: 6),

        // Nội dung theo bố cục ngang (wide) hoặc dọc (narrow)
        if (layout == ReviewRowLayout.wide)
          _buildDesktopContent(
            context,
            shortReason,
            showNameCrop && !showPaperStt,
          )
        else
          _buildMobileContent(
            context,
            shortReason,
            showNameCrop && !showPaperStt,
          ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context, bool showPaperStt) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (layout == ReviewRowLayout.narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'STT hệ thống ${row.stt ?? '—'} · ${row.studentName}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          if (showPaperStt) ...[
            const SizedBox(height: 4),
            buildSttMismatchChip(row),
          ],
        ],
      );
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          'STT hệ thống ${row.stt ?? '—'} · ${row.studentName}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        if (showPaperStt) buildSttMismatchChip(row),
      ],
    );
  }

  Widget _buildMenu(BuildContext context) {
    return PopupMenuButton<String>(
      key: ValueKey('review-menu-${row.rowId}'),
      icon: const Icon(Icons.more_vert_rounded, size: 22),
      padding: EdgeInsets.zero,
      tooltip: 'Tùy chọn dòng',
      onSelected: (val) {
        if (val == 'LEAVE_EMPTY') {
          onLeaveEmpty();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          key: ValueKey('review-empty-${row.rowId}'),
          value: 'LEAVE_EMPTY',
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block_rounded, size: 18),
              SizedBox(width: 8),
              Flexible(child: Text('Không ghi điểm (vắng/miễn…)')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopContent(
    BuildContext context,
    String shortReason,
    bool showNameCrop,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cột 1: Mức & Lý do + ảnh họ tên nếu có (flex: 3)
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  buildReviewLevelBadge(context, row.reviewLevel.value),
                  if (shortReason.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shortReason,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: row.reviewLevel.value == 'DO'
                              ? Colors.red.shade900
                              : Colors.amber.shade900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              if (showNameCrop) ...[
                const SizedBox(height: 6),
                ReviewCropImage(
                  label: 'Họ tên trên giấy',
                  imageUrl: row.nameCropUrl,
                  nullPlaceholder: 'Không có ảnh họ tên',
                  height: 48,
                  onRefresh: onRefresh,
                  isCancelled: isCancelled,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Cột 2: Ảnh ô Điểm số (flex: 2)
        Expanded(
          flex: 2,
          child: ReviewCropImage(
            label: 'Điểm số',
            imageUrl: row.numericCropUrl,
            nullPlaceholder: 'Không có ảnh',
            height: 64,
            onRefresh: onRefresh,
            isCancelled: isCancelled,
          ),
        ),
        const SizedBox(width: 10),

        // Cột 3: Ảnh ô Điểm chữ (flex: 2)
        Expanded(
          flex: 2,
          child: ReviewCropImage(
            label: 'Điểm chữ',
            imageUrl: row.writtenCropUrl,
            nullPlaceholder: 'Không có ảnh',
            height: 64,
            onRefresh: onRefresh,
            isCancelled: isCancelled,
          ),
        ),
        const SizedBox(width: 12),

        // Cột 4: Nhập điểm cuối & thao tác (flex: 3)
        Expanded(flex: 3, child: _buildGradeInputColumn(context)),
      ],
    );
  }

  Widget _buildMobileContent(
    BuildContext context,
    String shortReason,
    bool showNameCrop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Huy hiệu mức & lý do
        Row(
          children: [
            buildReviewLevelBadge(context, row.reviewLevel.value),
            if (shortReason.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shortReason,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: row.reviewLevel.value == 'DO'
                        ? Colors.red.shade900
                        : Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),

        // Ảnh họ tên nếu có (chỉ hiện khi chưa có khung STT)
        if (showNameCrop) ...[
          ReviewCropImage(
            label: 'Họ tên trên giấy',
            imageUrl: row.nameCropUrl,
            nullPlaceholder: 'Không có ảnh họ tên',
            height: 68,
            onRefresh: onRefresh,
            isCancelled: isCancelled,
          ),
          const SizedBox(height: 10),
        ],

        // Ảnh ô Điểm số (full width)
        ReviewCropImage(
          label: 'Điểm số',
          imageUrl: row.numericCropUrl,
          nullPlaceholder: 'Không có ảnh',
          height: 72,
          onRefresh: onRefresh,
          isCancelled: isCancelled,
        ),
        const SizedBox(height: 10),

        // Ảnh ô Điểm chữ (full width)
        ReviewCropImage(
          label: 'Điểm chữ',
          imageUrl: row.writtenCropUrl,
          nullPlaceholder: 'Không có ảnh',
          height: 72,
          onRefresh: onRefresh,
          isCancelled: isCancelled,
        ),
        const SizedBox(height: 12),

        // Nhập điểm cuối / không ghi điểm / chỉ xem (full width)
        _buildGradeInputColumn(context, isMobile: true),
      ],
    );
  }

  Widget _buildGradeInputColumn(BuildContext context, {bool isMobile = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isYellow = row.reviewLevel.value == 'VANG';

    // Chế độ CHỈ XEM
    if (readOnly) {
      final finalDisplay = row.finalValue != null
          ? '${row.finalValue}'
          : (valueController.text.isNotEmpty
                ? valueController.text
                : (row.numericValue != null ? '${row.numericValue}' : '—'));

      return Container(
        width: isMobile ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(120),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Điểm đã ghi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              finalDisplay,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: isMobile ? 18 : 16,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    // Không ghi điểm (vắng/miễn…)
    if (isLeavingEmpty) {
      return Container(
        width: isMobile ? double.infinity : null,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red.shade50.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Không ghi điểm',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: colorScheme.error,
                    ),
                  ),
                ),
                TextButton.icon(
                  key: ValueKey('review-cancel-empty-${row.rowId}'),
                  onPressed: enabled ? onCancelLeaveEmpty : null,
                  icon: const Icon(Icons.undo_rounded, size: 16),
                  label: const Text('Hủy'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(48, 36),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final chipLabel in ['Vắng thi', 'Miễn', 'Nhập sau'])
                  ChoiceChip(
                    key: ValueKey('review-chip-$chipLabel-${row.rowId}'),
                    label: Text(
                      chipLabel,
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: reasonController.text == chipLabel,
                    onSelected: enabled
                        ? (selected) {
                            if (selected) {
                              reasonController.text = chipLabel;
                              onReasonChanged?.call(chipLabel);
                            }
                          }
                        : null,
                  ),
                ActionChip(
                  key: ValueKey('review-chip-other-${row.rowId}'),
                  label: const Text('Khác…', style: TextStyle(fontSize: 12)),
                  onPressed: enabled
                      ? () {
                          if ([
                            'Vắng thi',
                            'Miễn',
                            'Nhập sau',
                          ].contains(reasonController.text)) {
                            reasonController.text = '';
                            onReasonChanged?.call('');
                          }
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              key: ValueKey('review-reason-${row.rowId}'),
              controller: reasonController,
              enabled: enabled,
              textInputAction: TextInputAction.next,
              onChanged: onReasonChanged,
              decoration: const InputDecoration(
                labelText: 'Lý do không ghi điểm (bắt buộc)',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'Cần chọn hoặc nhập lý do không ghi điểm.';
                }
                if (text.length > 500) {
                  return 'Tối đa 500 ký tự.';
                }
                return null;
              },
            ),
          ],
        ),
      );
    }

    // Nhập điểm cuối
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          key: ValueKey('review-value-${row.rowId}'),
          controller: valueController,
          enabled: enabled,
          focusNode: focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => onFocusNext?.call(),
          onChanged: onGradeChanged,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isMobile ? 16 : 14,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            labelText: 'Điểm cuối',
            isDense: true,
            helperText: 'Điểm hợp lệ từ 0.0 đến 10.0',
            contentPadding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: isMobile ? 12 : 10,
            ),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) {
              if (isLeavingEmpty) return null;
              return 'Nhập điểm hoặc chọn Không ghi điểm';
            }
            if (RegExp(r'^(10[.]0|[0-9][.][0-9])$').hasMatch(text)) {
              return null;
            }
            if (RegExp(r'^(10|[0-9])$').hasMatch(text)) {
              return 'Nhập dạng $text.0';
            }
            return 'Nhập 0.0–10.0 với một chữ số thập phân.';
          },
        ),
        if (isYellow && showInlineAgreeButton) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: isMobile ? double.infinity : null,
            height: isMobile ? 48 : 34,
            child: FilledButton.icon(
              key: ValueKey('review-agree-${row.rowId}'),
              onPressed: enabled
                  ? () {
                      onAgreeYellow();
                      onFocusNext?.call();
                    }
                  : null,
              icon: Icon(
                isAgreedYellow
                    ? Icons.check_circle_rounded
                    : Icons.check_rounded,
                size: 18,
              ),
              label: Text(
                isAgreedYellow ? 'Đã xem ✓' : 'Đồng ý',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isAgreedYellow
                    ? Colors.green.shade700
                    : Colors.amber.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size(48, isMobile ? 48 : 34),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
