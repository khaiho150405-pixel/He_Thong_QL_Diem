import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_tokens.dart';

const Map<String, String> _vietnameseCharMap = {
  // a
  'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a',
  'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a',
  'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
  'À': 'a', 'Á': 'a', 'Ạ': 'a', 'Ả': 'a', 'Ã': 'a',
  'Â': 'a', 'Ầ': 'a', 'Ấ': 'a', 'Ậ': 'a', 'Ẩ': 'a', 'Ẫ': 'a',
  'Ă': 'a', 'Ằ': 'a', 'Ắ': 'a', 'Ặ': 'a', 'Ẳ': 'a', 'Ẵ': 'a',

  // e
  'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e',
  'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
  'È': 'e', 'É': 'e', 'Ẹ': 'e', 'Ẻ': 'e', 'Ẽ': 'e',
  'Ê': 'e', 'Ề': 'e', 'Ế': 'e', 'Ệ': 'e', 'Ể': 'e', 'Ễ': 'e',

  // i
  'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
  'Ì': 'i', 'Í': 'i', 'Ị': 'i', 'Ỉ': 'i', 'Ĩ': 'i',

  // o
  'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o',
  'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o',
  'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
  'Ò': 'o', 'Ó': 'o', 'Ọ': 'o', 'Ỏ': 'o', 'Õ': 'o',
  'Ô': 'o', 'Ồ': 'o', 'Ố': 'o', 'Ộ': 'o', 'Ổ': 'o', 'Ỗ': 'o',
  'Ơ': 'o', 'Ờ': 'o', 'Ớ': 'o', 'Ợ': 'o', 'Ở': 'o', 'Ỡ': 'o',

  // u
  'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u',
  'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
  'Ù': 'u', 'Ú': 'u', 'Ụ': 'u', 'Ủ': 'u', 'Ũ': 'u',
  'Ư': 'u', 'Ừ': 'u', 'Ứ': 'u', 'Ự': 'u', 'Ử': 'u', 'Ữ': 'u',

  // y
  'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y',
  'Ỳ': 'y', 'Ý': 'y', 'Ỵ': 'y', 'Ỷ': 'y', 'Ỹ': 'y',

  // d
  'đ': 'd', 'Đ': 'd',
};

/// Chuyển đổi chuỗi tiếng Việt có dấu thành không dấu để tìm kiếm không phân biệt dấu và hoa/thường.
String _stripDiacritics(String text) {
  final buffer = StringBuffer();
  for (int i = 0; i < text.length; i++) {
    final char = text[i];
    final mapped = _vietnameseCharMap[char];
    if (mapped != null) {
      buffer.write(mapped);
    } else {
      buffer.write(char.toLowerCase());
    }
  }
  return buffer.toString();
}

int _matchRank(String cleanLabel, String cleanQuery) {
  if (cleanLabel.startsWith(cleanQuery)) {
    return 0; // Khớp đầu chuỗi
  }
  if (cleanLabel.contains(' $cleanQuery')) {
    return 1; // Khớp đầu từ
  }
  final delimiterPattern = RegExp(r'[\s\-_/().,]' + RegExp.escape(cleanQuery));
  if (cleanLabel.contains(delimiterPattern)) {
    return 1;
  }
  return 2; // Khớp bên trong từ
}

Widget _buildHighlightedLabel({
  required String label,
  required String query,
  required TextStyle baseStyle,
  required TextStyle highlightStyle,
}) {
  if (query.isEmpty) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: baseStyle,
    );
  }

  final cleanLabel = _stripDiacritics(label);
  final cleanQuery = _stripDiacritics(query);
  final matchIndex = cleanLabel.indexOf(cleanQuery);
  if (matchIndex < 0 || cleanLabel.length != label.length) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: baseStyle,
    );
  }

  final safeStart = matchIndex.clamp(0, label.length);
  final safeEnd = (matchIndex + cleanQuery.length).clamp(0, label.length);

  return Text.rich(
    TextSpan(
      style: baseStyle,
      children: [
        if (safeStart > 0) TextSpan(text: label.substring(0, safeStart)),
        TextSpan(
          text: label.substring(safeStart, safeEnd),
          style: highlightStyle,
        ),
        if (safeEnd < label.length) TextSpan(text: label.substring(safeEnd)),
      ],
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

class _ScoredEntry<T> {
  const _ScoredEntry(this.entry, this.rank, this.index);
  final DropdownMenuEntry<T?> entry;
  final int rank;
  final int index;
}

String _extractLabel(Widget widget) {
  if (widget is Text) {
    return widget.data ?? '';
  }
  if (widget is Align && widget.child != null) {
    return _extractLabel(widget.child!);
  }
  if (widget is Padding && widget.child != null) {
    return _extractLabel(widget.child!);
  }
  if (widget is Container && widget.child != null) {
    return _extractLabel(widget.child!);
  }
  if (widget is Center && widget.child != null) {
    return _extractLabel(widget.child!);
  }
  if (widget is SizedBox && widget.child != null) {
    return _extractLabel(widget.child!);
  }
  try {
    final dynamic dyn = widget;
    if (dyn.label is String) return dyn.label as String;
  } catch (_) {}
  return widget.toStringShort();
}

class AppSelectField<T> extends FormField<T> {
  AppSelectField({
    super.key,
    this.label,
    this.icon,
    this.prefixIcon,
    this.value,
    T? initialValue,
    required this.items,
    this.onChanged,
    super.validator,
    this.width,
    this.dense = false,
    this.hintText,
    this.helperText,
    this.searchable = true,
    super.enabled = true,
  }) : super(
         initialValue: value ?? initialValue,
         builder: (FormFieldState<T> state) {
           return _AppSelectFieldWidget<T>(
             fieldState: state,
             label: label,
             icon: icon,
             prefixIcon: prefixIcon,
             value: value ?? initialValue,
             items: items,
             onChanged: enabled ? onChanged : null,
             width: width,
             dense: dense,
             hintText: hintText,
             helperText: helperText,
             searchable: searchable,
             enabled: enabled && onChanged != null,
           );
         },
       );

  final String? label;
  final dynamic icon;
  final Widget? prefixIcon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final double? width;
  final bool dense;
  final String? hintText;
  final String? helperText;
  final bool searchable;
}

class _AppSelectFieldWidget<T> extends StatefulWidget {
  const _AppSelectFieldWidget({
    super.key,
    required this.fieldState,
    required this.label,
    required this.icon,
    required this.prefixIcon,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.width,
    required this.dense,
    this.hintText,
    required this.helperText,
    required this.searchable,
    required this.enabled,
  });

  final FormFieldState<T> fieldState;
  final String? label;
  final dynamic icon;
  final Widget? prefixIcon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final double? width;
  final bool dense;
  final String? hintText;
  final String? helperText;
  final bool searchable;
  final bool enabled;

  @override
  State<_AppSelectFieldWidget<T>> createState() =>
      _AppSelectFieldWidgetState<T>();
}

class _AppSelectFieldWidgetState<T> extends State<_AppSelectFieldWidget<T>> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isOpen = false;
  bool _hasUserTyped = false;
  String _query = '';
  int _highlightedIndex = -1;
  // Hoãn việc trả lại label khi rời ô: nếu làm ngay (setState + đổi text) giữa lúc
  // đang bấm vào một mục của menu thì menu bị dựng lại và lần bấm đầu bị mất.
  Timer? _blurResetTimer;

  DropdownMenuItem<T>? _findSelectedItem(T? val) {
    for (final item in widget.items) {
      if (item.value == val) return item;
    }
    return null;
  }

  String _getDisplayLabel(T? val) {
    final item = _findSelectedItem(val);
    if (item != null) {
      return _extractLabel(item.child);
    }
    return '';
  }

  void _selectItem(T? selected) {
    final label = _getDisplayLabel(selected);
    _controller.text = label;
    _hasUserTyped = false;
    _query = '';
    _highlightedIndex = -1;
    widget.fieldState.didChange(selected);
    widget.onChanged?.call(selected);
    _focusNode.unfocus();
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _getDisplayLabel(widget.value));
    _controller.addListener(_onTextChanged);
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          final expected = _getDisplayLabel(widget.value);
          _controller.text = expected;
          _hasUserTyped = false;
          _query = '';
          _highlightedIndex = -1;
          _focusNode.unfocus();
          if (mounted) {
            setState(() => _isOpen = false);
          }
          return KeyEventResult.handled;
        }

        if (!_isOpen || !widget.searchable) {
          return KeyEventResult.ignored;
        }

        final currentMatches = _getFilteredEntries();
        if (currentMatches.isEmpty ||
            (currentMatches.length == 1 &&
                currentMatches.first.value == null &&
                !currentMatches.first.enabled)) {
          return KeyEventResult.ignored;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          setState(() {
            if (_highlightedIndex < 0) {
              _highlightedIndex = 0;
            } else if (_highlightedIndex < currentMatches.length - 1) {
              _highlightedIndex++;
            }
          });
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          setState(() {
            if (_highlightedIndex > 0) {
              _highlightedIndex--;
            }
          });
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.enter) {
          final targetIndex = _highlightedIndex >= 0 ? _highlightedIndex : 0;
          if (targetIndex >= 0 && targetIndex < currentMatches.length) {
            final entry = currentMatches[targetIndex];
            if (entry.enabled) {
              _selectItem(entry.value);
              return KeyEventResult.handled;
            }
          }
        }

        return KeyEventResult.ignored;
      },
    )..addListener(_onFocusChange);
  }

  void _onTextChanged() {
    if (!widget.searchable) return;
    if (!_focusNode.hasFocus) return;

    final currentLabel = _getDisplayLabel(widget.value);
    if (_controller.text != currentLabel || _hasUserTyped) {
      _hasUserTyped = true;
      final newQuery = _controller.text;
      if (_query != newQuery) {
        setState(() {
          _query = newQuery;
          _highlightedIndex = -1;
        });
      }
    }
  }

  void _onFocusChange() {
    // KHÔNG setState ở đây: _isOpen chỉ dùng cho xử lý phím, không ảnh hưởng giao diện.
    // setState đúng lúc DropdownMenu đang mở menu / nhận lượt bấm làm mất lần bấm đầu.
    _isOpen = _focusNode.hasFocus;
    if (_focusNode.hasFocus) {
      _blurResetTimer?.cancel();
      if (widget.searchable) {
        _hasUserTyped = false;
        _query = '';
        _highlightedIndex = -1;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _focusNode.hasFocus) {
            _controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _controller.text.length,
            );
          }
        });
      }
    } else {
      // Đợi lượt bấm vào mục (nếu có) hoàn tất rồi mới trả lại label cũ.
      _blurResetTimer?.cancel();
      _blurResetTimer = Timer(const Duration(milliseconds: 300), () {
        if (!mounted || _focusNode.hasFocus) return;
        final expected = _getDisplayLabel(widget.value);
        final dirty =
            _hasUserTyped ||
            _query.isNotEmpty ||
            _highlightedIndex != -1 ||
            _controller.text != expected;
        if (!dirty) return;
        setState(() {
          _hasUserTyped = false;
          _query = '';
          _highlightedIndex = -1;
        });
        if (_controller.text != expected) {
          _controller.text = expected;
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant _AppSelectFieldWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.items != widget.items) {
      final expected = _getDisplayLabel(widget.value);
      if (_controller.text != expected) {
        _hasUserTyped = false;
        _query = '';
        _highlightedIndex = -1;
        _controller.text = expected;
      }
    }
  }

  @override
  void dispose() {
    _blurResetTimer?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  List<DropdownMenuEntry<T?>> _getFilteredEntries([AppTokens? tokenContext]) {
    final t = tokenContext ?? context.tokens;
    final activeQuery = _hasUserTyped ? _query.trim() : '';
    if (activeQuery.isEmpty) {
      return widget.items.asMap().entries.map((indexed) {
        final i = indexed.key;
        final item = indexed.value;
        final label = _extractLabel(item.child);
        final isHighlighted = i == _highlightedIndex;
        final labelWidget = item.child is Text
            ? Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: item.enabled ? t.ink : t.ink3,
                ),
              )
            : item.child;

        return DropdownMenuEntry<T?>(
          value: item.value,
          label: label.isNotEmpty ? label : (item.value?.toString() ?? ''),
          enabled: item.enabled,
          style: MenuItemButton.styleFrom(
            visualDensity: VisualDensity.compact,
            backgroundColor: isHighlighted ? t.subtle : null,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          ),
          labelWidget: labelWidget,
        );
      }).toList();
    }

    final cleanQuery = _stripDiacritics(activeQuery);
    final matches = <_ScoredEntry<T>>[];

    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final label = _extractLabel(item.child);
      final cleanLabel = _stripDiacritics(label);

      if (cleanLabel.contains(cleanQuery)) {
        final rank = _matchRank(cleanLabel, cleanQuery);
        final entry = DropdownMenuEntry<T?>(
          value: item.value,
          label: label.isNotEmpty ? label : (item.value?.toString() ?? ''),
          enabled: item.enabled,
        );
        matches.add(_ScoredEntry<T>(entry, rank, i));
      }
    }

    if (matches.isEmpty) {
      return [
        DropdownMenuEntry<T?>(
          value: null,
          label: 'Không tìm thấy “$activeQuery”',
          enabled: false,
          style: MenuItemButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          ),
          labelWidget: Text(
            'Không tìm thấy “$activeQuery”',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: t.ink3,
            ),
          ),
        ),
      ];
    }

    matches.sort((a, b) {
      if (a.rank != b.rank) return a.rank.compareTo(b.rank);
      return a.index.compareTo(b.index);
    });

    return matches.asMap().entries.map((indexed) {
      final idx = indexed.key;
      final m = indexed.value;
      final item = widget.items[m.index];
      final label = _extractLabel(item.child);
      final isHighlighted = idx == _highlightedIndex;

      final highlightedWidget = item.child is Text
          ? _buildHighlightedLabel(
              label: label,
              query: activeQuery,
              baseStyle: TextStyle(
                fontSize: 13,
                color: item.enabled ? t.ink : t.ink3,
              ),
              highlightStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: item.enabled ? t.ink : t.ink3,
              ),
            )
          : item.child;

      return DropdownMenuEntry<T?>(
        value: item.value,
        label: label.isNotEmpty ? label : (item.value?.toString() ?? ''),
        enabled: item.enabled,
        style: MenuItemButton.styleFrom(
          visualDensity: VisualDensity.compact,
          backgroundColor: isHighlighted ? t.subtle : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        ),
        labelWidget: highlightedWidget,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final size = MediaQuery.sizeOf(context);
    final insets = MediaQuery.viewInsetsOf(context);
    final isMobile = size.width < 600;
    final availableHeight = (size.height - insets.bottom).clamp(
      160.0,
      size.height,
    );
    final maxMenuHeight = isMobile
        ? (availableHeight * 0.5).clamp(140.0, 320.0)
        : 320.0;

    Widget? leading;
    if (widget.prefixIcon != null) {
      leading = widget.prefixIcon;
    } else if (widget.icon != null) {
      leading = widget.icon is Widget
          ? widget.icon as Widget
          : Icon(widget.icon as IconData, size: 18, color: t.ink2);
    }

    final inputTheme = InputDecorationTheme(
      isDense: widget.dense,
      constraints: widget.dense
          ? const BoxConstraints.tightFor(height: 48)
          : null,
      filled: true,
      fillColor: widget.enabled ? t.surface : t.subtle,
      contentPadding: widget.dense
          ? const EdgeInsets.fromLTRB(10, 4, 10, 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      labelStyle: TextStyle(
        fontSize: widget.dense ? 12 : 14,
        color: widget.enabled ? t.ink2 : t.ink3,
      ),
      hintStyle: TextStyle(fontSize: widget.dense ? 13 : 14, color: t.ink3),
      helperStyle: TextStyle(fontSize: 12, color: t.ink3),
      errorStyle: TextStyle(fontSize: 12, color: t.bad),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: t.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: t.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: t.pri, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: t.bad),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: t.bad, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: t.line),
      ),
    );

    Widget trailingWidget;
    if (_query.isNotEmpty && widget.enabled && widget.searchable) {
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            key: const ValueKey('app-select-clear-button'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _controller.clear();
              setState(() {
                _query = '';
                _hasUserTyped = true;
                _highlightedIndex = -1;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.close, size: 18, color: t.ink2),
            ),
          ),
          Icon(Icons.arrow_drop_down, color: t.ink2),
        ],
      );
    } else {
      trailingWidget = Icon(Icons.arrow_drop_down, color: t.ink2);
    }

    final menu = DropdownMenu<T?>(
      enabled: widget.enabled,
      controller: _controller,
      focusNode: _focusNode,
      width: widget.width,
      hintText: widget.hintText,
      expandedInsets: widget.width == null ? EdgeInsets.zero : null,
      menuHeight: maxMenuHeight,
      enableFilter: widget.searchable,
      enableSearch: widget.searchable,
      requestFocusOnTap: widget.searchable,
      leadingIcon: leading,
      trailingIcon: trailingWidget,
      selectedTrailingIcon: trailingWidget,
      label: widget.label != null ? Text(widget.label!) : null,
      helperText: widget.helperText,
      errorText: widget.fieldState.errorText,
      inputDecorationTheme: inputTheme,
      textStyle: TextStyle(
        fontSize: widget.dense ? 13 : 14,
        fontWeight: FontWeight.w500,
        color: widget.enabled ? t.ink : t.ink3,
        overflow: TextOverflow.ellipsis,
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(t.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(4),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            side: BorderSide(color: t.line),
          ),
        ),
      ),
      dropdownMenuEntries: _getFilteredEntries(t),
      initialSelection: widget.value,
      filterCallback: widget.searchable
          ? (allEntries, rawQuery) => _getFilteredEntries(t)
          : null,
      onSelected: widget.onChanged == null ? null : _selectItem,
    );

    final interactiveMenu = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        // Chỉ ghi nhận trạng thái, KHÔNG setState: dựng lại widget đúng lúc
        // DropdownMenu đang xử lý lượt bấm khiến lần bấm đầu không mở menu.
        if (!_isOpen && widget.enabled) {
          _isOpen = true;
          if (!_hasUserTyped) {
            _query = '';
            _highlightedIndex = -1;
          }
        }
        if (widget.searchable && widget.enabled) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _focusNode.hasFocus) {
              _controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _controller.text.length,
              );
            }
          });
        }
      },
      child: menu,
    );

    if (widget.dense) {
      return SizedBox(
        width: widget.width,
        height: 48.0,
        child: interactiveMenu,
      );
    }
    return interactiveMenu;
  }
}
