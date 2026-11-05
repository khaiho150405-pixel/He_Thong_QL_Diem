import 'package:client_flutter/features/academic_catalog/student_enrollment_dialogs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2024, 9, 1);
  final end = DateTime(2025, 5, 31);

  test('ngày hiệu lực mặc định giữ nguyên khi hôm nay nằm trong năm học', () {
    final today = DateTime(2025, 1, 20);
    expect(
      defaultEffectiveDate(yearStart: start, yearEnd: end, today: today),
      today,
    );
  });

  test('ngày hiệu lực mặc định kẹp về cuối năm học đã kết thúc', () {
    expect(
      defaultEffectiveDate(
        yearStart: start,
        yearEnd: end,
        today: DateTime(2026, 11, 5),
      ),
      end,
    );
  });

  test('ngày hiệu lực mặc định phải sau ngày bắt đầu năm học', () {
    expect(
      defaultEffectiveDate(
        yearStart: start,
        yearEnd: end,
        today: DateTime(2024, 8, 1),
      ),
      DateTime(2024, 9, 2),
    );
  });

  test('không biết năm học thì giữ ngày hôm nay', () {
    final today = DateTime(2026, 11, 5);
    expect(defaultEffectiveDate(today: today), today);
  });
}
