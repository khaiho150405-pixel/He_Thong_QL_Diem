import 'package:client_flutter/core/text_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('foldVietnamese bỏ dấu và đổi chữ thường', () {
    expect(foldVietnamese('Toán học'), 'toan hoc');
    expect(foldVietnamese('Đặng Thị Hương'), 'dang thi huong');
    expect(foldVietnamese('Giáo dục công dân'), 'giao duc cong dan');
    expect(foldVietnamese('Ngữ văn · HỌC KỲ 1'), 'ngu van · hoc ky 1');
  });

  test('matchesSearch: nhiều từ có thể khớp ở các trường khác nhau', () {
    final fields = ['11A1', 'Toán học', 'Học kỳ 1'];
    expect(matchesSearch('11a1 toan', fields), isTrue);
    expect(matchesSearch('toan 11A1', fields), isTrue);
    expect(matchesSearch('hoc ky', fields), isTrue);
    expect(matchesSearch('', fields), isTrue);
    expect(matchesSearch('   ', fields), isTrue);
    expect(matchesSearch('11a2 toan', fields), isFalse);
    expect(matchesSearch('vat ly', fields), isFalse);
  });

  test('matchesSearch bỏ qua trường null', () {
    expect(matchesSearch('an', ['Nguyễn Văn An', null]), isTrue);
  });
}
