import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_scaffold.dart';
import 'column_draft.dart';
import 'column_editor.dart';
import 'common.dart';
import 'definition_fields.dart';
import 'form_templates_screen.dart';
import 'repository.dart';

enum TemplateEditMode { edit, newVersion }

/// Sửa tại chỗ hoặc tạo phiên bản mới của một mẫu đã có. Chỉ sửa khai báo
/// (tên, mô tả, vai trò cột); ảnh mẫu và chữ ký lưới giữ nguyên.
/// Pop về [TemplateDetailDto] đã lưu, hoặc null nếu hủy.
class TemplateEditorScreen extends ConsumerStatefulWidget {
  const TemplateEditorScreen({
    super.key,
    required this.template,
    required this.mode,
    required this.onInUse,
  });

  final TemplateDetailDto template;
  final TemplateEditMode mode;

  /// Gọi khi backend trả `TEMPLATE_IN_USE`, để màn chi tiết ẩn nút Sửa.
  final VoidCallback onInUse;

  @override
  ConsumerState<TemplateEditorScreen> createState() =>
      _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  late final TextEditingController _name = TextEditingController(
    text: widget.template.name,
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.template.description ?? '',
  );
  late List<ColumnDraft> _columns = [
    for (final c in [
      ...widget.template.columns,
    ]..sort((a, b) => a.index.compareTo(b.index)))
      ColumnDraft.fromTemplate(c),
  ];
  late TemplateEditMode _mode = widget.mode;
  bool _busy = false;
  String? _error;
  bool _inUse = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  DraftValidation get _validation => validateDrafts(_columns);

  bool get _canSave =>
      !_busy &&
      _validation.isValid &&
      templateNameError(_name.text) == null &&
      templateDescriptionError(_description.text) == null;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(formTemplatesRepositoryProvider);
    final description = _description.text.trim();
    final columns = [for (final c in _columns) c.toDto()];
    try {
      final saved = _mode == TemplateEditMode.edit
          ? await repo.update(
              id: widget.template.id,
              expectedVersion: widget.template.version,
              name: _name.text.trim(),
              description: description.isEmpty ? null : description,
              columns: columns,
            )
          : await repo.createVersion(
              id: widget.template.id,
              expectedVersion: widget.template.version,
              name: _name.text.trim(),
              description: description.isEmpty ? null : description,
              columns: columns,
            );
      ref.invalidate(templateListProvider);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (error) {
      if (!mounted) return;
      final inUse = apiErrorCode(error) == 'TEMPLATE_IN_USE';
      if (inUse) widget.onInUse();
      setState(() {
        _busy = false;
        _error = templateErrorMessage(error);
        if (inUse) {
          // Giữ nguyên nội dung đã nhập, chuyển sang lưu thành phiên bản mới.
          _inUse = true;
          _mode = TemplateEditMode.newVersion;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final isEdit = _mode == TemplateEditMode.edit;
    return AppScaffold(
      title: isEdit ? 'Sửa mẫu' : 'Tạo phiên bản mới',
      currentPath: '/admin/form-templates',
      showBackButton: true,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: templatePagePadding(context),
            children: [
              Text(
                isEdit
                    ? 'Sửa tại chỗ chỉ được khi mẫu chưa có phiếu nhận dạng '
                          'nào dùng.'
                    : 'Phiên bản mới giữ nguyên ảnh mẫu; bản hiện tại chuyển '
                          'sang "Ngừng".',
                style: theme.textTheme.bodyMedium?.copyWith(color: t.ink2),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: TemplateNotice(
                    key: const ValueKey('editor-error'),
                    message: _inUse
                        ? '$_error Nội dung bạn nhập được giữ lại; bấm '
                              '"Lưu phiên bản mới" để tiếp tục.'
                        : _error!,
                    tone: _inUse ? AppBadgeTone.warn : AppBadgeTone.bad,
                    icon: _inUse ? Icons.info_outline : Icons.error_outline,
                  ),
                ),
              TemplateCard(
                child: TemplateDefinitionFields(
                  nameController: _name,
                  descriptionController: _description,
                  nameKey: const ValueKey('editor-name'),
                  descriptionKey: const ValueKey('editor-description'),
                  enabled: !_busy,
                  onChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TemplateColumnEditor(
                columns: _columns,
                validation: _validation,
                enabled: !_busy,
                onChanged: (next) => setState(() => _columns = next),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton(
                    key: const ValueKey('editor-cancel'),
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                  FilledButton(
                    key: const ValueKey('editor-save'),
                    onPressed: _canSave ? _save : null,
                    child: Text(
                      _busy
                          ? 'Đang lưu…'
                          : (isEdit ? 'Lưu thay đổi' : 'Lưu phiên bản mới'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
