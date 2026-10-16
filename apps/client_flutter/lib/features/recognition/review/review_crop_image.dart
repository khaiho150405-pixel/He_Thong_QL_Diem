import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../../app/widgets/app_progress.dart';
import '../image_preview.dart';

/// Widget hiển thị ảnh ô cắt nhận dạng (Điểm số, Điểm chữ, Họ tên).
/// Bấm / chạm vào ảnh sẽ phóng to bằng [showRecognitionImage].
///
/// Khi có [confidence] (0..1) hiện thanh [AppConfidenceBar] kèm phần trăm dưới
/// ảnh; khi có [readValue] hiện giá trị máy đọc được của kênh đó (bất biến 3:
/// ảnh ô cắt luôn đi cùng kết quả và độ tin cậy của từng kênh).
class ReviewCropImage extends StatelessWidget {
  const ReviewCropImage({
    super.key,
    required this.label,
    required this.imageUrl,
    this.nullPlaceholder = 'Không có ảnh',
    this.height = 72,
    this.width,
    this.subtitle,
    this.onRefresh,
    this.isCancelled = false,
    this.confidence,
    this.readValue,
    this.showRead = false,
  });

  final String label;
  final String? imageUrl;
  final String nullPlaceholder;
  final double height;
  final double? width;
  final String? subtitle;
  final VoidCallback? onRefresh;
  final bool isCancelled;

  /// Độ tin cậy 0..1 của kênh; null thì không vẽ thanh.
  final double? confidence;

  /// Giá trị máy đọc của kênh (đã chuẩn hóa); chỉ hiện khi [showRead] bật.
  final String? readValue;

  /// Bật dòng "Máy đọc: …" (kênh Điểm số / Điểm chữ). Ảnh họ tên không dùng.
  final bool showRead;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final base = Theme.of(context).textTheme.bodySmall;
    final hasNoImage = imageUrl == null || imageUrl!.trim().isEmpty;
    final placeholderText =
        (isCancelled || (imageUrl != null && imageUrl!.trim().isEmpty))
        ? 'Ảnh đã xóa'
        : nullPlaceholder;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: t.subtle,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: base?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.ink3,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.zoom_in_rounded, size: 14, color: t.ink3),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              color: t.paper,
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border: Border.all(color: t.paperLine),
            ),
            child: hasNoImage
                ? Center(
                    child: Text(
                      placeholderText,
                      style: base?.copyWith(fontSize: 11, color: t.ink3),
                    ),
                  )
                : InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    onTap: () => showRecognitionImage(
                      context,
                      image: Image.network(
                        imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Center(
                          child: Text(
                            'Không tải được ảnh. Đóng và tải lại phiếu.',
                          ),
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Center(
                              child: IconButton(
                                tooltip: 'Ảnh hết hạn. Nhấn để tải lại.',
                                onPressed: onRefresh,
                                icon: Icon(
                                  Icons.refresh_rounded,
                                  size: 20,
                                  color: t.ink2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          if (confidence != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: AppConfidenceBar(value: confidence!)),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${(confidence! * 100).round()}%',
                  style: base?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.ink2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
          if (showRead) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              readValue == null || readValue!.trim().isEmpty
                  ? 'Máy không đọc được'
                  : 'Máy đọc: ${readValue!.trim()}',
              style: base?.copyWith(fontSize: 12.5, color: t.ink2),
            ),
          ],
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: base?.copyWith(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: t.ink3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
