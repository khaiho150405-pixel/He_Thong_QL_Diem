import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/features/connection/connection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('connection failure offers retry and recovers', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectionProvider.overrideWith((ref) async {
            calls++;
            if (calls == 1) throw Exception('offline');
          }),
        ],
        child: const GradebookApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không thể kết nối'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Kết nối thành công'), findsOneWidget);
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets('responsive width $width', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [connectionProvider.overrideWith((ref) async {})],
          child: const GradebookApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kết nối thành công'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
