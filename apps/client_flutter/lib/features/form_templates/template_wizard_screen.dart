import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_scaffold.dart';
import '../recognition/image_picker.dart';
import '../recognition/image_preview.dart';
import 'column_draft.dart';
import 'column_editor.dart';
import 'common.dart';
import 'definition_fields.dart';
import 'form_templates_screen.dart';
import 'image_source_buttons.dart';
import 'repository.dart';

/// `/admin/form-templates/new`: trình hướng dẫn tạo mẫu 3 bước (ADR-0016 mục 5).
/// ① chọn/chụp ảnh tờ mẫu → ② `analyze` + khai báo cột → ③ tên, mô tả, lưu.
class TemplateWizardScreen extends ConsumerStatefulWidget {
  const TemplateWizardScreen({super.key});

  @override
  ConsumerState<TemplateWizardScreen> createState() =>
      _TemplateWizardScreenState();
}

class _TemplateWizardScreenState extends ConsumerState<TemplateWizardScreen> {
  static const _titles = ['Ảnh mẫu', 'Khai báo cột', 'Tên và lưu'];

  final _name = TextEditingController();
  final _description = TextEditingController();
  int _step = 0;
  RecognitionImage? _image;
  AnalyzeResultDto? _analysis;
  Uint8List? _previewBytes;
  List<ColumnDraft> _columns = const [];
  bool _busy = false;
  String? _error;

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

  void _picked(RecognitionImage image) => setState(() {
    _image = image;
    // Ảnh đổi thì kết quả phân tích cũ không còn đúng.
    _analysis = null;
    _previewBytes = null;
    _columns = const [];
    _error = null;
  });

  Future<void> _analyze() async {
    final image = _image;
    if (image == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(formTemplatesRepositoryProvider)
          .analyze(image);
      final preview = base64Decode(result.previewPngBase64);
      if (!mounted) return;
      final sorted = [...result.columns]
        ..sort((a, b) => a.index.compareTo(b.index));
      setState(() {
        _analysis = result;
        _previewBytes = preview;
        _columns = [for (final c in sorted) ColumnDraft.fromAnalyzed(c)];
        _step = 1;
      });
    } catch (error) {
      if (mounted) setState(() => _error = templateErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final image = _image;
    if (image == null || !_canSave) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final description = _description.text.trim();
      final saved = await ref
          .read(formTemplatesRepositoryProvider)
          .create(
            image: image,
            name: _name.text.trim(),
            description: description.isEmpty ? null : description,
            columns: [for (final c in _columns) c.toDto()],
          );
      ref.invalidate(templateListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu mẫu ở trạng thái Nháp. Kích hoạt để dùng.'),
        ),
      );
      context.go('/admin/form-templates/${saved.id}');
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = templateErrorMessage(error);
          _busy = false;
        });
      }
    }
  }

  void _zoomPreview() {
    final bytes = _previewBytes;
    if (bytes == null) return;
    showRecognitionImage(
      context,
      image: Image.memory(bytes, fit: BoxFit.contain),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Tạo mẫu bảng điểm',
      currentPath: '/admin/form-templates',
      showBackButton: true,
      onBack: () => context.go('/admin/form-templates'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: templatePagePadding(context),
            children: [
              _Steps(titles: _titles, current: _step),
              const SizedBox(height: AppSpacing.lg),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: TemplateNotice(
                    key: const ValueKey('wizard-error'),
                    message: _error!,
                  ),
                ),
              if (_step == 0) _stepImage(context),
              if (_step == 1) _stepColumns(context),
              if (_step == 2) _stepSave(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepImage(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final image = _image;
    return TemplateCard(
      key: const ValueKey('wizard-step-image'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Chọn hoặc chụp ảnh một tờ bảng điểm làm mẫu',
            style: theme.textTheme.titleSmall?.copyWith(color: t.heading),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Chụp thẳng, đủ toàn bộ bảng kẻ ô và hàng tiêu đề cột. Ảnh này '
            'chỉ dùng để nhận ra các cột của loại tờ.',
            style: theme.textTheme.bodyMedium?.copyWith(color: t.ink2),
          ),
          const SizedBox(height: AppSpacing.lg),
          ImageSourceButtons(
            enabled: !_busy,
            pickLabel: image == null ? 'Chọn ảnh' : 'Chọn ảnh khác',
            onPicked: _picked,
            onError: (message) => setState(() => _error = message),
          ),
          if (image != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              image.name,
              key: const ValueKey('wizard-image-name'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: t.ink2),
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.subtle,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: t.line),
                ),
                child: Image.memory(
                  image.bytes,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox(
                    height: 80,
                    child: Center(child: Text('Không xem trước được ảnh')),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: const ValueKey('wizard-analyze'),
              onPressed: image == null || _busy ? null : _analyze,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_outlined, size: 18),
              label: Text(_busy ? 'Đang phân tích…' : 'Phân tích ảnh'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepColumns(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final validation = _validation;
    return Column(
      key: const ValueKey('wizard-step-columns'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TemplateCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Máy tìm thấy ${_analysis?.columnCount ?? _columns.length} cột',
                style: theme.textTheme.titleSmall?.copyWith(color: t.heading),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Số trên ảnh là số của "Cột n" bên dưới. Chạm vào ảnh để '
                'phóng to.',
                style: theme.textTheme.bodyMedium?.copyWith(color: t.ink2),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_previewBytes != null)
                InkWell(
                  key: const ValueKey('wizard-preview'),
                  onTap: _zoomPreview,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.subtle,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: t.line),
                      ),
                      child: Image.memory(
                        _previewBytes!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox(
                          height: 80,
                          child: Center(
                            child: Text('Không xem trước được ảnh'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('wizard-zoom'),
                  onPressed: _previewBytes == null ? null : _zoomPreview,
                  icon: const Icon(Icons.zoom_in, size: 18),
                  label: const Text('Phóng to ảnh'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TemplateColumnEditor(
          columns: _columns,
          validation: validation,
          enabled: !_busy,
          onChanged: (next) => setState(() => _columns = next),
        ),
        const SizedBox(height: AppSpacing.md),
        _NavRow(
          back: () => setState(() {
            _step = 0;
            _error = null;
          }),
          next: () => setState(() {
            _step = 2;
            _error = null;
          }),
          nextLabel: 'Tiếp',
          nextKey: const ValueKey('wizard-next'),
        ),
      ],
    );
  }

  Widget _stepSave(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final validation = _validation;
    final grades = _columns.where((c) => c.role == Role.DIEM).length;
    return TemplateCard(
      key: const ValueKey('wizard-step-save'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TemplateDefinitionFields(
            nameController: _name,
            descriptionController: _description,
            nameKey: const ValueKey('wizard-name'),
            descriptionKey: const ValueKey('wizard-description'),
            enabled: !_busy,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              AppBadge('${_columns.length} cột', dot: false),
              AppBadge('$grades cột điểm', dot: false),
              const AppBadge('Lưu ở trạng thái Nháp', dot: false),
            ],
          ),
          if (!validation.isValid) ...[
            const SizedBox(height: AppSpacing.md),
            TemplateNotice(
              key: const ValueKey('wizard-invalid'),
              message:
                  'Khai báo cột còn ${validation.issues.length} lỗi nên chưa '
                  'lưu được. Quay lại bước 2 để sửa.',
              action: OutlinedButton(
                key: const ValueKey('wizard-fix-columns'),
                onPressed: () => setState(() => _step = 1),
                child: const Text('Sửa khai báo cột'),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            'Backend kiểm lại lần cuối khi lưu.',
            style: theme.textTheme.bodySmall?.copyWith(color: t.ink3),
          ),
          const SizedBox(height: AppSpacing.md),
          _NavRow(
            back: _busy ? null : () => setState(() => _step = 1),
            next: _canSave ? _save : null,
            nextLabel: _busy ? 'Đang lưu…' : 'Lưu mẫu',
            nextKey: const ValueKey('wizard-save'),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.back,
    required this.next,
    required this.nextLabel,
    required this.nextKey,
  });

  final VoidCallback? back;
  final VoidCallback? next;
  final String nextLabel;
  final Key nextKey;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton(
          key: const ValueKey('wizard-back'),
          onPressed: back,
          child: const Text('Quay lại'),
        ),
        FilledButton(key: nextKey, onPressed: next, child: Text(nextLabel)),
      ],
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.titles, required this.current});

  final List<String> titles;
  final int current;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Row(
      key: const ValueKey('wizard-steps'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < titles.length; i++)
          Expanded(
            child: Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == current
                        ? t.pri
                        : (i < current ? t.okSoft : t.subtle),
                    border: Border.all(
                      color: i == current
                          ? t.pri
                          : (i < current ? t.okLine : t.line),
                    ),
                  ),
                  child: SizedBox.square(
                    dimension: 32,
                    child: Center(
                      child: i < current
                          ? Icon(Icons.check, size: 16, color: t.ok)
                          : Text(
                              '${i + 1}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: i == current ? t.onPri : t.ink3,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  titles[i],
                  key: ValueKey('wizard-step-title-$i'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: i == current ? t.heading : t.ink3,
                    fontWeight: i == current ? FontWeight.w700 : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
