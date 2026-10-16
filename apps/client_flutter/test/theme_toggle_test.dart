import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/app/theme_mode.dart';
import 'package:client_flutter/app/widgets/app_scaffold.dart';
import 'package:client_flutter/app/widgets/theme_mode_button.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/connection/connection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _toggleKey = ValueKey('theme-mode-toggle');
const _toDark = 'Chuyển sang giao diện tối';
const _toLight = 'Chuyển sang giao diện sáng';

/// Server giả chỉ biết đăng nhập; mọi API khác trả 404.
class _Server implements HttpClientAdapter {
  _Server(this.role);
  final String role;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object? body = {};
    var status = 404;
    if (options.path.endsWith('/login')) {
      status = 200;
      body = {
        'id': 1,
        'username': 'fake_user',
        'role': role,
        'active': true,
        'token': 'test-token',
        'csrf': 'test-csrf',
      };
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

void _setView(WidgetTester tester, Size size, double textScale) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _pumpLogin(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
}) async {
  _setView(tester, size, textScale);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [connectionProvider.overrideWith((ref) async {})],
      child: const GradebookApp(initialLocation: '/login'),
    ),
  );
  await tester.pumpAndSettle();
}

/// Ứng dụng tối giản có khung điều hướng thật (`AppScaffold`) và đọc
/// `themeModeProvider` giống `GradebookApp`.
class _FrameApp extends ConsumerWidget {
  const _FrameApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ref.watch(themeModeProvider),
    home: const AppScaffold(
      title: 'Bảng điểm',
      currentPath: '/timetable',
      body: Center(child: Text('Nội dung trang')),
    ),
  );
}

Future<void> _login(WidgetTester tester, Finder app, String role) async {
  final container = ProviderScope.containerOf(tester.element(app));
  await tester.runAsync(
    () => container.read(sessionProvider.notifier).login('0000000000', 'x'),
  );
  await tester.pumpAndSettle();
}

ProviderScope _scope(String role, Widget child) => ProviderScope(
  overrides: [
    apiProvider.overrideWithValue(
      ApiClientDart(dio: Dio()..httpClientAdapter = _Server(role)),
    ),
  ],
  child: child,
);

/// Khung `AppScaffold` đã đăng nhập (topbar ở màn rộng, AppBar ở màn hẹp).
Future<void> _pumpFrame(
  WidgetTester tester, {
  required String role,
  required Size size,
  double textScale = 1.0,
}) async {
  _setView(tester, size, textScale);
  await tester.pumpWidget(_scope(role, const _FrameApp()));
  await _login(tester, find.byType(_FrameApp), role);
}

/// Trang chủ thật (`/`) đã đăng nhập.
Future<void> _pumpHome(
  WidgetTester tester, {
  required String role,
  required Size size,
}) async {
  _setView(tester, size, 1.0);
  await tester.pumpWidget(
    _scope(role, const GradebookApp(initialLocation: '/')),
  );
  await tester.pumpAndSettle();
  await _login(tester, find.byType(GradebookApp), role);
}

/// Tháo cây widget để huỷ timer 10 giây của các provider báo cáo.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).first)).brightness;

void _expectOneToggle(WidgetTester tester, {double? maxRight}) {
  final toggle = find.byKey(_toggleKey);
  expect(toggle, findsOneWidget);
  expect(find.byType(ThemeModeButton), findsOneWidget);
  final size = tester.getSize(toggle);
  expect(size.width, greaterThanOrEqualTo(44));
  expect(size.height, greaterThanOrEqualTo(48));
  if (maxRight != null) {
    expect(tester.getTopRight(toggle).dx, lessThanOrEqualTo(maxRight));
    expect(tester.getTopLeft(toggle).dx, greaterThanOrEqualTo(0));
  }
}

void main() {
  test('themeModeProvider mặc định ThemeMode.light', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  testWidgets('mặc định sáng dù hệ điều hành tối; bấm nút sang tối rồi sáng', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _pumpLogin(tester, size: const Size(390, 800));

    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    AppTokens tokens() => tester.element(find.byType(Scaffold).first).tokens;

    expect(app().themeMode, ThemeMode.light);
    expect(_brightness(tester), Brightness.light);
    expect(tokens().brightness, Brightness.light);
    expect(find.byTooltip(_toDark), findsOneWidget);
    expect(find.byTooltip(_toLight), findsNothing);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

    await tester.tap(find.byKey(_toggleKey));
    await tester.pumpAndSettle();
    expect(app().themeMode, ThemeMode.dark);
    expect(_brightness(tester), Brightness.dark);
    expect(tokens().brightness, Brightness.dark);
    expect(find.byTooltip(_toLight), findsOneWidget);
    expect(find.byTooltip(_toDark), findsNothing);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

    await tester.tap(find.byKey(_toggleKey));
    await tester.pumpAndSettle();
    expect(app().themeMode, ThemeMode.light);
    expect(_brightness(tester), Brightness.light);
    expect(find.byTooltip(_toDark), findsOneWidget);
  });

  group('màn đăng nhập', () {
    for (final width in [320.0, 390.0, 960.0, 1440.0]) {
      testWidgets(
        'một nút, không tràn ở ${width.toInt()} px với chữ 1.5x (màn hẹp)',
        (tester) async {
          await _pumpLogin(
            tester,
            size: Size(width, width >= 960 ? 900 : 720),
            // Nửa trái trang trí của màn rộng tràn dọc ở chữ 1.5x (không liên
            // quan tới nút), nên chỉ thử 1.5x ở màn hẹp.
            textScale: width < 960 ? 1.5 : 1.0,
          );
          _expectOneToggle(tester, maxRight: width);
          expect(tester.takeException(), isNull);

          await tester.tap(find.byKey(_toggleKey));
          await tester.pumpAndSettle();
          expect(_brightness(tester), Brightness.dark);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('khung điều hướng', () {
    testWidgets('màn rộng: nút nằm ở topbar, bấm đổi theme', (tester) async {
      await _pumpFrame(tester, role: 'GIAO_VIEN', size: const Size(1280, 800));
      _expectOneToggle(tester);
      expect(find.byType(AppBar), findsNothing);
      expect(tester.getRect(find.byKey(_toggleKey)).top, lessThan(100));

      await tester.tap(find.byKey(_toggleKey));
      await tester.pumpAndSettle();
      expect(_brightness(tester), Brightness.dark);
      expect(find.byTooltip(_toLight), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final width in [320.0, 390.0]) {
      testWidgets('màn hẹp ${width.toInt()} px: nút nằm ở AppBar, chữ 1.5x', (
        tester,
      ) async {
        await _pumpFrame(
          tester,
          role: 'GIAO_VIEN',
          size: Size(width, 800),
          textScale: 1.5,
        );
        _expectOneToggle(tester, maxRight: width);
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byKey(_toggleKey),
          ),
          findsOneWidget,
        );
        expect(find.byTooltip('Đăng xuất'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(_toggleKey));
        await tester.pumpAndSettle();
        expect(_brightness(tester), Brightness.dark);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('trang chủ', () {
    for (final role in ['QUAN_TRI_VIEN', 'GIAO_VIEN', 'HOC_SINH']) {
      testWidgets('$role màn rộng: một nút ở topbar', (tester) async {
        await _pumpHome(tester, role: role, size: const Size(1280, 800));
        _expectOneToggle(tester);
        expect(find.byType(AppBar), findsNothing);

        await tester.tap(find.byKey(_toggleKey));
        await tester.pumpAndSettle();
        expect(_brightness(tester), Brightness.dark);
        await _unmount(tester);
      });

      testWidgets('$role màn hẹp 320 px: một nút ở AppBar', (tester) async {
        await _pumpHome(tester, role: role, size: const Size(320, 800));
        _expectOneToggle(tester, maxRight: 320);
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byKey(_toggleKey),
          ),
          findsOneWidget,
        );
        await _unmount(tester);
      });
    }
  });
}
