import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

import '../image_preview.dart';

/// Widget hiển thị ảnh gốc của phiếu nhận dạng (ở cột phải trên Web hoặc đầu trang trên Mobile).
class ReviewSourceImage extends StatelessWidget {
  const ReviewSourceImage({
    super.key,
    required this.ticket,
    required this.onRefresh,
    this.isColumn = false,
  });

  final RecognitionTicketDetailDto ticket;
  final VoidCallback onRefresh;
  final bool isColumn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ảnh gốc bảng điểm',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: isColumn ? 320 : 160),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    (ticket.sourceImageUrl.trim().isEmpty ||
                        ticket.status.value == 'DA_HUY')
                    ? _deletedImage(context)
                    : Image.network(
                        ticket.sourceImageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => _expiredImage(context),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    (ticket.sourceImageUrl.trim().isEmpty ||
                        ticket.status.value == 'DA_HUY')
                    ? null
                    : () => showRecognitionImage(
                        context,
                        image: Image.network(
                          ticket.sourceImageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Center(
                            child: Text(
                              'Không tải được ảnh. Đóng và tải lại phiếu để lấy ảnh mới.',
                            ),
                          ),
                        ),
                      ),
                icon: const Icon(Icons.zoom_in, size: 18),
                label: const Text('Phóng to ảnh gốc'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 40),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (isColumn) {
      return SizedBox(
        key: const ValueKey('review-source-image-column'),
        width: 320,
        child: content,
      );
    }

    return content;
  }

  Widget _deletedImage(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 28,
              color: Colors.grey,
            ),
            SizedBox(height: 6),
            Text(
              'Ảnh đã xóa',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expiredImage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Không tải được ảnh gốc. URL có thể đã hết hạn.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('review-refresh-source'),
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Lấy URL ảnh mới'),
          ),
        ],
      ),
    );
  }
}
