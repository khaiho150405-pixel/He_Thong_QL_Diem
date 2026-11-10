import 'package:flutter/widgets.dart';

class ReviewPageLabels extends InheritedWidget {
  const ReviewPageLabels({
    super.key,
    required this.enabled,
    required super.child,
  });

  final bool enabled;

  static const int rowsPerPage = 1000;

  static bool looksBatched(Iterable<num> orders) =>
      orders.any((order) => order >= rowsPerPage);

  static int pageOfOrder(num order) => order ~/ rowsPerPage + 1;

  static String? labelOf(BuildContext context, num order) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ReviewPageLabels>();
    if (scope == null || !scope.enabled) return null;
    return 'Trang ${pageOfOrder(order)}';
  }

  @override
  bool updateShouldNotify(ReviewPageLabels oldWidget) =>
      oldWidget.enabled != enabled;
}
