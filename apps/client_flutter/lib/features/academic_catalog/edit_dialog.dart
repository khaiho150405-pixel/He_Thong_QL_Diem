import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_date_field.dart';
import '../../app/widgets/app_dialog.dart';
import '../../app/widgets/app_select_field.dart';
import '../authentication/session.dart';
import 'academic_year_scope.dart';
import 'fields.dart';
import 'repository.dart';
import 'semester_deadlines_repository.dart';

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

  int? _selectedStartYear;
  int? _selectedEndYear;

  @override
  void initState() {
    super.initState();
    for (final f in fields) {
      if (widget.spec.key == 'students' &&
          f.key == 'ma_lop' &&
          widget.row != null) {
        values[f.key] = widget.row?['currentClassId'] ?? widget.row?['ma_lop'];
      } else {
        values[f.key] =
            widget.row?[f.key] ??
            (f.kind == 'boolean'
                ? !['da_cong_bo', 'danh_gia_dat'].contains(f.key)
                : f.kind == 'coefficient'
                ? 'TX'
                : f.kind == 'role'
                ? 'HOC_SINH'
                : null);
      }
      var initialText = widget.row?[f.key]?.toString() ?? '';
      if (f.kind == 'date' && initialText.isNotEmpty) {
        final parsed = AppDateField.parseIsoDate(initialText);
        if (parsed != null) {
          initialText = AppDateField.formatIso(parsed);
        }
      }
      controllers[f.key] = TextEditingController(text: initialText);
    }

    if (widget.spec.key == 'years') {
      final tenText = widget.row?['ten']?.toString() ?? '';
      final match = RegExp(r'^(\d{4})\s*[-–]\s*(\d{4})$').firstMatch(tenText);
      if (match != null) {
        _selectedStartYear = int.tryParse(match.group(1)!);
        _selectedEndYear = int.tryParse(match.group(2)!);
      }
      if (_selectedStartYear == null) {
        final sDate = AppDateField.parseIsoDate(
          widget.row?['ngay_bat_dau']?.toString(),
        );
        _selectedStartYear = sDate?.year ?? DateTime.now().year;
      }
      if (_selectedEndYear == null) {
        final eDate = AppDateField.parseIsoDate(
          widget.row?['ngay_ket_thuc']?.toString(),
        );
        _selectedEndYear = eDate?.year ?? (_selectedStartYear! + 1);
      }
      controllers['ten']?.text = '$_selectedStartYear-$_selectedEndYear';
      if (widget.row == null) {
        controllers['ngay_bat_dau']?.text = AppDateField.formatIso(
          DateTime(_selectedStartYear!, 9, 5),
        );
        controllers['ngay_ket_thuc']?.text = AppDateField.formatIso(
          DateTime(_selectedEndYear!, 5, 31),
        );
      }
    } else if (widget.spec.key == 'semesters' && widget.row == null) {
      if ((controllers['ten']?.text ?? '').isEmpty) {
        controllers['ten']?.text = 'Học kỳ 1';
        controllers['thu_tu']?.text = '1';
      }
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

        var viewingYear = ref.read(viewingYearProvider);
        if (viewingYear == null) {
          final current = await ref.read(currentYearProvider.future);
          if (current != null && ref.read(viewingYearProvider) == null) {
            ref.read(viewingYearProvider.notifier).setYear(current);
          }
          viewingYear = ref.read(viewingYearProvider);
        }
        final viewingYearId = viewingYear?.id;

        // Prioritize items of the viewing year in choices
        if (viewingYearId != null) {
          if (choices['years'] != null) {
            choices['years']!.sort((a, b) {
              final aInYear = a['ma_nam_hoc'] == viewingYearId;
              final bInYear = b['ma_nam_hoc'] == viewingYearId;
              if (aInYear && !bInYear) return -1;
              if (!aInYear && bInYear) return 1;
              return 0;
            });
          }
          if (choices['semesters'] != null) {
            choices['semesters']!.sort((a, b) {
              final aInYear = a['ma_nam_hoc'] == viewingYearId;
              final bInYear = b['ma_nam_hoc'] == viewingYearId;
              if (aInYear && !bInYear) return -1;
              if (!aInYear && bInYear) return 1;
              return 0;
            });
          }
          if (choices['classes'] != null) {
            choices['classes']!.sort((a, b) {
              final aInYear = a['ma_nam_hoc'] == viewingYearId;
              final bInYear = b['ma_nam_hoc'] == viewingYearId;
              if (aInYear && !bInYear) return -1;
              if (!aInYear && bInYear) return 1;
              return 0;
            });
          }
        }

        // Pre-select for new record according to viewing year
        if (widget.row == null && viewingYearId != null) {
          if (values['ma_nam_hoc'] == null &&
              choices['years']?.any((y) => y['ma_nam_hoc'] == viewingYearId) ==
                  true) {
            values['ma_nam_hoc'] = viewingYearId;
          }
          if (values['ma_hoc_ky'] == null && choices['semesters'] != null) {
            final sem = choices['semesters']!.cast<Json?>().firstWhere(
              (s) => s?['ma_nam_hoc'] == viewingYearId,
              orElse: () => null,
            );
            if (sem != null) values['ma_hoc_ky'] = sem['ma_hoc_ky'];
          }
          if (values['ma_lop'] == null && choices['classes'] != null) {
            final cls = choices['classes']!.cast<Json?>().firstWhere(
              (c) => c?['ma_nam_hoc'] == viewingYearId,
              orElse: () => null,
            );
            if (cls != null) values['ma_lop'] = cls['ma_lop'];
          }
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

  Future<bool> _confirmSwitchCurrentYear() async {
    ViewingYear? currentYear;
    try {
      currentYear = await ref.read(currentYearProvider.future);
    } catch (_) {
      currentYear = null;
    }

    final currentId = currentYear?.id;
    final thisId = widget.row?['ma_nam_hoc'] as num?;
    if (currentYear == null || (thisId != null && currentId == thisId)) {
      return true;
    }

    final yearAName = currentYear.name;
    final textName = controllers['ten']?.text.trim();
    final yearBName = textName != null && textName.isNotEmpty
        ? textName
        : (widget.row?['ten']?.toString() ?? 'Năm mới');

    YearPendingSummaryDto? summary;
    try {
      summary = await ref
          .read(catalogRepositoryProvider)
          .getYearPendingSummary(currentId!);
    } catch (_) {
      // Lỗi tải pending-summary thì vẫn hiện hộp xác nhận không kèm số liệu
      summary = null;
    }

    final warnings = <String>[];
    if (summary != null) {
      if (summary.openGradebooks > 0) {
        warnings.add('${summary.openGradebooks} bảng điểm chưa chốt');
      }
      if (summary.pendingRecognitionTickets > 0) {
        warnings.add(
          '${summary.pendingRecognitionTickets} phiếu chờ đối chiếu',
        );
      }
      if (summary.unpublishedSemesters > 0) {
        warnings.add('${summary.unpublishedSemesters} học kỳ chưa công bố');
      }
    }

    final warningText = warnings.isNotEmpty
        ? '$yearAName còn ${warnings.join(', ')}.'
        : null;

    if (!mounted) return false;

    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) {
        final t = ctx.tokens;
        return AppDialog(
          title: 'Chuyển năm hiện hành từ $yearAName sang $yearBName?',
          confirmLabel: 'Chuyển năm',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (warningText != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: t.badSoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: t.badLine),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: t.bad),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warningText,
                          style: TextStyle(
                            color: t.bad,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Bạn có chắc chắn muốn chuyển năm học hiện hành sang $yearBName?',
                style: TextStyle(color: t.ink),
              ),
            ],
          ),
        );
      },
    );

    return confirmed == true;
  }

  List<PublishIssueDto> _extractIssues(Object e) {
    if (e is! DioException) return const [];
    final data = e.response?.data;
    if (data is! Map<String, dynamic>) return const [];
    final details = data['details'];
    if (details is! Map) return const [];
    final rawList = details['issues'];
    if (rawList is! List) return const [];
    final result = <PublishIssueDto>[];
    for (final item in rawList) {
      if (item is Map) {
        try {
          result.add(PublishIssueDto.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {}
      }
    }
    return result;
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

      if (widget.spec.key == 'years') {
        ref.invalidate(academicYearsProvider);
        ref.invalidate(currentYearProvider);
        if (input['hien_hanh'] == true) {
          final id = widget.row?[widget.spec.id] as num?;
          final name = input['ten']?.toString() ?? '';
          if (id != null) {
            ref
                .read(viewingYearProvider.notifier)
                .setYear(ViewingYear(id: id, name: name, isCurrent: true));
          } else {
            final curr = await ref.read(currentYearProvider.future);
            if (curr != null) {
              ref.read(viewingYearProvider.notifier).setYear(curr);
            }
          }
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        if (apiErrorCode(e) == 'TERM_RESULTS_INCOMPLETE') {
          final rawIssues = _extractIssues(e);
          final semesterId =
              widget.row?['ma_hoc_ky'] as num? ??
              widget.row?[widget.spec.id] as num?;
          if (semesterId != null) {
            await showAppDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => PublishReadinessDialog(
                semesterId: semesterId,
                initialIssues: rawIssues.isNotEmpty ? rawIssues : null,
              ),
            );
            return;
          }
        }
        setState(() => error = deadlineErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(FormFieldSpec f) {
    final isStudentEdit = widget.spec.key == 'students' && widget.row != null;
    final isStudentClassOrStatus =
        isStudentEdit && (f.key == 'ma_lop' || f.key == 'dang_theo_hoc');
    final locked =
        !editable ||
        busy ||
        isStudentClassOrStatus ||
        (widget.spec.key == 'teachers' &&
            widget.row != null &&
            f.key == 'ma_giao_vien');
    if (f.kind == 'boolean') {
      final t = context.tokens;
      final isYearHienHanh = widget.spec.key == 'years' && f.key == 'hien_hanh';
      final isSemesterDaCongBo =
          widget.spec.key == 'semesters' && f.key == 'da_cong_bo';
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
          subtitle: isStudentEdit && f.key == 'dang_theo_hoc'
              ? Text(
                  'Chuyển lớp, nghỉ học, học lại: dùng menu thao tác trên danh mục học sinh',
                  style: TextStyle(
                    fontSize: 12,
                    color: t.ink3,
                  ),
                )
              : null,
          value: values[f.key] as bool? ?? false,
          onChanged: locked
              ? null
              : (v) async {
                  if (isYearHienHanh && v == true) {
                    final shouldProceed = await _confirmSwitchCurrentYear();
                    if (shouldProceed && mounted) {
                      setState(() => values[f.key] = true);
                    }
                  } else if (isSemesterDaCongBo && v == true) {
                    final semesterId =
                        widget.row?['ma_hoc_ky'] as num? ??
                        widget.row?[widget.spec.id] as num?;
                    if (semesterId != null) {
                      final shouldProceed = await showAppDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) =>
                            PublishReadinessDialog(semesterId: semesterId),
                      );
                      if (shouldProceed == true && mounted) {
                        setState(() => values[f.key] = true);
                      }
                    } else {
                      setState(() => values[f.key] = true);
                    }
                  } else {
                    setState(() => values[f.key] = v);
                  }
                },
        ),
      );
    }
    if (f.kind == 'coefficient') {
      return AppSelectField<String>(
        value: values[f.key]?.toString() ?? 'TX',
        label: f.label,
        searchable: false,
        items: const [
          DropdownMenuItem(value: 'TX', child: Text('Thường xuyên')),
          DropdownMenuItem(value: 'GK', child: Text('Giữa kỳ')),
          DropdownMenuItem(value: 'CK', child: Text('Cuối kỳ')),
        ],
        onChanged: locked ? null : (v) => setState(() => values[f.key] = v),
      );
    }
    if (f.kind == 'role') {
      return AppSelectField<String>(
        value: values[f.key] as String?,
        label: f.label,
        searchable: false,
        prefixIcon: const Icon(Icons.security_rounded, size: 20),
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
        final fallbackLabel = (widget.spec.key == 'students' &&
                widget.row?['currentClassName'] != null &&
                widget.row!['currentClassName'].toString().isNotEmpty)
            ? widget.row!['currentClassName'].toString()
            : 'Bản ghi hiện tại';
        items.add(
          DropdownMenuItem(
            value: selected as num,
            child: Text(fallbackLabel),
          ),
        );
      }
      final dropdown = AppSelectField<num>(
        value: selected as num?,
        label: '${f.label}${f.optional ? ' (không bắt buộc)' : ''}',
        helperText: widget.spec.key == 'teachers' && widget.row != null
            ? 'Liên kết tài khoản không thể đổi sau khi tạo hồ sơ.'
            : (isStudentEdit && f.key == 'ma_lop'
                ? 'Chuyển lớp, nghỉ học, học lại: dùng menu thao tác trên danh mục học sinh'
                : null),
        prefixIcon: const Icon(Icons.link_rounded, size: 20),
        items: items,
        enabled: !locked,
        onChanged: locked
            ? null
            : (v) => setState(() {
                values[f.key] = v;
                if (widget.spec.key == 'semesters' &&
                    f.key == 'ma_nam_hoc' &&
                    v != null) {
                  final yearRows = choices['years'];
                  final yRow = yearRows?.firstWhere(
                    (r) => r['ma_nam_hoc'] == v,
                    orElse: () => <String, dynamic>{},
                  );
                  if (yRow != null && yRow.isNotEmpty) {
                    final yStart = AppDateField.parseIsoDate(
                      yRow['ngay_bat_dau']?.toString(),
                    );
                    final yEnd = AppDateField.parseIsoDate(
                      yRow['ngay_ket_thuc']?.toString(),
                    );
                    final curSemStart = AppDateField.parseIsoDate(
                      controllers['ngay_bat_dau']?.text,
                    );
                    final curSemEnd = AppDateField.parseIsoDate(
                      controllers['ngay_ket_thuc']?.text,
                    );
                    if (yStart != null &&
                        (curSemStart == null ||
                            curSemStart.isBefore(yStart) ||
                            (yEnd != null && curSemStart.isAfter(yEnd)))) {
                      controllers['ngay_bat_dau']?.text =
                          AppDateField.formatIso(yStart);
                    }
                    if (yEnd != null &&
                        (curSemEnd == null ||
                            curSemEnd.isAfter(yEnd) ||
                            (yStart != null && curSemEnd.isBefore(yStart)))) {
                      controllers['ngay_ket_thuc']?.text =
                          AppDateField.formatIso(yEnd);
                    }
                  }
                }
              }),
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
    if (widget.spec.key == 'years' && f.key == 'ten') {
      final t = context.tokens;
      final currentYear = DateTime.now().year;
      final startYears = List.generate(31, (i) => 2020 + i);
      final currentStart = _selectedStartYear ?? currentYear;
      final endYears = List.generate(6, (i) => currentStart + 1 + i);
      final currentEnd = _selectedEndYear ?? (currentStart + 1);

      return Container(
        decoration: BoxDecoration(
          color: t.subtle,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: t.line),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 18, color: t.priLink),
                const SizedBox(width: 8),
                Text(
                  'Chọn năm học: $currentStart–$currentEnd',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: t.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppSelectField<int>(
                    value: currentStart,
                    label: 'Năm bắt đầu',
                    searchable: false,
                    enabled: editable && !locked,
                    items: startYears
                        .map(
                          (y) => DropdownMenuItem(
                            value: y,
                            child: Text('$y'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _selectedStartYear = val;
                        if (_selectedEndYear == null ||
                            _selectedEndYear! <= val) {
                          _selectedEndYear = val + 1;
                        }
                        controllers['ten']?.text =
                            '$_selectedStartYear-$_selectedEndYear';

                        // Ràng buộc ngày bắt đầu trong năm chữ số trước (val)
                        final curStart = AppDateField.parseIsoDate(
                          controllers['ngay_bat_dau']?.text,
                        );
                        if (curStart == null || curStart.year != val) {
                          controllers['ngay_bat_dau']?.text =
                              AppDateField.formatIso(DateTime(val, 9, 5));
                        }
                        // Ràng buộc ngày kết thúc trong năm chữ số sau (_selectedEndYear)
                        final curEnd = AppDateField.parseIsoDate(
                          controllers['ngay_ket_thuc']?.text,
                        );
                        if (curEnd == null ||
                            curEnd.year != _selectedEndYear) {
                          controllers['ngay_ket_thuc']?.text =
                              AppDateField.formatIso(
                                DateTime(_selectedEndYear!, 5, 31),
                              );
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppSelectField<int>(
                    value: currentEnd,
                    label: 'Năm kết thúc',
                    searchable: false,
                    enabled: editable && !locked,
                    items: endYears
                        .map(
                          (y) => DropdownMenuItem(
                            value: y,
                            child: Text('$y'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _selectedEndYear = val;
                        controllers['ten']?.text =
                            '$_selectedStartYear-$_selectedEndYear';

                        // Ràng buộc ngày kết thúc trong năm chữ số sau (val)
                        final curEnd = AppDateField.parseIsoDate(
                          controllers['ngay_ket_thuc']?.text,
                        );
                        if (curEnd == null || curEnd.year != val) {
                          controllers['ngay_ket_thuc']?.text =
                              AppDateField.formatIso(DateTime(val, 5, 31));
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    if (widget.spec.key == 'semesters' && f.key == 'ten') {
      final currentTen = controllers['ten']?.text.trim() ?? '';
      const standardSemesters = ['Học kỳ 1', 'Học kỳ 2', 'Học kỳ hè'];
      final items = <DropdownMenuItem<String>>[
        const DropdownMenuItem(value: 'Học kỳ 1', child: Text('Học kỳ 1')),
        const DropdownMenuItem(value: 'Học kỳ 2', child: Text('Học kỳ 2')),
        const DropdownMenuItem(value: 'Học kỳ hè', child: Text('Học kỳ hè')),
      ];
      if (currentTen.isNotEmpty && !standardSemesters.contains(currentTen)) {
        items.insert(
          0,
          DropdownMenuItem(value: currentTen, child: Text(currentTen)),
        );
      }
      return AppSelectField<String>(
        value: currentTen.isNotEmpty ? currentTen : 'Học kỳ 1',
        label: f.label,
        searchable: false,
        enabled: editable && !locked,
        items: items,
        onChanged: (val) {
          if (val == null) return;
          setState(() {
            controllers['ten']?.text = val;
            if (val == 'Học kỳ 1') {
              controllers['thu_tu']?.text = '1';
            } else if (val == 'Học kỳ 2') {
              controllers['thu_tu']?.text = '2';
            } else if (val == 'Học kỳ hè') {
              controllers['thu_tu']?.text = '3';
            }
          });
        },
      );
    }
    if (widget.spec.key == 'semesters' && f.key == 'thu_tu') {
      return TextFormField(
        controller: controllers['thu_tu'],
        enabled: !locked,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          labelText: 'Thứ tự học kỳ (1, 2 hoặc 3)',
          helperText: '1: Học kỳ 1 · 2: Học kỳ 2 · 3: Học kỳ hè',
        ),
        validator: (value) {
          if (!editable) return null;
          if (value == null || value.trim().isEmpty) {
            return 'Nhập thứ tự học kỳ (1–3)';
          }
          final n = int.tryParse(value.trim());
          if (n == null || n < 1 || n > 3) {
            return 'Thứ tự học kỳ chỉ nhận 1, 2 hoặc 3';
          }
          return null;
        },
        onChanged: (val) {
          final n = int.tryParse(val.trim());
          if (n == 1) {
            controllers['ten']?.text = 'Học kỳ 1';
          } else if (n == 2) {
            controllers['ten']?.text = 'Học kỳ 2';
          } else if (n == 3) {
            controllers['ten']?.text = 'Học kỳ hè';
          }
        },
      );
    }
    if (f.kind == 'date') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      DateTime? firstDate;
      DateTime? lastDate;
      DateTime? initialDateWhenEmpty;
      FormFieldValidator<String>? crossValidator;

      if (widget.spec.key == 'students' && f.key == 'ngay_sinh') {
        firstDate = DateTime(1990, 1, 1);
        lastDate = today;
        initialDateWhenEmpty = DateTime(now.year - 16, 1, 1);
      } else if (widget.spec.key == 'years') {
        final startY = _selectedStartYear ?? DateTime.now().year;
        final endY = _selectedEndYear ?? (startY + 1);
        if (f.key == 'ngay_bat_dau') {
          firstDate = DateTime(startY, 1, 1);
          lastDate = DateTime(startY, 12, 31);
          initialDateWhenEmpty = DateTime(startY, 9, 5);
          crossValidator = (value) {
            if (!editable) return null;
            final d = AppDateField.parseIsoDate(value);
            if (d == null) return 'Chọn ngày bắt đầu';
            if (d.year != startY) {
              return 'Ngày bắt đầu phải là 1 ngày trong năm $startY';
            }
            return null;
          };
        } else if (f.key == 'ngay_ket_thuc') {
          firstDate = DateTime(endY, 1, 1);
          lastDate = DateTime(endY, 12, 31);
          initialDateWhenEmpty = DateTime(endY, 5, 31);
          crossValidator = (value) {
            if (!editable) return null;
            final s = AppDateField.parseIsoDate(
              controllers['ngay_bat_dau']?.text,
            );
            final e = AppDateField.parseIsoDate(value);
            if (e == null) return 'Chọn ngày kết thúc';
            if (s != null && !e.isAfter(s)) {
              return 'Ngày kết thúc phải sau ngày bắt đầu';
            }
            if (e.year != endY) {
              return 'Ngày kết thúc phải là 1 ngày trong năm $endY';
            }
            return null;
          };
        }
      } else if (widget.spec.key == 'semesters') {
        final selectedYearId = values['ma_nam_hoc'];
        final yearRows = choices['years'];
        Json? yearRow;
        if (selectedYearId != null && yearRows != null) {
          for (final r in yearRows) {
            if (r['ma_nam_hoc'] == selectedYearId) {
              yearRow = r;
              break;
            }
          }
        }
        final yearStart = AppDateField.parseIsoDate(
          yearRow?['ngay_bat_dau']?.toString(),
        );
        final yearEnd = AppDateField.parseIsoDate(
          yearRow?['ngay_ket_thuc']?.toString(),
        );
        final semStart = AppDateField.parseIsoDate(
          controllers['ngay_bat_dau']?.text,
        );
        final semEnd = AppDateField.parseIsoDate(
          controllers['ngay_ket_thuc']?.text,
        );

        if (f.key == 'ngay_bat_dau') {
          firstDate = yearStart ?? DateTime(2000, 1, 1);
          lastDate = semEnd ?? yearEnd ?? DateTime(2100, 12, 31);
          initialDateWhenEmpty = yearStart ?? today;
          crossValidator = (value) {
            if (!editable) return null;
            final s = AppDateField.parseIsoDate(value);
            if (s == null) return 'Chọn ngày bắt đầu học kỳ';
            if (yearStart != null && s.isBefore(yearStart)) {
              return 'Không được trước ngày bắt đầu năm học (${AppDateField.formatDisplay(yearStart)})';
            }
            if (yearEnd != null && s.isAfter(yearEnd)) {
              return 'Không được sau ngày kết thúc năm học (${AppDateField.formatDisplay(yearEnd)})';
            }
            final e = AppDateField.parseIsoDate(
              controllers['ngay_ket_thuc']?.text,
            );
            if (e != null && !s.isBefore(e)) {
              return 'Ngày bắt đầu phải trước ngày kết thúc';
            }
            return null;
          };
        } else if (f.key == 'ngay_ket_thuc') {
          firstDate = semStart != null
              ? semStart.add(const Duration(days: 1))
              : (yearStart ?? DateTime(2000, 1, 1));
          lastDate = yearEnd ?? DateTime(2100, 12, 31);
          initialDateWhenEmpty = semStart != null
              ? DateTime(semStart.year, semStart.month + 4, semStart.day)
              : (yearEnd ?? today);
          crossValidator = (value) {
            if (!editable) return null;
            final e = AppDateField.parseIsoDate(value);
            if (e == null) return 'Chọn ngày kết thúc học kỳ';
            if (yearEnd != null && e.isAfter(yearEnd)) {
              return 'Không được sau ngày kết thúc năm học (${AppDateField.formatDisplay(yearEnd)})';
            }
            if (yearStart != null && e.isBefore(yearStart)) {
              return 'Không được trước ngày bắt đầu năm học (${AppDateField.formatDisplay(yearStart)})';
            }
            final s = AppDateField.parseIsoDate(
              controllers['ngay_bat_dau']?.text,
            );
            if (s != null && !e.isAfter(s)) {
              return 'Ngày kết thúc phải sau ngày bắt đầu';
            }
            return null;
          };
        }
      } else if (widget.spec.key == 'assignments' &&
          f.key == 'ngay_phan_cong') {
        firstDate = DateTime(2000, 1, 1);
        lastDate = DateTime(2100, 12, 31);
        initialDateWhenEmpty = today;
      } else {
        firstDate = DateTime(1900, 1, 1);
        lastDate = DateTime(2100, 12, 31);
        initialDateWhenEmpty = today;
      }

      return AppDateField(
        label: f.label,
        value: controllers[f.key]?.text,
        enabled: editable && !locked,
        optional: f.optional,
        firstDate: firstDate,
        lastDate: lastDate,
        initialDateWhenEmpty: initialDateWhenEmpty,
        validator: crossValidator,
        onChanged: (isoDate) {
          setState(() {
            controllers[f.key]?.text = isoDate ?? '';
          });
        },
      );
    }
    return TextFormField(
      controller: controllers[f.key],
      enabled: !locked,
      obscureText: f.kind == 'password',
      keyboardType: f.kind == 'int' ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: f.label,
        helperText: f.kind == 'decimal'
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

String publishIssueDescription(PublishIssueDtoCodeEnum code) {
  switch (code) {
    case PublishIssueDtoCodeEnum.GRADEBOOK_MISSING:
      return 'Chưa có bảng điểm — dùng Khởi tạo bảng điểm ở màn Lịch nhập điểm học kỳ';
    case PublishIssueDtoCodeEnum.GRADEBOOK_NOT_LOCKED:
      return 'Bảng điểm chưa chốt (còn cột chưa hết hạn hoặc chưa có lịch)';
    case PublishIssueDtoCodeEnum.RECOGNITION_PENDING:
      return 'Còn phiếu nhận dạng chưa duyệt';
    case PublishIssueDtoCodeEnum.STUDENT_NOT_IN_GRADEBOOK:
      return 'Có học sinh chưa có trong bảng điểm — mở bảng điểm để xử lý';
    case PublishIssueDtoCodeEnum.RESULTS_MISSING:
      return 'Giáo viên chưa tính tổng kết đủ';
    case PublishIssueDtoCodeEnum.COLUMNS_WITHOUT_DEADLINE:
      return 'Có cột chưa có lịch nhập';
    case PublishIssueDtoCodeEnum.RESULTS_OUTDATED:
      return 'Đã điều chỉnh điểm, cần tính lại tổng kết';
    case PublishIssueDtoCodeEnum.ADJUSTMENT_PENDING:
      return 'Còn phiếu điều chỉnh điểm chờ duyệt';
  }
}

String publishIssueGroupTitle(PublishIssueDtoCodeEnum code) {
  switch (code) {
    case PublishIssueDtoCodeEnum.GRADEBOOK_MISSING:
      return 'Chưa có bảng điểm';
    case PublishIssueDtoCodeEnum.GRADEBOOK_NOT_LOCKED:
      return 'Bảng điểm chưa chốt';
    case PublishIssueDtoCodeEnum.RECOGNITION_PENDING:
      return 'Phiếu nhận dạng chưa duyệt';
    case PublishIssueDtoCodeEnum.STUDENT_NOT_IN_GRADEBOOK:
      return 'Học sinh chưa có trong bảng điểm';
    case PublishIssueDtoCodeEnum.RESULTS_MISSING:
      return 'Chưa tính tổng kết đủ';
    case PublishIssueDtoCodeEnum.COLUMNS_WITHOUT_DEADLINE:
      return 'Cột chưa có lịch nhập (Cảnh báo)';
    case PublishIssueDtoCodeEnum.RESULTS_OUTDATED:
      return 'Chưa tính lại tổng kết sau điều chỉnh';
    case PublishIssueDtoCodeEnum.ADJUSTMENT_PENDING:
      return 'Phiếu điều chỉnh chờ duyệt';
  }
}

class PublishReadinessDialog extends ConsumerStatefulWidget {
  const PublishReadinessDialog({
    super.key,
    required this.semesterId,
    this.initialIssues,
  });

  final num semesterId;
  final List<PublishIssueDto>? initialIssues;

  @override
  ConsumerState<PublishReadinessDialog> createState() =>
      _PublishReadinessDialogState();
}

class _PublishReadinessDialogState
    extends ConsumerState<PublishReadinessDialog> {
  bool _loading = false;
  String? _error;
  bool _ready = false;
  List<PublishIssueDto> _issues = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialIssues != null) {
      _issues = widget.initialIssues!;
      _ready = false;
    } else {
      _checkReadiness();
    }
  }

  Future<void> _checkReadiness() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref
          .read(semesterDeadlinesRepositoryProvider)
          .publishReadiness(widget.semesterId);
      if (mounted) {
        setState(() {
          _ready = res.ready;
          _issues = res.issues;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = deadlineErrorMessage(e);
          _loading = false;
        });
      }
    }
  }

  Widget _buildIssueGroup(
    BuildContext context,
    PublishIssueDtoCodeEnum code,
    List<PublishIssueDto> groupIssues,
  ) {
    final t = context.tokens;
    final isWarning = code == PublishIssueDtoCodeEnum.COLUMNS_WITHOUT_DEADLINE;
    final toneColor = isWarning ? t.warn : t.bad;
    final toneBg = isWarning ? t.warnSoft : t.badSoft;
    final toneLine = isWarning ? t.warnLine : t.badLine;

    return Container(
      decoration: BoxDecoration(
        color: toneBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: toneLine),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isWarning
                    ? Icons.warning_amber_rounded
                    : Icons.error_outline_rounded,
                size: 18,
                color: toneColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  publishIssueGroupTitle(code),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: toneColor,
                  ),
                ),
              ),
              AppBadge(
                '${groupIssues.length}',
                tone: isWarning ? AppBadgeTone.warn : AppBadgeTone.bad,
                dot: false,
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final issue in groupIssues)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: t.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${issue.className} – ${issue.subjectName}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: t.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          publishIssueDescription(issue.code),
                          style: TextStyle(color: t.ink2, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (issue.code == PublishIssueDtoCodeEnum.ADJUSTMENT_PENDING) ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                      key: ValueKey('open-adjustments-${issue.gradebookId ?? "all"}'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        context.push('/adjustments');
                      },
                      child: const Text(
                        'Duyệt điều chỉnh điểm',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ] else if (issue.gradebookId != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                      key: ValueKey('open-gradebook-${issue.gradebookId}'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        context.push('/gradebooks/${issue.gradebookId}');
                      },
                      child: const Text(
                        'Mở bảng điểm',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final grouped = <PublishIssueDtoCodeEnum, List<PublishIssueDto>>{};
    for (final issue in _issues) {
      grouped.putIfAbsent(issue.code, () => []).add(issue);
    }

    return AppDialog(
      title: 'Kiểm tra trước khi công bố',
      maxWidth: 620,
      confirmLabel: 'Xác nhận công bố',
      cancelLabel: 'Đóng',
      confirmEnabled: _ready && !_loading,
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _ready
                      ? 'Học kỳ đủ điều kiện công bố xếp loại.'
                      : 'Học kỳ chưa đủ điều kiện công bố xếp loại. Vui lòng xử lý các vấn đề bên dưới.',
                  style: TextStyle(
                    color: _ready ? t.ok : t.bad,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: const ValueKey('publish-readiness-retry'),
                onPressed: _loading ? null : _checkReadiness,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  'Kiểm tra lại',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.badSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: t.badLine),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: t.bad, fontSize: 13),
              ),
            )
          else if (_issues.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Không có vấn đề nào được phát hiện.',
                  style: TextStyle(color: t.ink2),
                ),
              ),
            )
          else ...[
            const SizedBox(height: 16),
            for (final entry in grouped.entries) ...[
              _buildIssueGroup(context, entry.key, entry.value),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}
