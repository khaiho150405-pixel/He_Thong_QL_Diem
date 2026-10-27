import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/app/widgets/app_scaffold.dart';
import 'package:client_flutter/app/widgets/app_sidebar.dart';
import 'package:client_flutter/app/widgets/app_user_avatar_menu.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Server giả chỉ biết đăng nhập/đăng xuất; mọi API khác trả 404.
class _ShellServer implements HttpClientAdapter {
  _ShellServer(this.role);
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
    } else if (options.path.endsWith('/logout')) {
      status = 204;
    }
    return ResponseBody.fromString(
      status == 204 ? '' : jsonEncode(body),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

const _roles = <({String role, String path, double sidebarWidth})>[
  (role: 'QUAN_TRI_VIEN', path: '/gradebooks', sidebarWidth: 258),
  (role: 'GIAO_VIEN', path: '/gradebooks', sidebarWidth: 242),
  (role: 'HOC_SINH', path: '/my-results', sidebarWidth: 236),
];

Future<ProviderContainer> _pumpShell(
  WidgetTester tester, {
  required String role,
  required String path,
  required Size size,
  required Brightness brightness,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      apiProvider.overrideWithValue(
        ApiClientDart(dio: Dio()..httpClientAdapter = _ShellServer(role)),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.runAsync(
    () => container.read(sessionProvider.notifier).login('0000000000', 'x'),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: AppScaffold(
          title: 'Bảng điểm',
          currentPath: path,
          body: const Center(child: Text('Nội dung trang')),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void _expectNoLegacySidebarText() {
  expect(find.text('08'), findsNothing);
  expect(find.text('Học kỳ I · 2024–2025'), findsNothing);
  expect(find.textContaining('Học kỳ I · 2024'), findsNothing);
}

void main() {
  for (final brightness in Brightness.values) {
    final tokens = brightness == Brightness.dark
        ? AppTokens.dark
        : AppTokens.light;
    for (final r in _roles) {
      testWidgets(
        'desktop shell ${r.role} ${brightness.name}: sidebar navy, vạch vàng, '
        'topbar',
        (tester) async {
          await _pumpShell(
            tester,
            role: r.role,
            path: r.path,
            size: const Size(1280, 800),
            brightness: brightness,
          );

          final sidebar = find.byKey(const ValueKey('app-sidebar'));
          expect(sidebar, findsOneWidget);
          expect(tester.widget<Material>(sidebar).color, tokens.navy);
          expect(tester.getSize(sidebar).width, r.sidebarWidth);

          // Mục đang chọn có đúng một vạch dọc vàng rộng 3px.
          final bar = find.byKey(const ValueKey('sidebar-active-bar'));
          expect(bar, findsOneWidget);
          expect(tester.getSize(bar).width, 3);
          final decoration =
              tester.widget<DecoratedBox>(bar).decoration as BoxDecoration;
          expect(decoration.color, tokens.acc);

          // Topbar: dòng nhỏ vai trò + tiêu đề, nền surface.
          final roleLabel = switch (r.role) {
            'QUAN_TRI_VIEN' => 'QUẢN TRỊ VIÊN',
            'GIAO_VIEN' => 'GIÁO VIÊN',
            _ => 'HỌC SINH',
          };
          expect(find.text(roleLabel), findsOneWidget);
          expect(find.text('Bảng điểm'), findsWidgets);
          final topBar = tester.widget<Material>(
            find
                .ancestor(
                  of: find.text(roleLabel),
                  matching: find.byType(Material),
                )
                .first,
          );
          expect(topBar.color, tokens.surface);

          // Chân sidebar: tên người dùng; thanh header có avatar menu tài khoản.
          expect(find.text('fake_user'), findsOneWidget);
          expect(find.byType(AppUserAvatarMenu), findsWidgets);
          expect(find.byType(NavigationBar), findsNothing);
          _expectNoLegacySidebarText();
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'mobile shell ${r.role} ${brightness.name}: AppBar, nav đáy, drawer navy',
        (tester) async {
          await _pumpShell(
            tester,
            role: r.role,
            path: r.path,
            size: const Size(390, 844),
            brightness: brightness,
          );

          expect(find.byType(AppBar), findsOneWidget);
          expect(find.byType(NavigationBar), findsOneWidget);
          expect(find.byKey(const ValueKey('app-sidebar')), findsNothing);
          // Nhãn tab 12px; tab đang chọn dùng màu primary.
          final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
          expect(bar.destinations.length, r.role == 'QUAN_TRI_VIEN' ? 5 : 4);
          final selectedLabel = tester.widget<Text>(
            find
                .descendant(
                  of: find.byType(NavigationBar),
                  matching: find.text(
                    r.role == 'HOC_SINH' ? 'Điểm số' : 'Bảng điểm',
                  ),
                )
                .first,
          );
          expect(selectedLabel.style?.fontSize ?? 12, 12);
          expect(tester.takeException(), isNull);

          // Mở drawer: nền navy, có vạch vàng ở mục đang chọn.
          tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
          await tester.pumpAndSettle();
          final sidebar = find.byKey(const ValueKey('app-sidebar'));
          expect(sidebar, findsOneWidget);
          expect(tester.widget<Material>(sidebar).color, tokens.navy);
          expect(
            find.byKey(const ValueKey('sidebar-active-bar')),
            findsOneWidget,
          );
          expect(find.byType(AppUserAvatarMenu), findsWidgets);
          _expectNoLegacySidebarText();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('sidebar thu gọn rộng 70, vẫn có avatar menu', (
    tester,
  ) async {
    final container = await _pumpShell(
      tester,
      role: 'GIAO_VIEN',
      path: '/gradebooks',
      size: const Size(1280, 800),
      brightness: Brightness.dark,
    );
    container.read(sidebarCollapsedProvider.notifier).state = true;
    await tester.pumpAndSettle();
    final sidebar = find.byKey(const ValueKey('app-sidebar'));
    expect(tester.getSize(sidebar).width, 70);
    expect(tester.widget<Material>(sidebar).color, AppTokens.dark.navy);
    expect(find.byKey(const ValueKey('sidebar-active-bar')), findsOneWidget);
    expect(find.byType(AppUserAvatarMenu), findsWidgets);
    expect(find.byTooltip('Mở rộng sidebar'), findsOneWidget);
    _expectNoLegacySidebarText();
    expect(tester.takeException(), isNull);
  });

  testWidgets('quản trị: đủ nhóm và mục, không có badge đếm giả', (
    tester,
  ) async {
    await _pumpShell(
      tester,
      role: 'QUAN_TRI_VIEN',
      path: '/catalog/years',
      size: const Size(1280, 2000),
      brightness: Brightness.light,
    );
    for (final label in [
      'Tổng quan',
      'Thời khóa biểu',
      'Điểm & Đánh giá',
      'Khung năm học & Lớp',
      'Môn học & Hệ số',
      'Hồ sơ & Tài khoản',
      'Năm học',
      'Học kỳ',
      'Lớp học',
      'Thành phần điểm',
      'Hệ số học kỳ',
      'ĐIỀU HƯỚNG CHÍNH',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    _expectNoLegacySidebarText();
    expect(tester.takeException(), isNull);
  });

  testWidgets('đăng xuất từ avatar menu hỏi xác nhận', (tester) async {
    await _pumpShell(
      tester,
      role: 'GIAO_VIEN',
      path: '/gradebooks',
      size: const Size(1280, 800),
      brightness: Brightness.light,
    );
    await tester.tap(find.byType(AppUserAvatarMenu).first);
    await tester.pumpAndSettle();
    expect(find.text('Đăng xuất'), findsOneWidget);
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận đăng xuất'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận đăng xuất'), findsNothing);
  });
}
