import 'package:client_flutter/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'phase2_gradebooks_test.dart';

Future<void> pumpLogin(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, width >= 960 ? 900 : 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    const ProviderScope(child: GradebookApp(initialLocation: '/login')),
  );
  await tester.pumpAndSettle();
}

List<Map<String, dynamic>> gradeCells(int components, {int students = 2}) => [
  for (var s = 1; s <= students; s++)
    for (var c = 1; c <= components; c++)
      {
        'id': '${s}0$c',
        'studentId': 100 + s,
        'studentName': 'Học sinh $s',
        'stt': s,
        'active': true,
        'componentId': 200 + c,
        'componentName': 'Cột $c',
        'coefficient': '1.0',
        'required': false,
        'displayOrder': c,
        'value': '7.0',
        'status': 'DA_DUYET',
        'source': 'NHAP_TAY',
      },
];

void main() {
  group('tờ giấy minh họa ở màn đăng nhập', () {
    testWidgets('điểm chữ không có "phẩy", điểm số có một chữ số thập phân', (
      tester,
    ) async {
      await pumpLogin(tester, 1440);

      expect(find.textContaining('phẩy'), findsNothing);
      expect(find.text('8.5'), findsOneWidget);
      expect(find.text('7.0'), findsOneWidget);
      expect(find.text('6.5'), findsOneWidget);
      expect(find.text('tám năm'), findsOneWidget);
      expect(find.text('bảy không'), findsOneWidget);
      expect(find.text('sáu năm'), findsOneWidget);
      // Cột điểm số đủ rộng cho "7.0": không xuống dòng, không tràn.
      final seven = tester.getSize(find.text('7.0'));
      expect(seven.height, lessThan(30));
      expect(tester.takeException(), isNull);
    });
  });

  group('nút ở màn đăng nhập rộng bằng cột form', () {
    for (final width in <double>[390, 960, 1440]) {
      testWidgets('${width.toInt()}px', (tester) async {
        await pumpLogin(tester, width);

        final field = tester.getSize(
          find.widgetWithText(TextFormField, 'Tên đăng nhập'),
        );
        final login = tester.getSize(find.byType(FilledButton));
        final check = tester.getSize(find.byType(OutlinedButton));

        expect(login.width, closeTo(field.width, 0.5));
        expect(check.width, closeTo(field.width, 0.5));
        expect(login.width, lessThanOrEqualTo(380));
        expect(login.height, greaterThanOrEqualTo(48));
        expect(check.height, greaterThanOrEqualTo(48));
        // Nút nằm đúng dưới ô nhập, không lệch trái.
        expect(
          tester.getTopLeft(find.byType(FilledButton)).dx,
          closeTo(
            tester
                .getTopLeft(find.widgetWithText(TextFormField, 'Tên đăng nhập'))
                .dx,
            0.5,
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('màn rộng: tiêu đề vẫn căn trái', (tester) async {
      await pumpLogin(tester, 1440);
      final title = tester.getTopLeft(find.text('Đăng nhập').first).dx;
      final field = tester.getTopLeft(
        find.widgetWithText(TextFormField, 'Tên đăng nhập'),
      );
      expect(title, closeTo(field.dx, 1));
    });
  });

  group('lưới nhập điểm kéo giãn hết khung', () {
    // 1024 có sidebar nên vùng nội dung < 800 và dùng thẻ (xem test riêng).
    for (final width in <double>[800, 1280, 1440]) {
      for (final columns in <int>[1, 3, 6]) {
        testWidgets('${width.toInt()}px, $columns cột điểm', (tester) async {
          final server = GradebookFakeServer()
            ..customCellItems = gradeCells(columns);
          final container = await pumpGradebooks(tester, server, width: width);
          addTearDown(container.dispose);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.tap(find.textContaining('10A1'));
          await tester.pumpAndSettle();

          expect(find.byType(DataTable), findsOneWidget);
          final form = tester.getSize(find.byType(Form)).width;
          final table = tester.getSize(find.byType(DataTable)).width;
          // Đủ chỗ: bảng chiếm hết khung (trừ lề 16 hai bên), không để trống.
          // Không đủ chỗ: giữ độ rộng gốc của các cột và cuộn ngang.
          final natural = 32 + 20 * (columns + 1) + 40 + 190 + 170.0 * columns;
          final expected = natural > form - 32 ? natural : form - 32;
          expect(table, closeTo(expected, 2));
          if (natural <= form - 32) {
            expect(table, closeTo(form - 32, 2));
          }
          // Ô nhập đầu tiên vẫn tìm được theo key cũ.
          expect(find.byKey(const ValueKey('grade-101')), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('1024px có sidebar: dùng thẻ, không lỗi bố cục', (
      tester,
    ) async {
      final server = GradebookFakeServer()..customCellItems = gradeCells(3);
      final container = await pumpGradebooks(tester, server, width: 1024);
      addTearDown(container.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.tap(find.textContaining('10A1'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('grade-101')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('quá nhiều cột thì giữ cuộn ngang, không co lại', (
      tester,
    ) async {
      final server = GradebookFakeServer()..customCellItems = gradeCells(10);
      final container = await pumpGradebooks(tester, server, width: 1280);
      addTearDown(container.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.tap(find.textContaining('10A1'));
      await tester.pumpAndSettle();

      final form = tester.getSize(find.byType(Form)).width;
      final table = tester.getSize(find.byType(DataTable)).width;
      expect(table, greaterThan(form));
      expect(tester.takeException(), isNull);
    });
  });
}
