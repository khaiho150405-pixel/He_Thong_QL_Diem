import 'dart:convert';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../authentication/session.dart';

final gradebooksRepositoryProvider = Provider(
  (ref) => GradebooksRepository(ref.read(apiProvider)),
);

class GradebooksRepository {
  GradebooksRepository(this.api);

  final ApiClientDart api;
  static int _keySequence = 0;
  final _pendingSignatures = <String, String>{};
  final _pendingKeys = <String, String>{};

  String _key(String operation, String signature) {
    if (_pendingSignatures[operation] == signature) {
      return _pendingKeys[operation]!;
    }
    final key =
        'flutter-$operation-${DateTime.now().microsecondsSinceEpoch}-${_keySequence++}';
    _pendingSignatures[operation] = signature;
    _pendingKeys[operation] = key;
    return key;
  }

  void _complete(String operation, String key) {
    if (_pendingKeys[operation] == key) {
      _pendingSignatures.remove(operation);
      _pendingKeys.remove(operation);
    }
  }

  Future<GradebookListDto> list({num? cursor}) async =>
      (await api.getGradebooksApi().gradebooksList(cursor: cursor)).data!;

  Future<GradebookDto> create({
    required num classId,
    required num subjectId,
    required num termId,
  }) async => (await api.getGradebooksApi().gradebooksCreate(
    createGradebookInput: CreateGradebookInput(
      classId: classId,
      subjectId: subjectId,
      termId: termId,
    ),
  )).data!;

  Future<CellsResponseDto> cells(num bookId) async {
    String? cursor;
    GradebookDto? book;
    final items = <GradeCellDto>[];
    final seen = <String>{};
    do {
      final page = (await api.getGradebooksApi().gradebooksCells(
        id: bookId,
        cursor: cursor,
      )).data!;
      book = page.book;
      items.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor != null && !seen.add(cursor)) {
        throw StateError('Cursor lưới điểm bị lặp.');
      }
    } while (cursor != null);
    return CellsResponseDto(book: book, items: items, nextCursor: null);
  }

  Future<BatchUpdateResultDto> update({
    required num bookId,
    required num expectedVersion,
    required List<GradeChangeInput> changes,
  }) async {
    final input = BatchUpdateInput(
      expectedVersion: expectedVersion,
      changes: changes,
    );
    final key = _key('batch', '$bookId:${jsonEncode(input)}');
    final result = (await api.getGradebooksApi().gradebooksBatchUpdate(
      xIdempotencyKey: key,
      id: bookId,
      batchUpdateInput: input,
    )).data!;
    _complete('batch', key);
    return result;
  }

  Future<GradebookDto> syncRoster({
    required num bookId,
    required num expectedVersion,
  }) async {
    final input = LockInput(expectedVersion: expectedVersion);
    final key = _key('sync', '$bookId:${jsonEncode(input)}');
    final result = (await api.getGradebooksApi().gradebooksSyncRoster(
      xIdempotencyKey: key,
      id: bookId,
      lockInput: input,
    )).data!;
    _complete('sync', key);
    return result;
  }

  Future<GradebookDto> lock({
    required num bookId,
    required num expectedVersion,
  }) async {
    final input = LockInput(expectedVersion: expectedVersion);
    final key = _key('lock', '$bookId:${jsonEncode(input)}');
    final result = (await api.getGradebooksApi().gradebooksLock(
      xIdempotencyKey: key,
      id: bookId,
      lockInput: input,
    )).data!;
    _complete('lock', key);
    return result;
  }

  Future<List<GradeHistoryEntryDto>> history({
    required num bookId,
    required String cellId,
  }) async {
    String? cursor;
    final items = <GradeHistoryEntryDto>[];
    final seen = <String>{};
    do {
      final page = (await api.getGradebooksApi().gradebooksHistory(
        id: bookId,
        cellId: cellId,
        cursor: cursor,
      )).data!;
      items.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor != null && !seen.add(cursor)) {
        throw StateError('Cursor lịch sử bị lặp.');
      }
    } while (cursor != null);
    return items;
  }
}
