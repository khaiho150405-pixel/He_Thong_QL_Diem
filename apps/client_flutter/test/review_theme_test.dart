import 'dart:io';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/app/widgets/app_badge.dart';
import 'package:client_flutter/app/widgets/app_progress.dart';
import 'package:client_flutter/app/widgets/stat_card.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recognition_review_screen_test.dart' show ReviewTestServer, evidenceRow;

/// Đủ các loại dòng: Xanh, Xanh lệch STT, Vàng (một kênh), Vàng lệch STT, Đỏ.
List<Map<String, dynamic>> _allKinds() => [
  {
    ...evidenceRow(
      level: 'XANH',
      matchLevel: 'XANH',
      gradeLevel: 'XANH',
      stt: 1,
      sttOnPaper: 1,
    ),
    'rowId': 'r-g',
    'order': 1,
    'studentName': 'Học sinh Xanh',
  },
  {
    ...evidenceRow(
      level: 'XANH',
      matchLevel: 'XANH',
      gradeLevel: 'XANH',
      stt: 2,
      sttOnPaper: 7,
    ),
    'rowId': 'r-gs',
    'order': 2,
    'studentName': 'Học sinh Xanh lệch STT',
  },
  {
    ...evidenceRow(
      level: 'VANG',
      matchLevel: 'XANH',
      gradeLevel: 'VANG',
      stt: 3,
      sttOnPaper: 3,
      comparison: 'MOT_KENH',
      suggestedSource: 'SO',
      numericValue: '7.0',
      writtenValue: null,
      writtenRaw: null,
      numericConfidence: '0.9000',
      writtenConfidence: '0.4000',
    ),
    'rowId': 'r-y',
    'order': 3,
    'studentName': 'Học sinh Vàng',
  },
  {
    ...evidenceRow(
      level: 'VANG',
      matchLevel: 'VANG',
      gradeLevel: 'XANH',
      stt: 4,
      sttOnPaper: 9,
    ),
    'rowId': 'r-ys',
    'order': 4,
    'studentName': 'Học sinh Vàng lệch STT',
  },
  {
    ...evidenceRow(
      level: 'DO',
      matchLevel: 'XANH',
      gradeLevel: 'DO',
      stt: 5,
      sttOnPaper: 5,
      comparison: 'LECH',
      numericValue: '9.0',
      writtenValue: '8.0',
      numericConfidence: '0.9100',
      writtenConfidence: '0.8800',
    ),
    'rowId': 'r-r',
    'order': 5,
    'studentName': 'Học sinh Đỏ',
  },
];

Future<void> _open(
  WidgetTester tester,
  ReviewTestServer server, {
  required Size size,
  required bool dark,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.platformBrightnessTestValue = dark
      ? Brightness.dark
      : Brightness.light;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final api = ApiClientDart(dio: Dio()..httpClientAdapter = server);
  final container = ProviderContainer(
    overrides: [apiProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);
  await tester.runAsync(
    () => container
        .read(sessionProvider.notifier)
        .login('0987654321', 'password'),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const GradebookApp(
        initialLocation: '/gradebooks/7/recognition/42',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Có hộp trang trí nền đúng màu token (dùng kiểm tra thanh tiêu đề dòng).
Finder _boxWithColor(Color color) => find.byWidgetPredicate(
  (w) =>
      w is DecoratedBox &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).color == color,
);

void main() {
  for (final dark in [false, true]) {
    final tokens = dark ? AppTokens.dark : AppTokens.light;
    final mode = dark ? 'tối' : 'sáng';

    for (final width in [1280.0, 1440.0]) {
      testWidgets('đối chiếu $mode ${width.toInt()} px: đủ dòng Xanh/Vàng/Đỏ/'
          'STT khác, không tràn, ảnh ô cắt có độ tin cậy', (tester) async {
        await _open(
          tester,
          ReviewTestServer(rowsOverride: _allKinds()),
          size: Size(width, 3200),
          dark: dark,
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('review-screen')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('review-source-image-column')),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.arrow_back), findsNothing);
        expect(find.text(' › Phiếu #42'), findsOneWidget);

        // Dải 3 chỉ số: StatCard Xanh / Vàng / Đỏ (số dòng của phiếu).
        expect(find.byType(StatCard), findsNWidgets(3));
        expect(
          tester.widgetList<StatCard>(find.byType(StatCard)).map((c) => c.tone),
          [StatTone.ok, StatTone.warn, StatTone.bad],
        );

        // Chip lọc giữ key và chữ cũ, có số đếm.
        for (final key in ['ALL', 'DO', 'VANG', 'XANH', 'STT_DIFF']) {
          expect(find.byKey(ValueKey(key)), findsOneWidget);
        }
        expect(find.text('Tất cả (3)'), findsOneWidget);
        expect(find.text('⇄ STT khác: 2'), findsOneWidget);

        // Thanh tiêu đề dòng đổi màu theo mức bằng token.
        expect(_boxWithColor(tokens.badSoft), findsWidgets);
        expect(_boxWithColor(tokens.warnSoft), findsWidgets);
        expect(find.byType(AppBadge), findsWidgets);

        // Bất biến 3: ảnh ô cắt Điểm số/Điểm chữ + giá trị máy đọc + độ tin cậy.
        expect(find.text('Điểm số'), findsWidgets);
        expect(find.text('Điểm chữ'), findsWidgets);
        expect(find.byType(AppConfidenceBar), findsWidgets);
        expect(find.text('91%'), findsOneWidget);
        expect(find.text('88%'), findsOneWidget);
        expect(find.text('90%'), findsOneWidget);
        expect(find.text('40%'), findsOneWidget);
        expect(find.text('Máy đọc: 9.0'), findsOneWidget);
        expect(find.text('Máy đọc: 8.0'), findsOneWidget);
        expect(find.text('Máy không đọc được'), findsOneWidget);

        // Vẫn không lộ nhãn bị cấm.
        expect(find.textContaining('Độ tin cậy'), findsNothing);
        expect(find.textContaining('Ký tự thô'), findsNothing);
        expect(find.textContaining('Lấy theo'), findsNothing);

        // Thanh dính đáy: tiến độ + ô xác nhận + nút Duyệt giữ key và chuỗi.
        expect(find.textContaining('Đã xử lý 1/4'), findsOneWidget);
        expect(find.byType(AppProgress), findsOneWidget);
        expect(
          find.byKey(const ValueKey('review-confirm-all')),
          findsOneWidget,
        );
        expect(find.text('Duyệt phiếu (5 dòng)'), findsOneWidget);
        final approve = tester.widget<FilledButton>(
          find.byKey(const ValueKey('review-approve')),
        );
        expect(approve.onPressed, isNull);

        // Nhóm Xanh gập: header dùng nền ok-soft của token. Ở 1280 px các
        // dòng xếp dọc nên nhóm nằm sâu trong danh sách, cuộn tới trước.
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('review-green-group')),
          600,
          scrollable: find
              .descendant(
                of: find.byWidgetPredicate(
                  (w) => w is ListView && w.cacheExtent == 5000,
                ),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        final group = tester.widget<ExpansionTile>(
          find.byKey(const ValueKey('review-green-group')),
        );
        expect(group.collapsedBackgroundColor, tokens.okSoft);
        await tester.tap(find.byKey(const ValueKey('review-green-group')));
        await tester.pumpAndSettle();
        expect(find.text('Học sinh Xanh'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    for (final width in [320.0, 390.0]) {
      testWidgets(
        'đối chiếu $mode ${width.toInt()} px: PageView, chấm tiến độ, '
        'ảnh ô cắt có độ tin cậy, không tràn',
        (tester) async {
          await _open(
            tester,
            ReviewTestServer(rowsOverride: _allKinds()),
            size: Size(width, 900),
            dark: dark,
            textScale: 1.3,
          );
          expect(tester.takeException(), isNull);
          expect(find.byType(PageView), findsOneWidget);
          expect(find.byIcon(Icons.arrow_back), findsOneWidget);
          expect(find.byTooltip('Quay lại bảng điểm'), findsOneWidget);
          expect(find.text(' › Phiếu #42'), findsNothing);
          expect(
            find.byKey(const ValueKey('review-pager-dots')),
            findsOneWidget,
          );
          expect(find.textContaining('Dòng 1 / 4'), findsOneWidget);

          // Trang đầu là dòng Đỏ: ảnh Điểm số/Điểm chữ + độ tin cậy từng kênh.
          expect(find.text('Điểm số'), findsOneWidget);
          expect(find.text('Điểm chữ'), findsOneWidget);
          expect(find.text('91%'), findsOneWidget);
          expect(find.text('88%'), findsOneWidget);
          expect(find.text('Máy đọc: 9.0'), findsOneWidget);
          expect(find.text('Máy đọc: 8.0'), findsOneWidget);
          expect(find.byType(AppConfidenceBar), findsNWidgets(2));
          expect(_boxWithColor(tokens.badSoft), findsWidgets);
          expect(find.text('Tiếp ›'), findsOneWidget);

          // Sang chế độ danh sách: dải chỉ số gọn + thanh dính đáy có tiến độ.
          await tester.tap(find.text('Danh sách'));
          await tester.pumpAndSettle();
          expect(find.byType(StatCard), findsNothing);
          for (final label in ['Xanh', 'Vàng', 'Đỏ']) {
            expect(find.text(label), findsWidgets);
          }
          expect(find.textContaining('Đã xử lý 1/4'), findsOneWidget);
          expect(find.byKey(const ValueKey('review-approve')), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('đối chiếu $mode: chế độ chỉ xem (DA_DUYET) vẫn hiện ảnh ô cắt '
        'và độ tin cậy, không có ô nhập/nút duyệt', (tester) async {
      await _open(
        tester,
        ReviewTestServer(ticketStatus: 'DA_DUYET', rowsOverride: _allKinds()),
        size: const Size(1280, 3200),
        dark: dark,
      );
      expect(tester.takeException(), isNull);

      // Banner chỉ xem dùng màu ok của token.
      expect(find.text('Phiếu đã duyệt — chỉ xem'), findsOneWidget);
      final title = tester.widget<Text>(find.text('Phiếu đã duyệt — chỉ xem'));
      expect(title.style?.color, tokens.ok);

      // Không có ô nhập, nút Đồng ý, menu ⋮, thanh duyệt.
      expect(find.byKey(const ValueKey('review-value-r-r')), findsNothing);
      expect(find.byKey(const ValueKey('review-agree-r-y')), findsNothing);
      expect(find.byKey(const ValueKey('review-menu-r-r')), findsNothing);
      expect(find.byKey(const ValueKey('review-confirm-all')), findsNothing);
      expect(find.byKey(const ValueKey('review-approve')), findsNothing);
      expect(find.byType(AppProgress), findsNothing);

      // Bất biến 3 vẫn đúng khi chỉ xem.
      expect(find.text('Điểm số'), findsWidgets);
      expect(find.text('Điểm chữ'), findsWidgets);
      expect(find.byType(AppConfidenceBar), findsWidgets);
      expect(find.text('91%'), findsOneWidget);
      expect(find.text('Điểm đã ghi'), findsWidgets);
    });

    testWidgets('đối chiếu $mode: nhập điểm dòng Đỏ cập nhật tiến độ và mở '
        'nút Duyệt như cũ', (tester) async {
      await _open(
        tester,
        ReviewTestServer(
          rowsOverride: [
            {
              ...evidenceRow(
                level: 'DO',
                matchLevel: 'XANH',
                gradeLevel: 'DO',
                comparison: 'LECH',
                numericValue: '9.0',
                writtenValue: '8.0',
              ),
              'rowId': 'r-1',
            },
          ],
        ),
        size: const Size(1280, 1600),
        dark: dark,
      );
      expect(find.text('Đã xử lý 0/1'), findsOneWidget);
      FilledButton approve() => tester.widget<FilledButton>(
        find.byKey(const ValueKey('review-approve')),
      );
      await tester.tap(find.byKey(const ValueKey('review-confirm-all')));
      await tester.pumpAndSettle();
      expect(approve().onPressed, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('review-value-r-1')),
        '8.5',
      );
      await tester.pumpAndSettle();
      expect(find.text('Đã xử lý 1/1'), findsOneWidget);
      expect(approve().onPressed, isNotNull);
    });
  }

  test(
    'các file màn đối chiếu không còn màu cứng ngoài Colors.transparent',
    () {
      final files = [
        File('lib/features/recognition/review_screen.dart'),
        ...Directory(
          'lib/features/recognition/review',
        ).listSync().whereType<File>().where((f) => f.path.endsWith('.dart')),
      ];
      expect(files.length, greaterThan(8));
      for (final file in files) {
        final source = file.readAsStringSync();
        final bad = RegExp(
          r'Colors\.(?!transparent)\w+|Color\(0x|AppTheme\.\w*[Cc]olor',
        );
        expect(
          bad.allMatches(source).map((m) => m.group(0)).toList(),
          isEmpty,
          reason: file.path,
        );
      }
    },
  );
}
