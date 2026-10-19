import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../recognition/image_picker.dart';
import 'repository.dart';

/// Nút "Chọn ảnh" (mọi nền tảng) và "Chụp ảnh" (chỉ Android/iOS), dùng lại
/// `RecognitionImagePicker` của luồng nhận dạng. Ảnh được kiểm sơ bộ ở máy
/// (loại, dung lượng, độ phân giải); backend vẫn kiểm lại byte thật.
class ImageSourceButtons extends ConsumerWidget {
  const ImageSourceButtons({
    super.key,
    required this.onPicked,
    required this.onError,
    this.enabled = true,
    this.pickLabel = 'Chọn ảnh',
  });

  final ValueChanged<RecognitionImage> onPicked;
  final ValueChanged<String> onError;
  final bool enabled;
  final String pickLabel;

  Future<void> _run(Future<RecognitionImage?> Function() source) async {
    try {
      final image = await source();
      if (image == null) return;
      recognitionImageMime(image);
      onPicked(image);
    } catch (error) {
      onError(templateErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picker = ref.read(recognitionImagePickerProvider);
    final canCapture =
        picker is RecognitionCameraPicker &&
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton.icon(
          key: const ValueKey('pick-image'),
          onPressed: enabled ? () => _run(picker.pick) : null,
          icon: const Icon(Icons.image_outlined, size: 18),
          label: Text(pickLabel),
        ),
        if (canCapture)
          OutlinedButton.icon(
            key: const ValueKey('capture-image'),
            onPressed: enabled
                ? () => _run((picker as RecognitionCameraPicker).capture)
                : null,
            icon: const Icon(Icons.photo_camera_outlined, size: 18),
            label: const Text('Chụp ảnh'),
          ),
      ],
    );
  }
}
