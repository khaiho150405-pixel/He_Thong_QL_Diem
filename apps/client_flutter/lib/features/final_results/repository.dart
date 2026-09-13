import 'dart:convert';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../authentication/session.dart';

final finalResultsRepositoryProvider = Provider(
  (ref) => FinalResultsRepository(ref.read(apiProvider)),
);

class FinalResultsRepository {
  FinalResultsRepository(this.api);

  final ApiClientDart api;
  static int _sequence = 0;
  String? _pendingSignature;
  String? _pendingKey;

  String _key(String signature) {
    if (_pendingSignature == signature) return _pendingKey!;
    _pendingSignature = signature;
    _pendingKey =
        'flutter-final-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';
    return _pendingKey!;
  }

  Future<List<FinalResultDto>> list(num gradebookId) async {
    String? cursor;
    final results = <FinalResultDto>[];
    final seen = <String>{};
    do {
      final page = (await api.getFinalResultsApi().finalResultsList(
        gradebookId: gradebookId,
        cursor: cursor,
      )).data!;
      results.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor != null && !seen.add(cursor)) {
        throw StateError('Cursor kết quả tổng kết bị lặp.');
      }
    } while (cursor != null);
    return results;
  }

  Future<CalculateFinalResultsDto> calculate({
    required num gradebookId,
    required num expectedVersion,
    required String reason,
  }) async {
    final input = CalculateFinalResultsInput(
      expectedVersion: expectedVersion,
      reason: reason,
    );
    final signature = '$gradebookId:${jsonEncode(input)}';
    final key = _key(signature);
    final result = (await api.getFinalResultsApi().finalResultsCalculate(
      xIdempotencyKey: key,
      gradebookId: gradebookId,
      calculateFinalResultsInput: input,
    )).data!;
    if (_pendingKey == key) {
      _pendingSignature = null;
      _pendingKey = null;
    }
    return result;
  }

  Future<List<CalculationHistoryDto>> history({
    required num gradebookId,
    required String resultId,
  }) async {
    String? cursor;
    final items = <CalculationHistoryDto>[];
    final seen = <String>{};
    do {
      final page = (await api.getFinalResultsApi().finalResultsHistory(
        resultId: resultId,
        gradebookId: gradebookId,
        cursor: cursor,
      )).data!;
      items.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor != null && !seen.add(cursor)) {
        throw StateError('Cursor lịch sử tổng kết bị lặp.');
      }
    } while (cursor != null);
    return items;
  }
}
