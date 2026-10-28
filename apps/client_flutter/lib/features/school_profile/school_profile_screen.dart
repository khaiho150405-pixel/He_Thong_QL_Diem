import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_dialog.dart';
import '../../app/widgets/app_scaffold.dart';
import '../academic_catalog/semester_deadlines_repository.dart';
import 'school_profile.dart';

const _maxLogoBytes = 1024 * 1024;

/// Màn "Thông tin trường" (chỉ QTV): sửa tên, liên hệ và logo hiển thị toàn app.
class SchoolProfileScreen extends ConsumerStatefulWidget {
  const SchoolProfileScreen({super.key});

  @override
  ConsumerState<SchoolProfileScreen> createState() =>
      _SchoolProfileScreenState();
}

class _SchoolProfileScreenState extends ConsumerState<SchoolProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  static const _keys = [
    'name',
    'shortName',
    'governingBody',
    'address',
    'phone',
    'email',
    'principal',
  ];
  final _ctrl = {for (final k in _keys) k: TextEditingController()};
  // Trường BE báo sai (details.fields); xóa khi người dùng sửa lại ô đó.
  final _serverInvalid = <String>{};

  SchoolProfileDto? _profile;
  Object? _loadError;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final p = await ref.read(schoolProfileRepositoryProvider).fetch();
      if (!mounted) return;
      setState(() {
        _fill(p);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  void _fill(SchoolProfileDto p) {
    _profile = p;
    _serverInvalid.clear();
    _ctrl['name']!.text = p.name;
    _ctrl['shortName']!.text = p.shortName;
    _ctrl['governingBody']!.text = p.governingBody ?? '';
    _ctrl['address']!.text = p.address ?? '';
    _ctrl['phone']!.text = p.phone ?? '';
    _ctrl['email']!.text = p.email ?? '';
    _ctrl['principal']!.text = p.principal ?? '';
  }

  String _text(String key) => _ctrl[key]!.text.trim();

  // Cùng luật với BE (apps/api/src/modules/school/application/service.ts).
  String? _validate(String key, String? raw) {
    final v = (raw ?? '').trim();
    if (_serverInvalid.contains(key)) return 'Giá trị không hợp lệ';
    const required = {'name': (3, 200), 'shortName': (2, 60)};
    const optional = {
      'governingBody': 200,
      'address': 300,
      'email': 200,
      'principal': 120,
    };
    final req = required[key];
    if (req != null) {
      if (v.isEmpty) return 'Bắt buộc nhập';
      if (v.length < req.$1) return 'Tối thiểu ${req.$1} ký tự';
      if (v.length > req.$2) return 'Tối đa ${req.$2} ký tự';
      return null;
    }
    if (v.length > (optional[key] ?? 11)) {
      return 'Tối đa ${optional[key] ?? 11} ký tự';
    }
    if (key == 'phone' &&
        v.isNotEmpty &&
        !RegExp(r'^[0-9]{10,11}$').hasMatch(v)) {
      return 'Điện thoại gồm 10–11 chữ số';
    }
    if (key == 'email' &&
        v.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'Email không đúng định dạng';
    }
    return null;
  }

  void _toast(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  /// Chạy một lệnh ghi; thành công thì cập nhật form và làm mới sidebar/tiêu đề.
  Future<void> _run(
    Future<SchoolProfileDto> Function() action,
    String success,
  ) async {
    setState(() => _busy = true);
    try {
      final p = await action();
      if (!mounted) return;
      setState(() => _fill(p));
      ref.invalidate(schoolProfileProvider);
      _toast(success);
    } catch (e) {
      if (!mounted) return;
      final fields = apiErrorDetails(e)?['fields'];
      if (apiErrorCode(e) == 'INVALID_SCHOOL_PROFILE' && fields is List) {
        setState(() => _serverInvalid.addAll(fields.map((f) => '$f')));
        _formKey.currentState?.validate();
      }
      _toast(deadlineErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final p = _profile;
    if (p == null || !(_formKey.currentState?.validate() ?? false)) return;
    String? opt(String k) => _text(k).isEmpty ? null : _text(k);
    await _run(
      () => ref
          .read(schoolProfileRepositoryProvider)
          .update(
            UpdateSchoolProfileInput(
              expectedVersion: p.version,
              name: _text('name'),
              shortName: _text('shortName'),
              governingBody: opt('governingBody'),
              address: opt('address'),
              phone: opt('phone'),
              email: opt('email'),
              principal: opt('principal'),
            ),
          ),
      'Đã lưu thông tin trường',
    );
  }

  Future<void> _pickLogo() async {
    final p = _profile;
    if (p == null) return;
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null || !mounted) return;
    final bytes = file.bytes;
    if (bytes == null || bytes.length > _maxLogoBytes) {
      _toast('Logo phải là ảnh PNG hoặc JPEG, tối đa 1 MB');
      return;
    }
    final png = file.name.toLowerCase().endsWith('.png');
    await _run(
      () => ref
          .read(schoolProfileRepositoryProvider)
          .setLogo(
            file: MultipartFile.fromBytes(
              bytes,
              filename: file.name,
              contentType: DioMediaType('image', png ? 'png' : 'jpeg'),
            ),
            expectedVersion: p.version.toInt(),
          ),
      'Đã cập nhật logo',
    );
  }

  Future<void> _removeLogo() async {
    final p = _profile;
    if (p == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const AppDialog(
        title: 'Gỡ logo',
        confirmLabel: 'Gỡ logo',
        danger: true,
        maxWidth: 420,
        child: Text(
          'Gỡ logo của trường? Giao diện sẽ dùng biểu tượng mặc định.',
        ),
      ),
    );
    if (ok != true || !mounted) return;
    await _run(
      () => ref.read(schoolProfileRepositoryProvider).removeLogo(p.version),
      'Đã gỡ logo',
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _formatTime(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso;
    return '${_two(d.hour)}:${_two(d.minute)} ${_two(d.day)}/${_two(d.month)}/${d.year}';
  }

  Widget _field(String key, String label, {String? helper, double? width}) {
    final isRequired = key == 'name' || key == 'shortName';
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: _ctrl[key],
        enabled: !_busy,
        keyboardType: key == 'phone'
            ? TextInputType.phone
            : key == 'email'
            ? TextInputType.emailAddress
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          helperText: helper,
          helperMaxLines: 2,
        ),
        validator: (v) => _validate(key, v),
        onChanged: (_) {
          if (_serverInvalid.remove(key)) _formKey.currentState?.validate();
        },
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
        boxShadow: t.shadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }

  Widget _logoCard(BuildContext context, SchoolProfileDto p) {
    final t = context.tokens;
    final preview = Container(
      width: 88,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.subtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.line),
      ),
      child: SchoolLogoImage(
        profile: p,
        size: 72,
        fallback: Icon(Icons.school_outlined, size: 36, color: t.ink3),
      ),
    );
    return _card(
      context,
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          preview,
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Logo trường',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  p.hasLogo
                      ? 'Hiển thị ở thanh menu và màn đăng nhập.'
                      : 'Chưa có logo. Ảnh PNG hoặc JPEG, tối đa 1 MB.',
                  style: TextStyle(color: t.ink3, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _pickLogo,
                      icon: const Icon(Icons.upload_outlined, size: 18),
                      label: const Text('Tải logo'),
                    ),
                    if (p.hasLogo)
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _removeLogo,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Gỡ logo'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard(BuildContext context, SchoolProfileDto p) {
    final t = context.tokens;
    return _card(
      context,
      child: LayoutBuilder(
        builder: (context, c) {
          final half = c.maxWidth >= 560
              ? (c.maxWidth - AppSpacing.lg) / 2
              : null;
          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.lg,
                  children: [
                    _field('name', 'Tên trường', width: c.maxWidth),
                    _field(
                      'shortName',
                      'Tên ngắn',
                      helper: 'Hiển thị trên thanh menu',
                      width: half ?? c.maxWidth,
                    ),
                    _field(
                      'principal',
                      'Hiệu trưởng',
                      width: half ?? c.maxWidth,
                    ),
                    _field(
                      'governingBody',
                      'Cơ quan chủ quản',
                      width: c.maxWidth,
                    ),
                    _field('address', 'Địa chỉ', width: c.maxWidth),
                    _field('phone', 'Điện thoại', width: half ?? c.maxWidth),
                    _field('email', 'Email', width: half ?? c.maxWidth),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Cập nhật lần cuối: ${_formatTime(p.updatedAt)}',
                      style: TextStyle(color: t.ink3, fontSize: 13),
                    ),
                    FilledButton(
                      onPressed: _busy ? null : _save,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Lưu'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final p = _profile;
    final Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (p == null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError == null
                  ? 'Chưa có thông tin trường.'
                  : 'Không thể tải thông tin trường.',
              style: TextStyle(color: t.bad),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    } else {
      body = SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _logoCard(context, p),
                const SizedBox(height: AppSpacing.lg),
                _formCard(context, p),
              ],
            ),
          ),
        ),
      );
    }
    return AppScaffold(
      title: 'Thông tin trường',
      currentPath: '/admin/school-profile',
      body: body,
    );
  }
}
