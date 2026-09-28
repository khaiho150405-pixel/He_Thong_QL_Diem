import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/widgets/app_controls.dart';
import '../../app/widgets/empty_state.dart';
import '../../app/widgets/shimmer_loading.dart';
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

  List<Json> _classes = [];
  List<Json> _subjects = [];
  bool _loadingCatalog = false;

  num? _filterClassId;
  num? _filterSubjectId;
  String? _filterStatus; // null | 'DANG_NHAP_LIEU' | 'DA_CHOT'

  bool get teacher => ref.read(sessionProvider)?.role.value == 'GIAO_VIEN';
  bool get _hasFilter =>
      _filterClassId != null ||
      _filterSubjectId != null ||
      _filterStatus != null;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    reload();
  }

  Future<void> _loadCatalog() async {
    setState(() => _loadingCatalog = true);
    try {
      final classes = await _allCatalogItems(
        'classes',
      ).catchError((_) => <Json>[]);
      final subjects = await _allCatalogItems(
        'subjects',
      ).catchError((_) => <Json>[]);
      if (!mounted) return;
      setState(() {
        _classes = classes;
        _subjects = subjects;
        _loadingCatalog = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCatalog = false);
    }
  }

  Future<List<Json>> _allCatalogItems(String resource) async {
    String? cursor;
    final items = <Json>[];
    final seen = <String>{};
    do {
      final res = await ref
          .read(catalogRepositoryProvider)
          .list(resource, cursor: cursor);
      items.addAll(res.items);
      cursor = res.nextCursor;
      if (cursor != null && !seen.add(cursor)) break;
    } while (cursor != null);
    return items;
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

  Widget _buildFilterBar(ColorScheme colorScheme, ThemeData theme) {
    if (_loadingCatalog) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_alt_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bộ lọc bảng điểm',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (_hasFilter)
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _filterClassId = null;
                      _filterSubjectId = null;
                      _filterStatus = null;
                    }),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Đặt lại bộ lọc'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Dropdown Lớp học
                AppFilterDropdown<num>(
                  label: 'Lớp học',
                  icon: Icons.meeting_room_outlined,
                  value: _filterClassId,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tất cả các lớp'),
                    ),
                    for (final c in _classes)
                      DropdownMenuItem(
                        value: c['ma_lop'] as num?,
                        child: Text(
                          c['ten_lop']?.toString() ?? 'Lớp ${c['ma_lop']}',
                        ),
                      ),
                  ],
                  onChanged: (val) => setState(() => _filterClassId = val),
                ),
                // Dropdown Môn học
                AppFilterDropdown<num>(
                  label: 'Môn học',
                  icon: Icons.menu_book_outlined,
                  value: _filterSubjectId,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tất cả môn học'),
                    ),
                    for (final s in _subjects)
                      DropdownMenuItem(
                        value: s['ma_mon'] as num?,
                        child: Text(
                          s['ten_mon']?.toString() ?? 'Môn ${s['ma_mon']}',
                        ),
                      ),
                  ],
                  onChanged: (val) => setState(() => _filterSubjectId = val),
                ),
                // Dropdown Trạng thái
                AppFilterDropdown<String>(
                  label: 'Trạng thái',
                  icon: Icons.check_circle_outline,
                  value: _filterStatus,
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Tất cả trạng thái'),
                    ),
                    DropdownMenuItem(
                      value: 'DANG_NHAP_LIEU',
                      child: Text('Đang nhập liệu'),
                    ),
                    DropdownMenuItem(
                      value: 'DA_CHOT',
                      child: Text('Đã chốt sổ'),
                    ),
                  ],
                  onChanged: (val) => setState(() => _filterStatus = val),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFilterBar(colorScheme, theme),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<GradebookListDto>(
                    future: page,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const ShimmerLoading(
                          itemCount: 5,
                          itemHeight: 84,
                        );
                      }
                      if (snapshot.hasError) {
                        return EmptyState(
                          icon: Icons.error_outline,
                          title: 'Lỗi tải danh sách bảng điểm',
                          message: errorMessage(snapshot.error!),
                          actionLabel: 'Thử lại',
                          onAction: () => setState(reload),
                        );
                      }
                      final data = snapshot.data!;

                      if (data.items.isEmpty) {
                        return EmptyState(
                          icon: Icons.table_chart_outlined,
                          title: 'Chưa có bảng điểm',
                          message: teacher
                              ? 'Bạn chưa tạo bảng điểm nào cho các lớp phụ trách.'
                              : 'Hệ thống chưa có bảng điểm nào được tạo.',
                          actionLabel: teacher ? 'Tạo bảng điểm' : null,
                          onAction: teacher ? create : null,
                        );
                      }

                      final filteredItems = data.items.where((book) {
                        if (_filterClassId != null &&
                            book.classId != _filterClassId) {
                          return false;
                        }
                        if (_filterSubjectId != null &&
                            book.subjectId != _filterSubjectId) {
                          return false;
                        }
                        if (_filterStatus != null &&
                            book.status.value != _filterStatus) {
                          return false;
                        }
                        return true;
                      }).toList();

                      if (filteredItems.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.filter_alt_off_rounded,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Không có bảng điểm phù hợp với bộ lọc.',
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  _filterClassId = null;
                                  _filterSubjectId = null;
                                  _filterStatus = null;
                                }),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Xóa bộ lọc'),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, box) {
                                if (box.maxWidth >= 768) {
                                  return GridView.builder(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisExtent: 94,
                                          crossAxisSpacing: 14,
                                          mainAxisSpacing: 12,
                                        ),
                                    itemCount: filteredItems.length,
                                    itemBuilder: (context, index) =>
                                        _buildGradebookCard(
                                          context,
                                          filteredItems[index],
                                          colorScheme,
                                          theme,
                                        ),
                                  );
                                }
                                return ListView.separated(
                                  itemCount: filteredItems.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) =>
                                      _buildGradebookCard(
                                        context,
                                        filteredItems[index],
                                        colorScheme,
                                        theme,
                                      ),
                                );
                              },
                            ),
                          ),

                          // Pagination
                          Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 20),
                            child: Row(
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant
                                          .withAlpha(80),
                                    ),
                                  ),
                                  child: Text(
                                    'Trang ${cursors.length}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
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
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradebookCard(
    BuildContext context,
    GradebookDto book,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final locked = book.status.value == 'DA_CHOT';
    final classDisplay = book.className;
    final subjectDisplay = book.subjectName;
    final termDisplay = book.termName;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: locked
                ? colorScheme.surfaceContainerHighest
                : colorScheme.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            locked ? Icons.lock_outline_rounded : Icons.edit_note_rounded,
            color: locked ? colorScheme.onSurfaceVariant : colorScheme.primary,
          ),
        ),
        title: Text(
          '$classDisplay · $subjectDisplay',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            '$termDisplay · '
            '${locked ? 'Đã chốt' : 'Đang nhập liệu'} · '
            'Phiên bản ${book.version}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.go('/gradebooks/${book.id}'),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Tạo bảng điểm'),
      content: SizedBox(
        width: 480,
        child: FutureBuilder<List<List<Json>>>(
          future: options,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Đang tải danh mục…'),
                    ],
                  ),
                ),
              );
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
                const SizedBox(height: 14),
                _ReferenceDropdown(
                  label: 'Môn học',
                  items: values[1],
                  idKey: 'ma_mon',
                  onChanged: (value) => subjectId = value,
                ),
                const SizedBox(height: 14),
                _ReferenceDropdown(
                  label: 'Học kỳ',
                  items: values[2],
                  idKey: 'ma_hoc_ky',
                  onChanged: (value) => termId = value,
                ),
                if (error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withAlpha(120),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colorScheme.error.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: colorScheme.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error!,
                            style: TextStyle(
                              color: colorScheme.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
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
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: items
        .map(
          (item) => DropdownMenuItem<num>(
            value: item[idKey] as num,
            child: Text(rowLabel(item), overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: onChanged,
  );
}
