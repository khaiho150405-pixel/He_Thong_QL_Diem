import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../image_preview.dart';
import 'review_page_labels.dart';

/// Mục thu gọn gom các dòng Xanh: "N dòng Xanh — điểm cuối đã điền".
/// Khi mở ra: danh sách gọn mỗi học sinh một hàng gồm STT, họ tên,
/// ảnh ô số, ảnh ô chữ (nhỏ, bấm phóng to, kèm độ tin cậy), điểm cuối (sửa được).
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
    final t = context.tokens;
    final count = rows.length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.okLine),
        boxShadow: t.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const ValueKey('review-green-group'),
          initiallyExpanded: initiallyExpanded,
          backgroundColor: t.surface,
          collapsedBackgroundColor: t.okSoft,
          iconColor: t.ok,
          collapsedIconColor: t.ok,
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Icon(Icons.check_circle_rounded, color: t.ok, size: 22),
          title: Text(
            '$count dòng Xanh — điểm cuối đã điền',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: t.ok,
            ),
          ),
          subtitle: Text(
            'Hai kênh đồng thuận tin cậy. Nhấn để xem hoặc sửa điểm nếu cần.',
            style: TextStyle(fontSize: 12, color: t.ink2),
          ),
          children: [
            Divider(height: 1, color: t.line),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: rows.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: t.line),
              itemBuilder: (context, index) =>
                  _buildRow(context, rows[index], index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    RecognitionEvidenceRowDto row,
    int index,
  ) {
    final t = context.tokens;
    final gradeField = SizedBox(
      width: 74,
      child: readOnly
          ? Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: t.okSoft,
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: Border.all(color: t.okLine),
              ),
              child: Text(
                row.finalValue != null
                    ? '${row.finalValue}'
                    : (values[row.rowId]?.text.isNotEmpty == true
                          ? values[row.rowId]!.text
                          : '—'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: t.ok,
                ),
              ),
            )
          : TextFormField(
              key: ValueKey('review-value-${row.rowId}'),
              controller: values[row.rowId],
              enabled: enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              onChanged: (text) => onGradeChanged(row.rowId, text),
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, color: t.ink),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Thiếu điểm';
                if (RegExp(r'^(10[.]0|[0-9][.][0-9])$').hasMatch(text)) {
                  return null;
                }
                if (RegExp(r'^(10|[0-9])$').hasMatch(text)) {
                  return 'Dạng $text.0';
                }
                return 'Sai định dạng';
              },
            ),
    );

    final stt = SizedBox(
      width: 26,
      child: Text(
        '${row.stt ?? index + 1}',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: t.ink2,
        ),
      ),
    );
    final pageLabel = ReviewPageLabels.labelOf(context, row.order);
    final name = Text(
      pageLabel == null ? row.studentName : '${row.studentName} · $pageLabel',
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: t.ink),
      overflow: TextOverflow.ellipsis,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Màn rộng: một hàng, ảnh số 96px và ảnh chữ 220px (cao 56px).
          if (constraints.maxWidth >= 560) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                stt,
                const SizedBox(width: 6),
                Expanded(child: name),
                const SizedBox(width: 8),
                _cropThumb(
                  context,
                  label: 'Số',
                  url: row.numericCropUrl,
                  width: 96,
                ),
                const SizedBox(width: 8),
                _cropThumb(
                  context,
                  label: 'Chữ',
                  url: row.writtenCropUrl,
                  width: 220,
                ),
                const SizedBox(width: 8),
                gradeField,
              ],
            );
          }
          // Màn hẹp: dòng 1 là STT, tên, điểm cuối; dòng 2 là hai ảnh trải rộng.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  stt,
                  const SizedBox(width: 6),
                  Expanded(child: name),
                  const SizedBox(width: 8),
                  gradeField,
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _cropThumb(
                      context,
                      label: 'Số',
                      url: row.numericCropUrl,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _cropThumb(
                      context,
                      label: 'Chữ',
                      url: row.writtenCropUrl,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// Ảnh ô cắt nhỏ (cao 56) kèm thanh độ tin cậy của kênh.
  Widget _cropThumb(
    BuildContext context, {
    required String label,
    required String? url,
    double? width,
  }) {
    final t = context.tokens;
    final decoration = BoxDecoration(
      color: t.paper,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      border: Border.all(color: t.paperLine),
    );
    final labelStyle = TextStyle(fontSize: 11, color: t.ink3);

    final Widget thumb;
    if (url == null) {
      thumb = Container(
        width: width,
        height: 56,
        decoration: decoration,
        child: Center(child: Text(label, style: labelStyle)),
      );
    } else {
      thumb = InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        onTap: () => showRecognitionImage(
          context,
          image: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Center(child: Text('Lỗi ảnh')),
          ),
        ),
        child: Container(
          width: width,
          height: 56,
          decoration: decoration,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  Center(child: Text(label, style: labelStyle)),
            ),
          ),
        ),
      );
    }

    return thumb;
  }
}
