import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class RecognitionImage {
  const RecognitionImage({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

abstract class RecognitionImagePicker {
  Future<RecognitionImage?> pick();
}

abstract interface class RecognitionCameraPicker {
  Future<RecognitionImage?> capture();
  Future<RecognitionImage?> recover();
}

class RecognitionImageException implements Exception {
  const RecognitionImageException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Client preflight only; the API still validates the actual upload bytes.
String recognitionImageMime(RecognitionImage image) {
  final bytes = image.bytes;
  if (bytes.isEmpty) {
    throw const RecognitionImageException('Ảnh trống. Hãy chọn lại ảnh.');
  }
  if (bytes.length > 10 * 1024 * 1024) {
    throw const RecognitionImageException(
      'Ảnh vượt quá 10 MB. Hãy chọn ảnh có dung lượng nhỏ hơn.',
    );
  }
  int width = 0, height = 0;
  String? mime;
  final view = ByteData.sublistView(bytes);
  if (bytes.length >= 24 &&
      listEquals(bytes.take(8).toList(), const [
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
      ])) {
    mime = 'png';
    width = view.getUint32(16);
    height = view.getUint32(20);
  } else if (bytes.length >= 4 && bytes[0] == 255 && bytes[1] == 216) {
    mime = 'jpeg';
    int offset = 2;
    while (offset + 1 < bytes.length) {
      if (bytes[offset++] != 255) continue;
      while (offset < bytes.length && bytes[offset] == 255) {
        offset++;
      }
      if (offset >= bytes.length) break;
      final marker = bytes[offset++];
      if (marker == 217 || marker == 218) break;
      if (marker == 1 || (marker >= 208 && marker <= 215)) continue;
      if (offset + 2 > bytes.length) break;
      final length = view.getUint16(offset);
      if (length < 2 || offset + length > bytes.length) break;
      if (const [
            192,
            193,
            194,
            195,
            197,
            198,
            199,
            201,
            202,
            203,
            205,
            206,
            207,
          ].contains(marker) &&
          length >= 7) {
        height = view.getUint16(offset + 3);
        width = view.getUint16(offset + 5);
        break;
      }
      offset += length;
    }
  }
  if (mime == null || width < 1 || height < 1) {
    throw const RecognitionImageException(
      'Chỉ hỗ trợ ảnh PNG/JPEG hợp lệ. Với HEIC, hãy chuyển sang JPEG trước.',
    );
  }
  if (width > 10000 || height > 10000 || width * height > 40000000) {
    throw const RecognitionImageException(
      'Ảnh quá lớn (tối đa 10.000 pixel mỗi chiều và 40 triệu pixel).',
    );
  }
  return mime;
}

class DeviceRecognitionImagePicker
    implements RecognitionImagePicker, RecognitionCameraPicker {
  final ImagePicker _camera = ImagePicker();
  Future<RecognitionImage> _read(XFile file) async {
    if (await file.length() > 10 * 1024 * 1024) {
      throw const RecognitionImageException(
        'Ảnh vượt quá 10 MB. Hãy chọn ảnh nhỏ hơn.',
      );
    }
    return RecognitionImage(name: file.name, bytes: await file.readAsBytes());
  }

  @override
  Future<RecognitionImage?> capture() async {
    try {
      final photo = await _camera.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        requestFullMetadata: false,
      );
      return photo == null ? null : await _read(photo);
    } on PlatformException catch (error) {
      throw RecognitionImageException(switch (error.code) {
        'camera_access_denied' ||
        'camera_access_denied_without_prompt' ||
        'camera_access_restricted' =>
          'Chưa có quyền camera. Hãy cho phép camera trong cài đặt ứng dụng hoặc chọn ảnh đã chụp.',
        _ => 'Không mở được camera. Hãy thử lại hoặc chọn ảnh đã chụp.',
      });
    }
  }

  @override
  Future<RecognitionImage?> recover() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final response = await _camera.retrieveLostData();
    if (response.exception != null) {
      throw const RecognitionImageException(
        'Không khôi phục được ảnh chụp. Hãy chụp hoặc chọn ảnh lại.',
      );
    }
    final files = response.files;
    return files == null || files.isEmpty ? null : await _read(files.first);
  }

  @override
  Future<RecognitionImage?> pick() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null) return null;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) throw StateError('Không đọc được tệp đã chọn.');
    return RecognitionImage(name: file.name, bytes: bytes);
  }
}

final recognitionImagePickerProvider = Provider<RecognitionImagePicker>(
  (_) => DeviceRecognitionImagePicker(),
);
