import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../authentication/session.dart';

String deadlineLabel(BuildContext context, String? value) {
  final date = value == null ? null : DateTime.tryParse(value)?.toLocal();
  if (date == null) return 'Chưa đặt lịch';
  final local = MaterialLocalizations.of(context);
  return '${local.formatShortDate(date)} ${local.formatTimeOfDay(TimeOfDay.fromDateTime(date), alwaysUse24HourFormat: true)}';
}

class GradeDeadlinesPanel extends ConsumerStatefulWidget {
  const GradeDeadlinesPanel({
    super.key,
    required this.bookId,
    required this.components,
    required this.isAdmin,
    required this.locked,
    required this.onReload,
  });
  final num bookId;
  final List<GradeCellDto> components;
  final bool isAdmin, locked;
  final VoidCallback onReload;

  @override
  ConsumerState<GradeDeadlinesPanel> createState() =>
      _GradeDeadlinesPanelState();
}

class _GradeDeadlinesPanelState extends ConsumerState<GradeDeadlinesPanel> {
  final horizontal = ScrollController();
  @override
  void dispose() {
    horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      initiallyExpanded: widget.isAdmin,
      title: const Text('Lịch nhập điểm của nhà trường'),
      subtitle: Text(
        '${widget.components.length} cột · Hết hạn: ô thiếu/chưa duyệt ghi 0 và tự khóa',
      ),
      children: [
        if (widget.components.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Chưa có cột điểm.'),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              if (isMobile) {
                return ListView.separated(
                  key: const ValueKey('grade-deadlines-vertical'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: widget.components.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final column = widget.components[index];
                    return _buildDeadlineCard(context, column);
                  },
                );
              }
              return Scrollbar(
                controller: horizontal,
                thumbVisibility: true,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  key: const ValueKey('grade-deadlines-horizontal'),
                  controller: horizontal,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final column in widget.components)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 268,
                            child: _buildDeadlineCard(context, column),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    ),
  );

  Widget _buildDeadlineCard(BuildContext context, GradeCellDto column) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              column.componentName,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Mở: ${deadlineLabel(context, column.opensAt)}\nHạn: ${deadlineLabel(context, column.closesAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (column.columnLocked == true)
              const Text('Đã khóa')
            else if (widget.isAdmin && !widget.locked)
              OutlinedButton.icon(
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  column.closesAt == null ? 'Đặt lịch' : 'Sửa lịch',
                ),
                onPressed: () async {
                  final saved = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => _DeadlineDialog(
                      bookId: widget.bookId,
                      column: column,
                    ),
                  );
                  if (saved == true) widget.onReload();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DeadlineDialog extends ConsumerStatefulWidget {
  const _DeadlineDialog({required this.bookId, required this.column});
  final num bookId;
  final GradeCellDto column;
  @override
  ConsumerState<_DeadlineDialog> createState() => _DeadlineDialogState();
}

class _DeadlineDialogState extends ConsumerState<_DeadlineDialog> {
  late DateTime opens, closes;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    opens =
        DateTime.tryParse(widget.column.opensAt ?? '')?.toLocal() ??
        DateTime.now();
    closes =
        DateTime.tryParse(widget.column.closesAt ?? '')?.toLocal() ??
        DateTime.now().add(const Duration(days: 7));
  }

  Future<void> pick(bool opening) async {
    final value = opening ? opens : closes;
    final date = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (time == null || !mounted) return;
    setState(() {
      final selected = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (opening) {
        opens = selected;
      } else {
        closes = selected;
      }
    });
  }

  Future<void> save() async {
    setState(() => busy = true);
    try {
      await ref
          .read(apiProvider)
          .getGradebooksApi()
          .gradebooksSetDeadline(
            id: widget.bookId,
            componentId: widget.column.componentId,
            gradeDeadlineInput: GradeDeadlineInput(
              opensAt: opens.toUtc(),
              closesAt: closes.toUtc(),
              expectedVersion: widget.column.deadlineVersion ?? 0,
            ),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Lịch nhập · ${widget.column.componentName}'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Giờ hiển thị theo thiết bị hiện tại. Đến hạn, điểm thiếu/chưa duyệt được ghi 0 và không thể mở lại cột đã khóa.',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: busy ? null : () => pick(true),
              icon: const Icon(Icons.calendar_today),
              label: Text(
                'Mở nhập: ${deadlineLabel(context, opens.toUtc().toIso8601String())}',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy ? null : () => pick(false),
              icon: const Icon(Icons.timer_outlined),
              label: Text(
                'Hạn nhập: ${deadlineLabel(context, closes.toUtc().toIso8601String())}',
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (busy) const LinearProgressIndicator(),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context, false),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: busy ? null : save,
        child: const Text('Lưu lịch nhập'),
      ),
    ],
  );
}
