import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/features/gradebooks/excel_file_name.dart';
import 'package:client_flutter/features/gradebooks/grade_import.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter_test/flutter_test.dart';

GradeCellDto _cell({
  required num studentId,
  required String name,
  required num componentId,
  required String componentName,
  String status = 'CHUA_CO',
  bool? passFail,
  bool locked = false,
}) => GradeCellDto.fromJson({
  'id': 'c-$studentId-$componentId',
  'studentId': studentId,
  'studentName': name,
  'stt': studentId,
  'active': true,
  'componentId': componentId,
  'componentName': componentName,
  'coefficient': '1.00',
  'required': true,
  'displayOrder': componentId,
  'value': null,
  'status': status,
  'exemptionReason': null,
  'source': 'NHAP_TAY',
  'openForInput': !locked,
  'columnLocked': locked,
  'passFail': ?passFail,
});

Map<num, List<GradeCellDto>> _students({
  String exemptComponent = '',
  bool lockSecond = false,
}) => {
  for (final entry in {1: 'Nguyễn An', 2: 'Trần Bình'}.entries)
    entry.key: [
      _cell(
        studentId: entry.key,
        name: entry.value,
        componentId: 11,
        componentName: 'TX1',
        status: exemptComponent == '${entry.key}-TX1' ? 'MIEN' : 'CHUA_CO',
      ),
      _cell(
        studentId: entry.key,
        name: entry.value,
        componentId: 12,
        componentName: 'TX2',
        locked: lockSecond,
      ),
    ],
};

GradeImportResult _run(
  String csv, {
  Map<num, List<GradeCellDto>>? students,
  bool scoreColumn = false,
}) {
  final table = parseCsvTable(csv);
  final map = students ?? _students();
  return analyzeGradeImport(
    headers: table.headers,
    rows: table.rows,
    students: map,
    components: map.values.first,
    scoreComponent: scoreColumn ? map.values.first.first : null,
  );
}

void main() {
  group('đọc CSV', () {
    test('nhận dấu chấm phẩy từ dòng tiêu đề và dấu phẩy thập phân', () {
      final result = _run(
        'STT;Mã học sinh;Họ và tên;TX1 (ID:11);TX2 (ID:12)\n'
        '1;1;Nguyễn An;8,5;7,0\n'
        '2;2;Trần Bình;6,0;\n',
      );
      expect(result.hasErrors, isFalse);
      expect(result.scores, {
        'c-1-11': '8.5',
        'c-1-12': '7.0',
        'c-2-11': '6.0',
      });
    });

    test('nhận dấu phẩy phân cách và tab', () {
      expect(detectCsvDelimiter('A,B,C'), ',');
      expect(detectCsvDelimiter('A;B;C'), ';');
      expect(detectCsvDelimiter('A\tB\tC'), '\t');
      final result = _run(
        'STT,Mã học sinh,Họ và tên,TX1 (ID:11)\n1,1,Nguyễn An,8.5\n',
      );
      expect(result.scores, {'c-1-11': '8.5'});
    });

    test('tôn trọng dấu ngoặc kép: dấu phẩy thập phân trong ô được trích', () {
      final result = _run(
        'STT,Mã học sinh,Họ và tên,TX1 (ID:11),TX2 (ID:12)\n'
        '1,1,"Nguyễn, An","8,5",7.0\n',
      );
      expect(result.hasErrors, isFalse);
      expect(result.scores, {'c-1-11': '8.5', 'c-1-12': '7.0'});
    });

    test('dấu phân cách trong ngoặc kép ở tiêu đề không bị đếm', () {
      expect(detectCsvDelimiter('"A,B,C";X;Y'), ';');
    });

    test('dòng trống giữa file giữ đúng số dòng trong báo lỗi', () {
      final result = _run(
        'STT;Mã học sinh;Họ và tên;TX1 (ID:11)\n'
        '1;1;Nguyễn An;8,5\n'
        '\n'
        '3;2;Trần Bình;11\n',
      );
      expect(result.errors.single.row, 4);
    });
  });

  group('file mẫu ba cột STT, Họ tên, Điểm', () {
    test('cột Điểm nạp vào cột điểm đã chọn, khớp theo tên và STT', () {
      final result = _run(
        'STT;Họ tên;Điểm\n1;Nguyễn An;8,5\n2;Trần Bình;6,0\n',
        scoreColumn: true,
      );
      expect(result.hasErrors, isFalse);
      expect(result.scores, {'c-1-11': '8.5', 'c-2-11': '6.0'});
    });

    test('chỉ có STT và Điểm vẫn khớp được học sinh', () {
      final result = _run('STT;Điểm\n2;7,5\n', scoreColumn: true);
      expect(result.hasErrors, isFalse);
      expect(result.scores, {'c-2-11': '7.5'});
    });

    test('STT lệch với họ tên bị báo lỗi, không gán nhầm học sinh', () {
      final result = _run(
        'STT;Họ tên;Điểm\n2;Nguyễn An;8,0\n',
        scoreColumn: true,
      );
      expect(result.errors.single.row, 2);
      expect(result.errors.single.message, contains('không khớp'));
      expect(result.scores, isEmpty);
    });

    test('tên trùng nhiều học sinh cần STT để phân biệt', () {
      final students = {
        for (final id in [1, 2])
          id: [
            _cell(
              studentId: id,
              name: 'Nguyễn An',
              componentId: 11,
              componentName: 'TX1',
            ),
          ],
      };
      final ok = _run(
        'STT;Họ tên;Điểm\n2;Nguyễn An;9,0\n',
        students: students,
        scoreColumn: true,
      );
      expect(ok.scores, {'c-2-11': '9.0'});
      final ambiguous = _run(
        'Họ tên;Điểm\nNguyễn An;9,0\n',
        students: students,
        scoreColumn: true,
      );
      expect(ambiguous.errors.single.message, contains('trùng'));
    });
  });

  group('dựng file mẫu', () {
    test('chỉ có ba cột STT, Họ tên, Điểm và điền sẵn điểm hiện có', () {
      final students = _students();
      final target = students.values.first.first;
      final table = readExcelTable(
        buildGradeTemplate(students: students, target: target),
      );
      expect(table.headers, ['STT', 'Họ tên', 'Điểm']);
      expect(table.rows.map((r) => r.take(2).toList()), [
        ['1', 'Nguyễn An'],
        ['2', 'Trần Bình'],
      ]);
      expect(table.rows.every((r) => r.length == 3), isTrue);
    });

    test('file mẫu tải lại được vào đúng cột đã chọn', () {
      final students = _students();
      final target = students.values.first[1];
      final table = readExcelTable(
        buildGradeTemplate(students: students, target: target),
      );
      final filled = [
        for (final row in table.rows) [row[0], row[1], '7,5'],
      ];
      final result = analyzeGradeImport(
        headers: table.headers,
        rows: filled,
        students: students,
        components: students.values.first,
        scoreComponent: target,
      );
      expect(result.hasErrors, isFalse);
      expect(result.scores, {'c-1-12': '7.5', 'c-2-12': '7.5'});
    });
  });

  group('tên file Excel', () {
    test('ghép các phần bằng dấu gạch và bỏ ký tự không hợp lệ', () {
      expect(
        excelFileName(['Bảng điểm', '12A7', 'Vật lí', 'Học kỳ 2']),
        'Bảng điểm - 12A7 - Vật lí - Học kỳ 2.xlsx',
      );
      expect(
        excelFileName(['Mẫu nhập điểm', null, 'Toán/Lý: 10', '']),
        'Mẫu nhập điểm - Toán Lý 10.xlsx',
      );
      expect(excelFileName([null, '']), 'Bảng điểm.xlsx');
    });
  });

  group('báo lỗi theo từng dòng và không nhập dở dang', () {
    test(
      'điểm ngoài khoảng: báo số dòng và lý do, không có điểm nào để áp',
      () {
        final result = _run(
          'STT;Mã học sinh;Họ và tên;TX1 (ID:11);TX2 (ID:12)\n'
          '1;1;Nguyễn An;6,4;\n'
          '2;2;Trần Bình;11;5\n',
        );
        expect(result.hasErrors, isTrue);
        expect(result.errors, hasLength(1));
        expect(result.errors.single.row, 3);
        expect(result.errors.single.message, contains('ngoài khoảng'));
        expect(result.scores, isEmpty);
      },
    );

    test('hai dòng cùng một học sinh: dòng sau bị báo trùng', () {
      final result = _run(
        'STT;Mã học sinh;Họ và tên;TX1 (ID:11)\n'
        '1;1;Nguyễn An;6,4\n'
        '1;1;Nguyễn An;7,0\n',
      );
      expect(result.errors.single.row, 3);
      expect(result.errors.single.message, contains('trùng với dòng 2'));
      expect(result.scores, isEmpty);
    });

    test('giá trị không phải số, nhiều hơn một chữ số thập phân, số âm', () {
      final result = _run(
        'STT;Mã học sinh;Họ và tên;TX1 (ID:11);TX2 (ID:12)\n'
        '1;1;Nguyễn An;abc;8,55\n'
        '2;2;Trần Bình;-1;5\n',
      );
      expect(result.errors.map((e) => e.row), [2, 2, 3]);
      expect(result.errors[0].message, contains('không phải là điểm'));
      expect(result.errors[1].message, contains('một chữ số thập phân'));
      expect(result.scores, isEmpty);
    });

    test('học sinh không có trong lớp bị báo lỗi thay vì bỏ qua âm thầm', () {
      final result = _run(
        'STT;Mã học sinh;Họ và tên;TX1 (ID:11)\n'
        '1;1;Nguyễn An;8,0\n'
        '9;99;Người lạ;7,0\n',
      );
      expect(result.errors.single.row, 3);
      expect(result.errors.single.message, contains('Người lạ'));
      expect(result.scores, isEmpty);
    });

    test('file hợp lệ: bỏ qua cột khóa và ô miễn, không coi là lỗi', () {
      final result = _run(
        'STT;Mã học sinh;Họ và tên;TX1 (ID:11);TX2 (ID:12)\n'
        '1;1;Nguyễn An;8,0;9,0\n'
        '2;2;Trần Bình;7,0;6,0\n',
        students: _students(exemptComponent: '2-TX1', lockSecond: true),
      );
      expect(result.hasErrors, isFalse);
      expect(result.scores, {'c-1-11': '8.0'});
      expect(result.skippedLockedColumns, ['TX2']);
      expect(result.skippedExemptCells, ['Trần Bình (TX1)']);
    });

    test('môn Đạt/Không đạt chỉ nhận Đạt hoặc Không đạt', () {
      final students = {
        1: [
          _cell(
            studentId: 1,
            name: 'Nguyễn An',
            componentId: 21,
            componentName: 'KQ',
            passFail: true,
          ),
        ],
      };
      final ok = _run(
        'STT;Mã học sinh;Họ và tên;KQ (ID:21)\n1;1;Nguyễn An;Đạt\n',
        students: students,
      );
      expect(ok.scores, {'c-1-21': '10.0'});
      final bad = _run(
        'STT;Mã học sinh;Họ và tên;KQ (ID:21)\n1;1;Nguyễn An;khá\n',
        students: students,
      );
      expect(bad.errors.single.row, 2);
      expect(bad.scores, isEmpty);
    });
  });

  group('mã hóa file', () {
    test('bỏ BOM UTF-8', () {
      final bytes = Uint8List.fromList([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode('Mã học sinh;Họ và tên'),
      ]);
      expect(decodeCsvBytes(bytes), 'Mã học sinh;Họ và tên');
    });

    test('file ANSI báo thông điệp dễ hiểu, không lộ FormatException', () {
      final bytes = Uint8List.fromList([
        ...latin1.encode('STT;M'),
        0xE3,
        ...latin1.encode(' HS;H'),
        0xE0,
        ...latin1.encode(' v'),
        0xE0,
      ]);
      expect(
        () => decodeCsvBytes(bytes),
        throwsA(
          isA<GradeImportException>().having(
            (e) => e.message,
            'message',
            contains('CSV UTF-8'),
          ),
        ),
      );
    });

    test('file CSV trống và thiếu cột học sinh', () {
      expect(() => parseCsvTable(''), throwsA(isA<GradeImportException>()));
      expect(
        () => _run('Điểm;Khác\n8;9\n'),
        throwsA(isA<GradeImportException>()),
      );
    });
  });

  group('đọc XLSX', () {
    test('ô thiếu (dòng thưa) đọc thành chuỗi rỗng, không ném lỗi null', () {
      final excel = Excel.createExcel();
      final sheet = excel[excel.getDefaultSheet()!];
      sheet.appendRow([
        TextCellValue('STT'),
        TextCellValue('Mã học sinh'),
        TextCellValue('Họ và tên'),
        TextCellValue('TX1 (ID:11)'),
      ]);
      sheet.updateCell(CellIndex.indexByString('A4'), IntCellValue(3));
      sheet.updateCell(CellIndex.indexByString('D4'), TextCellValue('8,5'));
      final table = readExcelTable(Uint8List.fromList(excel.save()!));
      expect(table.headers.take(4), [
        'STT',
        'Mã học sinh',
        'Họ và tên',
        'TX1 (ID:11)',
      ]);
      expect(table.rows.last.last, '8,5');
      expect(table.rows.any((r) => r.every((c) => c.isEmpty)), isTrue);
    });

    test('file hỏng báo thông điệp dễ hiểu', () {
      expect(
        () => readExcelTable(Uint8List.fromList([1, 2, 3, 4])),
        throwsA(
          isA<GradeImportException>().having(
            (e) => e.message,
            'message',
            contains('CSV UTF-8'),
          ),
        ),
      );
    });
  });
}
