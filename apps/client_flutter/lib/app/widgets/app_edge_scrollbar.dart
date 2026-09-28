import 'package:flutter/material.dart';

/// Owns the page scroll position outside its content padding and width limit.
/// Dialogs and navigation panels retain independent scroll controllers.
class AppEdgeScrollbar extends StatefulWidget {
  const AppEdgeScrollbar({super.key, required this.child});
  final Widget child;

  @override
  State<AppEdgeScrollbar> createState() => _AppEdgeScrollbarState();
}

class _AppEdgeScrollbarState extends State<AppEdgeScrollbar> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PrimaryScrollController(
    controller: _controller,
    automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
    child: Scrollbar(
      key: const ValueKey('app-edge-scrollbar'),
      controller: _controller,
      notificationPredicate: (notification) =>
          notification.metrics.axis == Axis.vertical &&
          notification.context != null &&
          _controller.positions.contains(
            Scrollable.maybeOf(notification.context!)?.position,
          ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: widget.child,
      ),
    ),
  );
}
