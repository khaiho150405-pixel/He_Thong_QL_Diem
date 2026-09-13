import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../authentication/session.dart';
import 'repository.dart';

class FinalResultsPanel extends ConsumerStatefulWidget {
  const FinalResultsPanel({
    super.key,
    required this.gradebookId,
    required this.gradebookVersion,
  });

  final num gradebookId;
  final num gradebookVersion;

  @override
  ConsumerState<FinalResultsPanel> createState() => _FinalResultsPanelState();
}

class _FinalResultsPanelState extends ConsumerState<FinalResultsPanel> {
  late Future<List<FinalResultDto>> results;
  bool busy = false;

  bool get teacher => ref.read(sessionProvider)?.role.value == 'GIAO_VIEN';

  @override
  void initState() {
    super.initState();
    results = ref.read(finalResultsRepositoryProvider).list(widget.gradebookId);
  }

  void reload() => setState(() {
    busy = false;
    results = ref.read(finalResultsRepositoryProvider).list(widget.gradebookId);
  });

  Future<String?> askReason() async {
    var reason = '';
    String? error;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tính kết quả tổng kết'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chỉ điểm đã duyệt được tính. Hệ thống lưu bộ hệ số, '
                  'phiên bản chính sách và lịch sử của lần tính này.',
                ),
                const SizedBox(height: 16),
                TextField(
                  autofocus: true,
                  maxLength: 500,
                  maxLines: 3,
                  onChanged: (value) => reason = value,
                  decoration: InputDecoration(
                    labelText: 'Lý do tính hoặc tính lại',
                    hintText: 'Ví dụ: Tổng kết học kỳ I',
                    errorText: error,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final normalized = reason.trim();
                if (normalized.isEmpty) {
                  setDialogState(() => error = 'Cần nhập lý do.');
                  return;
                }
                Navigator.pop(dialogContext, normalized);
              },
              child: const Text('Tính kết quả'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> calculate() async {
    final reason = await askReason();
    if (reason == null || !mounted) return;
    setState(() => busy = true);
    try {
      final summary = await ref
          .read(finalResultsRepositoryProvider)
          .calculate(
            gradebookId: widget.gradebookId,
            expectedVersion: widget.gradebookVersion,
            reason: reason,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã tính ${summary.calculatedStudents} học sinh; '
            'bỏ qua ${summary.skippedStudents}. '
            'Policy ${summary.policyVersion}.',
          ),
        ),
      );
      reload();
    } catch (error) {
      if (!mounted) return;
      setState(() => busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_message(error))));
    }
  }

  String _message(Object error) {
    if (error is DioException && error.response?.statusCode == 409) {
      return 'Không thể tính: bảng chưa chốt, phiên bản đã đổi, còn điểm chờ '
          'đối chiếu hoặc cấu hình chưa hợp lệ.';
    }
    return 'Không tải được kết quả tổng kết. Vui lòng thử lại.';
  }

  Future<void> showHistory(FinalResultDto item) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _FinalResultHistoryDialog(
        gradebookId: widget.gradebookId,
        result: item,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      initiallyExpanded: true,
      leading: const Icon(Icons.calculate_outlined),
      title: const Text('Kết quả tổng kết'),
      subtitle: const Text('UC14–UC15 · điểm đã duyệt và policy có phiên bản'),
      trailing: teacher
          ? FilledButton.icon(
              key: const ValueKey('calculate-final-results'),
              onPressed: busy ? null : calculate,
              icon: const Icon(Icons.functions),
              label: const Text('Tính kết quả'),
            )
          : null,
      children: [
        if (busy) const LinearProgressIndicator(),
        SizedBox(
          height: 260,
          child: FutureBuilder<List<FinalResultDto>>(
            future: results,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_message(snapshot.error!)),
                      TextButton(
                        onPressed: reload,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }
              final items = snapshot.data!;
              if (items.isEmpty) {
                return const Center(
                  child: Text('Chưa tính kết quả cho bảng điểm này.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    title: Text(item.studentName),
                    subtitle: Text(
                      'Hệ số ${item.weightVersion} · Policy ${item.policyVersion}',
                    ),
                    leading: CircleAvatar(child: Text(item.finalScore)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(label: Text(item.classification)),
                        IconButton(
                          tooltip: 'Lịch sử tính',
                          onPressed: () => showHistory(item),
                          icon: const Icon(Icons.history),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _FinalResultHistoryDialog extends ConsumerWidget {
  const _FinalResultHistoryDialog({
    required this.gradebookId,
    required this.result,
  });

  final num gradebookId;
  final FinalResultDto result;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AlertDialog(
    title: Text('Lịch sử tổng kết · ${result.studentName}'),
    content: SizedBox(
      width: 620,
      height: 400,
      child: FutureBuilder<List<CalculationHistoryDto>>(
        future: ref
            .read(finalResultsRepositoryProvider)
            .history(gradebookId: gradebookId, resultId: result.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Không tải được lịch sử.'));
          }
          final items = snapshot.data!;
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(
                  '${item.oldScore ?? 'Chưa có'} → ${item.newScore} · '
                  '${item.newClassification}',
                ),
                subtitle: Text(
                  '${item.reason}\nNgười tính #${item.calculatorId} · '
                  '${item.calculatedAt.toLocal()}',
                ),
              );
            },
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
    ],
  );
}
