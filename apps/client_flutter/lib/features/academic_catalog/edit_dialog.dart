import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../authentication/session.dart';
import 'repository.dart';
import 'fields.dart';

class EditDialog extends ConsumerStatefulWidget {
  const EditDialog({super.key, required this.spec, this.row});
  final ResourceSpec spec;
  final Json? row;
  @override
  ConsumerState<EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends ConsumerState<EditDialog> {
  final form = GlobalKey<FormState>();
  final controllers = <String, TextEditingController>{};
  final values = <String, dynamic>{};
  final choices = <String, List<Json>>{};
  bool loading = true, busy = false;
  String? error;
  bool get editable => ref.read(sessionProvider)?.role.value == 'QUAN_TRI_VIEN';
  List<FormFieldSpec> get fields => widget.spec.fields
      .where(
        (f) =>
            !(widget.spec.key == 'accounts' &&
                ((widget.row != null && f.key == 'username') ||
                    (widget.row == null && f.key == 'active'))),
      )
      .toList();
  @override
  void initState() {
    super.initState();
    for (final f in fields) {
      values[f.key] =
          widget.row?[f.key] ??
          (f.kind == 'boolean'
              ? true
              : f.kind == 'role'
              ? 'HOC_SINH'
              : null);
      controllers[f.key] = TextEditingController(
        text: widget.row?[f.key]?.toString() ?? '',
      );
    }
    loadChoices();
  }

  Future<void> loadChoices() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (editable) {
        for (final reference
            in fields.map((f) => f.reference).whereType<String>().toSet()) {
          final rows = <Json>[];
          String? cursor;
          do {
            final page = await ref
                .read(catalogRepositoryProvider)
                .list(reference, cursor: cursor);
            rows.addAll(page.items);
            cursor = page.nextCursor;
          } while (cursor != null);
          choices[reference] = rows;
        }
      }
    } catch (e) {
      error = errorMessage(e);
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final input = <String, dynamic>{};
    for (final f in fields) {
      if (f.reference != null || ['boolean', 'role'].contains(f.kind)) {
        input[f.key] = values[f.key];
        continue;
      }
      final text = controllers[f.key]!.text;
      if (f.kind == 'password' && widget.row != null && text.isEmpty) continue;
      input[f.key] = text.isEmpty && f.optional
          ? null
          : f.kind == 'int'
          ? int.parse(text)
          : text;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(catalogRepositoryProvider)
          .save(
            widget.spec.key,
            input,
            id: widget.row?[widget.spec.id] as num?,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(FormFieldSpec f) {
    final locked =
        !editable ||
        busy ||
        (widget.spec.key == 'teachers' &&
            widget.row != null &&
            f.key == 'ma_giao_vien');
    if (f.kind == 'boolean') {
      return SwitchListTile(
        title: Text(f.label),
        value: values[f.key] as bool? ?? false,
        onChanged: locked ? null : (v) => setState(() => values[f.key] = v),
      );
    }
    if (f.kind == 'role') {
      return DropdownButtonFormField<String>(
        initialValue: values[f.key] as String?,
        decoration: InputDecoration(labelText: f.label),
        items: ['QUAN_TRI_VIEN', 'GIAO_VIEN', 'HOC_SINH']
            .map((r) => DropdownMenuItem(value: r, child: Text(roleLabel(r))))
            .toList(),
        onChanged: locked ? null : (v) => values[f.key] = v,
      );
    }
    if (f.reference != null && editable) {
      final target = resources.firstWhere((r) => r.key == f.reference);
      var rows = choices[f.reference] ?? [];
      if (f.reference == 'accounts') {
        rows = rows
            .where(
              (r) =>
                  r['role'] ==
                  (widget.spec.key == 'teachers' ? 'GIAO_VIEN' : 'HOC_SINH'),
            )
            .toList();
      }
      final selected = values[f.key];
      final items = rows
          .map(
            (r) => DropdownMenuItem<num>(
              value: r[target.id] as num,
              child: Text(rowLabel(r), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList();
      if (selected != null && !rows.any((r) => r[target.id] == selected)) {
        items.add(
          DropdownMenuItem(
            value: selected as num,
            child: const Text('Bản ghi hiện tại'),
          ),
        );
      }
      return DropdownButtonFormField<num>(
        initialValue: selected as num?,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: '${f.label}${f.optional ? ' (không bắt buộc)' : ''}',
        ),
        items: items,
        onChanged: locked ? null : (v) => values[f.key] = v,
        validator: (v) =>
            v == null && !f.optional ? 'Chọn ${f.label.toLowerCase()}' : null,
      );
    }
    return TextFormField(
      controller: controllers[f.key],
      enabled: !locked,
      obscureText: f.kind == 'password',
      keyboardType: f.kind == 'int' ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: f.label,
        helperText: f.kind == 'date'
            ? 'YYYY-MM-DD'
            : f.kind == 'decimal'
            ? 'Ví dụ: 1.00'
            : f.optional
            ? 'Không bắt buộc'
            : f.kind == 'password' && widget.row != null
            ? 'Để trống để giữ mật khẩu hiện tại'
            : null,
      ),
      validator: (value) {
        if (!editable) return null;
        if (value == null || value.isEmpty) {
          return f.optional || (f.kind == 'password' && widget.row != null)
              ? null
              : 'Nhập ${f.label.toLowerCase()}';
        }
        if (f.kind == 'int' && int.tryParse(value) == null) {
          return 'Nhập số nguyên';
        }
        if (f.kind == 'password' && value.length < 12) {
          return 'Ít nhất 12 ký tự';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      '${widget.row == null
          ? 'Thêm'
          : editable
          ? 'Sửa'
          : 'Xem'} ${widget.spec.label.toLowerCase()}',
    ),
    content: SizedBox(
      width: 520,
      child: loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    for (final f in fields)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: field(f),
                      ),
                  ],
                ),
              ),
            ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
      if (error != null)
        TextButton(
          onPressed: busy ? null : loadChoices,
          child: const Text('Tải lại'),
        ),
      if (editable)
        FilledButton(
          onPressed: busy || loading ? null : save,
          child: Text(busy ? 'Đang lưu…' : 'Lưu'),
        ),
    ],
  );
}
