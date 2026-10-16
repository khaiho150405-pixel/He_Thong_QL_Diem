import 'package:flutter/material.dart';

/// Chuyển trang nhẹ nhàng: chỉ mờ dần vào (fade), tuyệt đối không phóng to
/// thu nhỏ (scale) hay trượt (slide). Thay cho hiệu ứng zoom mặc định của
/// Material trên Android, web và desktop (và hiệu ứng trượt của iOS).
///
/// - Chỉ trang MỚI mờ dần vào; trang cũ (`secondaryAnimation`) không có hiệu
///   ứng riêng.
/// - Tôn trọng cài đặt "giảm chuyển động" của hệ điều hành: khi
///   `MediaQuery.disableAnimationsOf(context)` là true thì không có hiệu ứng.
class GentleFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const GentleFadePageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 220);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}

/// Gán [GentleFadePageTransitionsBuilder] cho MỌI nền tảng.
PageTransitionsTheme gentlePageTransitionsTheme() => PageTransitionsTheme(
  builders: {
    for (final platform in TargetPlatform.values)
      platform: const GentleFadePageTransitionsBuilder(),
  },
);
