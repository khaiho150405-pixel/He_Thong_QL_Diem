import 'package:flutter/material.dart';
import '../academic_catalog/repository.dart';
import '../authentication/session.dart';
import 'timetable_model.dart';
import 'timetable_repository.dart';

class TimetableEditDialog extends StatefulWidget {
  const TimetableEditDialog({
    super.key,
    required this.assignments,
    required this.repository,
    this.item,
    this.initialDay,
    this.initialPeriod,
    this.moving = false,
  });

  final List<Json> assignments;
  final TimetableRepository repository;
  final TimetableItem? item;
  final int? initialDay, initialPeriod;
  final bool moving;

  @override
  State<TimetableEditDialog> createState() => _TimetableEditDialogState();
}

class _TimetableEditDialogState extends State<TimetableEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late num? _assignmentId;
  late int _day;
  late int _period;
  late bool _afternoon;
  late final TextEditingController _room;
  late final TextEditingController _note;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final matches = item == null
        ? (widget.assignments.length == 1
              ? [widget.assignments.single]
              : <Json>[])
        : widget.assignments
              .where(
                (row) =>
                    (row['ma_lop'] as num?)?.toInt() == item.maLop &&
                    (row['ma_mon'] as num?)?.toInt() == item.maMon &&
                    (row['ma_giao_vien'] as num?)?.toInt() == item.maGiaoVien &&
                    (row['ma_hoc_ky'] as num?)?.toInt() == item.maHocKy,
              )
              .toList();
    _assignmentId = matches.isEmpty
        ? null
        : matches.first['ma_phan_cong'] as num?;
    _day = item?.thu ?? widget.initialDay ?? 2;
    _period = item?.tiet ?? widget.initialPeriod ?? 1;
    _afternoon = _period > 5;
    _room = TextEditingController(text: item?.phongHoc ?? '');
    _note = TextEditingController(text: item?.ghiChu ?? '');
  }

  @override
  void dispose() {
    _room.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final assignment = widget.assignments.firstWhere(
      (row) => row['ma_phan_cong'] == _assignmentId,
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final values = (
        maLop: (assignment['ma_lop'] as num).toInt(),
        maMon: (assignment['ma_mon'] as num).toInt(),
        maGiaoVien: (assignment['ma_giao_vien'] as num).toInt(),
        maHocKy: (assignment['ma_hoc_ky'] as num).toInt(),
      );
      if (widget.item == null) {
        await widget.repository.createItem(
          maLop: values.maLop,
          maMon: values.maMon,
          maGiaoVien: values.maGiaoVien,
          maHocKy: values.maHocKy,
          thu: _day,
          tiet: _period,
          phongHoc: _room.text.trim(),
          ghiChu: _note.text.trim(),
        );
      } else {
        await widget.repository.updateItem(
          id: widget.item!.maTietHoc,
          maLop: values.maLop,
          maMon: values.maMon,
          maGiaoVien: values.maGiaoVien,
          maHocKy: values.maHocKy,
          thu: _day,
          tiet: _period,
          phongHoc: _room.text.trim(),
          ghiChu: _note.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = errorMessage(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.edit_calendar_outlined),
      title: Text(
        widget.moving
            ? 'Chuyển ngày / tiết học'
            : widget.item == null
            ? 'Xếp tiết học'
            : 'Cập nhật tiết học',
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mỗi ngày từ 3 tiết phải có ít nhất 3 môn. Mỗi buổi '
                          'tối đa 4 tiết; hai tiết cùng môn phải liền nhau.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<num>(
                  initialValue: _assignmentId,
                  isExpanded: true,
                  itemHeight: null,
                  decoration: const InputDecoration(
                    labelText: 'Lớp · môn · giáo viên · học kỳ',
                    helperText: 'Chỉ hiển thị các phân công giảng dạy hợp lệ',
                  ),
                  items: widget.assignments
                      .map(
                        (row) => DropdownMenuItem<num>(
                          value: row['ma_phan_cong'] as num?,
                          child: Text(row['label']?.toString() ?? 'Phân công'),
                        ),
                      )
                      .toList(),
                  onChanged: _saving || widget.moving
                      ? null
                      : (value) => setState(() => _assignmentId = value),
                  validator: (value) => value == null ? 'Chọn phân công' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _day,
                        isExpanded: true,
                        itemHeight: null,
                        decoration: const InputDecoration(labelText: 'Thứ'),
                        items: const [
                          DropdownMenuItem(value: 2, child: Text('Thứ Hai')),
                          DropdownMenuItem(value: 3, child: Text('Thứ Ba')),
                          DropdownMenuItem(value: 4, child: Text('Thứ Tư')),
                          DropdownMenuItem(value: 5, child: Text('Thứ Năm')),
                          DropdownMenuItem(value: 6, child: Text('Thứ Sáu')),
                          DropdownMenuItem(value: 7, child: Text('Thứ Bảy')),
                          DropdownMenuItem(value: 8, child: Text('Chủ nhật')),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _day = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Buổi học',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, constraints) => SegmentedButton<bool>(
                      direction: constraints.maxWidth < 340
                          ? Axis.vertical
                          : Axis.horizontal,
                      segments: const [
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.wb_sunny_outlined),
                          label: Text('Buổi sáng'),
                        ),
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.wb_twilight_outlined),
                          label: Text('Buổi chiều'),
                        ),
                      ],
                      selected: {_afternoon},
                      onSelectionChanged: _saving
                          ? null
                          : (value) {
                              setState(() {
                                _afternoon = value.first;
                                _period = _afternoon
                                    ? (_period > 5 ? _period : 6)
                                    : (_period <= 5 ? _period : 1);
                              });
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey(_afternoon),
                  initialValue: _period,
                  isExpanded: true,
                  itemHeight: null,
                  decoration: const InputDecoration(
                    labelText: 'Tiết học và khung giờ',
                    prefixIcon: Icon(Icons.schedule_outlined),
                  ),
                  items: [
                    for (
                      var period = _afternoon ? 6 : 1;
                      period <= (_afternoon ? 10 : 5);
                      period++
                    )
                      DropdownMenuItem(
                        value: period,
                        child: Text('Tiết $period · ${_timeOf(period)}'),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _period = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _room,
                  maxLength: 30,
                  decoration: const InputDecoration(labelText: 'Phòng học'),
                ),
                TextFormField(
                  controller: _note,
                  maxLength: 200,
                  decoration: const InputDecoration(labelText: 'Ghi chú'),
                ),
                if (_error != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.item == null ? 'Thêm vào lịch' : 'Lưu thay đổi'),
        ),
      ],
    );
  }

  static String _timeOf(int period) => const {
    1: '07:00–07:45',
    2: '07:50–08:35',
    3: '08:50–09:35',
    4: '09:40–10:25',
    5: '10:30–11:15',
    6: '13:00–13:45',
    7: '13:50–14:35',
    8: '14:50–15:35',
    9: '15:40–16:25',
    10: '16:30–17:15',
  }[period]!;
}
