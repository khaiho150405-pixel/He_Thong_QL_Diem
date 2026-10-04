import 'dart:convert';
import 'package:api_client_dart/api_client_dart.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/vietnamese_sort.dart';

class ExcelImportDialog extends StatefulWidget {
  const ExcelImportDialog({
    super.key,
    required this.bookId,
    required this.students,
    required this.components,
    required this.onApply,
  });

  final num bookId;
  final Map<num, List<GradeCellDto>> students;
  final List<GradeCellDto> components;
  final void Function(Map<String, String> values, String reason) onApply;

  @override
  State<ExcelImportDialog> createState() => _ExcelImportDialogState();
}

class _ExcelImportDialogState extends State<ExcelImportDialog> {
  String? _selectedFileName;
  bool _isProcessing = false;
  String? _errorMessage;

  // Parsed results
  int _matchedStudentsCount = 0;
  final Map<String, String> _parsedScores = {}; // cellId -> normalized score
  final List<String> _skippedLockedColumns = [];
  final List<Map<String, dynamic>> _previewRows = [];

  Future<void> _downloadTemplate() async {
    try {
      final excel = Excel.createExcel();
      const sheetName = 'BangDiem';
      excel.rename('Sheet1', sheetName);
      final sheet = excel[sheetName];

      // Header row
      final headers = <CellValue>[
        TextCellValue('STT'),
        TextCellValue('Mã HS'),
        TextCellValue('Họ và tên'),
      ];

      for (final comp in widget.components) {
        final lockStatus = comp.openForInput == false ? ' [KHÓA]' : '';
        headers.add(
          TextCellValue(
            '${comp.componentName} (ID:${comp.componentId})$lockStatus',
          ),
        );
      }
      sheet.appendRow(headers);

      // Data rows (sorted by Vietnamese name)
      final sortedStudents = widget.students.values.toList()
        ..sort((a, b) {
          final nameA = a.isNotEmpty ? a.first.studentName : '';
          final nameB = b.isNotEmpty ? b.first.studentName : '';
          return VietnameseCollation.compareStudentNames(nameA, nameB);
        });

      var stt = 1;
      for (final studentRow in sortedStudents) {
        if (studentRow.isEmpty) continue;
        final student = studentRow.first;
        final rowValues = <CellValue>[
          IntCellValue(stt++),
          IntCellValue(student.studentId.toInt()),
          TextCellValue(student.studentName),
        ];

        for (final comp in widget.components) {
          final cell = studentRow.firstWhere(
            (c) => c.componentId == comp.componentId,
            orElse: () => student,
          );
          final valStr = cell.value ?? '';
          rowValues.add(TextCellValue(valStr));
        }
        sheet.appendRow(rowValues);
      }

      final fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Không thể tạo file Excel.');

      final path = await FilePicker.saveFile(
        dialogTitle: 'Lưu file mẫu Excel',
        fileName: 'Mau_BangDiem_${widget.bookId}.xlsx',
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        bytes: Uint8List.fromList(fileBytes),
      );

      if (!mounted) return;
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tải xuống file mẫu Excel thành công!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Lỗi tạo file mẫu: $e');
    }
  }

  Future<void> _pickAndParseFile() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _parsedScores.clear();
      _skippedLockedColumns.clear();
      _previewRows.clear();
      _matchedStudentsCount = 0;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'xls', 'csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isProcessing = false);
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        throw Exception('Không thể đọc dữ liệu file tải lên.');
      }

      _selectedFileName = file.name;

      if (file.name.toLowerCase().endsWith('.csv')) {
        _parseCsv(utf8.decode(bytes));
      } else {
        _parseExcel(bytes);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi đọc file: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _parseExcel(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null || sheet.rows.isEmpty) {
      throw Exception('File Excel không có dữ liệu.');
    }

    final headerRow = sheet.rows.first;
    _processRows(
      headerRow.map((cell) => cell?.value?.toString() ?? '').toList(),
      sheet.rows
          .skip(1)
          .map((row) => row.map((c) => c?.value?.toString() ?? '').toList())
          .toList(),
    );
  }

  void _parseCsv(String csvContent) {
    final lines = const LineSplitter().convert(csvContent);
    if (lines.isEmpty) throw Exception('File CSV trống.');

    final header = lines.first
        .split(RegExp(r'[,;\t]'))
        .map((s) => s.trim().replaceAll('"', ''))
        .toList();
    final dataRows = lines
        .skip(1)
        .map(
          (line) => line
              .split(RegExp(r'[,;\t]'))
              .map((s) => s.trim().replaceAll('"', ''))
              .toList(),
        )
        .toList();

    _processRows(header, dataRows);
  }

  void _processRows(List<String> headers, List<List<String>> rows) {
    // Map column index to Component ID
    int? idColIndex;
    int? nameColIndex;
    final compColMap = <int, GradeCellDto>{};

    for (var i = 0; i < headers.length; i++) {
      final h = headers[i].trim().toLowerCase();
      if (h.contains('mã hs') ||
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

      for (final comp in widget.components) {
        final cName = comp.componentName.toLowerCase();
        if (h.contains('id:${comp.componentId}') ||
            h.contains('(id:${comp.componentId})') ||
            h == cName ||
            h.contains(cName)) {
          compColMap[i] = comp;
        }
      }
    }

    if (idColIndex == null && nameColIndex == null) {
      throw Exception(
        'Không tìm thấy cột "Mã HS" hoặc "Họ và tên" trong file.',
      );
    }

    final studentMapById = <num, List<GradeCellDto>>{};
    final studentMapByName = <String, List<GradeCellDto>>{};
    for (final entry in widget.students.entries) {
      studentMapById[entry.key] = entry.value;
      if (entry.value.isNotEmpty) {
        studentMapByName[entry.value.first.studentName.trim().toLowerCase()] =
            entry.value;
      }
    }

    final matchedStudentIds = <num>{};

    for (final row in rows) {
      if (row.isEmpty || row.every((c) => c.trim().isEmpty)) continue;

      List<GradeCellDto>? matchedStudentCells;
      if (idColIndex != null && idColIndex < row.length) {
        final idVal = num.tryParse(row[idColIndex].trim());
        if (idVal != null && studentMapById.containsKey(idVal)) {
          matchedStudentCells = studentMapById[idVal];
        }
      }

      if (matchedStudentCells == null &&
          nameColIndex != null &&
          nameColIndex < row.length) {
        final nameVal = row[nameColIndex].trim().toLowerCase();
        if (studentMapByName.containsKey(nameVal)) {
          matchedStudentCells = studentMapByName[nameVal];
        }
      }

      if (matchedStudentCells == null || matchedStudentCells.isEmpty) continue;

      final student = matchedStudentCells.first;
      matchedStudentIds.add(student.studentId);

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

        // Check if Admin locked this column
        if (comp.openForInput == false || comp.columnLocked == true) {
          if (!_skippedLockedColumns.contains(comp.componentName)) {
            _skippedLockedColumns.add(comp.componentName);
          }
          continue;
        }

        // Validate score
        final text = rawVal.toLowerCase();
        final double? parsedNum;
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
            throw Exception(
              'Cột ${comp.componentName}: chỉ nhập Đạt hoặc Không đạt.',
            );
          }
        } else {
          parsedNum = double.tryParse(rawVal.replaceAll(',', '.'));
        }

        if (parsedNum != null && parsedNum >= 0.0 && parsedNum <= 10.0) {
          final normalizedScore = parsedNum.toStringAsFixed(1);
          final targetCell = matchedStudentCells.firstWhere(
            (c) => c.componentId == comp.componentId,
            orElse: () => student,
          );

          _parsedScores[targetCell.id] = normalizedScore;
          (previewItem['scores'] as Map<String, String>)[comp.componentName] =
              normalizedScore;
        }
      }

      if ((previewItem['scores'] as Map).isNotEmpty) {
        _previewRows.add(previewItem);
      }
    }

    _matchedStudentsCount = matchedStudentIds.length;

    if (_parsedScores.isEmpty) {
      throw Exception(
        'Không tìm thấy ô điểm hợp lệ nào để nạp (kiểm tra lại tên cột hoặc giá trị 0.0–10.0).',
      );
    }
  }

  void _applyImport() {
    if (_parsedScores.isEmpty) return;
    widget.onApply(
      _parsedScores,
      'Import từ Excel: ${_selectedFileName ?? "file_diem.xlsx"} (${_parsedScores.length} con điểm)',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.table_chart_rounded,
              color: Colors.green.shade700,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Text('Nhập điểm từ file Excel'),
        ],
      ),
      content: SizedBox(
        width: 650,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tải file mẫu Excel có sẵn danh sách học sinh của lớp, nhập điểm vào các cột tương ứng và tải lên lại để cập nhật tự động.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons: Download template & Upload file
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _downloadTemplate,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Tải file mẫu (.xlsx)'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isProcessing ? null : _pickAndParseFile,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.upload_file_rounded),
                      label: Text(
                        _selectedFileName != null
                            ? 'Chọn file khác'
                            : 'Chọn file tải lên',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.error.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_skippedLockedColumns.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_clock_rounded,
                        color: Colors.amber.shade900,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cột điểm [${_skippedLockedColumns.join(', ')}] hiện đang bị Admin khóa (chưa mở cổng nhập) nên các điểm trong cột này sẽ được bỏ qua.',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Preview Section
              if (_parsedScores.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(100),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Khớp $_matchedStudentsCount học sinh · ${_parsedScores.length} con điểm hợp lệ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Sẵn sàng nạp',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.outlineVariant.withAlpha(80),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _previewRows.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final item = _previewRows[idx];
                        final scores = item['scores'] as Map<String, String>;
                        return ListTile(
                          dense: true,
                          title: Text(
                            item['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              for (final entry in scores.entries)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer
                                        .withAlpha(140),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${entry.key}: ${entry.value}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
        if (_parsedScores.isNotEmpty)
          FilledButton.icon(
            onPressed: _applyImport,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: Text('Áp dụng ${_parsedScores.length} điểm'),
          ),
      ],
    );
  }
}
