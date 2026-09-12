import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecognitionImage {
  const RecognitionImage({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

abstract class RecognitionImagePicker {
  Future<RecognitionImage?> pick();
}

class DeviceRecognitionImagePicker implements RecognitionImagePicker {
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
