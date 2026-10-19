import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../app/widgets/empty_state.dart';
import '../../app/widgets/shimmer_loading.dart';
import '../recognition/image_picker.dart';
import '../recognition/image_preview.dart';
import 'common.dart';
import 'form_templates_screen.dart';
import 'image_source_buttons.dart';
import 'repository.dart';
import 'template_editor_screen.dart';
import 'try_result_view.dart';

/// `/admin/form-templates/:id`: ảnh mẫu, bảng cột, đổi trạng thái, sửa / tạo
/// phiên bản và "Thử nhận dạng" (chỉ đọc, không lưu gì).
class TemplateDetailScreen extends ConsumerStatefulWidget {
  const TemplateDetailScreen({super.key, required this.templateId});

  final num templateId;

  @override
  ConsumerState<TemplateDetailScreen> createState() =>
      _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends ConsumerState<TemplateDetailScreen> {
  // Trạng thái tạm giữ ở đây (không ở widget con) để không mất khi tải lại.
  bool _inUse = false;
  bool _busy = false;
  String? _actionError;
  bool _tryBusy = false;
  String? _tryError;
  RecognitionImage? _tryImage;
  TryResultDto? _tryResult;

  void _reload() {
    ref.invalidate(templateDetailProvider(widget.templateId));
    ref.invalidate(templateListProvider);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _actionError = templateErrorMessage(error);
        if (apiErrorCode(error) == 'TEMPLATE_IN_USE') _inUse = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _activate(TemplateDetailDto template) => _run(() async {
    await ref
        .read(formTemplatesRepositoryProvider)
        .activate(id: template.id, expectedVersion: template.version);
    _reload();
  });

  Future<void> _retire(TemplateDetailDto template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ngừng dùng mẫu này?'),
        content: const Text(
          'Giáo viên sẽ không chọn được mẫu này nữa. Phiếu đã nhận dạng '
          'không bị ảnh hưởng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            key: const ValueKey('confirm-retire'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ngừng dùng'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      await ref
          .read(formTemplatesRepositoryProvider)
          .retire(id: template.id, expectedVersion: template.version);
      _reload();
    });
  }

  Future<void> _openEditor(
    TemplateDetailDto template,
    TemplateEditMode mode,
  ) async {
    final saved = await Navigator.of(context).push<TemplateDetailDto>(
      MaterialPageRoute(
        builder: (_) => TemplateEditorScreen(
          template: template,
          mode: mode,
          onInUse: () {
            if (mounted) setState(() => _inUse = true);
          },
        ),
      ),
    );
    if (!mounted || saved == null) return;
    if (saved.id != template.id) {
      context.go('/admin/form-templates/${saved.id}');
    } else {
      _reload();
    }
  }

  Future<void> _tryWith(
    TemplateDetailDto template,
    RecognitionImage image,
  ) async {
    if (_tryBusy) return;
    setState(() {
      _tryBusy = true;
      _tryError = null;
      _tryImage = image;
    });
    try {
      final result = await ref
          .read(formTemplatesRepositoryProvider)
          .tryTemplate(id: template.id, image: image);
      if (mounted) setState(() => _tryResult = result);
    } catch (error) {
      if (mounted) {
        setState(() {
          _tryError = templateErrorMessage(error);
          _tryResult = null;
        });
      }
    } finally {
      if (mounted) setState(() => _tryBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(templateDetailProvider(widget.templateId));
    return AppScaffold(
      title: 'Chi tiết mẫu',
      currentPath: '/admin/form-templates',
      showBackButton: true,
      onBack: () => context.go('/admin/form-templates'),
      actions: [
        IconButton(
          tooltip: 'Tải lại',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: detail.when(
            skipLoadingOnReload: true,
            loading: () => const Padding(
              key: ValueKey('detail-loading'),
              padding: EdgeInsets.all(AppSpacing.xl),
              child: ShimmerLoading(itemCount: 4, itemHeight: 88),
            ),
            error: (error, _) => EmptyState(
              key: const ValueKey('detail-error'),
              icon: Icons.error_outline,
              title: 'Không tải được mẫu',
              message: templateErrorMessage(error),
              actionLabel: 'Thử lại',
              onAction: _reload,
            ),
            data: (template) => _body(context, template),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, TemplateDetailDto template) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final columns = [...template.columns]
      ..sort((a, b) => a.index.compareTo(b.index));
    return ListView(
      padding: templatePagePadding(context),
      children: [
        TemplateCard(
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
                      maxWidth: MediaQuery.sizeOf(context).width - 96,
                    ),
                    child: Text(
                      template.name,
                      key: const ValueKey('detail-name'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: t.heading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  templateDetailStatusBadge(template.status),
                ],
              ),
              if ((template.description ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  template.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: t.ink2),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  AppBadge('Phiên bản ${template.revision}', dot: false),
                  AppBadge('${template.columnCount} cột', dot: false),
                  AppBadge('${template.gradeColumnCount} cột điểm', dot: false),
                  AppBadge(
                    key: const ValueKey('detail-readmode'),
                    readModeLabel(template.columns),
                    dot: false,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _actions(context, template),
            ],
          ),
        ),
        if (_actionError != null) ...[
          const SizedBox(height: AppSpacing.md),
          TemplateNotice(
            key: const ValueKey('detail-action-error'),
            message: _actionError!,
          ),
        ],
        if (_inUse) ...[
          const SizedBox(height: AppSpacing.md),
          const TemplateNotice(
            key: ValueKey('template-in-use-note'),
            tone: AppBadgeTone.warn,
            icon: Icons.info_outline,
            message:
                'Mẫu đã được phiếu nhận dạng sử dụng nên không sửa tại chỗ. '
                'Dùng "Tạo phiên bản mới": bản này chuyển sang "Ngừng" và '
                'phiếu cũ vẫn giữ nguyên.',
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _imageCard(context, template),
        const SizedBox(height: AppSpacing.lg),
        TemplateCard(
          key: const ValueKey('detail-columns'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Các cột của mẫu',
                style: theme.textTheme.titleSmall?.copyWith(color: t.heading),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final column in columns)
                _columnRow(context, column, columns),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _trySection(context, template),
      ],
    );
  }

  Widget _actions(BuildContext context, TemplateDetailDto template) {
    final status = template.status;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (status == TemplateDetailDtoStatusEnum.NHAP)
          FilledButton.icon(
            key: const ValueKey('act-activate'),
            onPressed: _busy ? null : () => _activate(template),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Kích hoạt'),
          ),
        if (status == TemplateDetailDtoStatusEnum.DANG_DUNG)
          OutlinedButton.icon(
            key: const ValueKey('act-retire'),
            onPressed: _busy ? null : () => _retire(template),
            icon: const Icon(Icons.pause_circle_outline, size: 18),
            label: const Text('Ngừng'),
          ),
        OutlinedButton.icon(
          key: const ValueKey('act-new-version'),
          onPressed: _busy
              ? null
              : () => _openEditor(template, TemplateEditMode.newVersion),
          icon: const Icon(Icons.copy_all_outlined, size: 18),
          label: const Text('Tạo phiên bản mới'),
        ),
        if (!_inUse)
          OutlinedButton.icon(
            key: const ValueKey('act-edit'),
            onPressed: _busy
                ? null
                : () => _openEditor(template, TemplateEditMode.edit),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Sửa'),
          ),
      ],
    );
  }

  Widget _imageCard(BuildContext context, TemplateDetailDto template) {
    final t = context.tokens;
    final theme = Theme.of(context);
    Widget image() => Image.network(
      template.imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const SizedBox(
        height: 80,
        child: Center(child: Text('Không tải được ảnh mẫu')),
      ),
    );
    return TemplateCard(
      key: const ValueKey('detail-image'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ảnh mẫu',
            style: theme.textTheme.titleSmall?.copyWith(color: t.heading),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            key: const ValueKey('detail-image-open'),
            onTap: () => showRecognitionImage(context, image: image()),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.subtle,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: t.line),
                ),
                child: image(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Chạm vào ảnh để phóng to.',
            style: theme.textTheme.bodySmall?.copyWith(color: t.ink3),
          ),
        ],
      ),
    );
  }

  Widget _columnRow(
    BuildContext context,
    TemplateColumnDto column,
    List<TemplateColumnDto> all,
  ) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final header = (column.headerText ?? '').trim();
    final detail = switch (column.role) {
      TemplateColumnDtoRoleEnum.DIEM =>
        column.group == null || column.order == null
            ? null
            : '${column.group!.value}${column.order}'
                  '${all.any((c) => c.role == TemplateColumnDtoRoleEnum.DIEM_CHU && c.pairedWith == column.index) ? ' · có cột chữ' : ' · chỉ số'}',
      TemplateColumnDtoRoleEnum.DIEM_CHU =>
        column.pairedWith == null ? null : 'Của cột ${column.pairedWith}',
      _ => null,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        key: ValueKey('detail-column-${column.index}'),
        decoration: BoxDecoration(
          color: t.subtle,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: t.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Cột ${column.index}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: t.ink3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width - 120,
                ),
                child: Text(
                  header.isEmpty ? 'Không có tiêu đề' : header,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: header.isEmpty ? t.ink3 : t.ink,
                  ),
                ),
              ),
              AppBadge(roleLabel(column.role), dot: false),
              if (detail != null)
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(color: t.ink2),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trySection(BuildContext context, TemplateDetailDto template) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return TemplateCard(
      key: const ValueKey('detail-try'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Thử nhận dạng',
            style: theme.textTheme.titleSmall?.copyWith(color: t.heading),
          ),
          const SizedBox(height: AppSpacing.xs),
          const TemplateNotice(
            key: ValueKey('try-notice'),
            tone: AppBadgeTone.info,
            icon: Icons.info_outline,
            message:
                'Chỉ thử, không lưu. Kết quả không ghi vào bảng điểm và không '
                'ghép với học sinh nào.',
          ),
          const SizedBox(height: AppSpacing.md),
          ImageSourceButtons(
            enabled: !_tryBusy,
            pickLabel: 'Chọn ảnh để thử',
            onPicked: (image) => _tryWith(template, image),
            onError: (message) => setState(() => _tryError = message),
          ),
          if (_tryBusy) ...[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(key: ValueKey('try-progress')),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Đang đọc ảnh, có thể mất đến vài chục giây…',
              style: theme.textTheme.bodySmall?.copyWith(color: t.ink3),
            ),
          ],
          if (_tryError != null) ...[
            const SizedBox(height: AppSpacing.md),
            TemplateNotice(
              key: const ValueKey('try-error'),
              message: _tryError!,
              action: _tryImage == null
                  ? null
                  : OutlinedButton(
                      key: const ValueKey('try-retry'),
                      onPressed: _tryBusy
                          ? null
                          : () => _tryWith(template, _tryImage!),
                      child: const Text('Thử lại với ảnh này'),
                    ),
            ),
          ],
          if (_tryResult != null) ...[
            const SizedBox(height: AppSpacing.lg),
            TryResultView(result: _tryResult!),
          ],
        ],
      ),
    );
  }
}
