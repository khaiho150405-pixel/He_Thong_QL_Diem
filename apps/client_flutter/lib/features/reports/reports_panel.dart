import 'package:api_client_dart/api_client_dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../authentication/session.dart';
import 'repository.dart';

class ReportsPanel extends ConsumerStatefulWidget {
  const ReportsPanel({
    super.key,
    required this.gradebookId,
    this.compact = false,
  });

  final num gradebookId;
  final bool compact;

  @override
  ConsumerState<ReportsPanel> createState() => _ReportsPanelState();
}

class _ReportsPanelState extends ConsumerState<ReportsPanel> {
  late Future<GradebookSummaryDto> summary;
  bool exporting = false;

  @override
  void initState() {
    super.initState();
    summary = ref.read(reportsRepositoryProvider).summary(widget.gradebookId);
  }

  Future<void> export() async {
    setState(() => exporting = true);
    try {
      final bytes = await ref
          .read(reportsRepositoryProvider)
          .export(widget.gradebookId);
      final path = await FilePicker.saveFile(
        dialogTitle: 'Lưu báo cáo Excel',
        fileName: 'bang-diem-${widget.gradebookId}.xlsx',
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        bytes: bytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'Đã hủy lưu báo cáo.'
                : 'Đã xuất báo cáo Excel thành công.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage(error))));
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<GradebookSummaryDto>(
          future: summary,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Column(
                children: [
                  SizedBox(height: 12),
                  LinearProgressIndicator(),
                  SizedBox(height: 12),
                ],
              );
            }
            if (snapshot.hasError) {
              return Row(
                children: [
                  Expanded(child: Text(errorMessage(snapshot.error!))),
                  TextButton(
                    onPressed: () => setState(() {
                      summary = ref
                          .read(reportsRepositoryProvider)
                          .summary(widget.gradebookId);
                    }),
                    child: const Text('Thử lại'),
                  ),
                ],
              );
            }
            final data = snapshot.data!;
            if (widget.compact) {
              return Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.bar_chart_rounded),
                  Text(
                    'Thống kê · ${data.students} HS · '
                    'ĐTB lớp ${data.average ?? '—'} · '
                    'Cao nhất ${data.highest ?? '—'} · '
                    'Thấp nhất ${data.lowest ?? '—'}',
                    style: theme.textTheme.labelLarge,
                  ),
                  FilledButton.tonalIcon(
                    key: const ValueKey('export-xlsx'),
                    onPressed: exporting ? null : export,
                    icon: exporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Xuất Excel'),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.bar_chart_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thống kê · Báo cáo kết quả',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Dữ liệu tổng hợp từ các điểm chính thức đã duyệt',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      key: const ValueKey('export-xlsx'),
                      onPressed: exporting ? null : export,
                      icon: exporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Xuất Excel'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Metric(
                      'Sĩ số học sinh',
                      '${data.students}',
                      Icons.people_alt_outlined,
                    ),
                    _Metric(
                      'ĐTB lớp',
                      data.average ?? '—',
                      Icons.analytics_outlined,
                    ),
                    _Metric(
                      'Cao nhất',
                      data.highest ?? '—',
                      Icons.arrow_upward_rounded,
                    ),
                    _Metric(
                      'Thấp nhất',
                      data.lowest ?? '—',
                      Icons.arrow_downward_rounded,
                    ),
                    _Metric(
                      'Đạt yêu cầu',
                      '${data.passed}',
                      Icons.check_circle_outline,
                    ),
                    _Metric(
                      'Chưa đạt',
                      '${data.failed}',
                      Icons.cancel_outlined,
                    ),
                  ],
                ),
                if (data.distribution.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(
                    'Phân bố xếp loại:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in data.distribution)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withAlpha(80),
                            ),
                          ),
                          child: Text(
                            '${item.classification}: ${item.students} HS',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
