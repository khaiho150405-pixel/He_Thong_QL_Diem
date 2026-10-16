import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import 'review_crop_image.dart';
import 'review_models.dart';
import 'review_stt_mismatch_box.dart';

/// Kiểu bố cục hiển thị một dòng:
/// - [wide]: Web/Tablet ngang (các cột trong Row)
/// - [narrow]: Mobile / Danh sách hẹp (xếp dọc, ảnh và nút full-width)
enum ReviewRowLayout { wide, narrow }

/// Widget dùng chung hiển thị toàn bộ nội dung của một dòng đối chiếu theo thẻ
/// `.rv` của prototype: thanh tiêu đề đổi màu theo mức (STT hệ thống, họ tên,
/// chip STT khác, huy hiệu mức, menu ⋮), khung STT khác, ảnh họ tên, ảnh ô
/// Điểm số và Điểm chữ (kèm độ tin cậy và giá trị máy đọc), vùng "Điểm ghi vào
/// bảng" (lý do, ô nhập Điểm cuối / Không ghi điểm / Chỉ xem, nút Đồng ý).
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
    final t = context.tokens;
    final level = row.reviewLevel.value;
    final colors = reviewLevelColors(t, level);
    final shortReason = getRowShortReason(row);
    final showNameCrop = shouldShowNameCrop(row);
    final showPaperStt =
        row.sttOnPaper != null &&
        row.stt != null &&
        row.sttOnPaper!.toInt() != row.stt;
    // Dòng Xanh chỉ lệch STT: ảnh họ tên thu nhỏ nằm chung hàng với ảnh điểm và điểm cuối.
    final compactInfo = showPaperStt && row.matchLevel?.value == 'XANH';
    final nameCropShown = (showNameCrop && !showPaperStt) || compactInfo;

    return Material(
      color: t.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thanh tiêu đề đổi màu theo mức (`.rv-h`)
          _buildHeader(context, colors, level, showPaperStt),

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

          // Nội dung theo bố cục ngang (wide) hoặc dọc (narrow)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: layout == ReviewRowLayout.wide
                ? _buildDesktopContent(
                    context,
                    colors,
                    shortReason,
                    nameCropShown,
                    compact: compactInfo,
                  )
                : _buildMobileContent(
                    context,
                    colors,
                    shortReason,
                    nameCropShown,
                    compact: compactInfo,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ReviewLevelColors colors,
    String level,
    bool showPaperStt,
  ) {
    final theme = Theme.of(context);
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.soft,
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          readOnly ? AppSpacing.lg : AppSpacing.xs,
          AppSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Text(
                      'STT hệ thống ${row.stt ?? '—'} · ${row.studentName}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: t.ink,
                      ),
                    ),
                    if (showPaperStt) buildSttMismatchChip(context, row),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            buildReviewLevelBadge(context, level),
            if (!readOnly) _buildMenu(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    final t = context.tokens;
    return PopupMenuButton<String>(
      key: ValueKey('review-menu-${row.rowId}'),
      icon: Icon(Icons.more_vert_rounded, size: 22, color: t.ink2),
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

  /// Ảnh ô Điểm số + độ tin cậy + giá trị máy đọc.
  Widget _numericCrop(double height) => ReviewCropImage(
    label: 'Điểm số',
    imageUrl: row.numericCropUrl,
    nullPlaceholder: 'Không có ảnh',
    height: height,
    onRefresh: onRefresh,
    isCancelled: isCancelled,
  );

  /// Ảnh ô Điểm chữ + độ tin cậy + giá trị máy đọc.
  Widget _writtenCrop(double height) => ReviewCropImage(
    label: 'Điểm chữ',
    imageUrl: row.writtenCropUrl,
    nullPlaceholder: 'Không có ảnh',
    height: height,
    onRefresh: onRefresh,
    isCancelled: isCancelled,
  );

  Widget _nameCrop(double height) => ReviewCropImage(
    label: 'Họ tên trên giấy',
    imageUrl: row.nameCropUrl,
    nullPlaceholder: 'Không có ảnh họ tên',
    height: height,
    onRefresh: onRefresh,
    isCancelled: isCancelled,
  );

  /// Lý do ngắn (`.why`): chỉ có chữ khi dòng Vàng/Đỏ.
  Widget? _buildWhy(
    BuildContext context,
    ReviewLevelColors colors,
    String shortReason,
  ) {
    if (shortReason.isEmpty) return null;
    final t = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: t.subtle,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: t.line),
      ),
      child: Text(
        shortReason,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colors.fg,
        ),
      ),
    );
  }

  Widget _buildDesktopContent(
    BuildContext context,
    ReviewLevelColors colors,
    String shortReason,
    bool showNameCrop, {
    bool compact = false,
  }) {
    final cropHeight = compact ? 96.0 : 136.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ảnh họ tên nếu có (chỉ khi cần kiểm tra đúng học sinh)
        if (showNameCrop) ...[
          Expanded(flex: 2, child: _nameCrop(48)),
          const SizedBox(width: AppSpacing.md),
        ],

        // Ảnh ô Điểm số
        Expanded(flex: 2, child: _numericCrop(cropHeight)),
        const SizedBox(width: AppSpacing.md),

        // Ảnh ô Điểm chữ — dạng ngang, cần rộng hơn Điểm số để chữ viết tay
        // không bị thu nhỏ (ảnh bị giới hạn bởi chiều rộng cột).
        Expanded(flex: 3, child: _writtenCrop(cropHeight)),
        const SizedBox(width: AppSpacing.lg),

        // Điểm ghi vào bảng: lý do, ô nhập và thao tác
        Expanded(
          flex: 3,
          child: _buildFinalColumn(context, colors, shortReason),
        ),
      ],
    );
  }

  Widget _buildMobileContent(
    BuildContext context,
    ReviewLevelColors colors,
    String shortReason,
    bool showNameCrop, {
    bool compact = false,
  }) {
    final why = _buildWhy(context, colors, shortReason);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lý do ngắn nằm trên cùng để thấy ngay việc cần làm
        if (why != null) ...[why, const SizedBox(height: AppSpacing.md)],

        // Ảnh họ tên nếu có (chỉ hiện khi chưa có khung STT)
        if (showNameCrop) ...[
          _nameCrop(compact ? 44 : 68),
          const SizedBox(height: AppSpacing.md),
        ],

        if (compact)
          // Dòng Xanh: ảnh điểm số và điểm chữ cạnh nhau để tiết kiệm chiều cao.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _numericCrop(88)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(flex: 3, child: _writtenCrop(88)),
            ],
          )
        else ...[
          // Ảnh ô Điểm số (full width)
          _numericCrop(128),
          const SizedBox(height: AppSpacing.md),

          // Ảnh ô Điểm chữ (full width, cao hơn vì chữ viết tay dài hơn điểm số)
          _writtenCrop(160),
        ],
        const SizedBox(height: AppSpacing.lg),

        // Điểm ghi vào bảng (full width); lý do đã hiện phía trên
        _buildFinalColumn(context, colors, '', isMobile: true),
      ],
    );
  }

  /// Vùng "Điểm ghi vào bảng" (`.rv-f`): nhãn, lý do (bố cục ngang), rồi ô
  /// nhập / Không ghi điểm / Chỉ xem.
  Widget _buildFinalColumn(
    BuildContext context,
    ReviewLevelColors colors,
    String shortReason, {
    bool isMobile = false,
  }) {
    final t = context.tokens;
    final why = _buildWhy(context, colors, shortReason);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!readOnly) ...[
          Text(
            'Điểm ghi vào bảng',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: t.ink3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (why != null) ...[why, const SizedBox(height: AppSpacing.sm)],
        _buildGradeInputColumn(context, isMobile: isMobile),
      ],
    );
  }

  Widget _buildGradeInputColumn(BuildContext context, {bool isMobile = false}) {
    final t = context.tokens;
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
          color: t.subtle,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: t.line),
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
                color: t.ink3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              finalDisplay,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: isMobile ? 18 : 16,
                color: t.ink,
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
          color: t.badSoft,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: t.badLine),
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
                      color: t.bad,
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
            fontSize: isMobile ? 18 : 16,
            color: t.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
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
                backgroundColor: isAgreedYellow ? t.ok : t.acc,
                foregroundColor: isAgreedYellow ? reviewOnOk(t) : t.onAcc,
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
