import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../design_tokens.dart';

/// Biểu đồ đường của prototype (`lineChart`): lưới ngang, vùng tô nhạt, chấm
/// cuối đặc, tooltip nền navy khi rê chuột hoặc chạm. Vẽ bằng [CustomPainter];
/// dữ liệu truyền qua tham số, widget không tự lấy dữ liệu.
class AppLineChart extends StatefulWidget {
  const AppLineChart({
    super.key,
    required this.labels,
    required this.values,
    this.min = 0,
    this.max = 10,
    this.unit = '',
    this.height = 220,
    this.semanticLabel = 'Biểu đồ đường',
    this.valueFormatter,
  });

  final List<String> labels;
  final List<double> values;
  final double min;
  final double max;

  /// Hậu tố của giá trị trong tooltip.
  final String unit;
  final double height;
  final String semanticLabel;

  /// Định dạng giá trị trong tooltip; mặc định bỏ ".0" với số nguyên.
  final String Function(double value)? valueFormatter;

  @override
  State<AppLineChart> createState() => _AppLineChartState();
}

class _AppLineChartState extends State<AppLineChart> {
  int? _hover;

  int get _count => math.min(widget.labels.length, widget.values.length);

  void _setHover(Offset local, double width) {
    final n = _count;
    if (n == 0) return;
    final geo = _ChartGeometry(
      width: width,
      height: widget.height,
      n: n,
      min: widget.min,
      max: widget.max,
    );
    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < n; i++) {
      final d = (geo.x(i) - local.dx).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    if (best != _hover) setState(() => _hover = best);
  }

  void _clearHover() {
    if (_hover != null) setState(() => _hover = null);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final base =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 11);
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : 320.0;
          return MouseRegion(
            onHover: (e) => _setHover(e.localPosition, width),
            onExit: (_) => _clearHover(),
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                if (e.kind != PointerDeviceKind.mouse) {
                  _setHover(e.localPosition, width);
                }
              },
              onPointerMove: (e) {
                if (e.kind != PointerDeviceKind.mouse) {
                  _setHover(e.localPosition, width);
                }
              },
              onPointerUp: (e) {
                if (e.kind != PointerDeviceKind.mouse) _clearHover();
              },
              onPointerCancel: (_) => _clearHover(),
              child: CustomPaint(
                key: const ValueKey('app-line-chart'),
                size: Size(width, widget.height),
                painter: AppLineChartPainter(
                  labels: widget.labels,
                  values: widget.values,
                  min: widget.min,
                  max: widget.max,
                  unit: widget.unit,
                  valueFormatter: widget.valueFormatter,
                  hoverIndex: _hover,
                  tokens: t,
                  textStyle: base,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChartGeometry {
  _ChartGeometry({
    required this.width,
    required this.height,
    required this.n,
    required this.min,
    required this.max,
  });

  static const double left = 36;
  static const double right = 16;
  static const double top = 16;
  static const double bottom = 30;

  final double width;
  final double height;
  final int n;
  final double min;
  final double max;

  double get innerW => math.max(1, width - left - right);
  double get innerH => math.max(1, height - top - bottom);
  double get span => max > min ? max - min : 1;

  double x(int i) => left + (n <= 1 ? innerW / 2 : i * innerW / (n - 1));
  double y(double v) => top + innerH - (v - min) / span * innerH;
}

/// Công khai để test đọc được `hoverIndex`; không dùng trực tiếp ngoài file này.
@visibleForTesting
class AppLineChartPainter extends CustomPainter {
  AppLineChartPainter({
    required this.labels,
    required this.values,
    required this.min,
    required this.max,
    required this.unit,
    required this.valueFormatter,
    required this.hoverIndex,
    required this.tokens,
    required this.textStyle,
  });

  final List<String> labels;
  final List<double> values;
  final double min;
  final double max;
  final String unit;
  final String Function(double value)? valueFormatter;
  final int? hoverIndex;
  final AppTokens tokens;
  final TextStyle textStyle;

  static String _fmtTick(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  String _fmtValue(double v) =>
      valueFormatter?.call(v) ??
      (v == v.roundToDouble() ? v.toInt().toString() : v.toString());

  void _text(
    Canvas canvas,
    String text,
    Offset anchor, {
    required TextStyle style,
    TextAlign align = TextAlign.center,
    double? maxWidth,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);
    final dx = switch (align) {
      TextAlign.right || TextAlign.end => anchor.dx - tp.width,
      TextAlign.left || TextAlign.start => anchor.dx,
      _ => anchor.dx - tp.width / 2,
    };
    tp.paint(canvas, Offset(dx, anchor.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = tokens;
    final n = math.min(labels.length, values.length);
    final g = _ChartGeometry(
      width: size.width,
      height: size.height,
      n: n,
      min: min,
      max: max,
    );
    final axis = textStyle.copyWith(color: t.ink3, fontSize: 11, height: 1);

    // Lưới ngang và nhãn trục Y.
    final gridPaint = Paint()
      ..color = t.line
      ..strokeWidth = 1;
    for (var k = 0; k <= 4; k++) {
      final v = min + (max - min) / 4 * k;
      final y = g.y(v);
      canvas.drawLine(
        Offset(_ChartGeometry.left, y),
        Offset(size.width - _ChartGeometry.right, y),
        gridPaint,
      );
      _text(
        canvas,
        _fmtTick(v),
        Offset(_ChartGeometry.left - 8, y),
        style: axis,
        align: TextAlign.right,
      );
    }

    // Nhãn trục X.
    for (var i = 0; i < n; i++) {
      _text(
        canvas,
        labels[i],
        Offset(g.x(i), size.height - 8 - 5),
        style: axis,
        maxWidth: n > 1 ? math.max(24, g.innerW / (n - 1)) : g.innerW,
      );
    }
    if (n == 0) return;

    // Đường và vùng tô.
    final line = Path();
    for (var i = 0; i < n; i++) {
      final p = Offset(g.x(i), g.y(values[i]));
      i == 0 ? line.moveTo(p.dx, p.dy) : line.lineTo(p.dx, p.dy);
    }
    final bottomY = _ChartGeometry.top + g.innerH;
    final area = Path.from(line)
      ..lineTo(g.x(n - 1), bottomY)
      ..lineTo(g.x(0), bottomY)
      ..close();
    canvas.drawPath(area, Paint()..color = t.pri.withValues(alpha: 0.1));
    canvas.drawPath(
      line,
      Paint()
        ..color = t.pri
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Đường chỉ dọc nét đứt ở điểm đang chọn.
    final h = hoverIndex;
    if (h != null && h >= 0 && h < n) {
      final cross = Paint()
        ..color = t.line2
        ..strokeWidth = 1;
      final x = g.x(h);
      for (var y = _ChartGeometry.top; y < bottomY; y += 6) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, math.min(y + 3, bottomY)),
          cross,
        );
      }
    }

    // Chấm dữ liệu; chấm cuối đặc.
    for (var i = 0; i < n; i++) {
      final c = Offset(g.x(i), g.y(values[i]));
      final last = i == n - 1;
      canvas.drawCircle(
        c,
        last ? 5 : 4,
        Paint()..color = last ? t.pri : t.surface,
      );
      canvas.drawCircle(
        c,
        last ? 5 : 4,
        Paint()
          ..color = t.pri
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // Tooltip nền navy.
    if (h != null && h >= 0 && h < n) {
      const tw = 96.0;
      const th = 36.0;
      final cx = g.x(h);
      final lo = _ChartGeometry.left;
      final hi = math.max(lo, size.width - _ChartGeometry.right - tw);
      final tx = (cx - tw / 2).clamp(lo, hi);
      final ty = math.max(g.y(values[h]) - 46, 2.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(tx, ty, tw, th),
          const Radius.circular(8),
        ),
        Paint()..color = t.navy,
      );
      _text(
        canvas,
        labels[h],
        Offset(tx + tw / 2, ty + 11),
        style: textStyle.copyWith(
          color: t.onPri.withValues(alpha: 0.8),
          fontSize: 10,
          height: 1,
        ),
        maxWidth: tw - 8,
      );
      _text(
        canvas,
        '${_fmtValue(values[h])}$unit',
        Offset(tx + tw / 2, ty + 25),
        style: textStyle.copyWith(
          color: t.onPri,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
        maxWidth: tw - 8,
      );
    }
  }

  @override
  bool shouldRepaint(AppLineChartPainter old) =>
      old.hoverIndex != hoverIndex ||
      old.tokens != tokens ||
      old.min != min ||
      old.max != max ||
      old.unit != unit ||
      old.textStyle != textStyle ||
      !_same(old.labels, labels) ||
      !_same(old.values, values);

  static bool _same(List<Object?> a, List<Object?> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Một cột của [AppHBars].
class AppHBarItem {
  const AppHBarItem({
    required this.label,
    required this.value,
    this.valueText,
    this.color,
  });

  final String label;
  final double value;

  /// Chữ hiển thị bên phải; mặc định là [value] (bỏ ".0" nếu là số nguyên).
  final String? valueText;

  /// Màu cột; mặc định `pri`.
  final Color? color;
}

/// Cột ngang có nhãn và giá trị (`hbars`). [max] mặc định là giá trị lớn nhất.
class AppHBars extends StatelessWidget {
  const AppHBars({
    super.key,
    required this.items,
    this.max,
    this.labelWidth = 72,
    this.valueWidth = 48,
  });

  final List<AppHBarItem> items;
  final double? max;
  final double labelWidth;
  final double valueWidth;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = Theme.of(context).textTheme.bodyMedium;
    final top = max ?? items.fold<double>(0, (m, i) => math.max(m, i.value));
    final denom = top > 0 ? top : 1.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(
                  items[i].label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style?.copyWith(
                    color: t.ink2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.hover,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 16,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: math.max(
                            0.02,
                            (items[i].value / denom).clamp(0.0, 1.0),
                          ),
                          heightFactor: 1,
                          child: DecoratedBox(
                            key: ValueKey('app-hbar-fill-$i'),
                            decoration: BoxDecoration(
                              color: items[i].color ?? t.pri,
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: valueWidth,
                child: Text(
                  items[i].valueText ?? _fmt(items[i].value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: style?.copyWith(
                    color: t.ink,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
