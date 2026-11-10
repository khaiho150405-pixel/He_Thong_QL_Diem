import 'package:flutter/material.dart';

import '../design_tokens.dart';

enum AppProgressTone { primary, ok, warn, bad }

class AppProgress extends StatelessWidget {
  const AppProgress({
    super.key,
    required this.value,
    this.tone = AppProgressTone.primary,
    this.minWidth = 70,
  });

  final double value;
  final AppProgressTone tone;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fill = switch (tone) {
      AppProgressTone.primary => t.pri,
      AppProgressTone.ok => t.ok,
      AppProgressTone.warn => t.acc,
      AppProgressTone.bad => t.bad,
    };
    return _Bar(
      height: 8,
      value: value,
      fill: fill,
      track: t.hover,
      minWidth: minWidth,
      semanticsLabel: 'Tiến độ',
    );
  }
}

class AppConfidenceBar extends StatelessWidget {
  const AppConfidenceBar({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fill = value >= 0.85
        ? t.ok
        : value >= 0.6
        ? t.acc
        : t.bad;
    return _Bar(
      height: 5,
      value: value,
      fill: fill,
      track: t.hover,
      minWidth: 0,
      semanticsLabel: 'Độ tin cậy',
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.height,
    required this.value,
    required this.fill,
    required this.track,
    required this.minWidth,
    required this.semanticsLabel,
  });

  final double height;
  final double value;
  final Color fill;
  final Color track;
  final double minWidth;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticsLabel,
      value: '${(v * 100).round()}%',
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: track,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: v,
                  heightFactor: 1,
                  child: DecoratedBox(
                    key: const ValueKey('app-progress-fill'),
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
