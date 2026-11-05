import 'package:client_flutter/core/date_format.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _http(int status, Object? data) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: status,
      data: data,
    ),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  test('400 chung chung của máy chủ được thay bằng gợi ý cụ thể hơn', () {
    const hint = 'Thông tin chưa hợp lệ. Kiểm tra các trường và khoảng ngày.';
    expect(
      errorMessage(_http(400, {'message': 'Yêu cầu không hợp lệ.'})),
      hint,
    );
    expect(errorMessage(_http(400, {'message': 'Bad Request'})), hint);
    expect(errorMessage(_http(400, null)), hint);
  });

  test('400 có thông báo cụ thể thì giữ nguyên', () {
    expect(
      errorMessage(
        _http(400, {'message': 'Ngày kết thúc phải sau ngày bắt đầu'}),
      ),
      'Ngày kết thúc phải sau ngày bắt đầu',
    );
  });

  test('409 chung chung có gợi ý, 409 cụ thể giữ nguyên', () {
    expect(
      errorMessage(_http(409, {'message': 'Yêu cầu không hợp lệ.'})),
      contains('đang được sử dụng'),
    );
    expect(
      errorMessage(_http(409, {'message': 'Lớp đã có bảng điểm'})),
      'Lớp đã có bảng điểm',
    );
  });

  test('formatDateTimeVi dạng dd/MM/yyyy HH:mm', () {
    expect(formatDateTimeVi(DateTime(2026, 11, 5, 9, 7)), '05/11/2026 09:07');
  });
}
