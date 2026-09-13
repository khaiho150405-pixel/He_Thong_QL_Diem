import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../authentication/session.dart';

class StudentResultsScreen extends ConsumerStatefulWidget {
  const StudentResultsScreen({super.key});

  @override
  ConsumerState<StudentResultsScreen> createState() =>
      _StudentResultsScreenState();
}

class _StudentResultsScreenState extends ConsumerState<StudentResultsScreen> {
  late Future<List<StudentSubjectResultDto>> data;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    data = ref
        .read(apiProvider)
        .getStudentResultsApi()
        .studentResultsList()
        .then((response) => response.data!.items);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Điểm của tôi'),
      leading: IconButton(
        onPressed: () => context.go('/'),
        icon: const Icon(Icons.arrow_back),
      ),
      actions: [
        IconButton(
          tooltip: 'Tải lại',
          onPressed: () => setState(reload),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<StudentSubjectResultDto>>(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(errorMessage(snapshot.error!)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => setState(reload),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return const Center(child: Text('Bạn chưa có điểm đã duyệt.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ExpansionTile(
                initiallyExpanded: index == 0,
                leading: const Icon(Icons.school_outlined),
                title: Text(item.subjectName),
                subtitle: Text(item.termName),
                trailing: item.finalScore == null
                    ? const Chip(label: Text('Chưa tổng kết'))
                    : Chip(
                        label: Text(
                          '${item.finalScore} · ${item.classification ?? '—'}',
                        ),
                      ),
                children: [
                  for (final component in item.components)
                    ListTile(
                      title: Text(component.componentName),
                      subtitle: Text('Hệ số ${component.coefficient}'),
                      trailing: Text(
                        component.value,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  if (item.calculatedAt != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tính lúc ${item.calculatedAt!.toLocal()}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}
