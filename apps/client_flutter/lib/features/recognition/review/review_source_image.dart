import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
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
    final t = context.tokens;

    final content = Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
        boxShadow: t.shadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.image_outlined, size: 18, color: t.pri),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ảnh gốc bảng điểm',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: t.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: isColumn ? 320 : 200),
              decoration: BoxDecoration(
                color: t.paper,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: t.paperLine),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
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
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 28, color: t.ink3),
            const SizedBox(height: 6),
            Text(
              'Ảnh đã xóa',
              style: TextStyle(
                fontSize: 12,
                color: t.ink3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expiredImage(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Không tải được ảnh gốc. URL có thể đã hết hạn.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: t.ink2),
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
