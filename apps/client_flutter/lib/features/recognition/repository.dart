import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../authentication/session.dart';
import 'image_picker.dart';

final recognitionRepositoryProvider = Provider(
  (ref) => RecognitionRepository(ref.read(apiProvider)),
);

class RecognitionRepository {
  RecognitionRepository(this.api);

  final ApiClientDart api;
  static int _keySequence = 0;
  String? _pendingSignature;
  String? _pendingKey;

  Future<List<RecognitionTicketDto>> list(num gradebookId) async =>
      (await api.getRecognitionApi().recognitionList(
        gradebookId: gradebookId,
      )).data!;

  Future<RecognitionTicketDetailDto> detail({
    required num gradebookId,
    required String ticketId,
  }) async => (await api.getRecognitionApi().recognitionDetail(
    ticketId: ticketId,
    gradebookId: gradebookId,
  )).data!;

  Future<RecognitionReceiptDto> upload({
    required num gradebookId,
    required num componentId,
    required int declaredRows,
    required RecognitionImage image,
  }) async {
    final signature =
        '$gradebookId:$componentId:$declaredRows:${identityHashCode(image)}';
    if (_pendingSignature != signature) {
      _pendingSignature = signature;
      _pendingKey =
          'flutter-recognition-${DateTime.now().microsecondsSinceEpoch}-${_keySequence++}';
    }
    final lower = image.name.toLowerCase();
    final type = lower.endsWith('.png')
        ? DioMediaType('image', 'png')
        : DioMediaType('image', 'jpeg');
    final result = (await api.getRecognitionApi().recognitionUpload(
      xIdempotencyKey: _pendingKey!,
      gradebookId: gradebookId,
      image: MultipartFile.fromBytes(
        image.bytes,
        filename: image.name,
        contentType: type,
      ),
      componentId: componentId.toInt(),
      declaredRows: declaredRows,
    )).data!;
    _pendingSignature = null;
    _pendingKey = null;
    return result;
  }
}
