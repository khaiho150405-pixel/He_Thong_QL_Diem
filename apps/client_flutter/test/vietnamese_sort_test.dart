import 'package:client_flutter/core/vietnamese_sort.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VietnameseCollation', () {
    test('standard Vietnamese alphabet character order', () {
      expect(VietnameseCollation.compare('a', 'ă') < 0, isTrue);
      expect(VietnameseCollation.compare('ă', 'â') < 0, isTrue);
      expect(VietnameseCollation.compare('â', 'b') < 0, isTrue);
      expect(VietnameseCollation.compare('d', 'đ') < 0, isTrue);
      expect(VietnameseCollation.compare('đ', 'e') < 0, isTrue);
      expect(VietnameseCollation.compare('e', 'ê') < 0, isTrue);
      expect(VietnameseCollation.compare('ê', 'g') < 0, isTrue);
      expect(VietnameseCollation.compare('o', 'ô') < 0, isTrue);
      expect(VietnameseCollation.compare('ô', 'ơ') < 0, isTrue);
      expect(VietnameseCollation.compare('u', 'ư') < 0, isTrue);
    });

    test(
      'Vietnamese tone marks order (ngang < huyền < hỏi < ngã < sắc < nặng)',
      () {
        expect(VietnameseCollation.compare('ma', 'mà') < 0, isTrue);
        expect(VietnameseCollation.compare('mà', 'mả') < 0, isTrue);
        expect(VietnameseCollation.compare('mả', 'mã') < 0, isTrue);
        expect(VietnameseCollation.compare('mã', 'má') < 0, isTrue);
        expect(VietnameseCollation.compare('má', 'mạ') < 0, isTrue);
      },
    );

    test('Student names sorted by given name first, then full name', () {
      final names = [
        'Trần Văn Dũng',
        'Lê Bảo Châu',
        'Nguyễn Văn An',
        'Phạm Quỳnh Anh',
        'Võ Minh Đức',
        'Hoàng Thúy Bình',
        'Nguyễn Thành An',
      ];

      names.sort(VietnameseCollation.compareStudentNames);

      expect(names, [
        'Nguyễn Thành An',
        'Nguyễn Văn An',
        'Phạm Quỳnh Anh',
        'Hoàng Thúy Bình',
        'Lê Bảo Châu',
        'Trần Văn Dũng',
        'Võ Minh Đức', // 'Đức' (Đ) comes after 'Dũng' (D) and before 'E'
      ]);
    });
  });

  group('StudentOrderIndex', () {
    test(
      'uses school order without a class filter and class order with one',
      () {
        final orders = StudentOrderIndex.from([
          {'ma_hoc_sinh': 30, 'ma_lop': 2, 'ho_ten': 'Trần Văn Bình'},
          {'ma_hoc_sinh': 20, 'ma_lop': 1, 'ho_ten': 'Nguyễn Văn An'},
          {'ma_hoc_sinh': 10, 'ma_lop': 2, 'ho_ten': 'Lê Văn An'},
          {'ma_hoc_sinh': 40, 'ma_lop': 1, 'ho_ten': 'Phạm Văn Cường'},
        ]);

        expect(orders.orderFor(20, classScope: false), 2);
        expect(orders.orderFor(20, classScope: true), 1);
        expect(orders.orderFor(30, classScope: false), 3);
        expect(orders.orderFor(30, classScope: true), 2);
      },
    );

    test('breaks duplicate names by student id for stable numbering', () {
      final orders = StudentOrderIndex.from([
        {'ma_hoc_sinh': 12, 'ma_lop': 1, 'ho_ten': 'Nguyễn Văn An'},
        {'ma_hoc_sinh': 5, 'ma_lop': 1, 'ho_ten': 'Nguyễn Văn An'},
      ]);

      expect(orders.school, {5: 1, 12: 2});
      expect(orders.byClass, {5: 1, 12: 2});
    });
  });
}
