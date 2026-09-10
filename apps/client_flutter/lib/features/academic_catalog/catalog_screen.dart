import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../authentication/session.dart';
import 'repository.dart';
import 'fields.dart';
import 'edit_dialog.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key, required this.resource});
  final String resource;
  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  late Future<CatalogPageData> page;
  final cursors = <String?>[null];
  String filter = '';
  ResourceSpec get spec =>
      resources.firstWhere((r) => r.key == widget.resource);
  bool get admin => ref.read(sessionProvider)?.role.value == 'QUAN_TRI_VIEN';
  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void didUpdateWidget(CatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resource != widget.resource) {
      cursors.clear();
      cursors.add(null);
      filter = '';
      reload();
    }
  }

  void reload() {
    page = ref
        .read(catalogRepositoryProvider)
        .list(widget.resource, cursor: cursors.last, q: filter);
  }

  Future<void> edit([Json? row]) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditDialog(spec: spec, row: row),
    );
    if (changed == true && mounted) setState(reload);
  }

  Future<void> remove(Json row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bản ghi chưa sử dụng?'),
        content: Text(
          'Xóa ${rowLabel(row)}? Dữ liệu đã được tham chiếu sẽ được giữ lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(catalogRepositoryProvider)
          .remove(spec.key, row[spec.id] as num);
      if (mounted) setState(reload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(spec.label),
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
    floatingActionButton: admin
        ? FloatingActionButton.extended(
            onPressed: () => edit(),
            icon: const Icon(Icons.add),
            label: const Text('Thêm mới'),
          )
        : null,
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            key: ValueKey(spec.key),
            decoration: const InputDecoration(
              labelText: 'Tìm tên, nhấn Enter để tìm',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => setState(() {
              filter = v.trim();
              cursors.clear();
              cursors.add(null);
              reload();
            }),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<CatalogPageData>(
              future: page,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(errorMessage(snapshot.error!)),
                        FilledButton(
                          onPressed: () => setState(reload),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                final data = snapshot.data!;
                final rows = data.items
                    .where(
                      (r) => rowLabel(
                        r,
                      ).toLowerCase().contains(filter.toLowerCase()),
                    )
                    .toList();
                return Column(
                  children: [
                    Expanded(
                      child: rows.isEmpty
                          ? const Center(
                              child: Text('Chưa có dữ liệu phù hợp.'),
                            )
                          : ListView.separated(
                              itemCount: rows.length,
                              separatorBuilder: (_, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final row = rows[index];
                                return ListTile(
                                  title: Text(rowLabel(row)),
                                  subtitle: Text(
                                    spec.key == 'accounts'
                                        ? '${roleLabel(row['role'] as String)} · ${row['active'] == true ? 'Hoạt động' : 'Đã khóa'}'
                                        : spec.key == 'students'
                                        ? (row['dang_theo_hoc'] == true
                                              ? 'Đang theo học'
                                              : 'Ngừng theo dõi')
                                        : 'Chọn để xem thông tin',
                                  ),
                                  onTap: () => edit(row),
                                  trailing:
                                      admin &&
                                          ![
                                            'accounts',
                                            'students',
                                          ].contains(spec.key)
                                      ? IconButton(
                                          tooltip: 'Xóa',
                                          onPressed: () => remove(row),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                        )
                                      : const Icon(Icons.chevron_right),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 64),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton(
                            onPressed: cursors.length > 1
                                ? () => setState(() {
                                    cursors.removeLast();
                                    reload();
                                  })
                                : null,
                            child: const Text('Trang trước'),
                          ),
                          Text('Trang ${cursors.length}'),
                          TextButton(
                            onPressed: data.nextCursor != null
                                ? () => setState(() {
                                    cursors.add(data.nextCursor);
                                    reload();
                                  })
                                : null,
                            child: const Text('Trang sau'),
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
  );
}
