import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';

const int kMaxTemplateName = 100;
const int kMaxTemplateDescription = 500;

/// Cùng giới hạn với backend: tên 1..100 ký tự, mô tả tối đa 500.
String? templateNameError(String value) {
  final name = value.trim();
  if (name.isEmpty) return 'Nhập tên mẫu.';
  if (name.length > kMaxTemplateName) {
    return 'Tên mẫu tối đa $kMaxTemplateName ký tự.';
  }
  return null;
}

String? templateDescriptionError(String value) =>
    value.length > kMaxTemplateDescription
    ? 'Mô tả tối đa $kMaxTemplateDescription ký tự.'
    : null;

/// Ô tên và mô tả của mẫu. Lỗi hiện sau khi người dùng đã chạm vào ô.
class TemplateDefinitionFields extends StatelessWidget {
  const TemplateDefinitionFields({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.onChanged,
    this.enabled = true,
    this.nameKey = const ValueKey('template-name'),
    this.descriptionKey = const ValueKey('template-description'),
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final VoidCallback onChanged;
  final bool enabled;
  final Key nameKey;
  final Key descriptionKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: nameKey,
          controller: nameController,
          enabled: enabled,
          maxLength: kMaxTemplateName,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            labelText: 'Tên mẫu',
            hintText: 'Ví dụ: Sổ điểm THCS 4 cột thường xuyên',
          ),
          validator: (value) => templateNameError(value ?? ''),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          key: descriptionKey,
          controller: descriptionController,
          enabled: enabled,
          maxLength: kMaxTemplateDescription,
          minLines: 2,
          maxLines: 4,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            labelText: 'Mô tả (không bắt buộc)',
            hintText: 'Loại tờ, trường hoặc ghi chú khi dùng mẫu',
          ),
          validator: (value) => templateDescriptionError(value ?? ''),
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
