import 'package:flutter/material.dart';

import '../design_tokens.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.child,
    this.confirmLabel = 'Lưu',
    this.cancelLabel = 'Hủy',
    this.onConfirm,
    this.onCancel,
    this.danger = false,
    this.confirmEnabled = true,
    this.showFooter = true,
    this.showCancel = true,
    this.maxWidth = 520,
  });

  final String title;
  final Widget child;
  final String confirmLabel;
  final String cancelLabel;

  final VoidCallback? onConfirm;

  final VoidCallback? onCancel;
  final bool danger;
  final bool confirmEnabled;
  final bool showFooter;

  final bool showCancel;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);
    void cancel() => onCancel != null
        ? onCancel!()
        : Navigator.of(context).maybePop<bool>(false);
    void confirm() => onConfirm != null
        ? onConfirm!()
        : Navigator.of(context).maybePop<bool>(true);

    final confirmStyle = danger
        ? FilledButton.styleFrom(
            backgroundColor: t.bad,
            foregroundColor: theme.colorScheme.onError,
          )
        : null;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          key: const ValueKey('app-dialog-box'),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: radius,
            border: Border.all(color: t.line),
            boxShadow: t.pop,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: t.line)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 12, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('app-dialog-close'),
                          tooltip: 'Đóng',
                          icon: const Icon(Icons.close, size: 20),
                          color: t.ink2,
                          onPressed: cancel,
                        ),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: AppSpacing.xl,
                    ),
                    child: child,
                  ),
                ),
                if (showFooter)
                  DecoratedBox(
                    key: const ValueKey('app-dialog-footer'),
                    decoration: BoxDecoration(
                      color: t.subtle,
                      border: Border(top: BorderSide(color: t.line)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (showCancel)
                            OutlinedButton(
                              key: const ValueKey('app-dialog-cancel'),
                              onPressed: cancel,
                              child: Text(cancelLabel),
                            ),
                          FilledButton(
                            key: const ValueKey('app-dialog-confirm'),
                            style: confirmStyle,
                            onPressed: confirmEnabled ? confirm : null,
                            child: Text(confirmLabel),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) => showDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  builder: builder,
);
