import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
