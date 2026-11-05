import 'package:client_flutter/features/gradebooks/gradebook_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeGradeText chấp nhận dấu phẩy và số nguyên khi gõ điểm', () {
    expect(normalizeGradeText('8,5'), '8.5');
    expect(normalizeGradeText('9'), '9.0');
    expect(normalizeGradeText('10'), '10.0');
    expect(normalizeGradeText('7.'), '7.0');
    expect(normalizeGradeText('  6.5 '), '6.5');
    expect(normalizeGradeText(''), '');
  });

  test('normalizeGradeText không sửa giá trị sai để ô vẫn bị báo đỏ', () {
    expect(normalizeGradeText('11'), '11.0');
    expect(normalizeGradeText('8.55'), '8.55');
    expect(normalizeGradeText('abc'), 'abc');
  });
}
