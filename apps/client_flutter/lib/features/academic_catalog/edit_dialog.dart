import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_dialog.dart';
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

  final Set<num> _existingTeacherIds = {};
  final List<Json> _existingAssignments = [];

  @override
  void initState() {
    super.initState();
    for (final f in fields) {
      values[f.key] =
          widget.row?[f.key] ??
          (f.kind == 'boolean'
              ? !['da_cong_bo', 'danh_gia_dat'].contains(f.key)
              : f.kind == 'coefficient'
              ? 'TX'
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

        // Preload teachers to prevent duplicate teacher creation
        if (widget.spec.key == 'teachers') {
          final tRows = <Json>[];
          String? cursor;
          do {
            final page = await ref
                .read(catalogRepositoryProvider)
                .list('teachers', cursor: cursor);
            tRows.addAll(page.items);
            cursor = page.nextCursor;
          } while (cursor != null);
          _existingTeacherIds.clear();
          for (final t in tRows) {
            final id = t['ma_giao_vien'];
            if (id is num) _existingTeacherIds.add(id);
          }
        }

        // Preload assignments to prevent duplicate assignment creation
        if (widget.spec.key == 'assignments') {
          final aRows = <Json>[];
          String? cursor;
          do {
            final page = await ref
                .read(catalogRepositoryProvider)
                .list('assignments', cursor: cursor);
            aRows.addAll(page.items);
            cursor = page.nextCursor;
          } while (cursor != null);
          _existingAssignments.clear();
          _existingAssignments.addAll(aRows);
        }
      }
    } catch (e) {
      error = errorMessage(e);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _createTeacherAccount() async {
    final username = TextEditingController();
    final password = TextEditingController();
    final accountForm = GlobalKey<FormState>();
    final submitted = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: 'Tạo tài khoản giáo viên',
        confirmLabel: 'Tạo và liên kết',
        onConfirm: () {
          if (accountForm.currentState!.validate()) {
            Navigator.pop(dialogContext, true);
          }
        },
        child: Form(
          key: accountForm,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: username,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại đăng nhập',
                ),
                validator: (value) =>
                    value == null || !RegExp(r'^0[0-9]{9}$').hasMatch(value)
                    ? 'Dùng số điện thoại 10 chữ số, bắt đầu bằng 0'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu ban đầu',
                  helperText: 'Ít nhất 12 ký tự',
                ),
                validator: (value) => value == null || value.length < 12
                    ? 'Mật khẩu cần ít nhất 12 ký tự'
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
    if (submitted != true || !mounted) {
      username.dispose();
      password.dispose();
      return;
    }
    final selectedUsername = username.text.trim();
    final selectedPassword = password.text;
    username.dispose();
    password.dispose();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(catalogRepositoryProvider).save('accounts', {
        'username': selectedUsername,
        'password': selectedPassword,
        'role': 'GIAO_VIEN',
      });
      final accounts = <Json>[];
      String? cursor;
      do {
        final page = await ref
            .read(catalogRepositoryProvider)
            .list('accounts', cursor: cursor);
        accounts.addAll(page.items);
        cursor = page.nextCursor;
      } while (cursor != null);
      final created = accounts.firstWhere(
        (row) => row['username'] == selectedUsername,
      );
      if (!mounted) return;
      setState(() {
        choices['accounts'] = accounts;
        values['ma_giao_vien'] = created['id'];
      });
    } catch (e) {
      if (mounted) setState(() => error = errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
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
      if (f.reference != null ||
          ['boolean', 'role', 'coefficient'].contains(f.kind)) {
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

    // Duplicate check for assignments (ma_lop, ma_mon, ma_hoc_ky)
    if (widget.spec.key == 'assignments') {
      final currentId = widget.row?['ma_phan_cong'];
      final isDup = _existingAssignments.any((a) {
        if (currentId != null && a['ma_phan_cong'] == currentId) return false;
        return a['ma_lop'] == input['ma_lop'] &&
            a['ma_mon'] == input['ma_mon'] &&
            a['ma_hoc_ky'] == input['ma_hoc_ky'];
      });
      if (isDup) {
        setState(() {
          error =
              'Lớp học, môn học và học kỳ này đã được phân công giáo viên. Vui lòng chọn sửa phân công có sẵn thay vì tạo trùng lặp.';
        });
        return;
      }
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
      final t = context.tokens;
      return Container(
        decoration: BoxDecoration(
          color: t.subtle,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: t.line),
        ),
        child: SwitchListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          title: Text(
            f.label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: t.ink,
            ),
          ),
          value: values[f.key] as bool? ?? false,
          onChanged: locked ? null : (v) => setState(() => values[f.key] = v),
        ),
      );
    }
    if (f.kind == 'coefficient') {
      return DropdownButtonFormField<String>(
        initialValue: values[f.key]?.toString() ?? 'TX',
        isExpanded: true,
        decoration: InputDecoration(labelText: f.label),
        items: const [
          DropdownMenuItem(value: 'TX', child: Text('Thường xuyên')),
          DropdownMenuItem(value: 'GK', child: Text('Giữa kỳ')),
          DropdownMenuItem(value: 'CK', child: Text('Cuối kỳ')),
        ],
        onChanged: locked ? null : (v) => setState(() => values[f.key] = v),
      );
    }
    if (f.kind == 'role') {
      return DropdownButtonFormField<String>(
        initialValue: values[f.key] as String?,
        decoration: InputDecoration(
          labelText: f.label,
          prefixIcon: const Icon(Icons.security_rounded, size: 20),
        ),
        items: ['QUAN_TRI_VIEN', 'GIAO_VIEN', 'HOC_SINH']
            .map(
              (r) => DropdownMenuItem(
                value: r,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: roleAppBadge(r),
                ),
              ),
            )
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

        // Exclude accounts that already have a teacher profile when creating a new teacher
        if (widget.spec.key == 'teachers' && widget.row == null) {
          rows = rows
              .where((r) => !_existingTeacherIds.contains(r['id']))
              .toList();
        }
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
      if (f.optional) {
        items.insert(
          0,
          const DropdownMenuItem<num>(
            value: null,
            child: Text('Không liên kết'),
          ),
        );
      }
      if (selected != null && !rows.any((r) => r[target.id] == selected)) {
        items.add(
          DropdownMenuItem(
            value: selected as num,
            child: const Text('Bản ghi hiện tại'),
          ),
        );
      }
      final dropdown = DropdownButtonFormField<num>(
        key: ValueKey(selected),
        initialValue: selected as num?,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: '${f.label}${f.optional ? ' (không bắt buộc)' : ''}',
          helperText: widget.spec.key == 'teachers' && widget.row != null
              ? 'Liên kết tài khoản không thể đổi sau khi tạo hồ sơ.'
              : null,
          prefixIcon: const Icon(Icons.link_rounded, size: 20),
        ),
        items: items,
        onChanged: locked ? null : (v) => setState(() => values[f.key] = v),
        validator: (v) =>
            v == null && !f.optional ? 'Chọn ${f.label.toLowerCase()}' : null,
      );
      if (widget.spec.key != 'teachers' ||
          f.key != 'ma_giao_vien' ||
          widget.row != null) {
        return dropdown;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          dropdown,
          const SizedBox(height: 6),
          if (rows.isEmpty)
            Text(
              'Không còn tài khoản giáo viên chưa liên kết.',
              style: TextStyle(fontSize: 12, color: context.tokens.ink3),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: busy ? null : _createTeacherAccount,
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              label: const Text('Tạo tài khoản giáo viên mới'),
            ),
          ),
        ],
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
            ? 'Định dạng: YYYY-MM-DD'
            : f.kind == 'decimal'
            ? 'Ví dụ: 1.00'
            : f.optional
            ? 'Không bắt buộc'
            : f.kind == 'password' && widget.row != null
            ? 'Để trống nếu muốn giữ nguyên mật khẩu cũ'
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
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final isNew = widget.row == null;

    return AppDialog(
      title:
          '${isNew
              ? 'Thêm mới'
              : editable
              ? 'Chỉnh sửa'
              : 'Thông tin'} ${widget.spec.label.toLowerCase()}',
      cancelLabel: 'Đóng',
      confirmLabel: busy ? 'Đang lưu…' : 'Lưu',
      confirmEnabled: !(busy || loading),
      showFooter: editable,
      onCancel: busy ? () {} : () => Navigator.pop(context),
      onConfirm: save,
      child: loading
          ? SizedBox(
              height: 120,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Đang tải danh mục liên kết…',
                      style: TextStyle(color: t.ink2),
                    ),
                  ],
                ),
              ),
            )
          : Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isNew && widget.row != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        rowLabel(widget.row!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: t.ink3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (widget.spec.key == 'semester-weights')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Hệ số này thay thế hệ số mặc định của thành phần '
                        'trong học kỳ đã chọn. Nhập từ 0.01 đến 9.99 '
                        '(ví dụ 2.00). Khi môn học đã có bảng điểm chốt '
                        'trong học kỳ, hệ số không thể sửa hoặc xóa.',
                        style: TextStyle(color: t.ink2),
                      ),
                    ),
                  if (error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: t.badSoft,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: t.badLine),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: t.bad,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error!,
                              style: TextStyle(color: t.bad, fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: busy ? null : loadChoices,
                            child: const Text('Tải lại'),
                          ),
                        ],
                      ),
                    ),
                  for (final f in fields.where(
                    (f) => editable || f.reference == null,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: field(f),
                    ),
                  if (!editable)
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Đóng'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Nhãn vai trò dạng [AppBadge]: quản trị viên đỏ, giáo viên xanh, học sinh
/// trung tính (theo bảng tài khoản của prototype).
AppBadge roleAppBadge(String role) => AppBadge(
  roleLabel(role),
  tone: switch (role) {
    'QUAN_TRI_VIEN' => AppBadgeTone.bad,
    'GIAO_VIEN' => AppBadgeTone.info,
    _ => AppBadgeTone.neutral,
  },
  dot: false,
);
