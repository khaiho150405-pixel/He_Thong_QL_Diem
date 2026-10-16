import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_controls.dart';
import '../authentication/session.dart';
import 'repository.dart';

const List<String> kPresetCancelReasons = [
  'Chọn nhầm ảnh',
  'Nhầm thành phần điểm',
  'Ảnh mờ / chụp lại',
  'Khác…',
];

Future<bool?> showCancelTicketDialog({
  required BuildContext context,
  required WidgetRef ref,
  required num gradebookId,
  required String ticketId,
  required num expectedVersion,
  VoidCallback? onSuccess,
}) async {
  final isMobile = MediaQuery.sizeOf(context).width < 600;
  final t = context.tokens;
  if (isMobile) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        side: BorderSide(color: t.line),
      ),
      builder: (ctx) => CancelTicketSheetContent(
        key: const ValueKey('cancel-ticket-bottom-sheet'),
        gradebookId: gradebookId,
        ticketId: ticketId,
        expectedVersion: expectedVersion,
        onSuccess: onSuccess,
        isMobile: true,
      ),
    );
  } else {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        key: const ValueKey('cancel-ticket-dialog'),
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: t.line),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: CancelTicketSheetContent(
            gradebookId: gradebookId,
            ticketId: ticketId,
            expectedVersion: expectedVersion,
            onSuccess: onSuccess,
            isMobile: false,
          ),
        ),
      ),
    );
  }
}

class CancelTicketSheetContent extends ConsumerStatefulWidget {
  const CancelTicketSheetContent({
    super.key,
    required this.gradebookId,
    required this.ticketId,
    required this.expectedVersion,
    this.onSuccess,
    required this.isMobile,
  });

  final num gradebookId;
  final String ticketId;
  final num expectedVersion;
  final VoidCallback? onSuccess;
  final bool isMobile;

  @override
  ConsumerState<CancelTicketSheetContent> createState() =>
      _CancelTicketSheetContentState();
}

class _CancelTicketSheetContentState
    extends ConsumerState<CancelTicketSheetContent> {
  String? selectedPreset;
  final otherController = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    otherController.dispose();
    super.dispose();
  }

  String? get resolvedReason {
    if (selectedPreset == null) return null;
    if (selectedPreset == 'Khác…') {
      final text = otherController.text.trim();
      if (text.isEmpty || text.length > 200) return null;
      return text;
    }
    return selectedPreset;
  }

  Future<void> _submit() async {
    final reason = resolvedReason;
    if (reason == null || busy) return;

    setState(() => busy = true);
    try {
      await ref
          .read(recognitionRepositoryProvider)
          .cancel(
            gradebookId: widget.gradebookId,
            ticketId: widget.ticketId,
            expectedVersion: widget.expectedVersion,
            reason: reason,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã hủy phiếu #${widget.ticketId}')),
      );
      widget.onSuccess?.call();
    } catch (error) {
      if (!mounted) return;
      setState(() => busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final t = context.tokens;
    final canSubmit = !busy && resolvedReason != null;

    final insets = MediaQuery.viewInsetsOf(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + (widget.isMobile ? insets.bottom : 0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.cancel_outlined, color: t.bad, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hủy phiếu #${widget.ticketId}?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Kết quả nhận dạng sẽ bị bỏ, không ghi điểm. Có thể tải lại ảnh đúng sau khi hủy.',
            style: theme.textTheme.bodyMedium?.copyWith(color: t.ink2),
          ),
          const SizedBox(height: 16),
          Text(
            'Lý do hủy (bắt buộc):',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in kPresetCancelReasons)
                ChoiceChip(
                  key: ValueKey('cancel-reason-$preset'),
                  label: Text(preset),
                  selectedColor: t.priSoft,
                  backgroundColor: t.surface,
                  side: BorderSide(
                    color: selectedPreset == preset ? t.pri : t.line2,
                  ),
                  shape: const StadiumBorder(),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: selectedPreset == preset
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: selectedPreset == preset ? t.priLink : t.ink2,
                  ),
                  checkmarkColor: t.priLink,
                  selected: selectedPreset == preset,
                  onSelected: busy
                      ? null
                      : (selected) {
                          setState(() {
                            selectedPreset = selected ? preset : null;
                          });
                        },
                ),
            ],
          ),
          if (selectedPreset == 'Khác…') ...[
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('cancel-reason-other-input'),
              controller: otherController,
              enabled: !busy,
              maxLength: 200,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Lý do cụ thể (1–200 ký tự)',
                hintText: 'Nhập lý do hủy phiếu…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppControlMetrics.radius),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 24),
          if (widget.isMobile) ...[
            SizedBox(
              height: AppControlMetrics.height,
              child: FilledButton.icon(
                key: const ValueKey('confirm-cancel-ticket-button'),
                onPressed: canSubmit ? _submit : null,
                icon: busy
                    ? SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onError,
                        ),
                      )
                    : const Icon(Icons.cancel_outlined, size: 20),
                label: const Text('Hủy phiếu'),
                style: FilledButton.styleFrom(
                  backgroundColor: t.bad,
                  foregroundColor: colorScheme.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppControlMetrics.radius,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: AppControlMetrics.height,
              child: OutlinedButton(
                key: const ValueKey('close-cancel-ticket-button'),
                onPressed: busy ? null : () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppControlMetrics.radius,
                    ),
                  ),
                ),
                child: const Text('Đóng'),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  key: const ValueKey('close-cancel-ticket-button'),
                  onPressed: busy
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(80, AppControlMetrics.height),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppControlMetrics.radius,
                      ),
                    ),
                  ),
                  child: const Text('Đóng'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  key: const ValueKey('confirm-cancel-ticket-button'),
                  onPressed: canSubmit ? _submit : null,
                  icon: busy
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onError,
                          ),
                        )
                      : const Icon(Icons.cancel_outlined, size: 20),
                  label: const Text('Hủy phiếu'),
                  style: FilledButton.styleFrom(
                    backgroundColor: t.bad,
                    foregroundColor: colorScheme.onError,
                    minimumSize: const Size(120, AppControlMetrics.height),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppControlMetrics.radius,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
