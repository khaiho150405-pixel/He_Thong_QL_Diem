import 'package:api_client_dart/api_client_dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_dialog.dart';
import 'excel_file_name.dart';
import 'grade_import.dart';

class ExcelImportDialog extends StatefulWidget {
  const ExcelImportDialog({
    super.key,
    required this.bookId,
    required this.students,
    required this.components,
    required this.onApply,
    this.className,
    this.subjectName,
  });

  final String? className;
  final String? subjectName;
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

  int _matchedStudentsCount = 0;
  final Map<String, String> _parsedScores = {};
  final List<String> _skippedLockedColumns = [];
  final List<String> _skippedExemptCells = [];
  final List<Map<String, dynamic>> _previewRows = [];
  final List<GradeImportRowError> _rowErrors = [];
  late GradeCellDto _target = _defaultTarget();

  GradeCellDto _defaultTarget() => widget.components.firstWhere(
    (c) => c.openForInput != false && c.columnLocked != true,
    orElse: () => widget.components.first,
  );

  Future<void> _downloadTemplate() async {
    try {
      final fileBytes = buildGradeTemplate(
        students: widget.students,
        target: _target,
      );

      final path = await FilePicker.saveFile(
        dialogTitle: 'Lưu file mẫu Excel',
        fileName: excelFileName([
          'Mẫu nhập điểm',
          widget.className,
          widget.subjectName,
          _target.componentName,
        ]),
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        bytes: fileBytes,
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
      _skippedExemptCells.clear();
      _previewRows.clear();
      _rowErrors.clear();
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
        throw const GradeImportException('Không thể đọc dữ liệu file tải lên.');
      }

      _selectedFileName = file.name;

      final GradeImportTable table;
      if (file.name.toLowerCase().endsWith('.csv')) {
        table = parseCsvTable(decodeCsvBytes(bytes));
      } else {
        table = readExcelTable(bytes);
      }
      _applyAnalysis(
        analyzeGradeImport(
          headers: table.headers,
          rows: table.rows,
          students: widget.students,
          components: widget.components,
          scoreComponent: _target,
        ),
      );
    } on GradeImportException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(
        () => _errorMessage =
            'Không đọc được file này. Hãy mở bằng Excel, lưu lại dạng .xlsx hoặc CSV UTF-8 rồi thử lại.',
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _applyAnalysis(GradeImportResult result) {
    setState(() {
      _skippedLockedColumns.addAll(result.skippedLockedColumns);
      _skippedExemptCells.addAll(result.skippedExemptCells);
      _rowErrors.addAll(result.errors);
      if (result.hasErrors) return;
      if (result.scores.isEmpty) {
        _errorMessage =
            'Không tìm thấy ô điểm hợp lệ nào để nạp (kiểm tra lại tên cột hoặc giá trị 0.0–10.0).';
        return;
      }
      _parsedScores.addAll(result.scores);
      _previewRows.addAll(result.previewRows);
      _matchedStudentsCount = result.matchedStudents;
    });
  }

  String get _rowErrorsText {
    final shown = _rowErrors.take(10).join('\n');
    final more = _rowErrors.length > 10
        ? '\nvà ${_rowErrors.length - 10} lỗi khác.'
        : '';
    return 'File có ${_rowErrors.length} lỗi nên chưa thể áp dụng. Sửa file rồi chọn lại.\n$shown$more';
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
    final t = context.tokens;

    return AppDialog(
      title: 'Nhập điểm từ file Excel',
      maxWidth: 650,
      cancelLabel: 'Đóng',
      confirmLabel: _parsedScores.isEmpty
          ? 'Áp dụng'
          : 'Áp dụng ${_parsedScores.length} điểm',
      confirmEnabled: _parsedScores.isNotEmpty,
      onConfirm: _applyImport,
      onCancel: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Chọn cột điểm cần nhập, tải file mẫu (STT, Họ tên, Điểm) có sẵn danh sách học sinh của lớp, điền điểm rồi tải lên lại để cập nhật tự động.',
            style: theme.textTheme.bodyMedium?.copyWith(color: t.ink2),
          ),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Cột điểm cần nhập',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<num>(
                key: const ValueKey('excel-import-target'),
                value: _target.componentId,
                isExpanded: true,
                isDense: true,
                items: [
                  for (final comp in widget.components)
                    DropdownMenuItem<num>(
                      value: comp.componentId,
                      child: Text(
                        comp.openForInput == false || comp.columnLocked == true
                            ? '${comp.componentName} (đã khóa)'
                            : comp.componentName,
                      ),
                    ),
                ],
                onChanged: (id) {
                  if (id == null) return;
                  setState(() {
                    _target = widget.components.firstWhere(
                      (c) => c.componentId == id,
                    );
                    _parsedScores.clear();
                    _previewRows.clear();
                    _rowErrors.clear();
                    _errorMessage = null;
                    _selectedFileName = null;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _downloadTemplate,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Tải file mẫu (.xlsx)'),
              ),
              FilledButton.icon(
                onPressed: _isProcessing ? null : _pickAndParseFile,
                icon: _isProcessing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: t.onPri,
                        ),
                      )
                    : const Icon(Icons.upload_file_rounded),
                label: Text(
                  _selectedFileName != null
                      ? 'Chọn file khác'
                      : 'Chọn file tải lên',
                ),
              ),
            ],
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _notice(
              icon: Icons.error_outline_rounded,
              text: _errorMessage!,
              background: t.badSoft,
              border: t.badLine,
              foreground: t.bad,
              fontSize: 13,
            ),
          ],

          if (_rowErrors.isNotEmpty) ...[
            const SizedBox(height: 14),
            _notice(
              key: const ValueKey('excel-import-row-errors'),
              icon: Icons.error_outline_rounded,
              text: _rowErrorsText,
              background: t.badSoft,
              border: t.badLine,
              foreground: t.bad,
              fontSize: 12.5,
            ),
          ],

          if (_skippedLockedColumns.isNotEmpty) ...[
            const SizedBox(height: 14),
            _notice(
              icon: Icons.lock_clock_rounded,
              text:
                  'Cột điểm [${_skippedLockedColumns.join(', ')}] hiện đang bị khóa hoặc chưa mở nhập nên các điểm trong cột này sẽ được bỏ qua.',
              background: t.warnSoft,
              border: t.warnLine,
              foreground: t.warn,
              fontSize: 12.5,
            ),
          ],

          if (_skippedExemptCells.isNotEmpty) ...[
            const SizedBox(height: 14),
            _notice(
              icon: Icons.info_outline_rounded,
              text:
                  'Các ô điểm được miễn [${_skippedExemptCells.join(', ')}] được bỏ qua khi nhập.',
              background: t.warnSoft,
              border: t.warnLine,
              foreground: t.warn,
              fontSize: 12.5,
            ),
          ],

          if (_parsedScores.isNotEmpty) ...[
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                color: t.subtle,
                borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                border: Border.all(color: t.line),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Khớp $_matchedStudentsCount học sinh · ${_parsedScores.length} con điểm hợp lệ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: t.priLink,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const AppBadge.ok('Sẵn sàng nạp', dot: false),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: t.line),
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _previewRows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
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
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: t.priSoft,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xs,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                child: Text(
                                  '${entry.key}: ${entry.value}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: t.priLink,
                                  ),
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
    );
  }

  Widget _notice({
    Key? key,
    required IconData icon,
    required String text,
    required Color background,
    required Color border,
    required Color foreground,
    required double fontSize,
  }) => DecoratedBox(
    key: key,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.sm + 2),
      border: Border.all(color: border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: foreground,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
