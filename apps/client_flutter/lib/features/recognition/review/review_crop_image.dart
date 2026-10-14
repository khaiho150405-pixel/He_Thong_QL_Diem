import 'package:flutter/material.dart';

import '../image_preview.dart';

/// Widget hiển thị ảnh ô cắt nhận dạng (Điểm số, Điểm chữ, Họ tên).
/// Bấm / chạm vào ảnh sẽ phóng to bằng [showRecognitionImage].
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
  });

  final String label;
  final String? imageUrl;
  final String nullPlaceholder;
  final double height;
  final double? width;
  final String? subtitle;
  final VoidCallback? onRefresh;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasNoImage = imageUrl == null || imageUrl!.trim().isEmpty;
    final placeholderText =
        (isCancelled || (imageUrl != null && imageUrl!.trim().isEmpty))
        ? 'Ảnh đã xóa'
        : nullPlaceholder;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(100)),
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
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.zoom_in_rounded,
                size: 14,
                color: colorScheme.onSurfaceVariant.withAlpha(150),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: hasNoImage
                ? Center(
                    child: Text(
                      placeholderText,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : InkWell(
                    borderRadius: BorderRadius.circular(6),
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
                      borderRadius: BorderRadius.circular(6),
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
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
