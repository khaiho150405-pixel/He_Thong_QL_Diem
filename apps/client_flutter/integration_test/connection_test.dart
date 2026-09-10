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
    await tester.pumpAndSettle(const Duration(seconds: 1));
    if (const bool.fromEnvironment('EXPECT_TRANSIENT_FAILURE')) {
      expect(find.text('Không thể kết nối'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }
    expect(find.text('Kết nối thành công'), findsOneWidget);
  });
}
