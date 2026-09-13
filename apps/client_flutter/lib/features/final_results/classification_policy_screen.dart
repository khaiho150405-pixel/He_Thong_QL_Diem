import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../authentication/session.dart';

class ClassificationPolicyScreen extends ConsumerStatefulWidget {
  const ClassificationPolicyScreen({super.key});

  @override
  ConsumerState<ClassificationPolicyScreen> createState() =>
      _ClassificationPolicyScreenState();
}

class _ClassificationPolicyScreenState
    extends ConsumerState<ClassificationPolicyScreen> {
  final formKey = GlobalKey<FormState>();
  final version = TextEditingController();
  final name = TextEditingController();
  final criteria = <_CriterionDraft>[];
  bool loading = true;
  bool saving = false;
  String? loadError;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      loadError = null;
    });
    try {
      final active =
          (await ref
                  .read(apiProvider)
                  .getClassificationPoliciesApi()
                  .classificationPoliciesActive())
              .data!;
      for (final row in criteria) {
        row.dispose();
      }
      criteria
        ..clear()
        ..addAll(active.criteria.map(_CriterionDraft.fromDto));
      version.text = '';
      name.text = active.name;
      if (mounted) setState(() => loading = false);
    } catch (error) {
      if (mounted) {
        setState(() {
          loading = false;
          loadError = errorMessage(error);
        });
      }
    }
  }

  @override
  void dispose() {
    version.dispose();
    name.dispose();
    for (final row in criteria) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (!criteria.any((item) => item.passing) ||
        !criteria.any((item) => !item.passing) ||
        !criteria.any((item) => item.minimum.text.trim() == '0.0')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cần ngưỡng 0.0, ít nhất một mức đạt và một mức chưa đạt.',
          ),
        ),
      );
      return;
    }
    setState(() => saving = true);
    try {
      await ref
          .read(apiProvider)
          .getClassificationPoliciesApi()
          .classificationPoliciesActivate(
            xIdempotencyKey:
                'flutter-policy-${DateTime.now().microsecondsSinceEpoch}',
            activateClassificationPolicyInput:
                ActivateClassificationPolicyInput(
                  version: version.text.trim(),
                  name: name.text.trim(),
                  roundingDigits: 1,
                  criteria: [
                    for (var index = 0; index < criteria.length; index++)
                      ClassificationCriterionDto(
                        code: criteria[index].code.text.trim(),
                        minimum: criteria[index].minimum.text.trim(),
                        passing: criteria[index].passing,
                        order: index + 1,
                      ),
                  ],
                ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã kích hoạt phiên bản chính sách mới.')),
      );
      await load();
    } catch (error) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage(error))));
    }
  }

  String? requiredText(String? value) =>
      (value?.trim().isEmpty ?? true) ? 'Không được để trống.' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Chính sách xếp loại'),
      leading: IconButton(
        onPressed: () => context.go('/'),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : loadError != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loadError!),
                FilledButton(onPressed: load, child: const Text('Thử lại')),
              ],
            ),
          )
        : Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Mỗi lần lưu tạo một phiên bản mới. Kết quả đã tính giữ '
                      'snapshot policy cũ để có thể giải thích về sau.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('policy-version'),
                  controller: version,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: 'Phiên bản mới',
                    hintText: 'Ví dụ: SCHOOL-2026-01',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      RegExp(r'^[A-Za-z0-9._-]{1,20}$').hasMatch(value ?? '')
                      ? null
                      : 'Chỉ dùng chữ, số, dấu chấm, gạch ngang hoặc gạch dưới.',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: name,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Tên chính sách',
                    border: OutlineInputBorder(),
                  ),
                  validator: requiredText,
                ),
                const SizedBox(height: 12),
                Text(
                  'Các mức xếp loại',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < criteria.length; index++)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 190,
                            child: TextFormField(
                              controller: criteria[index].code,
                              decoration: const InputDecoration(
                                labelText: 'Mã xếp loại',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  RegExp(
                                    r'^[A-Z][A-Z0-9_]{0,19}$',
                                  ).hasMatch(value ?? '')
                                  ? null
                                  : 'Ví dụ: GIOI',
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              controller: criteria[index].minimum,
                              decoration: const InputDecoration(
                                labelText: 'Điểm tối thiểu',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  RegExp(
                                    r'^(?:[0-9]\.[0-9]|10\.0)$',
                                  ).hasMatch(value ?? '')
                                  ? null
                                  : 'Dùng 0.0–10.0',
                            ),
                          ),
                          FilterChip(
                            selected: criteria[index].passing,
                            label: Text(
                              criteria[index].passing ? 'Đạt' : 'Chưa đạt',
                            ),
                            onSelected: (value) =>
                                setState(() => criteria[index].passing = value),
                          ),
                          IconButton(
                            tooltip: 'Xóa mức',
                            onPressed: criteria.length <= 2
                                ? null
                                : () => setState(() {
                                    criteria.removeAt(index).dispose();
                                  }),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: criteria.length >= 20
                      ? null
                      : () => setState(() {
                          criteria.add(_CriterionDraft('', '0.0', false));
                        }),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm mức'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const ValueKey('activate-policy'),
                  onPressed: saving ? null : save,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Kích hoạt phiên bản mới'),
                ),
                if (saving) const LinearProgressIndicator(),
              ],
            ),
          ),
  );
}

class _CriterionDraft {
  _CriterionDraft(String code, String minimum, this.passing)
    : code = TextEditingController(text: code),
      minimum = TextEditingController(text: minimum);

  factory _CriterionDraft.fromDto(ClassificationCriterionDto dto) =>
      _CriterionDraft(dto.code, dto.minimum, dto.passing);

  final TextEditingController code;
  final TextEditingController minimum;
  bool passing;

  void dispose() {
    code.dispose();
    minimum.dispose();
  }
}
