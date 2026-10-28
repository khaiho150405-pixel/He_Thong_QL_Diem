import 'package:flutter/material.dart';

class AppDateField extends StatefulWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.optional = false,
    this.firstDate,
    this.lastDate,
    this.initialDateWhenEmpty,
    this.validator,
  });

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final bool optional;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDateWhenEmpty;
  final FormFieldValidator<String>? validator;

  /// Đọc giá trị ngày: lấy 10 ký tự đầu rồi tách năm/tháng/ngày.
  /// Không dùng DateTime.parse(...).toLocal() để tránh lệch múi giờ.
  static DateTime? parseIsoDate(String? value) {
    if (value == null) return null;
    final s = value.trim();
    if (s.isEmpty) return null;
    final raw = s.length >= 10 ? s.substring(0, 10) : s;

    // yyyy-MM-dd
    final isoMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
    if (isoMatch != null) {
      final y = int.tryParse(isoMatch.group(1)!);
      final m = int.tryParse(isoMatch.group(2)!);
      final d = int.tryParse(isoMatch.group(3)!);
      if (y != null &&
          m != null &&
          d != null &&
          m >= 1 &&
          m <= 12 &&
          d >= 1 &&
          d <= 31) {
        try {
          final dt = DateTime(y, m, d);
          if (dt.year == y && dt.month == m && dt.day == d) return dt;
        } catch (_) {}
      }
    }

    // dd/MM/yyyy
    final vnMatch = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(raw);
    if (vnMatch != null) {
      final d = int.tryParse(vnMatch.group(1)!);
      final m = int.tryParse(vnMatch.group(2)!);
      final y = int.tryParse(vnMatch.group(3)!);
      if (y != null &&
          m != null &&
          d != null &&
          m >= 1 &&
          m <= 12 &&
          d >= 1 &&
          d <= 31) {
        try {
          final dt = DateTime(y, m, d);
          if (dt.year == y && dt.month == m && dt.day == d) return dt;
        } catch (_) {}
      }
    }

    return null;
  }

  /// Hiển thị dd/MM/yyyy
  static String formatDisplay(DateTime? dt) {
    if (dt == null) return '';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }

  /// Định dạng ISO yyyy-MM-dd cho API
  static String formatIso(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  State<AppDateField> createState() => _AppDateFieldState();
}

class _AppDateFieldState extends State<AppDateField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: AppDateField.formatDisplay(AppDateField.parseIsoDate(widget.value)),
    );
  }

  @override
  void didUpdateWidget(covariant AppDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final newText = AppDateField.formatDisplay(
        AppDateField.parseIsoDate(widget.value),
      );
      if (_controller.text != newText) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _controller.text != newText) {
            _controller.text = newText;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    if (!widget.enabled) return;

    final effectiveFirst = widget.firstDate ?? DateTime(1900, 1, 1);
    var effectiveLast = widget.lastDate ?? DateTime(2100, 12, 31);
    if (effectiveLast.isBefore(effectiveFirst)) {
      effectiveLast = effectiveFirst;
    }

    final parsedCurrent = AppDateField.parseIsoDate(widget.value);
    DateTime candidate =
        parsedCurrent ?? widget.initialDateWhenEmpty ?? DateTime.now();

    if (candidate.isBefore(effectiveFirst)) {
      candidate = effectiveFirst;
    } else if (candidate.isAfter(effectiveLast)) {
      candidate = effectiveLast;
    }

    Locale? pickerLocale = const Locale('vi');
    if (Localizations.maybeLocaleOf(context) == null) {
      pickerLocale = null;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: candidate,
      firstDate: effectiveFirst,
      lastDate: effectiveLast,
      initialEntryMode: DatePickerEntryMode.calendar,
      locale: pickerLocale,
      helpText: 'Chọn ngày',
      fieldLabelText: 'Ngày',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: const InputDecorationTheme(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            isDense: true,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      widget.onChanged(AppDateField.formatIso(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null && widget.value!.trim().isNotEmpty;

    return TextFormField(
      controller: _controller,
      readOnly: true,
      enabled: widget.enabled,
      onTap: widget.enabled ? () => _pickDate(context) : null,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: 'Chọn ngày',
        prefixIcon: IconButton(
          icon: const Icon(Icons.calendar_today_outlined),
          tooltip: widget.label,
          onPressed: widget.enabled ? () => _pickDate(context) : null,
        ),
        suffixIcon: widget.enabled && widget.optional && hasValue
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Xóa',
                onPressed: () => widget.onChanged(null),
              )
            : null,
      ),
      validator: (text) {
        if (!widget.enabled) return null;
        if (widget.validator != null) {
          final customError = widget.validator!(widget.value);
          if (customError != null) return customError;
        }
        final parsed = AppDateField.parseIsoDate(widget.value);
        if (!widget.optional && parsed == null) {
          return 'Chọn ${widget.label.toLowerCase()}';
        }
        return null;
      },
    );
  }
}
