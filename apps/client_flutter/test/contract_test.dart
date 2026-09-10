import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client_flutter/main.dart' as app;

void main() {
  test('grade contract preserves bigint strings and nullable decimals', () {
    final change = GradeChangeInput.fromJson({
      'cellId': '9007199254740993',
      'value': null,
      'reason': 'Test fixture',
    });
    expect(change.toJson()['cellId'], '9007199254740993');
    expect(change.toJson().containsKey('value'), isTrue);
    expect(change.toJson()['value'], isNull);
    final zero = UpdatedCellDto.fromJson({
      'id': '9007199254740993',
      'value': '0.0',
      'status': 'DA_DUYET',
      'source': 'NHAP_TAY',
    });
    expect(zero.toJson()['value'], '0.0');
    final batch = BatchUpdateInput.fromJson({
      'expectedVersion': 7,
      'changes': [change.toJson()],
    });
    expect(batch.toJson()['expectedVersion'], 7);
  });
  test('startup rejects missing environment before rendering login', () {
    expect(app.main, throwsStateError);
  });
  test('generated health and nullable error models round-trip', () {
    final health = HealthDto.fromJson({'status': 'ok'});
    expect(health.toJson(), {'status': 'ok'});
    final error = ErrorDto.fromJson({
      'code': 'DEPENDENCY_UNAVAILABLE',
      'message': 'Unavailable',
      'details': null,
      'requestId': 'test-id',
    });
    expect(error.details, isNull);
    expect(error.toJson()['requestId'], 'test-id');
  });
}
