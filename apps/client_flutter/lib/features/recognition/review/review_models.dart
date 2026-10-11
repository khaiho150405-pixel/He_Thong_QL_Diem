import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

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

/// Huy hiệu mức (màu + biểu tượng + chữ "Đỏ" / "Vàng" / "Xanh").
Widget buildReviewLevelBadge(BuildContext context, String level) {
  Color bg;
  Color fg;
  Color border;
  String label;
  IconData icon;

  switch (level) {
    case 'XANH':
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
      border = Colors.green.shade300;
      label = 'Xanh';
      icon = Icons.check_circle_rounded;
      break;
    case 'VANG':
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
      border = Colors.amber.shade300;
      label = 'Vàng';
      icon = Icons.warning_amber_rounded;
      break;
    case 'DO':
    default:
      bg = Colors.red.shade50;
      fg = Colors.red.shade900;
      border = Colors.red.shade300;
      label = 'Đỏ';
      icon = Icons.error_outline_rounded;
      break;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
