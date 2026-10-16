import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/features/academic_catalog/catalog_screen.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Server giả cho màn danh mục quản trị: đăng nhập QTV và vài tài nguyên.
class _CatalogServer implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  static const _students = [
    {
      'ma_hoc_sinh': 1,
      'ma_nguoi_dung': 7,
      'ma_lop': 1,
      'ho_ten': 'Nguyễn Văn An',
      'ngay_sinh': '2010-05-12',
      'dang_theo_hoc': true,
      'label': 'Nguyễn Văn An · 10A1',
      'stt_toan_truong': 1,
      'stt_lop': 1,
    },
    {
      'ma_hoc_sinh': 2,
      'ma_nguoi_dung': null,
      'ma_lop': 2,
      'ho_ten': 'Trần Thị Bình',
      'ngay_sinh': '2010-08-03',
      'dang_theo_hoc': false,
      'label': 'Trần Thị Bình · 10A2',
      'stt_toan_truong': 2,
      'stt_lop': 1,
    },
  ];

  static const _teachers = [
    {
      'ma_giao_vien': 10,
      'ho_ten': 'Lê Hoàng Cúc',
      'to_chuyen_mon': 'Tổ Toán',
      'email': 'cuc.le@truong.test',
      'dien_thoai': '0901234567',
      'label': 'Lê Hoàng Cúc',
    },
    {
      'ma_giao_vien': 11,
      'ho_ten': 'Phạm Minh Đức',
      'to_chuyen_mon': null,
      'email': null,
      'dien_thoai': null,
      'label': 'Phạm Minh Đức',
    },
  ];

  static const _accounts = [
    {'id': 1, 'username': 'admin', 'role': 'QUAN_TRI_VIEN', 'active': true},
    {'id': 10, 'username': '0901234567', 'role': 'GIAO_VIEN', 'active': true},
    {'id': 7, 'username': '0912345678', 'role': 'HOC_SINH', 'active': false},
  ];

  static const _classes = [
    {
      'ma_lop': 1,
      'ma_nam_hoc': 1,
      'ma_gv_chu_nhiem': 10,
      'ten_lop': '10A1',
      'khoi': 10,
      'label': '10A1',
    },
    {
      'ma_lop': 2,
      'ma_nam_hoc': 1,
      'ma_gv_chu_nhiem': 11,
      'ten_lop': '10A2',
      'khoi': 10,
      'label': '10A2',
    },
  ];

  static const _years = [
    {
      'ma_nam_hoc': 1,
      'ten': '2026-2027',
      'ngay_bat_dau': '2026-09-01',
      'ngay_ket_thuc': '2027-06-01',
      'hien_hanh': true,
      'label': '2026-2027',
    },
  ];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    List<Object?> items = const [];
    if (path.endsWith('/identity/login')) {
      return _json({
        'id': 1,
        'username': 'admin',
        'role': 'QUAN_TRI_VIEN',
        'active': true,
        'token': 'token',
        'csrf': 'csrf',
      });
    } else if (path.endsWith('/catalog/students')) {
      items = _students;
    } else if (path.endsWith('/catalog/teachers')) {
      items = _teachers;
    } else if (path.endsWith('/identity/accounts')) {
      items = _accounts;
    } else if (path.endsWith('/catalog/classes')) {
      items = _classes;
    } else if (path.endsWith('/catalog/years')) {
      items = _years;
    }
    return _json({'items': items, 'nextCursor': null});
  }

  ResponseBody _json(Object body) => ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      'content-type': ['application/json'],
    },
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required String resource,
  required double width,
  required Brightness brightness,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      apiProvider.overrideWithValue(
        ApiClientDart(dio: Dio()..httpClientAdapter = _CatalogServer()),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.runAsync(
    () => container
        .read(sessionProvider.notifier)
        .login('admin', 'password-for-test'),
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
        home: CatalogScreen(resource: resource),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AppTokens _tokens(Brightness brightness) =>
    brightness == Brightness.dark ? AppTokens.dark : AppTokens.light;

Color? _decorationColor(WidgetTester tester, Finder finder) {
  final box = tester.widget<DecoratedBox>(finder);
  return (box.decoration as BoxDecoration).color;
}

void main() {
  for (final brightness in Brightness.values) {
    for (final width in [390.0, 1280.0]) {
      final wide = width >= 1280;
      final tokens = _tokens(brightness);

      testWidgets('học sinh ở $width, ${brightness.name}: '
          '${wide ? 'bảng' : 'thẻ'}, không overflow', (tester) async {
        await _pump(
          tester,
          resource: 'students',
          width: width,
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Nguyễn Văn An'), findsOneWidget);
        expect(find.text('Trần Thị Bình'), findsOneWidget);
        expect(find.text('Đang theo học'), findsOneWidget);
        expect(find.text('Ngừng theo dõi'), findsOneWidget);
        // Phân trang hiện có giữ nguyên.
        expect(find.text('Trang trước'), findsOneWidget);
        expect(find.text('Trang sau'), findsOneWidget);
        // Thanh lọc và sắp xếp hiện có vẫn còn.
        expect(find.text('Sắp xếp:'), findsOneWidget);
        final table = find.byKey(const ValueKey('catalog-table-students'));
        if (wide) {
          expect(table, findsOneWidget);
          expect(find.text('STT'), findsOneWidget);
          expect(find.text('#1 TRƯỜNG'), findsOneWidget);
          expect(find.text('HỌC SINH'), findsOneWidget);
          expect(find.text('NGÀY SINH'), findsOneWidget);
          expect(find.text('Đã liên kết'), findsOneWidget);
          expect(find.text('Chưa liên kết'), findsOneWidget);
          expect(_decorationColor(tester, table), tokens.surface);
          expect(
            _decorationColor(
              tester,
              find.byKey(const ValueKey('catalog-table-header')),
            ),
            tokens.subtle,
          );
        } else {
          expect(table, findsNothing);
          expect(find.text('HỌC SINH'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('giáo viên ở $width, ${brightness.name}: '
          '${wide ? 'bảng' : 'thẻ'}, không overflow', (tester) async {
        await _pump(
          tester,
          resource: 'teachers',
          width: width,
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Lê Hoàng Cúc'), findsOneWidget);
        expect(find.text('Phạm Minh Đức'), findsOneWidget);
        final table = find.byKey(const ValueKey('catalog-table-teachers'));
        if (wide) {
          expect(table, findsOneWidget);
          expect(find.text('TỔ CHUYÊN MÔN'), findsOneWidget);
          expect(find.text('Tổ Toán'), findsOneWidget);
          expect(find.text('cuc.le@truong.test'), findsOneWidget);
          expect(find.text('0901234567'), findsOneWidget);
          // Thiếu dữ liệu thì hiện dấu gạch, không bịa.
          expect(find.text('—'), findsNWidgets(3));
          // Nút xóa giữ nguyên cho giáo viên.
          expect(find.byTooltip('Xóa'), findsNWidgets(2));
        } else {
          expect(table, findsNothing);
          expect(find.text('Mã: 10'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('tài khoản ở $width, ${brightness.name}: '
          '${wide ? 'bảng' : 'thẻ'}, không overflow', (tester) async {
        await _pump(
          tester,
          resource: 'accounts',
          width: width,
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
        final table = find.byKey(const ValueKey('catalog-table-accounts'));
        // Vùng nội dung (bỏ thanh bên, cũng hiện tên đăng nhập và vai trò).
        final content = wide ? table : find.byType(ListView);
        Finder inContent(String text) =>
            find.descendant(of: content, matching: find.text(text));
        expect(inContent('admin'), findsOneWidget);
        expect(inContent('Quản trị viên'), findsOneWidget);
        expect(inContent('Giáo viên'), findsOneWidget);
        expect(inContent('Học sinh'), findsOneWidget);
        expect(inContent('Hoạt động'), findsNWidgets(2));
        expect(inContent('Đã khóa'), findsOneWidget);
        if (wide) {
          expect(table, findsOneWidget);
          expect(find.text('VAI TRÒ'), findsOneWidget);
          expect(find.text('TRẠNG THÁI'), findsOneWidget);
          // Backend không có "đăng nhập gần nhất" nên không có cột đó.
          expect(find.textContaining('ĐĂNG NHẬP'), findsNothing);
          expect(find.text('GIỚI TÍNH'), findsNothing);
        } else {
          expect(table, findsNothing);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('năm học (thẻ) ở $width, ${brightness.name}: '
          'không có bảng, không overflow', (tester) async {
        await _pump(
          tester,
          resource: 'years',
          width: width,
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('2026-2027'), findsOneWidget);
        expect(find.text('Mã: 1'), findsOneWidget);
        expect(find.byType(Card), findsWidgets);
        expect(find.byKey(const ValueKey('catalog-table-years')), findsNothing);
        expect(find.text('Thêm mới'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    for (final resource in ['students', 'teachers', 'accounts']) {
      testWidgets('$resource ở 1080 (bảng hẹp nhất), ${brightness.name}: '
          'không overflow', (tester) async {
        await _pump(
          tester,
          resource: resource,
          width: 1080,
          brightness: brightness,
        );
        expect(find.byKey(ValueKey('catalog-table-$resource')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('hộp thoại sửa học sinh dùng khung AppDialog, '
        '${brightness.name}', (tester) async {
      await _pump(
        tester,
        resource: 'students',
        width: 1280,
        brightness: brightness,
      );
      await tester.tap(find.text('Nguyễn Văn An'));
      await tester.pumpAndSettle();
      expect(find.text('Chỉnh sửa học sinh'), findsOneWidget);
      expect(find.text('Lưu'), findsOneWidget);
      expect(find.text('Đóng'), findsOneWidget);
      final box = find.byKey(const ValueKey('app-dialog-box'));
      expect(box, findsOneWidget);
      expect(_decorationColor(tester, box), _tokens(brightness).surface);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(box, findsNothing);
    });

    testWidgets('hộp thoại nhập file dùng khung AppDialog, '
        '${brightness.name}', (tester) async {
      await _pump(
        tester,
        resource: 'students',
        width: 1280,
        brightness: brightness,
      );
      await tester.tap(find.text('Nhập từ file'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập nhanh học sinh'), findsOneWidget);
      expect(find.text('Nhập 0 dòng'), findsOneWidget);
      expect(find.text('Tải file mẫu'), findsOneWidget);
      expect(find.text('Chọn Excel/CSV'), findsOneWidget);
      expect(find.byKey(const ValueKey('app-dialog-box')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('app-dialog-box')), findsNothing);
    });
  }
}
