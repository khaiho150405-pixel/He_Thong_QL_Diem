import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../../app/widgets/app_badge.dart';

/// Lý do ngắn, KHÔNG chứa con số (chỉ cho dòng Vàng/Đỏ).
/// - matchLevel == DO → "Nghi lệch học sinh"
/// - ngược lại theo comparison:
///   - LECH → "Số và chữ khác nhau"
///   - MOT_KENH → "Không đọc được điểm số" (nếu numericCropUrl/numericValue null) hoặc "Không đọc được điểm chữ"
///   - KHONG_DOC_DUOC → "Máy không đọc được, nhập tay"
/// - matchLevel == VANG → thêm "Kiểm tra đúng học sinh"
String getRowShortReason(RecognitionEvidenceRowDto row) {
  if (row.reviewLevel.value == 'XANH') return '';

  final matchLevel = row.matchLevel?.value;

  // 1) matchLevel == DO → "Kiểm tra đúng học sinh"
  if (matchLevel == 'DO') {
    return 'Kiểm tra đúng học sinh';
  }

  // 2) matchLevel == VANG (vd STT giấy khác STT hệ thống) → "Kiểm tra đúng học sinh (STT trên giấy khác)"
  if (matchLevel == 'VANG') {
    return 'Kiểm tra đúng học sinh (STT trên giấy khác)';
  }

  // 3) comparison == KHONG_DOC_DUOC hoặc ô điểm không có ảnh → "Ô điểm mờ, nhập theo ảnh"
  final comp = row.comparison.value;
  final missingCrop = row.numericCropUrl == null || row.writtenCropUrl == null;
  if (comp == 'KHONG_DOC_DUOC' || missingCrop) {
    return 'Ô điểm mờ, nhập theo ảnh';
  }

  // 4) reviewLevel == DO → "Nhập điểm theo ảnh"
  if (row.reviewLevel.value == 'DO') {
    return 'Nhập điểm theo ảnh';
  }

  // 5) reviewLevel == VANG → "Kiểm tra điểm đã điền"
  if (row.reviewLevel.value == 'VANG') {
    return 'Kiểm tra điểm đã điền';
  }

  return '';
}

/// Ảnh ô họ tên CHỈ hiện khi matchLevel là VANG hoặc DO (kèm dòng "Kiểm tra đúng học sinh");
/// matchLevel XANH hoặc null → ẩn.
bool shouldShowNameCrop(RecognitionEvidenceRowDto row) {
  final match = row.matchLevel?.value;
  return match == 'VANG' || match == 'DO';
}

/// Kiểm tra giá trị điểm hợp lệ (0.0 đến 10.0 với một chữ số thập phân).
bool isValidGrade(String text) {
  final trimmed = text.trim();
  return RegExp(r'^(10[.]0|[0-9][.][0-9])$').hasMatch(trimmed);
}

/// Kiểm tra lý do hợp lệ (1–500 ký tự).
bool isValidReason(String text) {
  final trimmed = text.trim();
  return trimmed.isNotEmpty && trimmed.length <= 500;
}

/// Kiểm tra xem dòng Đỏ đã được xử lý chưa:
/// - Có điểm hợp lệ
/// - HOẶC bấm để trống và có lý do hợp lệ
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

/// Kiểm tra xem dòng Vàng đã được xem / xử lý chưa:
/// - Bấm "✓ Đồng ý"
/// - HOẶC sửa điểm (khác giá trị gợi ý và hợp lệ hoặc để trống có lý do)
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

/// Bộ màu của một mức Xanh / Vàng / Đỏ, lấy từ token (đúng cả chế độ tối).
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

/// Màu theo mức: `XANH` là ok, `VANG` là warn, còn lại (`DO`) là bad.
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

/// Chữ trên nền màu đặc `ok` (nút "Đã xem").
Color reviewOnOk(AppTokens t) =>
    t.brightness == Brightness.light ? t.onPri : t.onAcc;

/// Độ tin cậy 0..1 từ chuỗi số của API (vd. '0.9600'); null nếu không có.
double? parseConfidence(String? raw) {
  if (raw == null) return null;
  final value = double.tryParse(raw.trim());
  if (value == null || value.isNaN) return null;
  return value.clamp(0.0, 1.0);
}

/// Nhãn mức: "Xanh" / "Vàng" / "Đỏ".
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

/// Huy hiệu mức ([AppBadge] ok / warn / bad, chữ "Xanh" / "Vàng" / "Đỏ").
Widget buildReviewLevelBadge(BuildContext context, String level) {
  final tone = switch (level) {
    'XANH' => AppBadgeTone.ok,
    'VANG' => AppBadgeTone.warn,
    _ => AppBadgeTone.bad,
  };
  return AppBadge(reviewLevelLabel(level), tone: tone);
}
