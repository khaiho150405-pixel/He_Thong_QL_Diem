import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/app/theme_mode.dart';
import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/features/authentication/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const widths = <double>[320, 390, 960, 1440];
  const modes = <Brightness>[Brightness.light, Brightness.dark];

  for (final mode in modes) {
    for (final width in widths) {
      testWidgets('login ${mode.name} ${width.toInt()}px', (tester) async {
        tester.view.physicalSize = Size(width, width >= 960 ? 900 : 720);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.platformBrightnessTestValue = mode;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              themeModeProvider.overrideWith(
                (ref) =>
                    mode == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
              ),
            ],
            child: const GradebookApp(initialLocation: '/login'),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('EduScore'), findsOneWidget);
        expect(
          find.widgetWithText(TextFormField, 'Tên đăng nhập'),
          findsOneWidget,
        );
        expect(find.widgetWithText(FilledButton, 'Đăng nhập'), findsOneWidget);

        final tokens = Theme.of(
          tester.element(find.byType(LoginScreen)),
        ).extension<AppTokens>()!;
        expect(tokens.brightness, mode);
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(scaffold.backgroundColor, tokens.surface);

        // Nửa trái navy chỉ có từ 960 trở lên.
        final navyPanel = find.byWidgetPredicate(
          (w) => w is Container && w.color == tokens.navy,
        );
        expect(navyPanel, width >= 960 ? findsOneWidget : findsNothing);
        expect(
          find.text('Nhập điểm nhanh hơn, đối chiếu rõ ràng hơn.'),
          width >= 960 ? findsOneWidget : findsNothing,
        );

        // Ô nhập và nút cao tối thiểu 48.
        expect(
          tester.getSize(find.byType(FilledButton)).height,
          greaterThanOrEqualTo(48),
        );
        expect(
          tester
              .getSize(find.widgetWithText(TextFormField, 'Tên đăng nhập'))
              .height,
          greaterThanOrEqualTo(48),
        );
      });
    }
  }
}
