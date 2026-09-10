import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client_flutter/main.dart' as app;

void main() {
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
