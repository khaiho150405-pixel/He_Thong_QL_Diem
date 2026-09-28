import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/app/widgets/app_edge_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const profiles = <({String name, Size size, double textScale})>[
    (name: 'small Android', size: Size(320, 568), textScale: 1),
    (name: 'large-text phone', size: Size(390, 844), textScale: 1.5),
    (name: 'tablet', size: Size(768, 1024), textScale: 1.15),
    (name: 'desktop web', size: Size(1440, 900), textScale: 1),
  ];

  for (final profile in profiles) {
    testWidgets('login remains readable on ${profile.name}', (tester) async {
      tester.view.physicalSize = profile.size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = profile.textScale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        const ProviderScope(child: GradebookApp(initialLocation: '/login')),
      );
      await tester.pumpAndSettle();

      expect(find.text('EduScore'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Tên đăng nhập'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Đăng nhập'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('global vertical scrollbar uses the outer window edge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light().copyWith(platform: TargetPlatform.windows),
        home: Scaffold(
          body: AppEdgeScrollbar(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.builder(
                  itemCount: 60,
                  itemBuilder: (_, index) =>
                      SizedBox(height: 48, child: Text('Dòng $index')),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollbar = find.byKey(const ValueKey('app-edge-scrollbar'));
    expect(scrollbar, findsOneWidget);
    expect(tester.getTopRight(scrollbar).dx, 1440);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    final before = position.pixels;
    // Thumb position follows the content offset (500 / 2880 * 700).
    await tester.pump(const Duration(milliseconds: 200));
    await tester.dragFrom(
      const Offset(1434, 150),
      const Offset(0, 100),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    expect(position.pixels, greaterThan(before));
    expect(tester.takeException(), isNull);
    final pageOffset = position.pixels;
    showDialog<void>(
      context: tester.element(find.byType(ListView)),
      builder: (_) => AlertDialog(
        content: SizedBox(
          width: 300,
          height: 200,
          child: ListView(
            key: const ValueKey('dialog-list'),
            children: List.generate(
              30,
              (i) => SizedBox(height: 48, child: Text('Mục $i')),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('dialog-list')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(position.pixels, pageOffset);
    expect(tester.takeException(), isNull);
  });
}
