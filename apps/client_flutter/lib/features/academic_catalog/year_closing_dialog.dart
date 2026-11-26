import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/app_dialog.dart';
import '../authentication/session.dart';
import 'repository.dart';

String yearClosingIssueText(YearClosingIssueDto issue) {
  final count = issue.count.toInt();
  return switch (issue.code) {
    'YEAR_IS_CURRENT' =>
      'Đây đang là năm học hiện hành. Hãy chuyển năm hiện hành sang năm khác trước.',
    'TERM_NOT_PUBLISHED' => '${issue.label} chưa công bố kết quả.',
    'GRADEBOOK_OPEN' => '$count bảng điểm chưa khóa.',
    'RECOGNITION_PENDING' =>
      '$count phiếu nhận dạng đang xử lý hoặc chờ đối chiếu.',
    'ADJUSTMENT_PENDING' => '$count đơn điều chỉnh đang chờ duyệt.',
    'STUDENTS_NOT_PROMOTED' =>
      'Lớp ${issue.label} còn $count học sinh chưa được xếp lên lớp, lưu ban, tốt nghiệp hoặc nghỉ học.',
    'YEAR_NOT_ENDED' => 'Năm học chưa đến ngày kết thúc.',
    _ => '${issue.label}: ${issue.code}',
  };
}

String _eventText(YearClosingEventDto event) {
  final action = event.action == 'DONG' ? 'Đóng' : 'Mở lại';
  final time = DateTime.tryParse(event.at)?.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  final when = time == null
      ? event.at
      : '${two(time.day)}/${two(time.month)}/${time.year} ${two(time.hour)}:${two(time.minute)}';
  return '$action lúc $when bởi ${event.actor}: ${event.reason}';
}

class YearClosingDialog extends StatefulWidget {
  const YearClosingDialog({
    super.key,
    required this.repository,
    required this.yearId,
    required this.yearName,
  });

  final CatalogRepository repository;
  final num yearId;
  final String yearName;

  @override
  State<YearClosingDialog> createState() => _YearClosingDialogState();
}

class _YearClosingDialogState extends State<YearClosingDialog> {
  final _reason = TextEditingController();
  YearClosingDto? _status;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final status = await widget.repository.yearClosing(widget.yearId);
      if (mounted) setState(() => _status = status);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    }
  }

  Future<void> _submit() async {
    final closed = _status!.closedAt != null;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.changeYearClosing(
        widget.yearId,
        close: !closed,
        reason: _reason.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final message = errorMessage(error);
      await _load();
      if (mounted) {
        setState(() {
          _error = message;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final status = _status;
    final closed = status?.closedAt != null;
    final blocking = [
      ...?status?.issues.where((issue) => issue.severity == 'BLOCKING'),
    ];
    final warnings = [
      ...?status?.issues.where((issue) => issue.severity == 'WARNING'),
    ];
    final canSubmit =
        !_busy &&
        status != null &&
        (closed || status.ready) &&
        _reason.text.trim().isNotEmpty;

    Widget lines(Iterable<String> values, Color color) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final value in values)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text('• $value', style: TextStyle(color: color)),
          ),
      ],
    );

    return AppDialog(
      title: closed
          ? 'Mở lại năm học ${widget.yearName}?'
          : 'Đóng năm học ${widget.yearName}?',
      confirmLabel: closed ? 'Mở lại' : 'Đóng năm học',
      danger: true,
      confirmEnabled: canSubmit,
      onConfirm: _submit,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status == null && _error == null)
            const Center(child: CircularProgressIndicator()),
          if (status != null) ...[
            Text(
              closed
                  ? 'Mở lại cho phép sửa dữ liệu của năm này. Lý do được ghi vào lịch sử.'
                  : 'Sau khi đóng, dữ liệu của năm chỉ còn xem và thống kê: không sửa lớp, phân công, điểm và không bỏ công bố học kỳ.',
            ),
            if (!closed && blocking.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Cần xử lý trước khi đóng',
                style: TextStyle(fontWeight: FontWeight.w700, color: t.bad),
              ),
              lines(blocking.map(yearClosingIssueText), t.ink),
            ],
            if (!closed && warnings.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              lines(warnings.map(yearClosingIssueText), t.warn),
            ],
            if (closed || status.ready) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const ValueKey('year-closing-reason'),
                controller: _reason,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Lý do'),
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (status.history.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Lịch sử',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              lines(status.history.map(_eventText), t.ink2),
            ],
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: TextStyle(color: t.bad)),
            if (status == null)
              TextButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ],
      ),
    );
  }
}
