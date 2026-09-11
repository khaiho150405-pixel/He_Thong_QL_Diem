import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../authentication/session.dart';
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
    body: FutureBuilder<CellsResponseDto>(
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
  bool busy = false;
  bool conflict = false;

  bool get teacher => ref.read(sessionProvider)?.role.value == 'GIAO_VIEN';
  bool get locked => widget.data.book.status.value == 'DA_CHOT';
  bool get editable => teacher && !locked && !conflict;

  @override
  void initState() {
    super.initState();
    for (final cell in widget.data.items) {
      controllers[cell.id] = TextEditingController(text: cell.value ?? '');
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
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

  Future<void> lock() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chốt bảng điểm?'),
        content: const Text(
          'Sau khi chốt, bảng điểm không thể sửa bằng luồng thông thường. '
          'Hệ thống sẽ từ chối nếu còn thiếu điểm bắt buộc hoặc đang chờ đối chiếu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Chốt bảng'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await mutate(() async {
      await ref
          .read(gradebooksRepositoryProvider)
          .lock(
            bookId: widget.data.book.id,
            expectedVersion: widget.data.book.version,
          );
    }, success: 'Bảng điểm đã được chốt.');
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

  Future<void> showHistory(GradeCellDto cell) async {
    await showDialog<void>(
      context: context,
      builder: (_) =>
          GradeHistoryDialog(bookId: widget.data.book.id, cell: cell),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = <num, List<GradeCellDto>>{};
    for (final cell in widget.data.items) {
      students.putIfAbsent(cell.studentId, () => []).add(cell);
    }
    final components = <num, GradeCellDto>{};
    for (final cell in widget.data.items) {
      components.putIfAbsent(cell.componentId, () => cell);
    }
    final orderedComponents = components.values.toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Lớp #${widget.data.book.classId} · '
                    'Môn #${widget.data.book.subjectId} · '
                    'Học kỳ #${widget.data.book.termId}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Chip(
                    avatar: Icon(locked ? Icons.lock : Icons.edit, size: 18),
                    label: Text(locked ? 'Đã chốt' : 'Đang nhập liệu'),
                  ),
                  Text('Phiên bản ${widget.data.book.version}'),
                  if (editable) ...[
                    OutlinedButton.icon(
                      onPressed: busy ? null : syncRoster,
                      icon: const Icon(Icons.group_add_outlined),
                      label: const Text('Đồng bộ sĩ số'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: busy ? null : save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Lưu thay đổi'),
                    ),
                    FilledButton.icon(
                      onPressed: busy ? null : lock,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Chốt bảng'),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
          const SizedBox(height: 8),
          Expanded(
            child: widget.data.items.isEmpty
                ? const Center(child: Text('Bảng điểm chưa có ô dữ liệu.'))
                : Form(
                    key: formKey,
                    child: LayoutBuilder(
                      builder: (context, box) => box.maxWidth >= 800
                          ? _wideGrid(students, orderedComponents)
                          : _mobileGrid(students),
                    ),
                  ),
          ),
          if (busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Widget _wideGrid(
    Map<num, List<GradeCellDto>> students,
    List<GradeCellDto> components,
  ) => Scrollbar(
    thumbVisibility: true,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Học sinh')),
            for (final component in components)
              DataColumn(
                label: Text(
                  '${component.componentName}\nHệ số ${component.coefficient}'
                  '${component.required_ ? ' · bắt buộc' : ''}',
                ),
              ),
          ],
          rows: [
            for (final row in students.values)
              DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 190,
                      child: Text(
                        row.first.active
                            ? row.first.studentName
                            : '${row.first.studentName}\nNgừng theo học',
                      ),
                    ),
                  ),
                  for (final component in components)
                    DataCell(
                      _gradeField(
                        row.firstWhere(
                          (cell) => cell.componentId == component.componentId,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    ),
  );

  Widget _mobileGrid(Map<num, List<GradeCellDto>> students) => ListView(
    children: [
      for (final row in students.values)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.first.studentName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (!row.first.active) const Text('Ngừng theo học'),
                const SizedBox(height: 12),
                for (final cell in row) ...[
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
          child: TextFormField(
            key: ValueKey('grade-${cell.id}'),
            controller: controllers[cell.id],
            enabled:
                editable && cell.active && cell.status.value != 'CHO_DOI_CHIEU',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: '—',
              helperText: cell.status.value == 'CHO_DOI_CHIEU'
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
        IconButton(
          tooltip: 'Lịch sử',
          onPressed: () => showHistory(cell),
          icon: const Icon(Icons.history),
        ),
      ],
    ),
  );
}

class GradeHistoryDialog extends ConsumerWidget {
  const GradeHistoryDialog({
    super.key,
    required this.bookId,
    required this.cell,
  });

  final num bookId;
  final GradeCellDto cell;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AlertDialog(
    title: Text('Lịch sử · ${cell.studentName} · ${cell.componentName}'),
    content: SizedBox(
      width: 620,
      height: 420,
      child: FutureBuilder<List<GradeHistoryEntryDto>>(
        future: ref
            .read(gradebooksRepositoryProvider)
            .history(bookId: bookId, cellId: cell.id),
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
              child: Text('Ô điểm chưa có lịch sử thay đổi.'),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final item = items[index];
              final timestamp = DateTime.tryParse(item.timestamp)?.toLocal();
              return ListTile(
                title: Text(
                  '${item.oldValue ?? 'NULL'} → ${item.newValue ?? 'NULL'}',
                ),
                subtitle: Text(
                  '${item.reason}\nNgười sửa #${item.editor}'
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
