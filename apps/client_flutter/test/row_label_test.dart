import 'package:client_flutter/features/academic_catalog/edit_dialog.dart';
import 'package:client_flutter/features/academic_catalog/fields.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'thành phần điểm hiện tên thành phần để phân biệt các cột cùng nhóm',
    () {
      expect(
        rowLabel({
          'ten_thanh_phan': 'ĐĐGtx 1',
          'label': 'Thường xuyên · Toán học',
        }),
        'ĐĐGtx 1 · Toán học',
      );
      expect(
        rowLabel({
          'ten_thanh_phan': 'ĐĐGtx 2',
          'label': 'Thường xuyên · Toán học',
        }),
        'ĐĐGtx 2 · Toán học',
      );
    },
  );

  test('hệ số nhập tay được chuẩn hóa về d.dd hoặc bị từ chối', () {
    expect(normalizeCoefficientText('2'), '2.00');
    expect(normalizeCoefficientText('1,5'), '1.50');
    expect(normalizeCoefficientText(' 0.01 '), '0.01');
    expect(normalizeCoefficientText('9.99'), '9.99');
    expect(normalizeCoefficientText('0'), isNull);
    expect(normalizeCoefficientText('10'), isNull);
    expect(normalizeCoefficientText('9.999'), isNull);
    expect(normalizeCoefficientText('abc'), isNull);
    expect(normalizeCoefficientText(''), isNull);
  });

  test('các loại dòng khác giữ nhãn của máy chủ', () {
    expect(
      rowLabel({'ma_lop': 1, 'ten_lop': '10A1', 'label': '10A1 · 2024-2025'}),
      '10A1 · 2024-2025',
    );
    expect(rowLabel({'ho_ten': 'Nguyễn Văn An'}), 'Nguyễn Văn An');
    expect(rowLabel({}), 'Phân công');
  });
}
