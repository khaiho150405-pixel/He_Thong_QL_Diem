import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../authentication/session.dart';
import 'repository.dart';

class CatalogImportDialog extends StatefulWidget {
  const CatalogImportDialog({
    super.key,
    required this.resource,
    required this.repository,
  });

  final String resource;
  final CatalogRepository repository;

  @override
  State<CatalogImportDialog> createState() => _CatalogImportDialogState();
}

class _CatalogImportDialogState extends State<CatalogImportDialog> {
  List<Json> _rows = const [];
  String? _fileName;
  String? _error;
  bool _busy = false;

  List<String> get _headers => switch (widget.resource) {
    'accounts' => ['username', 'password', 'role'],
    'teachers' => [
      'ma_giao_vien',
      'ho_ten',
      'to_chuyen_mon',
      'email',
      'dien_thoai',
    ],
    'students' => [
      'ma_nguoi_dung',
      'ma_lop',
      'ho_ten',
      'ngay_sinh',
      'dang_theo_hoc',
    ],
    _ => const [],
  };

  String get _title => switch (widget.resource) {
    'accounts' => 'Nhập nhanh tài khoản',
    'teachers' => 'Nhập nhanh giáo viên',
    'students' => 'Nhập nhanh học sinh',
    _ => 'Nhập dữ liệu',
  };

  String get _hint => switch (widget.resource) {
    'accounts' =>
      'Giáo viên/học sinh: username là số điện thoại 10 chữ số bắt đầu bằng 0, định dạng ô Excel là Văn bản để giữ số 0. role: QUAN_TRI_VIEN, GIAO_VIEN hoặc HOC_SINH. Mật khẩu từ 12 ký tự.',
    'teachers' =>
      'ma_giao_vien là mã của tài khoản GIAO_VIEN chưa liên kết hồ sơ.',
    'students' =>
      'ma_lop là mã lớp; ma_nguoi_dung có thể để trống. Ngày sinh: YYYY-MM-DD.',
    _ => '',
  };

  Future<void> _downloadTemplate() async {
    final workbook = Excel.createExcel();
    workbook.rename('Sheet1', 'DuLieu');
    workbook['DuLieu'].appendRow(
      _headers.map<CellValue>((value) => TextCellValue(value)).toList(),
    );
    if (widget.resource == 'accounts') {
      for (var row = 1; row <= 500; row++) {
        workbook['DuLieu']
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .cellStyle = CellStyle(
          numberFormat: NumFormat.standard_49,
        );
      }
    }
    final bytes = workbook.save();
    if (bytes == null) return;
    await FilePicker.saveFile(
      dialogTitle: 'Lưu file mẫu',
      fileName: widget.resource == 'accounts'
          ? 'mau_tai_khoan_so_dien_thoai.xlsx'
          : 'mau_${widget.resource}.xlsx',
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      bytes: Uint8List.fromList(bytes),
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'csv'],
        withData: true,
      );
      if (result == null) return;
      final file = result.files.single;
      if (file.bytes == null) throw Exception('Không đọc được nội dung tệp.');
      final table = file.name.toLowerCase().endsWith('.csv')
          ? _csv(file.bytes!)
          : _xlsx(file.bytes!);
      final parsed = _parse(table.$1, table.$2);
      setState(() {
        _fileName = file.name;
        _rows = parsed;
      });
    } catch (error) {
      setState(() => _error = 'Không thể đọc tệp: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  (List<String>, List<List<String>>) _xlsx(Uint8List bytes) {
    final book = Excel.decodeBytes(bytes);
    final sheet = book.tables.values.firstOrNull;
    if (sheet == null || sheet.rows.isEmpty) throw Exception('Tệp trống.');
    List<String> values(List<Data?> cells) =>
        cells.map((cell) => cell?.value?.toString().trim() ?? '').toList();
    return (values(sheet.rows.first), sheet.rows.skip(1).map(values).toList());
  }

  (List<String>, List<List<String>>) _csv(Uint8List bytes) {
    final lines = const LineSplitter().convert(utf8.decode(bytes));
    if (lines.isEmpty) throw Exception('Tệp trống.');
    List<String> values(String line) => line
        .split(RegExp(r'[,;\t]'))
        .map((value) => value.trim().replaceAll('"', ''))
        .toList();
    return (values(lines.first), lines.skip(1).map(values).toList());
  }

  List<Json> _parse(List<String> rawHeaders, List<List<String>> rawRows) {
    final headers = rawHeaders.map((value) => value.toLowerCase()).toList();
    for (final required in _headers) {
      if (!headers.contains(required)) throw Exception('Thiếu cột $required.');
    }
    final rows = <Json>[];
    for (var rowIndex = 0; rowIndex < rawRows.length; rowIndex++) {
      final values = rawRows[rowIndex];
      if (values.every((value) => value.trim().isEmpty)) continue;
      final row = <String, dynamic>{};
      for (final key in _headers) {
        final index = headers.indexOf(key);
        final value = index < values.length ? values[index].trim() : '';
        if (['ma_giao_vien', 'ma_lop'].contains(key)) {
          row[key] =
              int.tryParse(value) ??
              (throw Exception('Dòng ${rowIndex + 2}: $key phải là số.'));
        } else if (key == 'ma_nguoi_dung') {
          row[key] = value.isEmpty
              ? null
              : int.tryParse(value) ??
                    (throw Exception(
                      'Dòng ${rowIndex + 2}: mã tài khoản không hợp lệ.',
                    ));
        } else if (key == 'dang_theo_hoc') {
          row[key] = ![
            'false',
            '0',
            'không',
            'khong',
          ].contains(value.toLowerCase());
        } else if (['to_chuyen_mon', 'email', 'dien_thoai'].contains(key)) {
          row[key] = value.isEmpty ? null : value;
        } else {
          row[key] = value;
        }
      }
      rows.add(row);
    }
    if (rows.isEmpty) throw Exception('Không có dòng dữ liệu nào.');
    if (rows.length > 500) throw Exception('Mỗi lần nhập tối đa 500 dòng.');
    return rows;
  }

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final count = await widget.repository.importMany(widget.resource, _rows);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã nhập thành công $count bản ghi.')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const Icon(Icons.upload_file_outlined),
    title: Text(_title),
    content: SizedBox(
      width: 620,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_hint),
          const SizedBox(height: 8),
          Text('Các cột bắt buộc: ${_headers.join(', ')}'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _downloadTemplate,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Tải file mẫu'),
              ),
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _pickFile,
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Chọn Excel/CSV'),
              ),
            ],
          ),
          if (_fileName != null) ...[
            const SizedBox(height: 16),
            Text(
              '$_fileName · ${_rows.length} dòng hợp lệ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _rows.take(3).map((row) => row.values.join(' · ')).join('\n'),
                maxLines: 4,
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
      FilledButton.icon(
        onPressed: _busy || _rows.isEmpty ? null : _import,
        icon: const Icon(Icons.cloud_upload_outlined),
        label: Text('Nhập ${_rows.length} dòng'),
      ),
    ],
  );
}
