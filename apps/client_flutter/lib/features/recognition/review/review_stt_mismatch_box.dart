import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

import 'review_crop_image.dart';

/// Chip hiển thị trên tiêu đề dòng: "STT giấy {sttOnPaper} ≠ hệ thống {stt}" với icon swap_horiz.
Widget buildSttMismatchChip(RecognitionEvidenceRowDto row) {
  if (row.sttOnPaper == null ||
      row.stt == null ||
      row.sttOnPaper!.toInt() == row.stt) {
    return const SizedBox.shrink();
  }

  final isInfo = row.matchLevel?.value == 'XANH';
  final isRed = row.matchLevel?.value == 'DO';

  final Color bg = isInfo
      ? Colors.blue.shade50
      : (isRed ? Colors.red.shade50 : Colors.orange.shade50);
  final Color border = isInfo
      ? Colors.blue.shade200
      : (isRed ? Colors.red.shade200 : Colors.orange.shade300);
  final Color textCol = isInfo
      ? Colors.blue.shade800
      : (isRed ? Colors.red.shade900 : Colors.orange.shade900);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.swap_horiz_rounded, size: 14, color: textCol),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'STT giấy ${row.sttOnPaper!.toInt()} ≠ hệ thống ${row.stt}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textCol,
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
/// - matchLevel == VANG/DO/null: màu cảnh báo (cam; DO thì đỏ).
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

    final sttPaper = row.sttOnPaper!.toInt();
    final sttSystem = row.stt;
    final isInfo = row.matchLevel?.value == 'XANH';
    final isRed = row.matchLevel?.value == 'DO';

    final Color bgColor = isInfo
        ? Colors.blue.shade50.withAlpha(220)
        : (isRed
              ? Colors.red.shade50.withAlpha(220)
              : Colors.orange.shade50.withAlpha(220));

    final Color borderColor = isInfo
        ? Colors.blue.shade300
        : (isRed ? Colors.red.shade300 : Colors.orange.shade300);

    final Color primaryColor = isInfo
        ? Colors.blue.shade900
        : (isRed ? Colors.red.shade900 : Colors.orange.shade900);

    final Color iconColor = isInfo
        ? Colors.blue.shade800
        : (isRed ? Colors.red.shade800 : Colors.orange.shade900);

    final String titleText = isInfo
        ? 'STT khác nhau: trên giấy là $sttPaper, trong hệ thống là $sttSystem'
        : 'STT không khớp: trên giấy là $sttPaper, trong hệ thống là $sttSystem';

    final String subtitleText = isInfo
        ? 'Tờ giấy xếp tên khác hệ thống; đã ghép theo họ tên.'
        : 'Hãy kiểm tra ảnh họ tên có đúng là ${row.studentName} không.';

    return Container(
      key: ValueKey('review-stt-box-${row.rowId}'),
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dòng 1: Icon swap_horiz + Tiêu đề in đậm (>= 14sp)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.swap_horiz_rounded, size: 22, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titleText,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
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
                color: primaryColor.withAlpha(220),
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
          ),

          // Checkbox xác nhận cho trường hợp cảnh báo (VANG/DO/null), không hiện ở chế độ chỉ xem
          if (!isInfo && !readOnly) ...[
            const SizedBox(height: 8),
            InkWell(
              key: ValueKey('review-stt-confirm-${row.rowId}'),
              onTap: () => onConfirmedChanged?.call(!isConfirmed),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Checkbox(
                      value: isConfirmed,
                      onChanged: (val) =>
                          onConfirmedChanged?.call(val ?? false),
                      activeColor: isRed
                          ? Colors.red.shade700
                          : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Đúng học sinh này',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isConfirmed
                              ? Colors.green.shade900
                              : primaryColor,
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
