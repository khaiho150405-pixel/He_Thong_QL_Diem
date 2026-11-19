import 'package:client_flutter/core/school_year.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('từ tháng 8 trở đi thuộc năm học bắt đầu trong năm đó', () {
    expect(schoolYearName(DateTime(2026, 8, 1)), '2026-2027');
    expect(schoolYearName(DateTime(2026, 11, 19)), '2026-2027');
    expect(schoolYearName(DateTime(2026, 12, 31)), '2026-2027');
  });

  test('trước tháng 8 thuộc năm học bắt đầu từ năm trước', () {
    expect(schoolYearName(DateTime(2027, 1, 1)), '2026-2027');
    expect(schoolYearName(DateTime(2027, 7, 31)), '2026-2027');
  });
}
