import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

import '../image_preview.dart';

/// Mục thu gọn gom các dòng Xanh: "N dòng Xanh — điểm cuối đã điền".
/// Khi mở ra: danh sách gọn mỗi học sinh một hàng gồm STT, họ tên,
/// ảnh ô số, ảnh ô chữ (nhỏ, bấm phóng to), điểm cuối (sửa được).
class ReviewGreenGroup extends StatelessWidget {
  const ReviewGreenGroup({
    super.key,
    required this.rows,
    required this.values,
    required this.enabled,
    required this.onGradeChanged,
    this.initiallyExpanded = false,
    this.readOnly = false,
  });

  final List<RecognitionEvidenceRowDto> rows;
  final Map<String, TextEditingController> values;
  final bool enabled;
  final void Function(String rowId, String text) onGradeChanged;
  final bool initiallyExpanded;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final count = rows.length;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.green.shade200),
      ),
      color: Colors.green.shade50.withAlpha(25),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const ValueKey('review-green-group'),
          initiallyExpanded: initiallyExpanded,
          leading: Icon(
            Icons.check_circle_rounded,
            color: Colors.green.shade700,
            size: 22,
          ),
          title: Text(
            '$count dòng Xanh — điểm cuối đã điền',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Colors.green.shade900,
            ),
          ),
          subtitle: Text(
            'Hai kênh đồng thuận tin cậy. Nhấn để xem hoặc sửa điểm nếu cần.',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          children: [
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = rows[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      // STT & Tên học sinh
                      SizedBox(
                        width: 26,
                        child: Text(
                          '${row.stt ?? index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          row.studentName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Ảnh ô Điểm số (nhỏ, bấm phóng to)
                      _cropThumb(context, label: 'Số', url: row.numericCropUrl),
                      const SizedBox(width: 6),

                      // Ảnh ô Điểm chữ (nhỏ, bấm phóng to)
                      _cropThumb(
                        context,
                        label: 'Chữ',
                        url: row.writtenCropUrl,
                      ),
                      const SizedBox(width: 6),

                      // Điểm cuối (sửa được hoặc chỉ xem)
                      SizedBox(
                        width: 74,
                        child: readOnly
                            ? Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50.withAlpha(80),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                                child: Text(
                                  row.finalValue != null
                                      ? '${row.finalValue}'
                                      : (values[row.rowId]?.text.isNotEmpty ==
                                                true
                                            ? values[row.rowId]!.text
                                            : '—'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              )
                            : TextFormField(
                                key: ValueKey('review-value-${row.rowId}'),
                                controller: values[row.rowId],
                                enabled: enabled,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textInputAction: TextInputAction.next,
                                onChanged: (text) =>
                                    onGradeChanged(row.rowId, text),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) return 'Thiếu điểm';
                                  if (RegExp(
                                    r'^(10[.]0|[0-9][.][0-9])$',
                                  ).hasMatch(text)) {
                                    return null;
                                  }
                                  if (RegExp(r'^(10|[0-9])$').hasMatch(text)) {
                                    return 'Dạng $text.0';
                                  }
                                  return 'Sai định dạng';
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _cropThumb(
    BuildContext context, {
    required String label,
    required String? url,
  }) {
    if (url == null) {
      return Container(
        width: 46,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => showRecognitionImage(
        context,
        image: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Center(child: Text('Lỗi ảnh')),
        ),
      ),
      child: Container(
        width: 46,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Center(
              child: Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
