import 'grade_deadlines_panel.dart';
import '../../app/widgets/app_edge_scrollbar.dart';
import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../authentication/session.dart';
import '../final_results/final_results_panel.dart';
import '../final_results/repository.dart';
import '../recognition/recognition_panel.dart';
import '../reports/reports_panel.dart';
import 'excel_import_dialog.dart';
import 'repository.dart';

class GradebookScreen extends ConsumerStatefulWidget {
  const GradebookScreen({super.key, required this.bookId});

  final num bookId;

  @override
  ConsumerState<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends ConsumerState<GradebookScreen> {
  late Future<CellsResponseDto> data;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    data = ref.read(gradebooksRepositoryProvider).cells(widget.bookId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Bảng điểm #${widget.bookId}'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/gradebooks'),
      ),
      actions: [
        IconButton(
          tooltip: 'Tải lại',
          onPressed: () => setState(reload),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: AppEdgeScrollbar(
      child: FutureBuilder<CellsResponseDto>(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _GradebookLoadError(
              error: snapshot.error!,
              retry: () => setState(reload),
            );
          }
          final value = snapshot.data!;
          return GradebookEditor(
            key: ValueKey('${value.book.id}-${value.book.version}'),
            data: value,
            onReload: () => setState(reload),
          );
        },
      ),
    ),
  );
}

class GradebookEditor extends ConsumerStatefulWidget {
  const GradebookEditor({
    super.key,
    required this.data,
    required this.onReload,
  });

  final CellsResponseDto data;
  final VoidCallback onReload;

  @override
  ConsumerState<GradebookEditor> createState() => _GradebookEditorState();
}

class _GradebookEditorState extends ConsumerState<GradebookEditor> {
  final formKey = GlobalKey<FormState>();
  final controllers = <String, TextEditingController>{};
  final horizontalGridController = ScrollController();
  bool busy = false;
  bool conflict = false;
  late Future<List<FinalResultDto>> finalResults;

  bool get teacher => ref.read(sessionProvider)?.role.value == 'GIAO_VIEN';
  bool get admin => ref.read(sessionProvider)?.role.value == 'QUAN_TRI_VIEN';
  String resultScore(String? value) => value == null
      ? '—'
      : widget.data.items.firstOrNull?.passFail == true
      ? (value == '10.0' ? 'Đạt' : 'Không đạt')
      : value;
  String classificationLabel(String value) => value == 'CHUA_CONG_BO'
      ? 'Chưa công bố'
      : value == 'DAT'
      ? 'Đạt'
      : value == 'CHUA_DAT'
      ? 'Không đạt'
      : value;
  bool get locked => widget.data.book.status.value == 'DA_CHOT';
  bool get editable => teacher && !locked && !conflict;

  @override
  void initState() {
    super.initState();
    for (final cell in widget.data.items) {
      controllers[cell.id] = TextEditingController(text: cell.value ?? '');
    }
    finalResults = locked
        ? ref.read(finalResultsRepositoryProvider).list(widget.data.book.id)
        : Future.value(const []);
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    horizontalGridController.dispose();
    super.dispose();
  }

  String? validateGrade(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return null;
    if (!RegExp(r'^(?:[0-9]\.[0-9]|10\.0)$').hasMatch(value)) {
      return 'Dùng 0.0–10.0';
    }
    return null;
  }

  List<GradeCellDto> changedCells() => widget.data.items.where((cell) {
    if (cell.openForInput == false || cell.columnLocked == true) return false;
    final text = controllers[cell.id]!.text.trim();
    return (text.isEmpty ? null : text) != cell.value;
  }).toList();

  Future<String?> askReason(int count) async {
    var reason = '';
    String? error;
    final value = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Lưu $count ô điểm'),
          content: SizedBox(
            width: 480,
            child: TextField(
              autofocus: true,
              maxLength: 500,
              maxLines: 3,
              onChanged: (value) => reason = value,
              decoration: InputDecoration(
                labelText: 'Lý do thay đổi',
                hintText: 'Ví dụ: Nhập điểm kiểm tra giữa kỳ',
                errorText: error,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final normalized = reason.trim();
                if (normalized.isEmpty) {
                  setDialogState(() => error = 'Cần nhập lý do.');
                  return;
                }
                Navigator.pop(ctx, normalized);
              },
              child: const Text('Xác nhận lưu'),
            ),
          ],
        ),
      ),
    );
    return value;
  }

  Future<void> save() async {
    setState(() => conflict = false);
    if (!(formKey.currentState?.validate() ?? false)) return;
    final changed = changedCells();
    if (changed.isEmpty) {
      showMessage('Chưa có ô điểm nào thay đổi.');
      return;
    }
    if (changed.length > 100) {
      showMessage('Mỗi lần chỉ lưu tối đa 100 ô điểm.');
      return;
    }
    final reason = await askReason(changed.length);
    if (reason == null || !mounted) return;
    await mutate(() async {
      await ref
          .read(gradebooksRepositoryProvider)
          .update(
            bookId: widget.data.book.id,
            expectedVersion: widget.data.book.version,
            changes: changed
                .map(
                  (cell) => GradeChangeInput(
                    cellId: cell.id,
                    value: controllers[cell.id]!.text.trim().isEmpty
                        ? null
                        : controllers[cell.id]!.text.trim(),
                    reason: reason,
                  ),
                )
                .toList(),
          );
    }, success: 'Đã lưu ${changed.length} ô điểm.');
  }

  Future<void> syncRoster() async {
    await mutate(() async {
      await ref
          .read(gradebooksRepositoryProvider)
          .syncRoster(
            bookId: widget.data.book.id,
            expectedVersion: widget.data.book.version,
          );
    }, success: 'Đã đồng bộ sĩ số.');
  }

  Future<void> openExcelImport(
    Map<num, List<GradeCellDto>> students,
    List<GradeCellDto> components,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => ExcelImportDialog(
        bookId: widget.data.book.id,
        students: students,
        components: components,
        onApply: (updatedValues, reason) async {
          for (final entry in updatedValues.entries) {
            if (controllers.containsKey(entry.key)) {
              controllers[entry.key]!.text = entry.value;
            }
          }
          final changed = changedCells();
          if (changed.isEmpty) {
            showMessage(
              'Các điểm trong file trùng khớp với điểm hiện tại trên hệ thống.',
            );
            return;
          }
          await mutate(
            () async {
              await ref
                  .read(gradebooksRepositoryProvider)
                  .update(
                    bookId: widget.data.book.id,
                    expectedVersion: widget.data.book.version,
                    changes: changed
                        .map(
                          (cell) => GradeChangeInput(
                            cellId: cell.id,
                            value: controllers[cell.id]!.text.trim().isEmpty
                                ? null
                                : controllers[cell.id]!.text.trim(),
                            reason: reason,
                          ),
                        )
                        .toList(),
                  );
            },
            success:
                'Đã nạp thành công ${changed.length} con điểm từ file Excel.',
          );
        },
      ),
    );
  }

  Future<void> mutate(
    Future<void> Function() action, {
    required String success,
  }) async {
    setState(() {
      busy = true;
      conflict = false;
    });
    try {
      await action();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      showMessage(success);
      widget.onReload();
    } catch (error) {
      if (!mounted) return;
      final isConflict =
          error is DioException && error.response?.statusCode == 409;
      setState(() {
        busy = false;
        conflict = isConflict;
      });
      showMessage(errorMessage(error));
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> showAllHistory() async {
    await showDialog<void>(
      context: context,
      builder: (_) => GradebookHistoryDialog(bookId: widget.data.book.id),
    );
  }

  Future<void> showFinalResults() async {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: FinalResultsPanel(
            gradebookId: widget.data.book.id,
            gradebookVersion: widget.data.book.version,
            showResults: true,
          ),
        ),
      ),
    );
    if (mounted && locked) {
      setState(() {
        finalResults = ref
            .read(finalResultsRepositoryProvider)
            .list(widget.data.book.id);
      });
    }
  }

  void showIdentifiers() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mã tham chiếu bảng điểm'),
        content: Text(
          'Mã bảng điểm: ${widget.data.book.id}\n'
          'Mã lớp: ${widget.data.book.classId}\n'
          'Mã môn: ${widget.data.book.subjectId}\n'
          'Mã học kỳ: ${widget.data.book.termId}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawStudents = <num, List<GradeCellDto>>{};
    for (final cell in widget.data.items) {
      rawStudents.putIfAbsent(cell.studentId, () => []).add(cell);
    }
    // Sắp xếp danh sách học sinh theo STT từ API (stt null xếp cuối, giữ thứ tự ổn định theo studentId)
    final sortedStudentRows = rawStudents.values.toList()
      ..sort((a, b) {
        final sttA = a.isNotEmpty ? a.first.stt : null;
        final sttB = b.isNotEmpty ? b.first.stt : null;
        if (sttA != null && sttB != null) {
          final cmp = sttA.compareTo(sttB);
          if (cmp != 0) return cmp;
        } else if (sttA != null && sttB == null) {
          return -1;
        } else if (sttA == null && sttB != null) {
          return 1;
        }
        final idA = a.isNotEmpty ? a.first.studentId : 0;
        final idB = b.isNotEmpty ? b.first.studentId : 0;
        return idA.compareTo(idB);
      });
    final students = {
      for (final row in sortedStudentRows) row.first.studentId: row,
    };
    final components = <num, GradeCellDto>{};
    for (final cell in widget.data.items) {
      components.putIfAbsent(cell.componentId, () => cell);
    }
    final orderedComponents = components.values.toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return Column(
      children: [
        Material(
          elevation: 2,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${widget.data.book.className} · '
                      '${widget.data.book.subjectName} · '
                      '${widget.data.book.termName}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (admin)
                      IconButton(
                        tooltip: 'Xem mã tham chiếu',
                        onPressed: showIdentifiers,
                        icon: const Icon(Icons.info_outline),
                      ),
                    Chip(
                      avatar: Icon(locked ? Icons.lock : Icons.edit, size: 18),
                      label: Text(locked ? 'Đã chốt' : 'Đang nhập liệu'),
                    ),
                    Text('Phiên bản ${widget.data.book.version}'),
                    OutlinedButton.icon(
                      onPressed: showAllHistory,
                      icon: const Icon(Icons.history_outlined),
                      label: const Text('Lịch sử cập nhật'),
                    ),
                    if (locked && teacher)
                      OutlinedButton.icon(
                        onPressed: showFinalResults,
                        icon: const Icon(Icons.functions),
                        label: const Text('Tính tổng kết'),
                      ),
                    if (editable) ...[
                      OutlinedButton.icon(
                        onPressed: busy ? null : syncRoster,
                        icon: const Icon(Icons.group_add_outlined),
                        label: const Text('Đồng bộ sĩ số'),
                      ),
                      OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () =>
                                  openExcelImport(students, orderedComponents),
                        icon: const Icon(Icons.table_chart_outlined),
                        label: const Text('Nhập từ Excel'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: busy ? null : save,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Lưu thay đổi'),
                      ),
                    ],
                    ReportsPanel(
                      gradebookId: widget.data.book.id,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (conflict)
                  MaterialBanner(
                    content: const Text(
                      'Bảng điểm đã thay đổi ở nơi khác. Tải lại để đối chiếu trước khi nhập lại.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: widget.onReload,
                        child: const Text('Tải lại'),
                      ),
                    ],
                  ),
                if (teacher) ...[
                  const SizedBox(height: 8),
                  RecognitionPanel(
                    gradebookId: widget.data.book.id,
                    components: [
                      for (final item in orderedComponents.where(
                        (c) =>
                            c.columnLocked != true &&
                            c.passFail != true &&
                            c.openForInput != false,
                      ))
                        RecognitionComponentOption(
                          item.componentId,
                          item.componentName,
                        ),
                    ],
                    gradebookVersion: widget.data.book.version,
                    enabled: !locked && !busy && !conflict,
                    onApproved: widget.onReload,
                  ),
                ],
                GradeDeadlinesPanel(
                  bookId: widget.data.book.id,
                  components: orderedComponents,
                  isAdmin: !teacher,
                  locked: locked,
                  onReload: widget.onReload,
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<FinalResultDto>>(
                  future: finalResults,
                  builder: (context, snapshot) =>
                      _gradeGrid(students, orderedComponents, {
                        for (final result in snapshot.data ?? const [])
                          result.studentId: result,
                      }),
                ),
                if (busy) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _gradeGrid(
    Map<num, List<GradeCellDto>> students,
    List<GradeCellDto> components,
    Map<num, FinalResultDto> results,
  ) => SizedBox(
    height: 520,
    child: widget.data.items.isEmpty
        ? const Center(child: Text('Bảng điểm chưa có ô dữ liệu.'))
        : Form(
            key: formKey,
            child: LayoutBuilder(
              builder: (context, box) => box.maxWidth >= 800
                  ? _wideGrid(students, components, results)
                  : _mobileGrid(students, results),
            ),
          ),
  );

  Widget _wideGrid(
    Map<num, List<GradeCellDto>> students,
    List<GradeCellDto> components,
    Map<num, FinalResultDto> results,
  ) => Scrollbar(
    controller: horizontalGridController,
    thumbVisibility: true,
    child: SingleChildScrollView(
      controller: horizontalGridController,
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            const DataColumn(label: Text('STT')),
            const DataColumn(label: Text('Học sinh')),
            for (final component in components)
              DataColumn(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${component.componentName}\nHệ số ${component.coefficient}'
                      '${component.required_ ? ' · bắt buộc' : ''}',
                    ),
                    if (component.openForInput == false) ...[
                      const SizedBox(width: 4),
                      const Tooltip(
                        message:
                            'Cột đang khóa hoặc ngoài lịch nhập nhà trường đặt',
                        child: Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (locked) ...[
              const DataColumn(label: Text('Điểm tổng kết')),
              const DataColumn(label: Text('Xếp loại')),
            ],
          ],
          rows: [
            for (final entry in students.values.toList().asMap().entries)
              DataRow(
                cells: [
                  DataCell(
                    Text(
                      entry.value.first.stt != null
                          ? '${entry.value.first.stt}'
                          : '—',
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 190,
                      child: Text(
                        entry.value.first.active
                            ? entry.value.first.studentName
                            : '${entry.value.first.studentName}\nNgừng theo học',
                      ),
                    ),
                  ),
                  for (final component in components)
                    DataCell(
                      Builder(
                        builder: (context) {
                          final cell = entry.value
                              .cast<GradeCellDto?>()
                              .firstWhere(
                                (c) => c?.componentId == component.componentId,
                                orElse: () => null,
                              );
                          return cell != null
                              ? _gradeField(cell)
                              : const Text('—');
                        },
                      ),
                    ),
                  if (locked) ...[
                    DataCell(
                      Text(
                        resultScore(
                          results[entry.value.first.studentId]?.finalScore,
                        ),
                      ),
                    ),
                    DataCell(
                      results[entry.value.first.studentId] == null
                          ? const Text('—')
                          : Chip(
                              label: Text(
                                classificationLabel(
                                  results[entry.value.first.studentId]!
                                      .classification,
                                ),
                              ),
                            ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    ),
  );

  Widget _mobileGrid(
    Map<num, List<GradeCellDto>> students,
    Map<num, FinalResultDto> results,
  ) => ListView(
    children: [
      for (final entry in students.values.toList().asMap().entries)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STT ${entry.value.first.stt ?? '—'} · ${entry.value.first.studentName}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (!entry.value.first.active) const Text('Ngừng theo học'),
                if (locked) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Điểm tổng kết: '
                    '${resultScore(results[entry.value.first.studentId]?.finalScore)} · '
                    'Xếp loại: ${results[entry.value.first.studentId]?.classification == 'CHUA_CONG_BO' ? 'Chưa công bố' : results[entry.value.first.studentId]?.classification ?? '—'}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
                const SizedBox(height: 12),
                for (final cell in entry.value) ...[
                  Text(
                    '${cell.componentName} · Hệ số ${cell.coefficient}'
                    '${cell.required_ ? ' · bắt buộc' : ''}',
                  ),
                  const SizedBox(height: 4),
                  _gradeField(cell, width: double.infinity),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
    ],
  );

  Widget _gradeField(GradeCellDto cell, {double width = 170}) => SizedBox(
    width: width,
    child: Row(
      children: [
        Expanded(
          child: cell.passFail == true
              ? DropdownButtonFormField<String>(
                  initialValue: controllers[cell.id]!.text.isEmpty
                      ? 'EMPTY'
                      : controllers[cell.id]!.text,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Đánh giá'),
                  items: const [
                    DropdownMenuItem(
                      value: 'EMPTY',
                      child: Text('Chưa đánh giá'),
                    ),
                    DropdownMenuItem(value: '10.0', child: Text('Đạt')),
                    DropdownMenuItem(value: '0.0', child: Text('Không đạt')),
                  ],
                  onChanged:
                      editable &&
                          cell.active &&
                          cell.openForInput != false &&
                          cell.columnLocked != true &&
                          cell.status.value != 'CHO_DOI_CHIEU'
                      ? (v) => setState(
                          () => controllers[cell.id]!.text = v == 'EMPTY'
                              ? ''
                              : v ?? '',
                        )
                      : null,
                )
              : TextFormField(
                  key: ValueKey('grade-${cell.id}'),
                  controller: controllers[cell.id],
                  enabled:
                      editable &&
                      cell.active &&
                      cell.openForInput != false &&
                      cell.columnLocked != true &&
                      cell.status.value != 'CHO_DOI_CHIEU',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: '—',
                    prefixIcon: cell.openForInput == false
                        ? const Tooltip(
                            message:
                                'Cột đang khóa hoặc ngoài lịch nhập nhà trường đặt',
                            child: Icon(
                              Icons.lock_rounded,
                              size: 14,
                              color: Colors.orange,
                            ),
                          )
                        : null,
                    helperText: cell.columnLocked == true
                        ? 'Cột đã chốt'
                        : cell.openForInput == false
                        ? 'Ngoài lịch nhập / đang khóa'
                        : cell.status.value == 'CHO_DOI_CHIEU'
                        ? 'Chờ đối chiếu'
                        : cell.value == null
                        ? 'Chưa có điểm'
                        : cell.source_.value == 'NHAN_DIEN'
                        ? 'Nhận dạng'
                        : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: validateGrade,
                ),
        ),
      ],
    ),
  );
}

class GradebookHistoryDialog extends ConsumerWidget {
  const GradebookHistoryDialog({super.key, required this.bookId});

  final num bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AlertDialog(
    title: const Text('Lịch sử cập nhật điểm'),
    content: SizedBox(
      width: 620,
      height: 420,
      child: FutureBuilder<List<GradebookHistoryEntryDto>>(
        future: ref
            .read(gradebooksRepositoryProvider)
            .historyAll(bookId: bookId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(errorMessage(snapshot.error!)));
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(
              child: Text('Bảng điểm chưa có lịch sử thay đổi.'),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final item = items[index];
              final timestamp = DateTime.tryParse(item.timestamp)?.toLocal();
              return ListTile(
                title: Text('${item.studentName} · ${item.componentName}'),
                subtitle: Text(
                  '${item.oldValue ?? 'NULL'} → ${item.newValue ?? 'NULL'}'
                  '\n${item.reason}\nNgười sửa #${item.editor}'
                  '${timestamp == null ? '' : ' · $timestamp'}',
                ),
              );
            },
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
    ],
  );
}

class _GradebookLoadError extends StatelessWidget {
  const _GradebookLoadError({required this.error, required this.retry});

  final Object error;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(errorMessage(error)),
        const SizedBox(height: 12),
        FilledButton(onPressed: retry, child: const Text('Thử lại')),
      ],
    ),
  );
}
