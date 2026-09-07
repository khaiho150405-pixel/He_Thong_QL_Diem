import 'package:client_flutter/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('connects to a running API', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Kết nối thành công'), findsOneWidget);
  });
}
