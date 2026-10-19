import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_controls.dart';
import 'batch_repository.dart';
import 'cancel_ticket_dialog.dart' show kPresetCancelReasons;

/// Hộp thoại hủy cả lô: hủy mềm mọi phiếu chưa duyệt của lô (ADR-0016 mục 3).
/// Trả `true` khi đã hủy.
Future<bool?> showCancelBatchDialog({
  required BuildContext context,
  required num gradebookId,
  required String batchId,
}) => showDialog<bool>(
  context: context,
  builder: (_) =>
      _CancelBatchDialog(gradebookId: gradebookId, batchId: batchId),
);

class _CancelBatchDialog extends ConsumerStatefulWidget {
  const _CancelBatchDialog({required this.gradebookId, required this.batchId});

  final num gradebookId;
  final String batchId;

  @override
  ConsumerState<_CancelBatchDialog> createState() => _CancelBatchDialogState();
}

class _CancelBatchDialogState extends ConsumerState<_CancelBatchDialog> {
  String? preset;
  final other = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    other.dispose();
    super.dispose();
  }

  String? get reason {
    if (preset == null) return null;
    if (preset == 'Khác…') {
      final text = other.text.trim();
      return text.isEmpty || text.length > 200 ? null : text;
    }
    return preset;
  }

  Future<void> _submit() async {
    final resolved = reason;
    if (resolved == null || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(recognitionBatchRepositoryProvider)
          .cancel(
            gradebookId: widget.gradebookId,
            batchId: widget.batchId,
            reason: resolved,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        error = batchErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    return Dialog(
      key: const ValueKey('cancel-batch-dialog'),
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: t.line),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.cancel_outlined, color: t.bad, size: 24),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Hủy lô nhận dạng #${widget.batchId}?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Mọi phiếu chưa duyệt của lô sẽ bị hủy, không ghi điểm. Phiếu đã duyệt được giữ nguyên.',
                style: theme.textTheme.bodyMedium?.copyWith(color: t.ink2),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Lý do hủy (bắt buộc):',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final item in kPresetCancelReasons)
                    ChoiceChip(
                      key: ValueKey('cancel-batch-reason-$item'),
                      label: Text(item),
                      selected: preset == item,
                      selectedColor: t.priSoft,
                      backgroundColor: t.surface,
                      side: BorderSide(color: preset == item ? t.pri : t.line2),
                      shape: const StadiumBorder(),
                      labelStyle: TextStyle(
                        fontSize: 13,
                        color: preset == item ? t.priLink : t.ink2,
                      ),
                      checkmarkColor: t.priLink,
                      onSelected: busy
                          ? null
                          : (on) => setState(() => preset = on ? item : null),
                    ),
                ],
              ),
              if (preset == 'Khác…') ...[
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const ValueKey('cancel-batch-reason-other'),
                  controller: other,
                  enabled: !busy,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Lý do cụ thể (1–200 ký tự)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error!,
                  key: const ValueKey('cancel-batch-error'),
                  style: theme.textTheme.bodyMedium?.copyWith(color: t.bad),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton(
                    key: const ValueKey('close-cancel-batch'),
                    onPressed: busy
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(80, AppControlMetrics.height),
                    ),
                    child: const Text('Đóng'),
                  ),
                  FilledButton.icon(
                    key: const ValueKey('confirm-cancel-batch'),
                    onPressed: busy || reason == null ? null : _submit,
                    icon: busy
                        ? SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onError,
                            ),
                          )
                        : const Icon(Icons.cancel_outlined, size: 20),
                    label: const Text('Hủy lô'),
                    style: FilledButton.styleFrom(
                      backgroundColor: t.bad,
                      foregroundColor: theme.colorScheme.onError,
                      minimumSize: const Size(120, AppControlMetrics.height),
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
