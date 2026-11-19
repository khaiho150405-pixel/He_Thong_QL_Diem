import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../../app/widgets/app_badge.dart';

String getRowShortReason(RecognitionEvidenceRowDto row) {
  if (row.reviewLevel.value == 'XANH') return '';

  final matchLevel = row.matchLevel?.value;

  if (matchLevel == 'DO') {
    return 'Kiểm tra đúng học sinh';
  }

  if (matchLevel == 'VANG') {
    return 'Kiểm tra đúng học sinh (STT trên giấy khác)';
  }

  final comp = row.comparison.value;
  final missingCrop = row.numericCropUrl == null || row.writtenCropUrl == null;
  if (comp == 'KHONG_DOC_DUOC' || missingCrop) {
    return 'Ô điểm mờ, nhập theo ảnh';
  }

  if (row.reviewLevel.value == 'DO') {
    return 'Nhập điểm theo ảnh';
  }

  if (row.reviewLevel.value == 'VANG') {
    return 'Kiểm tra điểm đã điền';
  }

  return '';
}

bool shouldShowNameCrop(RecognitionEvidenceRowDto row) {
  final match = row.matchLevel?.value;
  return match == 'VANG' || match == 'DO';
}

bool isValidGrade(String text) {
  final trimmed = text.trim();
  return RegExp(r'^(10[.]0|[0-9][.][0-9])$').hasMatch(trimmed);
}

bool isValidReason(String text) {
  final trimmed = text.trim();
  return trimmed.isNotEmpty && trimmed.length <= 500;
}

bool isRedRowHandled({
  required String? value,
  required String? reason,
  required bool leavingEmpty,
}) {
  final val = value?.trim() ?? '';
  if (isValidGrade(val)) return true;
  if (leavingEmpty && val.isEmpty && isValidReason(reason ?? '')) return true;
  return false;
}

bool isYellowRowHandled({
  required String? value,
  required String? reason,
  required String? suggestedValue,
  required bool agreedYellow,
  required bool leavingEmpty,
}) {
  if (agreedYellow) return true;
  final val = value?.trim() ?? '';
  final initial = suggestedValue?.trim() ?? '';
  if (val != initial) {
    if (isValidGrade(val)) return true;
    if (leavingEmpty && val.isEmpty && isValidReason(reason ?? '')) return true;
  }
  return false;
}

@immutable
class ReviewLevelColors {
  const ReviewLevelColors({
    required this.fg,
    required this.soft,
    required this.line,
  });

  final Color fg;
  final Color soft;
  final Color line;
}

ReviewLevelColors reviewLevelColors(AppTokens t, String level) {
  switch (level) {
    case 'XANH':
      return ReviewLevelColors(fg: t.ok, soft: t.okSoft, line: t.okLine);
    case 'VANG':
      return ReviewLevelColors(fg: t.warn, soft: t.warnSoft, line: t.warnLine);
    case 'DO':
    default:
      return ReviewLevelColors(fg: t.bad, soft: t.badSoft, line: t.badLine);
  }
}

Color reviewOnOk(AppTokens t) =>
    t.brightness == Brightness.light ? t.onPri : t.onAcc;

String reviewLevelLabel(String level) {
  switch (level) {
    case 'XANH':
      return 'Xanh';
    case 'VANG':
      return 'Vàng';
    case 'DO':
    default:
      return 'Đỏ';
  }
}

Widget buildReviewLevelBadge(BuildContext context, String level) {
  final tone = switch (level) {
    'XANH' => AppBadgeTone.ok,
    'VANG' => AppBadgeTone.warn,
    _ => AppBadgeTone.bad,
  };
  return AppBadge(reviewLevelLabel(level), tone: tone, dot: false);
}
