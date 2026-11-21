import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:excel/excel.dart' hide Border;

class GradeImportException implements Exception {
  const GradeImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GradeImportRowError {
  const GradeImportRowError(this.row, this.message);

  final int row;
  final String message;

  @override
  String toString() => 'Dòng $row: $message';
}

class GradeImportTable {
  const GradeImportTable(this.headers, this.rows);

  final List<String> headers;
  final List<List<String>> rows;
}

class GradeImportResult {
  GradeImportResult();

  final Map<String, String> scores = {};
  final List<Map<String, dynamic>> previewRows = [];
  final List<String> skippedLockedColumns = [];
  final List<String> skippedExemptCells = [];
  final List<GradeImportRowError> errors = [];
  int matchedStudents = 0;

  bool get hasErrors => errors.isNotEmpty;
}

String decodeCsvBytes(Uint8List bytes) {
  var data = bytes;
  if (data.length >= 3 &&
      data[0] == 0xEF &&
      data[1] == 0xBB &&
      data[2] == 0xBF) {
    data = Uint8List.sublistView(data, 3);
  }
  try {
    return utf8.decode(data);
  } on FormatException {
    throw const GradeImportException(
      'File CSV không phải mã hóa UTF-8. Hãy lưu file dạng "CSV UTF-8" rồi thử lại.',
    );
  }
}

String detectCsvDelimiter(String headerLine) {
  const candidates = [';', '\t', ','];
  final counts = {for (final c in candidates) c: 0};
  var inQuotes = false;
  for (final ch in headerLine.split('')) {
    if (ch == '"') {
      inQuotes = !inQuotes;
    } else if (!inQuotes && counts.containsKey(ch)) {
      counts[ch] = counts[ch]! + 1;
    }
  }
  var best = ',';
  var bestCount = 0;
  for (final c in candidates) {
    if (counts[c]! > bestCount) {
      best = c;
      bestCount = counts[c]!;
    }
  }
  return best;
}

List<List<String>> splitDelimited(String text, String delimiter) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var fieldStarted = false;
  void endField() {
    row.add(field.toString().trim());
    field.clear();
    fieldStarted = false;
  }

  void endRow() {
    endField();
    rows.add(row);
    row = <String>[];
  }

  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(ch);
      }
    } else if (ch == '"' && !fieldStarted) {
      inQuotes = true;
      fieldStarted = true;
    } else if (ch == delimiter) {
      endField();
    } else if (ch == '\r') {
      if (i + 1 < text.length && text[i + 1] == '\n') i++;
      endRow();
    } else if (ch == '\n') {
      endRow();
    } else {
      field.write(ch);
      if (ch.trim().isNotEmpty) fieldStarted = true;
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

GradeImportTable parseCsvTable(String text) {
  final firstLineEnd = text.indexOf(RegExp(r'[\r\n]'));
  final headerLine = firstLineEnd < 0 ? text : text.substring(0, firstLineEnd);
  if (headerLine.trim().isEmpty) {
    throw const GradeImportException('File CSV trống.');
  }
  final rows = splitDelimited(text, detectCsvDelimiter(headerLine));
  return GradeImportTable(rows.first, rows.skip(1).toList());
}

GradeImportTable readExcelTable(Uint8List bytes) {
  final Excel excel;
  try {
    excel = Excel.decodeBytes(bytes);
  } catch (_) {
    throw const GradeImportException(
      'Không đọc được file Excel này (có thể do định dạng ô đặc biệt). Hãy mở bằng Excel, lưu lại dạng .xlsx hoặc CSV UTF-8 rồi thử lại.',
    );
  }
  final sheet = excel.tables.isEmpty ? null : excel.tables.values.first;
  if (sheet == null || sheet.rows.isEmpty) {
    throw const GradeImportException('File Excel không có dữ liệu.');
  }
  List<String> textOf(List<Data?> row) =>
      row.map((cell) => cell?.value?.toString() ?? '').toList();
  return GradeImportTable(
    textOf(sheet.rows.first),
    sheet.rows.skip(1).map(textOf).toList(),
  );
}

final _gradePattern = RegExp(r'^\d{1,2}([.]\d+)?$');

int? _parseStt(String text) {
  if (text.isEmpty) return null;
  final value = double.tryParse(text.replaceAll(',', '.'));
  if (value == null || value != value.roundToDouble()) return null;
  return value.toInt();
}

GradeImportResult analyzeGradeImport({
  required List<String> headers,
  required List<List<String>> rows,
  required Map<num, List<GradeCellDto>> students,
  required List<GradeCellDto> components,
  GradeCellDto? scoreComponent,
}) {
  int? idColIndex;
  int? nameColIndex;
  int? sttColIndex;
  final compColMap = <int, GradeCellDto>{};

  for (var i = 0; i < headers.length; i++) {
    final h = headers[i].trim().toLowerCase();
    if (scoreComponent != null && (h == 'điểm' || h == 'diem')) {
      compColMap[i] = scoreComponent;
      continue;
    }
    if (h == 'stt' || h == 'số thứ tự') {
      sttColIndex = i;
      continue;
    }
    if (h.contains('mã học sinh') ||
        h.contains('mã hs') ||
        h.contains('ma_hoc_sinh') ||
        h == 'id' ||
        h == 'mã') {
      idColIndex = i;
    } else if (h.contains('họ và tên') ||
        h.contains('họ tên') ||
        h.contains('tên') ||
        h.contains('name')) {
      nameColIndex = i;
    }

    for (final comp in components) {
      final cName = comp.componentName.toLowerCase();
      if (h.contains('id:${comp.componentId}') ||
          h.contains('(id:${comp.componentId})') ||
          h == cName ||
          h.contains(cName)) {
        compColMap[i] = comp;
      }
    }
  }

  if (idColIndex == null && nameColIndex == null && sttColIndex == null) {
    throw const GradeImportException(
      'Không tìm thấy cột "STT", "Họ tên" hoặc "Mã học sinh" trong file.',
    );
  }

  final studentMapById = <num, List<GradeCellDto>>{};
  final studentMapByName = <String, List<List<GradeCellDto>>>{};
  final studentMapByStt = <int, List<GradeCellDto>>{};
  for (final entry in students.entries) {
    studentMapById[entry.key] = entry.value;
    if (entry.value.isNotEmpty) {
      final first = entry.value.first;
      (studentMapByName[first.studentName.trim().toLowerCase()] ??= []).add(
        entry.value,
      );
      final stt = first.stt;
      if (stt != null) studentMapByStt[stt.toInt()] = entry.value;
    }
  }

  final result = GradeImportResult();
  final firstRowOfStudent = <num, int>{};
  final pendingScores = <String, String>{};

  for (var index = 0; index < rows.length; index++) {
    final row = rows[index];
    final fileRow = index + 2;
    if (row.isEmpty || row.every((c) => c.trim().isEmpty)) continue;

    List<GradeCellDto>? matchedStudentCells;
    String identity = '';
    if (idColIndex != null && idColIndex < row.length) {
      final idText = row[idColIndex].trim();
      identity = idText;
      final idVal = num.tryParse(idText);
      if (idVal != null && studentMapById.containsKey(idVal)) {
        matchedStudentCells = studentMapById[idVal];
      }
    }
    String? matchProblem;
    if (matchedStudentCells == null &&
        (nameColIndex != null || sttColIndex != null)) {
      final nameText = nameColIndex != null && nameColIndex < row.length
          ? row[nameColIndex].trim()
          : '';
      final sttText = sttColIndex != null && sttColIndex < row.length
          ? row[sttColIndex].trim()
          : '';
      final sttValue = _parseStt(sttText);
      final bySttCells = sttValue == null ? null : studentMapByStt[sttValue];
      if (nameText.isNotEmpty) {
        identity = nameText;
        final sameName = studentMapByName[nameText.toLowerCase()] ?? const [];
        if (sameName.length == 1) {
          matchedStudentCells = sameName.single;
          if (bySttCells != null &&
              bySttCells.first.studentId !=
                  matchedStudentCells.first.studentId) {
            matchedStudentCells = null;
            matchProblem =
                'STT $sttText không khớp với học sinh "$nameText" trong lớp.';
          }
        } else if (sameName.length > 1) {
          for (final candidate in sameName) {
            if (bySttCells != null &&
                candidate.first.studentId == bySttCells.first.studentId) {
              matchedStudentCells = candidate;
            }
          }
          if (matchedStudentCells == null) {
            matchProblem =
                'tên "$nameText" trùng nhiều học sinh trong lớp, cần STT đúng để phân biệt.';
          }
        }
      } else if (bySttCells != null) {
        matchedStudentCells = bySttCells;
        identity = 'STT $sttText';
      } else if (sttText.isNotEmpty) {
        identity = 'STT $sttText';
      }
    }

    if (matchedStudentCells == null || matchedStudentCells.isEmpty) {
      result.errors.add(
        GradeImportRowError(
          fileRow,
          matchProblem ??
              (identity.isEmpty
                  ? 'không xác định được học sinh trong lớp.'
                  : 'không tìm thấy học sinh "$identity" trong lớp.'),
        ),
      );
      continue;
    }

    final student = matchedStudentCells.first;
    final earlier = firstRowOfStudent[student.studentId];
    if (earlier != null) {
      result.errors.add(
        GradeImportRowError(
          fileRow,
          'học sinh ${student.studentName} bị trùng với dòng $earlier.',
        ),
      );
      continue;
    }
    firstRowOfStudent[student.studentId] = fileRow;

    final previewItem = <String, dynamic>{
      'name': student.studentName,
      'scores': <String, String>{},
    };

    for (final compEntry in compColMap.entries) {
      final colIdx = compEntry.key;
      final comp = compEntry.value;

      if (colIdx >= row.length) continue;
      final rawVal = row[colIdx].trim();
      if (rawVal.isEmpty) continue;

      if (comp.openForInput == false || comp.columnLocked == true) {
        if (!result.skippedLockedColumns.contains(comp.componentName)) {
          result.skippedLockedColumns.add(comp.componentName);
        }
        continue;
      }

      final text = rawVal.toLowerCase();
      double? parsedNum;
      if (comp.passFail == true) {
        if (['đạt', 'dat', 'đ', 'd'].contains(text)) {
          parsedNum = 10.0;
        } else if ([
          'không đạt',
          'khong dat',
          'kđ',
          'kd',
          'chưa đạt',
          'chua dat',
        ].contains(text)) {
          parsedNum = 0.0;
        } else {
          result.errors.add(
            GradeImportRowError(
              fileRow,
              'cột ${comp.componentName} chỉ nhận Đạt hoặc Không đạt, không nhận "$rawVal".',
            ),
          );
          continue;
        }
      } else {
        final normalized = rawVal.replaceAll(',', '.');
        if (!_gradePattern.hasMatch(normalized)) {
          result.errors.add(
            GradeImportRowError(
              fileRow,
              'cột ${comp.componentName} có giá trị "$rawVal" không phải là điểm.',
            ),
          );
          continue;
        }
        parsedNum = double.parse(normalized);
        if (parsedNum < 0.0 || parsedNum > 10.0) {
          result.errors.add(
            GradeImportRowError(
              fileRow,
              'cột ${comp.componentName} có điểm "$rawVal" ngoài khoảng 0.0–10.0.',
            ),
          );
          continue;
        }
        if ((parsedNum * 10 - (parsedNum * 10).roundToDouble()).abs() > 1e-9) {
          result.errors.add(
            GradeImportRowError(
              fileRow,
              'cột ${comp.componentName} có điểm "$rawVal" nhiều hơn một chữ số thập phân.',
            ),
          );
          continue;
        }
      }

      final targetCell = matchedStudentCells.firstWhere(
        (c) => c.componentId == comp.componentId,
        orElse: () => student,
      );

      if (targetCell.status.value == 'MIEN') {
        final desc = '${student.studentName} (${comp.componentName})';
        if (!result.skippedExemptCells.contains(desc)) {
          result.skippedExemptCells.add(desc);
        }
        continue;
      }

      final normalizedScore = parsedNum.toStringAsFixed(1);
      pendingScores[targetCell.id] = normalizedScore;
      (previewItem['scores'] as Map<String, String>)[comp.componentName] =
          normalizedScore;
    }

    if ((previewItem['scores'] as Map).isNotEmpty) {
      result.previewRows.add(previewItem);
    }
  }

  result.matchedStudents = firstRowOfStudent.length;
  if (!result.hasErrors) result.scores.addAll(pendingScores);
  return result;
}

String _templateScore(GradeCellDto cell) {
  final raw = cell.value;
  if (raw == null || raw.isEmpty) return '';
  if (cell.passFail == true) return raw == '10.0' ? 'Đạt' : 'Không đạt';
  return raw;
}

Uint8List buildGradeTemplate({
  required Map<num, List<GradeCellDto>> students,
  required GradeCellDto target,
}) {
  final excel = Excel.createExcel();
  const sheetName = 'BangDiem';
  excel.rename('Sheet1', sheetName);
  final sheet = excel[sheetName];
  sheet.appendRow([
    TextCellValue('STT'),
    TextCellValue('Họ tên'),
    TextCellValue('Điểm'),
  ]);
  final sorted = students.values.where((row) => row.isNotEmpty).toList()
    ..sort((a, b) {
      final sttA = a.first.stt;
      final sttB = b.first.stt;
      if (sttA != null && sttB != null) {
        final cmp = sttA.compareTo(sttB);
        if (cmp != 0) return cmp;
      } else if (sttA != null) {
        return -1;
      } else if (sttB != null) {
        return 1;
      }
      return a.first.studentId.compareTo(b.first.studentId);
    });
  for (final row in sorted) {
    final student = row.first;
    final cell = row.firstWhere(
      (c) => c.componentId == target.componentId,
      orElse: () => student,
    );
    sheet.appendRow([
      student.stt != null
          ? IntCellValue(student.stt!.toInt())
          : TextCellValue('—'),
      TextCellValue(student.studentName),
      TextCellValue(
        cell.componentId == target.componentId ? _templateScore(cell) : '',
      ),
    ]);
  }
  return Uint8List.fromList(excel.save()!);
}
