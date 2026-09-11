import 'package:client_flutter/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../test/phase1_test.dart' as phase1;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Native UI exercises a test HTTP adapter; real DB policies are tested in API CI.
  phase1.registerPhaseOneTests(resize: false);
  testWidgets('connects to a running API', (tester) async {
    app.main();
    if (const bool.fromEnvironment('EXPECT_TRANSIENT_FAILURE')) {
      await _pumpUntilVisible(tester, find.text('Không thể kết nối'));
      expect(find.text('Không thể kết nối'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
    }
    await _pumpUntilVisible(tester, find.text('Kết nối thành công'));
    expect(find.text('Kết nối thành công'), findsOneWidget);
  });
}

Future<void> _pumpUntilVisible(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}
