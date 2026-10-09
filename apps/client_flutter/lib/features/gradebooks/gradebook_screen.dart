import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../authentication/session.dart';
import '../final_results/final_results_panel.dart';
import '../final_results/repository.dart';
import '../recognition/recognition_panel.dart';
import '../reports/reports_panel.dart';
import 'excel_import_dialog.dart';
import 'grade_deadlines_panel.dart';
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
  Widget build(BuildContext context) => FutureBuilder<CellsResponseDto>(
    future: data,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Bảng điểm #${widget.bookId}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/gradebooks'),
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Bảng điểm #${widget.bookId}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/gradebooks'),
            ),
          ),
          body: _GradebookLoadError(
            error: snapshot.error!,
            retry: () => setState(reload),
          ),
        );
      }
      final value = snapshot.data!;
      return GradebookEditor(
        key: ValueKey('${value.book.id}-${value.book.version}'),
        data: value,
        onReload: () => setState(reload),
      );
    },
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
  final verticalGridController = ScrollController();
  bool busy = false;
  bool conflict = false;
  num? _selectedComponentId;
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
    verticalGridController.dispose();
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

  Widget _buildStatusBadge() {
    final isLocked = locked;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isLocked ? Colors.green.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLocked ? Colors.green.shade600 : Colors.amber.shade700,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocked ? Icons.lock_outline_rounded : Icons.edit_note_rounded,
            size: 12,
            color: isLocked ? Colors.green.shade800 : Colors.amber.shade900,
          ),
          const SizedBox(width: 4),
          Text(
            isLocked ? 'Đã chốt' : 'Đang nhập liệu',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isLocked ? Colors.green.shade800 : Colors.amber.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildStickyBottomBar() {
    if (!editable) return null;
    final changed = changedCells();

    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: changed.isNotEmpty
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  changed.isNotEmpty
                      ? 'Đã sửa ${changed.length} ô điểm'
                      : 'Chưa có thay đổi',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: changed.isNotEmpty
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.outline,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: busy ? null : save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawStudents = <num, List<GradeCellDto>>{};
    for (final cell in widget.data.items) {
      rawStudents.putIfAbsent(cell.studentId, () => []).add(cell);
    }
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

    return FutureBuilder<List<FinalResultDto>>(
      future: finalResults,
      builder: (context, resultsSnapshot) {
        final results = {
          for (final result in resultsSnapshot.data ?? const <FinalResultDto>[])
            result.studentId: result,
        };

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/gradebooks'),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          '${widget.data.book.className} · ${widget.data.book.subjectName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          widget.data.book.termName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        ' · ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      Text(
                        'Phiên bản ${widget.data.book.version}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Tải lại',
                  onPressed: widget.onReload,
                  icon: const Icon(Icons.refresh),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Thao tác khác',
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (action) {
                    switch (action) {
                      case 'history':
                        showAllHistory();
                        break;
                      case 'sync_roster':
                        syncRoster();
                        break;
                      case 'import_excel':
                        openExcelImport(students, orderedComponents);
                        break;
                      case 'identifiers':
                        showIdentifiers();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'history',
                      child: Row(
                        children: [
                          Icon(Icons.history_outlined, size: 20),
                          SizedBox(width: 10),
                          Expanded(child: Text('Lịch sử cập nhật')),
                        ],
                      ),
                    ),
                    if (editable)
                      PopupMenuItem(
                        value: 'sync_roster',
                        enabled: !busy,
                        child: const Row(
                          children: [
                            Icon(Icons.group_add_outlined, size: 20),
                            SizedBox(width: 10),
                            Expanded(child: Text('Đồng bộ sĩ số')),
                          ],
                        ),
                      ),
                    if (editable)
                      PopupMenuItem(
                        value: 'import_excel',
                        enabled: !busy,
                        child: const Row(
                          children: [
                            Icon(Icons.table_chart_outlined, size: 20),
                            SizedBox(width: 10),
                            Expanded(child: Text('Nhập từ Excel')),
                          ],
                        ),
                      ),
                    if (admin)
                      const PopupMenuItem(
                        value: 'identifiers',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 20),
                            SizedBox(width: 10),
                            Expanded(child: Text('Mã tham chiếu')),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(
                    icon: Icon(Icons.edit_note_rounded),
                    text: 'Nhập điểm',
                  ),
                  Tab(
                    icon: Icon(Icons.camera_alt_outlined),
                    text: 'Quét ảnh OCR',
                  ),
                  Tab(
                    icon: Icon(Icons.analytics_outlined),
                    text: 'Báo cáo & Tiện ích',
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildTabGradeEntry(
                  students,
                  sortedStudentRows,
                  orderedComponents,
                  results,
                ),
                _buildTabOcr(orderedComponents),
                _buildTabReports(students, orderedComponents),
              ],
            ),
            bottomNavigationBar: _buildStickyBottomBar(),
          ),
        );
      },
    );
  }

  Widget _buildTabGradeEntry(
    Map<num, List<GradeCellDto>> students,
    List<List<GradeCellDto>> sortedStudentRows,
    List<GradeCellDto> orderedComponents,
    Map<num, FinalResultDto> results,
  ) {
    if (widget.data.items.isEmpty) {
      return const Center(child: Text('Bảng điểm chưa có ô dữ liệu.'));
    }

    return Column(
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80),
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  selected: _selectedComponentId == null,
                  avatar: Icon(
                    Icons.grid_view_rounded,
                    size: 16,
                    color: _selectedComponentId == null
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  label: Text(
                    'Tất cả cột',
                    style: TextStyle(
                      color: _selectedComponentId == null
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: _selectedComponentId == null
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: AppTheme.navActiveBg,
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(
                    color: _selectedComponentId == null
                        ? Theme.of(context).colorScheme.primary.withAlpha(150)
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                  onSelected: (_) => setState(() => _selectedComponentId = null),
                ),
                for (final comp in orderedComponents) ...[
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _selectedComponentId == comp.componentId,
                    avatar: comp.openForInput == false
                        ? const Icon(
                            Icons.lock_outline_rounded,
                            size: 14,
                            color: Colors.orange,
                          )
                        : null,
                    label: Text(
                      comp.componentName,
                      style: TextStyle(
                        color: _selectedComponentId == comp.componentId
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: _selectedComponentId == comp.componentId
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: AppTheme.navActiveBg,
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: _selectedComponentId == comp.componentId
                          ? Theme.of(context).colorScheme.primary.withAlpha(150)
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedComponentId = comp.componentId),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (busy) const LinearProgressIndicator(),
        Expanded(
          child: Form(
            key: formKey,
            child: _selectedComponentId != null
                ? _singleColumnView(sortedStudentRows, orderedComponents)
                : LayoutBuilder(
                    builder: (context, box) => box.maxWidth >= 800
                        ? _wideGrid(students, orderedComponents, results)
                        : _mobileGrid(students, results),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _singleColumnView(
    List<List<GradeCellDto>> sortedStudentRows,
    List<GradeCellDto> orderedComponents,
  ) {
    final selectedComp = orderedComponents.firstWhere(
      (c) => c.componentId == _selectedComponentId,
    );
    final isLocked =
        selectedComp.openForInput == false || selectedComp.columnLocked == true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withAlpha(120),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outlineVariant.withAlpha(100),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isLocked
                    ? Icons.lock_outline_rounded
                    : Icons.info_outline_rounded,
                size: 18,
                color: isLocked
                    ? Colors.orange
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cột: ${selectedComp.componentName} · Hệ số ${selectedComp.coefficient}'
                  '${selectedComp.required_ ? ' · Bắt buộc' : ''}'
                  '${isLocked ? ' · (Đang khóa)' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
        for (final studentRow in sortedStudentRows) ...[
          Builder(
            builder: (context) {
              final student = studentRow.first;
              final cell = studentRow
                  .cast<GradeCellDto?>()
                  .firstWhere(
                    (c) => c?.componentId == _selectedComponentId,
                    orElse: () => null,
                  );
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withAlpha(120),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          student.stt != null ? '${student.stt}' : '—',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.studentName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            if (!student.active)
                              Text(
                                'Ngừng theo học',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (cell != null)
                        _gradeField(cell, width: 150)
                      else
                        const Text('—'),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTabOcr(List<GradeCellDto> orderedComponents) {
    if (!teacher) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 12),
              Text(
                'Chức năng nhận dạng OCR chỉ dành cho giáo viên phụ trách.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: RecognitionPanel(
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
        embedded: true,
      ),
    );
  }

  Widget _buildTabReports(
    Map<num, List<GradeCellDto>> students,
    List<GradeCellDto> orderedComponents,
  ) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportsPanel(
          gradebookId: widget.data.book.id,
          compact: false,
        ),
        const SizedBox(height: 16),
        if (editable) ...[
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.file_upload_outlined,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nhập điểm từ Excel',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Nạp điểm học sinh tự động từ bảng tính Excel',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: busy
                        ? null
                        : () => openExcelImport(students, orderedComponents),
                    icon: const Icon(Icons.table_chart_outlined, size: 18),
                    label: const Text('Nhập Excel'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (locked && teacher) ...[
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.functions_rounded,
                      color:
                          Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng kết môn học',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Tính ĐTB và xếp loại cho toàn bộ học sinh trong bảng điểm',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: showFinalResults,
                    icon: const Icon(Icons.calculate_outlined, size: 18),
                    label: const Text('Tính tổng kết'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        GradeDeadlinesPanel(
          bookId: widget.data.book.id,
          components: orderedComponents,
          isAdmin: !teacher,
          locked: locked,
          onReload: widget.onReload,
        ),
      ],
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
      child: Scrollbar(
        controller: verticalGridController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: verticalGridController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
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
    ),
  );

  Widget _mobileGrid(
    Map<num, List<GradeCellDto>> students,
    Map<num, FinalResultDto> results,
  ) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
    children: [
      for (final entry in students.values.toList().asMap().entries)
        Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withAlpha(100),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        entry.value.first.stt != null
                            ? '${entry.value.first.stt}'
                            : '—',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value.first.studentName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                if (!entry.value.first.active)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Ngừng theo học',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (locked) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Điểm tổng kết: '
                      '${resultScore(results[entry.value.first.studentId]?.finalScore)} · '
                      'Xếp loại: ${classificationLabel(results[entry.value.first.studentId]?.classification ?? 'CHUA_CONG_BO')}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                for (final cell in entry.value) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${cell.componentName} · Hệ số ${cell.coefficient}'
                          '${cell.required_ ? ' · bắt buộc' : ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                      if (cell.source_.value == 'NHAN_DIEN')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '● AI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onTertiaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _gradeField(cell, width: double.infinity),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
    ],
  );

  Widget _gradeField(GradeCellDto cell, {double width = 170}) {
    final isLocked = cell.columnLocked == true || cell.openForInput == false;
    final isPending = cell.status.value == 'CHO_DOI_CHIEU';
    final isAi = cell.source_.value == 'NHAN_DIEN';
    final isEnabled =
        editable && cell.active && !isLocked && !isPending;

    return SizedBox(
      width: width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAi && width < 200)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '● AI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          Expanded(
            child: cell.passFail == true
                ? DropdownButtonFormField<String>(
                    key: ValueKey('grade-pf-${cell.id}'),
                    initialValue: controllers[cell.id]!.text.isEmpty
                        ? 'EMPTY'
                        : controllers[cell.id]!.text,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Đánh giá',
                      prefixIcon: isLocked
                          ? const Tooltip(
                              message: 'Cột đang khóa hoặc ngoài lịch nhập',
                              child: Icon(
                                Icons.lock_outline_rounded,
                                size: 14,
                                color: Colors.orange,
                              ),
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'EMPTY',
                        child: Text('Chưa đánh giá'),
                      ),
                      DropdownMenuItem(value: '10.0', child: Text('Đạt')),
                      DropdownMenuItem(value: '0.0', child: Text('Không đạt')),
                    ],
                    onChanged: isEnabled
                        ? (v) => setState(() {
                              controllers[cell.id]!.text =
                                  v == 'EMPTY' ? '' : v ?? '';
                            })
                        : null,
                  )
                : TextFormField(
                    key: ValueKey('grade-${cell.id}'),
                    controller: controllers[cell.id],
                    enabled: isEnabled,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: '—',
                      prefixIcon: isLocked
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
                          ? 'Ngoài lịch nhập'
                          : isPending
                          ? 'Chờ đối chiếu'
                          : cell.value == null
                          ? 'Chưa có điểm'
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
