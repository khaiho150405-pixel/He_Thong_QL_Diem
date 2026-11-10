import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';

const gradeCellHeight = 40.0;

const gradeCellSide = 24.0;

TextStyle gradeNumberStyle(
  BuildContext context, {
  Color? color,
  double size = 14,
  FontWeight weight = FontWeight.w600,
}) => TextStyle(
  fontSize: size,
  fontWeight: weight,
  height: 1.2,
  color: color ?? context.tokens.ink,
  fontFeatures: const [FontFeature.tabularFigures()],
);

InputDecoration gradeInputDecoration(
  BuildContext context, {
  String hint = '—',
  double hintSize = 14,
}) {
  final t = context.tokens;
  return InputDecoration(
    isCollapsed: true,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    filled: false,
    hintText: hint,
    hintStyle: gradeNumberStyle(
      context,
      color: t.ink3.withValues(alpha: .6),
      size: hintSize,
      weight: FontWeight.w400,
    ),
    errorStyle: const TextStyle(fontSize: 0, height: 0),
    contentPadding: const EdgeInsets.symmetric(vertical: 11.5),
  );
}

enum GradeCellTone { normal, readOnly, changed, invalid }

class GradeCellFrame extends StatefulWidget {
  const GradeCellFrame({
    super.key,
    required this.width,
    required this.tone,
    required this.child,
    this.leading,
    this.trailing,
    this.tooltip,
    this.tooltipTrigger = TooltipTriggerMode.longPress,
  });

  final double width;
  final GradeCellTone tone;

  final Widget child;
  final Widget? leading;
  final Widget? trailing;

  final String? tooltip;
  final TooltipTriggerMode tooltipTrigger;

  @override
  State<GradeCellFrame> createState() => _GradeCellFrameState();
}

class _GradeCellFrameState extends State<GradeCellFrame> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (fill, edge) = switch (widget.tone) {
      GradeCellTone.invalid => (t.badSoft, t.bad),
      GradeCellTone.changed => (t.accSoft, t.warnLine),
      GradeCellTone.readOnly => (t.subtle, t.line),
      GradeCellTone.normal => (t.surface, t.line2),
    };
    final focusEdge = widget.tone == GradeCellTone.invalid ? t.bad : t.pri;
    final frame = SizedBox(
      width: widget.width,
      height: gradeCellHeight,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: _focused ? focusEdge : edge,
              width: _focused ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: gradeCellSide,
                child: Center(child: widget.leading),
              ),
              Expanded(child: widget.child),
              SizedBox(
                width: gradeCellSide,
                child: Center(child: widget.trailing),
              ),
            ],
          ),
        ),
      ),
    );
    if (widget.tooltip == null) return frame;
    return Tooltip(
      message: widget.tooltip!,
      triggerMode: widget.tooltipTrigger,
      waitDuration: const Duration(milliseconds: 400),
      child: frame,
    );
  }
}

class GradeAiDot extends StatelessWidget {
  const GradeAiDot({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Tooltip(
      message: 'Nhập từ ảnh',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.ok,
          shape: BoxShape.circle,
          border: Border.all(color: t.okLine),
        ),
        child: const SizedBox(width: 8, height: 8),
      ),
    );
  }
}

class GradePassFailMenu extends StatelessWidget {
  const GradePassFailMenu({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.includeEmpty = true,
    this.display,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  final bool includeEmpty;

  final String? display;

  static String label(String value) => switch (value) {
    '10.0' => 'Đạt',
    '0.0' => 'Không đạt',
    _ => '—',
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = display ?? label(value);
    return PopupMenuButton<String>(
      enabled: enabled,
      tooltip: '',
      padding: EdgeInsets.zero,
      onSelected: onChanged,
      itemBuilder: (_) => [
        if (includeEmpty)
          const PopupMenuItem(value: 'EMPTY', child: Text('Chưa đánh giá')),
        const PopupMenuItem(value: '10.0', child: Text('Đạt')),
        const PopupMenuItem(value: '0.0', child: Text('Không đạt')),
      ],
      child: SizedBox.expand(
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: gradeNumberStyle(
                context,
                color: text == '—' ? t.ink3 : (enabled ? t.ink : t.ink2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
