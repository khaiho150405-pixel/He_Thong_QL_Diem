import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_scaffold.dart';
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

  /// Phiên bản đang áp dụng do backend trả về (chỉ để hiển thị badge).
  String? activeVersion;
  bool activeFlag = false;

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
      activeVersion = active.version;
      activeFlag = active.active;
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;

    return AppScaffold(
      title: 'Chính sách xếp loại',
      currentPath: '/classification-policy',
      showBackButton: true,
      onBack: () => context.go('/'),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 40, color: t.bad),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      loadError!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(onPressed: load, child: const Text('Thử lại')),
                  ],
                ),
              ),
            )
          : Form(
              key: formKey,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      Card(
                        child: Padding(
                          padding: AppSpacing.cardBody,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (activeVersion != null) ...[
                                AppBadge(
                                  activeFlag
                                      ? 'Phiên bản $activeVersion · đang áp dụng'
                                      : 'Phiên bản $activeVersion',
                                  tone: activeFlag
                                      ? AppBadgeTone.info
                                      : AppBadgeTone.neutral,
                                ),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              Text(
                                'Mỗi lần lưu tạo một phiên bản mới. Kết quả đã tính giữ '
                                'snapshot policy cũ để có thể giải thích về sau.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
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
                            RegExp(
                              r'^[A-Za-z0-9._-]{1,20}$',
                            ).hasMatch(value ?? '')
                            ? null
                            : 'Chỉ dùng chữ, số, dấu chấm, gạch ngang hoặc gạch dưới.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: name,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'Tên chính sách',
                          border: OutlineInputBorder(),
                        ),
                        validator: requiredText,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Các mức xếp loại',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: t.heading,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (var index = 0; index < criteria.length; index++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: LayoutBuilder(
                                builder: (context, cardConstraints) {
                                  final isWide =
                                      cardConstraints.maxWidth >= 600;
                                  final codeField = TextFormField(
                                    controller: criteria[index].code,
                                    decoration: const InputDecoration(
                                      labelText: 'Mã xếp loại',
                                      hintText: 'Ví dụ: GIOI',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    validator: (value) =>
                                        RegExp(
                                          r'^[A-Z][A-Z0-9_]{0,19}$',
                                        ).hasMatch(value ?? '')
                                        ? null
                                        : 'Ví dụ: GIOI',
                                  );

                                  final minField = TextFormField(
                                    controller: criteria[index].minimum,
                                    decoration: const InputDecoration(
                                      labelText: 'Điểm tối thiểu',
                                      hintText: '0.0–10.0',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    validator: (value) =>
                                        RegExp(
                                          r'^(?:[0-9]\.[0-9]|10\.0)$',
                                        ).hasMatch(value ?? '')
                                        ? null
                                        : 'Dùng 0.0–10.0',
                                  );

                                  final passChip = FilterChip(
                                    selected: criteria[index].passing,
                                    selectedColor: t.okSoft,
                                    checkmarkColor: t.ok,
                                    side: BorderSide(
                                      color: criteria[index].passing
                                          ? t.okLine
                                          : t.line2,
                                    ),
                                    label: Text(
                                      criteria[index].passing
                                          ? 'Đạt'
                                          : 'Chưa đạt',
                                      style: TextStyle(
                                        color: criteria[index].passing
                                            ? t.ok
                                            : t.ink2,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onSelected: (value) => setState(
                                      () => criteria[index].passing = value,
                                    ),
                                  );

                                  final deleteBtn = IconButton(
                                    tooltip: 'Xóa mức',
                                    onPressed: criteria.length <= 2
                                        ? null
                                        : () => setState(() {
                                            criteria.removeAt(index).dispose();
                                          }),
                                    icon: const Icon(Icons.delete_outline),
                                  );

                                  if (isWide) {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(flex: 3, child: codeField),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(flex: 2, child: minField),
                                        const SizedBox(width: AppSpacing.md),
                                        passChip,
                                        const SizedBox(width: AppSpacing.xs),
                                        deleteBtn,
                                      ],
                                    );
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      codeField,
                                      const SizedBox(height: AppSpacing.sm),
                                      minField,
                                      const SizedBox(height: AppSpacing.sm),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [passChip, deleteBtn],
                                      ),
                                    ],
                                  );
                                },
                              ),
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
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        key: const ValueKey('activate-policy'),
                        onPressed: saving ? null : save,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Kích hoạt phiên bản mới'),
                      ),
                      if (saving) ...[
                        const SizedBox(height: AppSpacing.md),
                        const LinearProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
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
