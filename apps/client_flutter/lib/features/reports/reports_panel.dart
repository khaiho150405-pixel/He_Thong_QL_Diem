import 'package:api_client_dart/api_client_dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../authentication/session.dart';
import 'repository.dart';

class ReportsPanel extends ConsumerStatefulWidget {
  const ReportsPanel({super.key, required this.gradebookId});

  final num gradebookId;

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
            path == null ? 'Đã hủy lưu báo cáo.' : 'Đã xuất báo cáo Excel.',
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
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<GradebookSummaryDto>(
        future: summary,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LinearProgressIndicator();
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Thống kê và báo cáo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('export-xlsx'),
                    onPressed: exporting ? null : export,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Xuất Excel'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Metric('Học sinh', '${data.students}'),
                  _Metric('Trung bình', data.average ?? '—'),
                  _Metric('Cao nhất', data.highest ?? '—'),
                  _Metric('Thấp nhất', data.lowest ?? '—'),
                  _Metric('Đạt', '${data.passed}'),
                  _Metric('Chưa đạt', '${data.failed}'),
                  for (final item in data.distribution)
                    Chip(
                      label: Text('${item.classification}: ${item.students}'),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 110),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}
