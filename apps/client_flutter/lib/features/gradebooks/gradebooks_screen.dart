import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../academic_catalog/fields.dart';
import '../academic_catalog/repository.dart';
import '../authentication/session.dart';
import 'repository.dart';

class GradebooksScreen extends ConsumerStatefulWidget {
  const GradebooksScreen({super.key});

  @override
  ConsumerState<GradebooksScreen> createState() => _GradebooksScreenState();
}

class _GradebooksScreenState extends ConsumerState<GradebooksScreen> {
  late Future<GradebookListDto> page;
  final cursors = <num?>[null];

  bool get teacher => ref.read(sessionProvider)?.role.value == 'GIAO_VIEN';

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    page = ref.read(gradebooksRepositoryProvider).list(cursor: cursors.last);
  }

  Future<void> create() async {
    final book = await showDialog<GradebookDto>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CreateGradebookDialog(),
    );
    if (book != null && mounted) context.go('/gradebooks/${book.id}');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Bảng điểm'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/'),
      ),
      actions: [
        IconButton(
          tooltip: 'Tải lại',
          onPressed: () => setState(reload),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    floatingActionButton: teacher
        ? FloatingActionButton.extended(
            onPressed: create,
            icon: const Icon(Icons.add),
            label: const Text('Tạo bảng điểm'),
          )
        : null,
    body: FutureBuilder<GradebookListDto>(
      future: page,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _LoadError(
            error: snapshot.error!,
            retry: () => setState(reload),
          );
        }
        final data = snapshot.data!;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: data.items.isEmpty
                        ? const Center(child: Text('Chưa có bảng điểm.'))
                        : ListView.separated(
                            itemCount: data.items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final book = data.items[index];
                              final locked = book.status.value == 'DA_CHOT';
                              return Card(
                                child: ListTile(
                                  leading: Icon(
                                    locked ? Icons.lock : Icons.edit_note,
                                  ),
                                  title: Text(
                                    'Lớp #${book.classId} · Môn #${book.subjectId}',
                                  ),
                                  subtitle: Text(
                                    'Học kỳ #${book.termId} · '
                                    '${locked ? 'Đã chốt' : 'Đang nhập liệu'} · '
                                    'Phiên bản ${book.version}',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () =>
                                      context.go('/gradebooks/${book.id}'),
                                ),
                              );
                            },
                          ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Trang trước',
                        onPressed: cursors.length > 1
                            ? () => setState(() {
                                cursors.removeLast();
                                reload();
                              })
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('Trang ${cursors.length}'),
                      IconButton(
                        tooltip: 'Trang sau',
                        onPressed: data.nextCursor == null
                            ? null
                            : () => setState(() {
                                cursors.add(data.nextCursor);
                                reload();
                              }),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class CreateGradebookDialog extends ConsumerStatefulWidget {
  const CreateGradebookDialog({super.key});

  @override
  ConsumerState<CreateGradebookDialog> createState() =>
      _CreateGradebookDialogState();
}

class _CreateGradebookDialogState extends ConsumerState<CreateGradebookDialog> {
  late Future<List<List<Json>>> options;
  num? classId;
  num? subjectId;
  num? termId;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    options = Future.wait([
      _allCatalogItems('classes'),
      _allCatalogItems('subjects'),
      _allCatalogItems('semesters'),
    ]);
  }

  Future<List<Json>> _allCatalogItems(String resource) async {
    String? cursor;
    final items = <Json>[];
    final seen = <String>{};
    do {
      final page = await ref
          .read(catalogRepositoryProvider)
          .list(resource, cursor: cursor);
      items.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor != null && !seen.add(cursor)) {
        throw StateError('Cursor danh mục bị lặp.');
      }
    } while (cursor != null);
    return items;
  }

  Future<void> submit() async {
    if (classId == null || subjectId == null || termId == null) {
      setState(() => error = 'Chọn đủ lớp, môn học và học kỳ.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final book = await ref
          .read(gradebooksRepositoryProvider)
          .create(classId: classId!, subjectId: subjectId!, termId: termId!);
      if (mounted) Navigator.pop(context, book);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = errorMessage(e);
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Tạo bảng điểm'),
    content: SizedBox(
      width: 480,
      child: FutureBuilder<List<List<Json>>>(
        future: options,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Text(errorMessage(snapshot.error!));
          }
          final values = snapshot.data!;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ReferenceDropdown(
                label: 'Lớp',
                items: values[0],
                idKey: 'ma_lop',
                onChanged: (value) => classId = value,
              ),
              const SizedBox(height: 12),
              _ReferenceDropdown(
                label: 'Môn học',
                items: values[1],
                idKey: 'ma_mon',
                onChanged: (value) => subjectId = value,
              ),
              const SizedBox(height: 12),
              _ReferenceDropdown(
                label: 'Học kỳ',
                items: values[2],
                idKey: 'ma_hoc_ky',
                onChanged: (value) => termId = value,
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(onPressed: busy ? null : submit, child: const Text('Tạo')),
    ],
  );
}

class _ReferenceDropdown extends StatelessWidget {
  const _ReferenceDropdown({
    required this.label,
    required this.items,
    required this.idKey,
    required this.onChanged,
  });

  final String label;
  final List<Json> items;
  final String idKey;
  final ValueChanged<num?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<num>(
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: items
        .map(
          (item) => DropdownMenuItem<num>(
            value: item[idKey] as num,
            child: Text(rowLabel(item)),
          ),
        )
        .toList(),
    onChanged: onChanged,
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.retry});

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
