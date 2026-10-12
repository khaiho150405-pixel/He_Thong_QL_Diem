import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

import 'review_row_content.dart';

/// Thẻ hiển thị một dòng cần đối chiếu (Đỏ / Vàng) trên Web hoặc Mobile.
class ReviewRowCard extends StatelessWidget {
  const ReviewRowCard({
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
    this.isDesktop = false,
    this.readOnly = false,
    this.isSttConfirmed = false,
    this.onSttConfirmedChanged,
    this.isCancelled = false,
  });

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
  final bool isDesktop;
  final bool readOnly;
  final bool isSttConfirmed;
  final ValueChanged<bool>? onSttConfirmedChanged;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRed = row.reviewLevel.value == 'DO';
    final isYellow = row.reviewLevel.value == 'VANG';

    final borderColor = isRed
        ? Colors.red.shade200
        : (isYellow
              ? Colors.amber.shade200
              : colorScheme.outlineVariant.withAlpha(100));

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor, width: isRed ? 1.5 : 1.0),
      ),
      color: isRed
          ? Colors.red.shade50.withAlpha(30)
          : (isYellow ? Colors.amber.shade50.withAlpha(20) : Colors.white),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = isDesktop && constraints.maxWidth >= 760;
            return ReviewRowContent(
              row: row,
              valueController: valueController,
              reasonController: reasonController,
              isLeavingEmpty: isLeavingEmpty,
              isAgreedYellow: isAgreedYellow,
              enabled: enabled,
              onGradeChanged: onGradeChanged,
              onReasonChanged: onReasonChanged,
              onLeaveEmpty: onLeaveEmpty,
              onCancelLeaveEmpty: onCancelLeaveEmpty,
              onAgreeYellow: onAgreeYellow,
              focusNode: focusNode,
              onFocusNext: onFocusNext,
              onRefresh: onRefresh,
              readOnly: readOnly,
              isSttConfirmed: isSttConfirmed,
              onSttConfirmedChanged: onSttConfirmedChanged,
              layout: isWide ? ReviewRowLayout.wide : ReviewRowLayout.narrow,
              showInlineAgreeButton: true,
              isCancelled: isCancelled,
            );
          },
        ),
      ),
    );
  }
}
