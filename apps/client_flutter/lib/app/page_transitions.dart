import 'package:flutter/material.dart';

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

PageTransitionsTheme gentlePageTransitionsTheme() => PageTransitionsTheme(
  builders: {
    for (final platform in TargetPlatform.values)
      platform: const GentleFadePageTransitionsBuilder(),
  },
);
