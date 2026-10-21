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

  Future<GradebookListDto> list({num? cursor, num? yearId}) async =>
      (await api.getGradebooksApi().gradebooksList(
        cursor: cursor,
        yearId: yearId,
      )).data!;

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

  Future<GradebookDto> lockColumn({
    required num bookId,
    required num componentId,
    required num expectedVersion,
  }) async {
    final input = LockInput(expectedVersion: expectedVersion);
    final key = _key(
      'column-lock',
      '$bookId:$componentId:${jsonEncode(input)}',
    );
    final result = (await api.getGradebooksApi().gradebooksLockColumn(
      id: bookId,
      componentId: componentId,
      xIdempotencyKey: key,
      lockInput: input,
    )).data!;
    _complete('column-lock', key);
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

  Future<List<GradebookHistoryEntryDto>> historyAll({
    required num bookId,
  }) async {
    String? cursor;
    final items = <GradebookHistoryEntryDto>[];
    final seen = <String>{};
    do {
      final page = (await api.getGradebooksApi().gradebooksHistoryAll(
        id: bookId,
        cursor: cursor,
      )).data!;
      items.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor != null && !seen.add(cursor)) {
        throw StateError('Cursor lịch sử bảng điểm bị lặp.');
      }
    } while (cursor != null);
    return items;
  }

  Future<ExemptionsResultDto> setExemptions({
    required num bookId,
    required num expectedVersion,
    required List<ExemptionChangeInput> changes,
  }) async {
    final input = ExemptionsInput(
      expectedVersion: expectedVersion,
      changes: changes,
    );
    final key = _key('exemptions', '$bookId:${jsonEncode(input)}');
    final result = (await api.getGradebooksApi().gradebooksExemptions(
      xIdempotencyKey: key,
      id: bookId,
      exemptionsInput: input,
    )).data!;
    _complete('exemptions', key);
    return result;
  }

  Future<List<MissingStudentDto>> missingStudents(num bookId) async {
    final res =
        await api.getGradebooksApi().gradebooksMissingStudents(id: bookId);
    return res.data?.items ?? [];
  }

  Future<LateStudentResultDto> addLateStudent({
    required num bookId,
    required num studentId,
    required String reason,
  }) async {
    final input = LateStudentInput(studentId: studentId, reason: reason);
    final key =
        _key('late-student', '$bookId:$studentId:${jsonEncode(input)}');
    final result = (await api.getGradebooksApi().gradebooksLateStudent(
      xIdempotencyKey: key,
      id: bookId,
      lateStudentInput: input,
    )).data!;
    _complete('late-student', key);
    return result;
  }
}
