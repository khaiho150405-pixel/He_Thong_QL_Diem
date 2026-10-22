import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_badge.dart';
import '../../app/widgets/app_dialog.dart';
import '../../app/widgets/app_select_field.dart';
import 'semester_deadlines_repository.dart';

String enrollmentStatusLabel(EnrollmentDtoStatusEnum status) {
  return switch (status) {
    EnrollmentDtoStatusEnum.DANG_HOC => 'Đang học',
    EnrollmentDtoStatusEnum.LEN_LOP => 'Lên lớp',
    EnrollmentDtoStatusEnum.LUU_BAN => 'Lưu ban',
    EnrollmentDtoStatusEnum.DA_CHUYEN_LOP => 'Đã chuyển lớp',
    EnrollmentDtoStatusEnum.NGHI_HOC => 'Nghỉ học',
    EnrollmentDtoStatusEnum.TOT_NGHIEP => 'Tốt nghiệp',
  };
}

AppBadgeTone enrollmentStatusTone(EnrollmentDtoStatusEnum status) {
  return switch (status) {
    EnrollmentDtoStatusEnum.DANG_HOC => AppBadgeTone.ok,
    EnrollmentDtoStatusEnum.LEN_LOP => AppBadgeTone.info,
    EnrollmentDtoStatusEnum.LUU_BAN => AppBadgeTone.warn,
    EnrollmentDtoStatusEnum.DA_CHUYEN_LOP => AppBadgeTone.neutral,
    EnrollmentDtoStatusEnum.NGHI_HOC => AppBadgeTone.bad,
    EnrollmentDtoStatusEnum.TOT_NGHIEP => AppBadgeTone.ok,
  };
}

String _formatDate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Hộp thoại Chuyển lớp
class StudentTransferDialog extends StatefulWidget {
  const StudentTransferDialog({
    super.key,
    required this.student,
    required this.api,
    required this.allClasses,
  });

  final Map<String, dynamic> student;
  final ApiClientDart api;
  final List<Map<String, dynamic>> allClasses;

  @override
  State<StudentTransferDialog> createState() => _StudentTransferDialogState();
}

class _StudentTransferDialogState extends State<StudentTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dateController;
  late final TextEditingController _reasonController;

  num? _selectedTargetClassId;
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _eligibleClasses = [];

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: _formatDate(DateTime.now()));
    _reasonController = TextEditingController();

    final currentClassId = widget.student['ma_lop'] as num?;
    final currentClass = widget.allClasses.cast<Map<String, dynamic>?>().firstWhere(
      (c) => c != null && c['ma_lop'] == currentClassId,
      orElse: () => null,
    );

    if (currentClass != null) {
      final currentYearId = currentClass['ma_nam_hoc'];
      final currentGrade = currentClass['khoi'];
      _eligibleClasses = widget.allClasses.where((c) {
        return c['ma_nam_hoc'] == currentYearId &&
            c['khoi'] == currentGrade &&
            c['ma_lop'] != currentClassId;
      }).toList();
    } else {
      _eligibleClasses = widget.allClasses
          .where((c) => c['ma_lop'] != currentClassId)
          .toList();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTargetClassId == null) {
      setState(() => _error = 'Vui lòng chọn lớp chuyển đến');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final studentId = widget.student['ma_hoc_sinh'] as num;
      final idempotencyKey =
          'transfer-$studentId-${DateTime.now().microsecondsSinceEpoch}';

      final res = await widget.api
          .getEnrollmentsApi()
          .studentEnrollmentsTransfer(
            xIdempotencyKey: idempotencyKey,
            id: studentId,
            transferInput: TransferInput(
              targetClassId: _selectedTargetClassId!,
              effectiveDate: _dateController.text.trim(),
              reason: _reasonController.text.trim(),
            ),
          );

      if (mounted) {
        Navigator.of(context).pop<TransferResultDto>(res.data);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = deadlineErrorMessage(e);
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final studentName = widget.student['ho_ten']?.toString() ?? 'Học sinh';

    return AppDialog(
      title: 'Chuyển lớp: $studentName',
      confirmLabel: 'Chuyển lớp',
      confirmEnabled: !_busy && _eligibleClasses.isNotEmpty,
      onConfirm: _submit,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Container(
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
                ),
                const SizedBox(height: 16),
              ],
              if (_eligibleClasses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: t.warnSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: t.warnLine),
                  ),
                  child: Text(
                    'Không có lớp nào khác cùng khối trong năm học này.',
                    style: TextStyle(color: t.warn, fontSize: 13),
                  ),
                )
              else
                AppSelectField<num>(
                  value: _selectedTargetClassId,
                  label: 'Lớp chuyển đến (cùng khối, cùng năm)',
                  items: _eligibleClasses
                      .map(
                        (c) => DropdownMenuItem<num>(
                          value: c['ma_lop'] as num,
                          child: Text(
                            c['ten_lop']?.toString() ??
                                c['label']?.toString() ??
                                'Lớp ${c['ma_lop']}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _selectedTargetClassId = v),
                  validator: (v) => v == null ? 'Vui lòng chọn lớp đích' : null,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Ngày hiệu lực (YYYY-MM-DD)',
                  suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onTap: _busy
                    ? null
                    : () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) {
                          _dateController.text = _formatDate(picked);
                        }
                      },
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nhập ngày hiệu lực' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                enabled: !_busy,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'Lý do chuyển lớp *',
                  hintText: 'Nhập lý do chuyển lớp...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Lý do là bắt buộc';
                  }
                  if (v.trim().length > 500) {
                    return 'Lý do không được quá 500 ký tự';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hộp thoại Cho nghỉ học
class StudentWithdrawDialog extends StatefulWidget {
  const StudentWithdrawDialog({
    super.key,
    required this.student,
    required this.api,
  });

  final Map<String, dynamic> student;
  final ApiClientDart api;

  @override
  State<StudentWithdrawDialog> createState() => _StudentWithdrawDialogState();
}

class _StudentWithdrawDialogState extends State<StudentWithdrawDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dateController;
  late final TextEditingController _reasonController;

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: _formatDate(DateTime.now()));
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final studentId = widget.student['ma_hoc_sinh'] as num;
      final idempotencyKey =
          'withdraw-$studentId-${DateTime.now().microsecondsSinceEpoch}';

      final res = await widget.api
          .getEnrollmentsApi()
          .studentEnrollmentsWithdraw(
            xIdempotencyKey: idempotencyKey,
            id: studentId,
            withdrawInput: WithdrawInput(
              effectiveDate: _dateController.text.trim(),
              reason: _reasonController.text.trim(),
            ),
          );

      if (mounted) {
        Navigator.of(context).pop<EnrollmentResultDto>(res.data);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = deadlineErrorMessage(e);
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final studentName = widget.student['ho_ten']?.toString() ?? 'Học sinh';

    return AppDialog(
      title: 'Cho nghỉ học: $studentName',
      confirmLabel: 'Xác nhận nghỉ học',
      danger: true,
      confirmEnabled: !_busy,
      onConfirm: _submit,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Container(
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
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Ngày hiệu lực (YYYY-MM-DD)',
                  suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onTap: _busy
                    ? null
                    : () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) {
                          _dateController.text = _formatDate(picked);
                        }
                      },
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nhập ngày hiệu lực' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                enabled: !_busy,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'Lý do nghỉ học *',
                  hintText: 'Nhập lý do nghỉ học...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Lý do là bắt buộc';
                  }
                  if (v.trim().length > 500) {
                    return 'Lý do không được quá 500 ký tự';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hộp thoại Học lại
class StudentReenrollDialog extends StatefulWidget {
  const StudentReenrollDialog({
    super.key,
    required this.student,
    required this.api,
    required this.allClasses,
  });

  final Map<String, dynamic> student;
  final ApiClientDart api;
  final List<Map<String, dynamic>> allClasses;

  @override
  State<StudentReenrollDialog> createState() => _StudentReenrollDialogState();
}

class _StudentReenrollDialogState extends State<StudentReenrollDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dateController;
  late final TextEditingController _reasonController;

  num? _selectedClassId;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: _formatDate(DateTime.now()));
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      setState(() => _error = 'Vui lòng chọn lớp học lại');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final studentId = widget.student['ma_hoc_sinh'] as num;
      final idempotencyKey =
          'reenroll-$studentId-${DateTime.now().microsecondsSinceEpoch}';

      final res = await widget.api
          .getEnrollmentsApi()
          .studentEnrollmentsReenroll(
            xIdempotencyKey: idempotencyKey,
            id: studentId,
            reenrollInput: ReenrollInput(
              classId: _selectedClassId!,
              effectiveDate: _dateController.text.trim(),
              reason: _reasonController.text.trim(),
            ),
          );

      if (mounted) {
        Navigator.of(context).pop<EnrollmentResultDto>(res.data);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = deadlineErrorMessage(e);
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final studentName = widget.student['ho_ten']?.toString() ?? 'Học sinh';

    return AppDialog(
      title: 'Học lại: $studentName',
      confirmLabel: 'Xác nhận học lại',
      confirmEnabled: !_busy && widget.allClasses.isNotEmpty,
      onConfirm: _submit,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Container(
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
                ),
                const SizedBox(height: 16),
              ],
              AppSelectField<num>(
                value: _selectedClassId,
                label: 'Lớp vào học lại',
                items: widget.allClasses
                    .map(
                      (c) => DropdownMenuItem<num>(
                        value: c['ma_lop'] as num,
                        child: Text(
                          c['ten_lop']?.toString() ??
                              c['label']?.toString() ??
                              'Lớp ${c['ma_lop']}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _selectedClassId = v),
                validator: (v) => v == null ? 'Vui lòng chọn lớp học lại' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Ngày hiệu lực (YYYY-MM-DD)',
                  suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onTap: _busy
                    ? null
                    : () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) {
                          _dateController.text = _formatDate(picked);
                        }
                      },
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nhập ngày hiệu lực' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                enabled: !_busy,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'Lý do học lại *',
                  hintText: 'Nhập lý do học lại...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Lý do là bắt buộc';
                  }
                  if (v.trim().length > 500) {
                    return 'Lý do không được quá 500 ký tự';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hộp thoại Lịch sử xếp lớp
class StudentEnrollmentHistoryDialog extends StatefulWidget {
  const StudentEnrollmentHistoryDialog({
    super.key,
    required this.student,
    required this.api,
  });

  final Map<String, dynamic> student;
  final ApiClientDart api;

  @override
  State<StudentEnrollmentHistoryDialog> createState() =>
      _StudentEnrollmentHistoryDialogState();
}

class _StudentEnrollmentHistoryDialogState
    extends State<StudentEnrollmentHistoryDialog> {
  late Future<List<EnrollmentDto>> _enrollmentsFuture;

  @override
  void initState() {
    super.initState();
    final studentId = widget.student['ma_hoc_sinh'] as num;
    _enrollmentsFuture = widget.api
        .getEnrollmentsApi()
        .studentEnrollmentsList(id: studentId)
        .then((res) => res.data?.items ?? <EnrollmentDto>[]);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final studentName = widget.student['ho_ten']?.toString() ?? 'Học sinh';

    return AppDialog(
      title: 'Lịch sử xếp lớp: $studentName',
      cancelLabel: 'Đóng',
      confirmLabel: 'Đóng',
      maxWidth: 720,
      showFooter: true,
      onConfirm: () => Navigator.of(context).pop(),
      child: FutureBuilder<List<EnrollmentDto>>(
        future: _enrollmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(22),
              child: Text(
                'Lỗi: ${deadlineErrorMessage(snapshot.error!)}',
                style: TextStyle(color: t.bad),
              ),
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Chưa có lịch sử ghi danh.')),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(3),
                3: FlexColumnWidth(2.5),
                4: FlexColumnWidth(3),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: t.subtle,
                    border: Border(bottom: BorderSide(color: t.line)),
                  ),
                  children: [
                    _th(t, 'Năm học'),
                    _th(t, 'Lớp (Khối)'),
                    _th(t, 'Thời gian'),
                    _th(t, 'Trạng thái'),
                    _th(t, 'Lý do / Người tạo'),
                  ],
                ),
                for (final item in items)
                  TableRow(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: t.line)),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 6,
                        ),
                        child: Text(
                          item.yearName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: t.ink,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 6,
                        ),
                        child: Text(
                          '${item.className} (Khối ${item.grade})',
                          style: TextStyle(fontSize: 13, color: t.ink2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 6,
                        ),
                        child: Text(
                          '${item.fromDate} → ${item.toDate ?? 'nay'}',
                          style: TextStyle(fontSize: 12, color: t.ink2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 6,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AppBadge(
                            enrollmentStatusLabel(item.status),
                            tone: enrollmentStatusTone(item.status),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 6,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.reason ?? '—',
                              style: TextStyle(fontSize: 12, color: t.ink),
                            ),
                            if (item.actorName != null &&
                                item.actorName!.isNotEmpty)
                              Text(
                                item.actorName!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: t.ink3,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
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

  Widget _th(AppTokens t, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: t.ink3,
        ),
      ),
    );
  }
}

/// Thông báo sau khi chuyển lớp thành công nếu có affectedGradebooks
Future<void> showAffectedGradebooksNotice(
  BuildContext context, {
  required List<AffectedGradebookDto> affectedGradebooks,
}) async {
  if (affectedGradebooks.isEmpty) return;

  await showAppDialog<void>(
    context: context,
    builder: (ctx) {
      final t = ctx.tokens;
      return AppDialog(
        title: 'Bảng điểm bị ảnh hưởng',
        cancelLabel: 'Đã hiểu',
        confirmLabel: 'Đã hiểu',
        maxWidth: 520,
        onConfirm: () => Navigator.of(ctx).pop(),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Học sinh được chuyển sang lớp mới. Các bảng điểm bị ảnh hưởng:',
                style: TextStyle(fontSize: 14, color: t.ink),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.subtle,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: t.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final g in affectedGradebooks)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.book_outlined, size: 16, color: t.priLink),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${g.subjectName} · ${g.termName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: t.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.priSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: t.priLine),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: t.priLink),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nhắc: Cột đã chốt: dùng chức năng Học sinh vào lớp sau khi chốt; cột còn mở: giáo viên có thể đặt Miễn.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: t.priLink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
