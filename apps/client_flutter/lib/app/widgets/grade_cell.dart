import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_tokens.dart';

/// Ô điểm của prototype (`.gc`): 64x36 trên màn rộng, 80x48 trên mobile.
///
/// Chỉ là lớp hiển thị bọc quanh [TextField]. Widget KHÔNG kiểm tra giá trị
/// điểm: màn cha tự quyết định [isInvalid] (theo quy tắc validate đang có) và
/// [isChanged] (đã sửa chưa lưu). Thứ tự ưu tiên màu: không hợp lệ, rồi đã sửa,
/// rồi bình thường. [fromImage] chỉ thêm chấm ở góc phải trên.
class AppGradeCell extends StatefulWidget {
  const AppGradeCell({
    super.key,
    required this.controller,
    this.fieldKey,
    this.focusNode,
    this.mobile = false,
    this.isChanged = false,
    this.fromImage = false,
    this.isInvalid = false,
    this.readOnly = false,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.textInputAction,
    this.inputFormatters,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.semanticLabel,
  });

  final TextEditingController controller;

  /// Key đặt trên [TextField] (ví dụ `ValueKey('grade-<id>')` khi gắn vào lưới).
  final Key? fieldKey;
  final FocusNode? focusNode;

  /// Kiểu 80x48, chữ 18 đậm, viền và nền luôn hiện.
  final bool mobile;
  final bool isChanged;
  final bool fromImage;
  final bool isInvalid;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType keyboardType;
  final String? semanticLabel;

  static const Size desktopSize = Size(64, 36);
  static const Size mobileSize = Size(80, 48);

  @override
  State<AppGradeCell> createState() => _AppGradeCellState();
}

class _AppGradeCellState extends State<AppGradeCell> {
  FocusNode? _ownNode;
  bool _hovered = false;
  bool _focused = false;

  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
    _focused = _node.hasFocus;
  }

  @override
  void didUpdateWidget(AppGradeCell old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownNode)?.removeListener(_onFocus);
      _node.addListener(_onFocus);
      _focused = _node.hasFocus;
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _ownNode?.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_focused != _node.hasFocus) setState(() => _focused = _node.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final size = widget.mobile
        ? AppGradeCell.mobileSize
        : AppGradeCell.desktopSize;
    final interactive = !widget.readOnly;
    final lifted = interactive && (_hovered || _focused);

    Color bg;
    Color border;
    if (widget.isInvalid) {
      bg = t.badSoft;
      border = t.bad;
    } else if (widget.isChanged) {
      bg = t.accSoft;
      border = t.warnLine;
    } else if (widget.mobile) {
      bg = lifted ? t.surface : t.subtle;
      border = t.line2;
    } else {
      bg = lifted ? t.surface : Colors.transparent;
      border = Colors.transparent;
    }
    if (interactive && !widget.isInvalid && !widget.isChanged) {
      if (_focused) {
        border = t.pri;
      } else if (_hovered) {
        border = t.line2;
      }
    }

    final base = Theme.of(context).textTheme.bodyMedium;
    final textStyle = base?.copyWith(
      color: t.ink,
      fontSize: widget.mobile ? 18 : 13.5,
      fontWeight: widget.mobile ? FontWeight.w600 : FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: DecoratedBox(
          key: const ValueKey('app-grade-cell-box'),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(
              widget.mobile ? AppRadius.sm + 2 : AppRadius.xs,
            ),
            border: Border.all(color: border),
            boxShadow: _focused && interactive
                ? [BoxShadow(color: t.focus, spreadRadius: 3)]
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Semantics(
                  label: widget.semanticLabel,
                  child: TextField(
                    key: widget.fieldKey,
                    controller: widget.controller,
                    focusNode: _node,
                    readOnly: widget.readOnly,
                    textAlign: TextAlign.center,
                    style: textStyle,
                    cursorColor: t.pri,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    inputFormatters: widget.inputFormatters,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    onEditingComplete: widget.onEditingComplete,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: BoxConstraints.tightFor(
                        width: size.width,
                        height: size.height,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.fromImage)
                Positioned(
                  top: 7,
                  right: 7,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      key: const ValueKey('app-grade-cell-image-dot'),
                      decoration: BoxDecoration(
                        color: t.ok,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox(width: 5, height: 5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
