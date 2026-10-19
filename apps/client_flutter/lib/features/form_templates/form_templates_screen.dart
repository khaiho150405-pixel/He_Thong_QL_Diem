import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../app/widgets/empty_state.dart';
import '../../app/widgets/shimmer_loading.dart';
import 'common.dart';
import 'repository.dart';

final templateListProvider =
    FutureProvider.autoDispose<List<TemplateSummaryDto>>(
      (ref) => ref.read(formTemplatesRepositoryProvider).list(),
    );

/// `/admin/form-templates`: danh sách mẫu bảng điểm cho QTV (ADR-0016 mục 5).
class FormTemplatesScreen extends ConsumerWidget {
  const FormTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(templateListProvider);
    void reload() => ref.invalidate(templateListProvider);
    void create() => context.go('/admin/form-templates/new');
    return AppScaffold(
      title: 'Mẫu bảng điểm',
      currentPath: '/admin/form-templates',
      showBackButton: true,
      actions: [
        IconButton(
          tooltip: 'Tải lại',
          onPressed: reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: list.when(
            loading: () => const Padding(
              key: ValueKey('templates-loading'),
              padding: EdgeInsets.all(AppSpacing.xl),
              child: ShimmerLoading(itemCount: 4, itemHeight: 88),
            ),
            error: (error, _) => EmptyState(
              key: const ValueKey('templates-error'),
              icon: Icons.error_outline,
              title: 'Không tải được danh sách mẫu',
              message: templateErrorMessage(error),
              actionLabel: 'Thử lại',
              onAction: reload,
            ),
            data: (items) => items.isEmpty
                ? EmptyState(
                    key: const ValueKey('templates-empty'),
                    icon: Icons.grid_on_outlined,
                    title: 'Chưa có mẫu bảng điểm',
                    message:
                        'Tạo mẫu từ ảnh một tờ bảng điểm để giáo viên nhận '
                        'dạng nhiều cột, nhiều trang.',
                    actionLabel: 'Tạo mẫu',
                    onAction: create,
                  )
                : _Content(items: items, onCreate: create),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.items, required this.onCreate});

  final List<TemplateSummaryDto> items;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListView(
      padding: templatePagePadding(context),
      children: [
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.md,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Text(
                'Mỗi mẫu khai báo các cột của một loại tờ bảng điểm. Giáo '
                'viên chọn mẫu khi nhận dạng.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: t.ink2),
              ),
            ),
            FilledButton.icon(
              key: const ValueKey('create-template'),
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tạo mẫu'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _TemplateTile(item: item),
          ),
      ],
    );
  }
}

class _TemplateTile extends ConsumerWidget {
  const _TemplateTile({required this.item});

  final TemplateSummaryDto item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final theme = Theme.of(context);
    // Bản tóm tắt không có kiểu đọc; lấy từ chi tiết (đã cache) để không đoán.
    final detail = ref.watch(templateDetailProvider(item.id));
    final readMode = detail.when(
      data: (d) => readModeLabel(d.columns),
      loading: () => 'Đang tải…',
      error: (_, _) => '—',
    );
    final meta = theme.textTheme.bodySmall?.copyWith(color: t.ink2);
    return InkWell(
      key: ValueKey('template-tile-${item.id}'),
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => context.go('/admin/form-templates/${item.id}'),
      child: TemplateCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width - 120,
                  ),
                  child: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: t.heading,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                templateStatusBadge(item.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: [
                Text('Phiên bản ${item.revision}', style: meta),
                Text('${item.gradeColumnCount} cột điểm', style: meta),
                Text(
                  readMode,
                  key: ValueKey('template-readmode-${item.id}'),
                  style: meta,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
