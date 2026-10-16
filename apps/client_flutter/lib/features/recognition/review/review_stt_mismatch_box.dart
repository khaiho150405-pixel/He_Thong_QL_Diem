import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import 'review_crop_image.dart';
import 'review_models.dart';

/// Bộ màu của chip/khung STT khác: xanh dương (thông tin) khi ghép họ tên đã
/// chắc chắn, đỏ khi nghi lệch học sinh, vàng cảnh báo còn lại.
({Color bg, Color line, Color fg}) _sttColors(
  AppTokens t,
  RecognitionEvidenceRowDto row,
) {
  final isInfo = row.matchLevel?.value == 'XANH';
  final isRed = row.matchLevel?.value == 'DO';
  if (isInfo) return (bg: t.priSoft, line: t.priLine, fg: t.priLink);
  if (isRed) return (bg: t.badSoft, line: t.badLine, fg: t.bad);
  return (bg: t.warnSoft, line: t.warnLine, fg: t.warn);
}

/// Chip hiển thị trên tiêu đề dòng: "STT giấy {sttOnPaper} ≠ hệ thống {stt}" với icon swap_horiz.
Widget buildSttMismatchChip(
  BuildContext context,
  RecognitionEvidenceRowDto row,
) {
  if (row.sttOnPaper == null ||
      row.stt == null ||
      row.sttOnPaper!.toInt() == row.stt) {
    return const SizedBox.shrink();
  }

  final c = _sttColors(context.tokens, row);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
    decoration: BoxDecoration(
      color: c.bg,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: c.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.swap_horiz_rounded, size: 14, color: c.fg),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'STT giấy ${row.sttOnPaper!.toInt()} ≠ hệ thống ${row.stt}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.fg,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

/// Khung ghi chú riêng khi STT trên giấy khác STT hệ thống:
/// - Ngay dưới tiêu đề, full width, icon swap_horiz.
/// - Luôn hiện ảnh ô họ tên (bấm phóng to).
/// - matchLevel == XANH: màu thông tin (xanh dương nhạt).
///   Dòng 1 in đậm: "STT khác nhau: trên giấy là {N}, trong hệ thống là {M}".
///   Dòng 2: "Tờ giấy xếp tên khác hệ thống; đã ghép theo họ tên." (không có checkbox).
/// - matchLevel == VANG/DO/null: màu cảnh báo (vàng; DO thì đỏ).
///   Dòng 1 in đậm: "STT không khớp: trên giấy là {N}, trong hệ thống là {M}".
///   Dòng 2: "Hãy kiểm tra ảnh họ tên có đúng là {studentName} không." + checkbox "Đúng học sinh này".
/// - Chữ >= 14sp, responsive không tràn trên mobile 320px.
class ReviewSttMismatchBox extends StatelessWidget {
  final RecognitionEvidenceRowDto row;
  final bool isConfirmed;
  final ValueChanged<bool>? onConfirmedChanged;
  final bool readOnly;
  final VoidCallback? onRefresh;
  final bool isCancelled;

  const ReviewSttMismatchBox({
    super.key,
    required this.row,
    required this.isConfirmed,
    this.onConfirmedChanged,
    this.readOnly = false,
    this.onRefresh,
    this.isCancelled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (row.sttOnPaper == null ||
        row.stt == null ||
        row.sttOnPaper!.toInt() == row.stt) {
      return const SizedBox.shrink();
    }

    final t = context.tokens;
    final sttPaper = row.sttOnPaper!.toInt();
    final sttSystem = row.stt;
    final isInfo = row.matchLevel?.value == 'XANH';
    final isRed = row.matchLevel?.value == 'DO';
    final c = _sttColors(t, row);

    final String titleText = isInfo
        ? 'STT khác nhau: trên giấy là $sttPaper, trong hệ thống là $sttSystem'
        : 'STT không khớp: trên giấy là $sttPaper, trong hệ thống là $sttSystem';

    final String subtitleText = isInfo
        ? 'Tờ giấy xếp tên khác hệ thống; đã ghép theo họ tên.'
        : 'Hãy kiểm tra ảnh họ tên có đúng là ${row.studentName} không.';

    // Dòng Xanh chỉ cần ghi chú gọn một khối; ảnh họ tên nằm chung hàng với
    // ảnh điểm số/điểm chữ/điểm cuối trong [ReviewRowContent].
    if (isInfo) {
      return Container(
        key: ValueKey('review-stt-box-${row.rowId}'),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: c.line),
        ),
        child: Row(
          children: [
            Icon(Icons.swap_horiz_rounded, size: 18, color: c.fg),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 12,
                runSpacing: 2,
                children: [
                  Text(
                    titleText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.fg,
                    ),
                  ),
                  Text(
                    subtitleText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: c.fg,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      key: ValueKey('review-stt-box-${row.rowId}'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.line, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dòng 1: Icon swap_horiz + Tiêu đề in đậm (>= 14sp)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.swap_horiz_rounded, size: 22, color: c.fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titleText,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: c.fg,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Dòng 2: Nội dung hướng dẫn (>= 14sp)
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              subtitleText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: c.fg,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Ảnh ô họ tên (full width, bấm phóng to)
          ReviewCropImage(
            label: 'Họ tên trên giấy',
            imageUrl: row.nameCropUrl,
            nullPlaceholder: 'Không có ảnh họ tên',
            height: 56,
            onRefresh: onRefresh,
            isCancelled: isCancelled,
            confidence: parseConfidence(row.matchConfidence),
          ),

          // Checkbox xác nhận cho trường hợp cảnh báo (VANG/DO/null), không hiện ở chế độ chỉ xem
          if (!isInfo && !readOnly) ...[
            const SizedBox(height: 8),
            InkWell(
              key: ValueKey('review-stt-confirm-${row.rowId}'),
              onTap: () => onConfirmedChanged?.call(!isConfirmed),
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Checkbox(
                      value: isConfirmed,
                      onChanged: (val) =>
                          onConfirmedChanged?.call(val ?? false),
                      activeColor: isRed ? t.bad : t.pri,
                      checkColor: isRed ? reviewOnOk(t) : t.onPri,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Đúng học sinh này',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isConfirmed ? t.ok : c.fg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
