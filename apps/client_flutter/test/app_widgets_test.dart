import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/app/widgets/app_avatar.dart';
import 'package:client_flutter/app/widgets/app_badge.dart';
import 'package:client_flutter/app/widgets/app_charts.dart';
import 'package:client_flutter/app/widgets/app_dialog.dart';
import 'package:client_flutter/app/widgets/app_pager.dart';
import 'package:client_flutter/app/widgets/app_progress.dart';
import 'package:client_flutter/app/widgets/app_tabs.dart';
import 'package:client_flutter/app/widgets/grade_cell.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  ThemeData theme,
  Widget child, {
  Size size = const Size(320, 700),
  double textScale = 1.5,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  );
}

Color _decorationColor(WidgetTester tester, Finder finder) {
  final box = tester.widget<DecoratedBox>(finder);
  return (box.decoration as BoxDecoration).color!;
}

Border _decorationBorder(WidgetTester tester, Finder finder) {
  final box = tester.widget<DecoratedBox>(finder);
  return (box.decoration as BoxDecoration).border! as Border;
}

void main() {
  final modes = <String, (ThemeData, AppTokens)>{
    'light': (AppTheme.light(), AppTokens.light),
    'dark': (AppTheme.dark(), AppTokens.dark),
  };

  final controller = TextEditingController(text: '8.5');
  tearDownAll(controller.dispose);

  final gallery = <String, Widget Function()>{
    'AppBadge': () => const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        AppBadge.ok('Đã duyệt'),
        AppBadge.warn('Cần xem lại'),
        AppBadge.bad('Không đọc được'),
        AppBadge.info('Đang nhập liệu'),
        AppBadge('Trung tính'),
        AppBadge('Không chấm', dot: false),
        AppBadge.info('Một nhãn rất rất dài để thử cắt chữ ở màn hẹp 320'),
      ],
    ),
    'AppProgress + AppConfidenceBar': () => const Column(
      children: [
        AppProgress(value: 0.4),
        SizedBox(height: 8),
        AppProgress(value: 1, tone: AppProgressTone.ok),
        SizedBox(height: 8),
        AppProgress(value: 0.7, tone: AppProgressTone.warn),
        SizedBox(height: 8),
        AppConfidenceBar(value: 0.9),
        SizedBox(height: 8),
        AppConfidenceBar(value: 0.7),
        SizedBox(height: 8),
        AppConfidenceBar(value: 0.2),
      ],
    ),
    'AppAvatar': () => const Wrap(
      spacing: 8,
      children: [
        AppAvatar(name: 'Nguyễn Thị Lan', size: AppAvatarSize.sm),
        AppAvatar(name: 'Hồ Gia Bảo'),
        AppAvatar(name: 'Quản trị', size: AppAvatarSize.lg),
      ],
    ),
    'AppTabs': () => AppTabs(
      tabs: const [
        AppTabItem(label: 'Cần xem', count: 7),
        AppTabItem(label: 'Vàng', count: 4),
        AppTabItem(label: 'Đỏ', count: 3),
        AppTabItem(label: 'Tất cả'),
      ],
      selectedIndex: 1,
      onChanged: (_) {},
    ),
    'AppPager': () => AppPager(page: 4, pageCount: 20, onChanged: (_) {}),
    'AppLineChart': () => const AppLineChart(
      labels: ['HK1 lớp 9', 'HK2 lớp 9', 'HK1 lớp 10'],
      values: [8.1, 8.3, 8.6],
      min: 6,
      max: 10,
      height: 200,
    ),
    'AppHBars': () => const AppHBars(
      max: 8,
      items: [
        AppHBarItem(label: 'Giỏi', value: 6),
        AppHBarItem(label: 'Khá', value: 4),
        AppHBarItem(label: 'Chưa đạt', value: 1, valueText: '1 em'),
      ],
    ),
    'AppGradeCell (desktop + mobile, đủ trạng thái)': () => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        AppGradeCell(controller: controller),
        AppGradeCell(controller: controller, isChanged: true),
        AppGradeCell(controller: controller, fromImage: true),
        AppGradeCell(controller: controller, isInvalid: true),
        AppGradeCell(controller: controller, readOnly: true),
        AppGradeCell(controller: controller, mobile: true),
        AppGradeCell(controller: controller, mobile: true, isChanged: true),
      ],
    ),
  };

  for (final mode in modes.entries) {
    group('render ở chế độ ${mode.key}, 320px, chữ 150%', () {
      for (final entry in gallery.entries) {
        testWidgets(entry.key, (tester) async {
          await _pump(tester, mode.value.$1, entry.value());
          await tester.pump();
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('AppDialog (thường và danger)', (tester) async {
        for (final danger in [false, true]) {
          await _pump(
            tester,
            mode.value.$1,
            Builder(
              builder: (context) => FilledButton(
                onPressed: () => showAppDialog<bool>(
                  context: context,
                  builder: (_) => AppDialog(
                    title: 'Xóa bảng điểm này khỏi hệ thống?',
                    confirmLabel: 'Xóa',
                    danger: danger,
                    child: const Text(
                      'Nội dung hộp thoại đủ dài để xuống dòng.',
                    ),
                  ),
                ),
                child: const Text('Mở'),
              ),
            ),
          );
          await tester.tap(find.text('Mở'));
          await tester.pumpAndSettle();
          expect(find.byType(AppDialog), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byKey(const ValueKey('app-dialog-cancel')));
          await tester.pumpAndSettle();
        }
      });
    });
  }

  for (final mode in modes.entries) {
    final theme = mode.value.$1;
    final tk = mode.value.$2;

    group('giá trị màu ở chế độ ${mode.key}', () {
      testWidgets('AppBadge lấy màu từ token', (tester) async {
        await _pump(
          tester,
          theme,
          const Column(
            children: [
              AppBadge.ok('ok'),
              AppBadge.warn('warn'),
              AppBadge.bad('bad'),
              AppBadge.info('info'),
              AppBadge('neu'),
            ],
          ),
          textScale: 1,
        );
        Finder box(String label) => find
            .ancestor(of: find.text(label), matching: find.byType(DecoratedBox))
            .first;
        expect(_decorationColor(tester, box('ok')), tk.okSoft);
        expect(_decorationColor(tester, box('warn')), tk.warnSoft);
        expect(_decorationColor(tester, box('bad')), tk.badSoft);
        expect(_decorationColor(tester, box('info')), tk.priSoft);
        expect(_decorationColor(tester, box('neu')), tk.neuSoft);
        expect(_decorationBorder(tester, box('ok')).top.color, tk.okLine);
        expect(_decorationBorder(tester, box('info')).top.color, tk.priLine);
        expect(tester.widget<Text>(find.text('ok')).style!.color, tk.ok);
        expect(tester.widget<Text>(find.text('info')).style!.color, tk.priLink);
        expect(tester.widget<Text>(find.text('ok')).style!.fontSize, 12);
        // 5 chấm tròn; tắt chấm thì không còn.
        expect(find.byKey(const ValueKey('app-badge-dot')), findsNWidgets(5));
      });

      testWidgets('AppBadge nodot không có chấm', (tester) async {
        await _pump(tester, theme, const AppBadge.ok('x', dot: false));
        expect(find.byKey(const ValueKey('app-badge-dot')), findsNothing);
      });

      testWidgets('AppProgress và AppConfidenceBar: chiều cao, màu, ngưỡng', (
        tester,
      ) async {
        await _pump(
          tester,
          theme,
          const Column(
            children: [
              AppProgress(value: 0.5),
              AppProgress(value: 0.5, tone: AppProgressTone.ok),
              AppProgress(value: 0.5, tone: AppProgressTone.warn),
              AppConfidenceBar(value: 0.85),
              AppConfidenceBar(value: 0.6),
              AppConfidenceBar(value: 0.59),
            ],
          ),
          textScale: 1,
        );
        final fills = find.byKey(const ValueKey('app-progress-fill'));
        Color fill(int i) => _decorationColor(tester, fills.at(i));
        expect(fill(0), tk.pri);
        expect(fill(1), tk.ok);
        expect(fill(2), tk.acc);
        expect(fill(3), tk.ok);
        expect(fill(4), tk.acc);
        expect(fill(5), tk.bad);
        expect(tester.getSize(find.byType(AppProgress).first).height, 8);
        expect(tester.getSize(find.byType(AppConfidenceBar).first).height, 5);
        expect(
          tester.getSize(fills.at(0)).width,
          closeTo(
            tester.getSize(find.byType(AppProgress).first).width / 2,
            0.01,
          ),
        );
      });

      testWidgets('AppAvatar: cỡ, chữ cái đầu, màu', (tester) async {
        await _pump(
          tester,
          theme,
          const Wrap(
            children: [
              AppAvatar(name: 'Nguyễn Thị Lan', size: AppAvatarSize.sm),
              AppAvatar(name: 'Hồ Gia Bảo'),
              AppAvatar(name: 'Quản trị', size: AppAvatarSize.lg),
            ],
          ),
          textScale: 1,
        );
        expect(find.text('NL'), findsOneWidget);
        expect(find.text('HB'), findsOneWidget);
        expect(find.text('QT'), findsOneWidget);
        final sizes = tester
            .widgetList<AppAvatar>(find.byType(AppAvatar))
            .map((a) => tester.getSize(find.byWidget(a)))
            .toList();
        expect(sizes, const [Size(30, 30), Size(36, 36), Size(56, 56)]);
        final box = find
            .descendant(
              of: find.byType(AppAvatar).at(1),
              matching: find.byType(DecoratedBox),
            )
            .first;
        expect(_decorationColor(tester, box), tk.priSoft);
        expect(_decorationBorder(tester, box).top.color, tk.priLine);
        expect(AppAvatar.initialsOf('  lan  '), 'L');
        expect(AppAvatar.initialsOf(''), '');
      });

      testWidgets('AppTabs: gạch chân pri khi chọn, chip đếm, gọi onChanged', (
        tester,
      ) async {
        int? picked;
        await _pump(
          tester,
          theme,
          AppTabs(
            tabs: const [
              AppTabItem(label: 'Cần xem', count: 7),
              AppTabItem(label: 'Tất cả'),
            ],
            selectedIndex: 0,
            onChanged: (i) => picked = i,
          ),
          textScale: 1,
        );
        final sel = _decorationBorder(
          tester,
          find.byKey(const ValueKey('app-tab-box-0')),
        );
        final unsel = _decorationBorder(
          tester,
          find.byKey(const ValueKey('app-tab-box-1')),
        );
        expect(sel.bottom.color, tk.pri);
        expect(sel.bottom.width, 2);
        expect(unsel.bottom.color, Colors.transparent);
        expect(find.text('7'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('app-tab-1')));
        expect(picked, 1);
      });

      testWidgets('AppPager: chữ trang, nút chọn nền pri, onChanged', (
        tester,
      ) async {
        int? picked;
        await _pump(
          tester,
          theme,
          AppPager(page: 2, pageCount: 5, onChanged: (p) => picked = p),
          textScale: 1,
        );
        expect(find.text('Trang 2 / 5'), findsOneWidget);
        final selectedMaterial = tester.widget<Material>(
          find
              .descendant(
                of: find.byKey(const ValueKey('app-pager-2')),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(selectedMaterial.color, tk.pri);
        final otherMaterial = tester.widget<Material>(
          find
              .descendant(
                of: find.byKey(const ValueKey('app-pager-3')),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(otherMaterial.color, tk.surface);
        await tester.tap(find.byKey(const ValueKey('app-pager-3')));
        expect(picked, 3);
        await tester.tap(find.byKey(const ValueKey('app-pager-next')));
        expect(picked, 3);
        await tester.tap(find.byKey(const ValueKey('app-pager-prev')));
        expect(picked, 1);
      });

      testWidgets('AppDialog: rộng tối đa 520, danger đổi màu nút chính', (
        tester,
      ) async {
        bool? result;
        Future<void> open(bool danger) async {
          await _pump(
            tester,
            theme,
            Builder(
              builder: (context) => TextButton(
                onPressed: () async => result = await showAppDialog<bool>(
                  context: context,
                  builder: (_) => AppDialog(
                    title: 'Xác nhận',
                    confirmLabel: 'Đồng ý',
                    danger: danger,
                    child: const Text('Nội dung'),
                  ),
                ),
                child: const Text('Mở'),
              ),
            ),
            size: const Size(1200, 800),
            textScale: 1,
          );
          await tester.tap(find.text('Mở'));
          await tester.pumpAndSettle();
        }

        await open(false);
        final boxFinder = find.byKey(const ValueKey('app-dialog-box'));
        expect(tester.getSize(boxFinder).width, 520);
        final decoration =
            tester.widget<DecoratedBox>(boxFinder).decoration as BoxDecoration;
        expect(decoration.color, tk.surface);
        expect(decoration.borderRadius, BorderRadius.circular(AppRadius.lg));
        expect(
          _decorationColor(
            tester,
            find.byKey(const ValueKey('app-dialog-footer')),
          ),
          tk.subtle,
        );
        final normalStyle = tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('app-dialog-confirm')),
            )
            .style;
        expect(normalStyle, isNull);
        await tester.tap(find.byKey(const ValueKey('app-dialog-confirm')));
        await tester.pumpAndSettle();
        expect(result, isTrue);

        await open(true);
        final dangerButton = tester.widget<FilledButton>(
          find.byKey(const ValueKey('app-dialog-confirm')),
        );
        expect(dangerButton.style!.backgroundColor!.resolve({}), tk.bad);
        await tester.tap(find.byKey(const ValueKey('app-dialog-close')));
        await tester.pumpAndSettle();
        expect(result, isFalse);
        expect(find.byType(AppDialog), findsNothing);
      });

      testWidgets('AppHBars: màu mặc định pri, tỉ lệ theo max', (tester) async {
        await _pump(
          tester,
          theme,
          const AppHBars(
            max: 10,
            items: [
              AppHBarItem(label: 'Giỏi', value: 5),
              AppHBarItem(label: 'Khá', value: 10, valueText: '10 em'),
            ],
          ),
          textScale: 1,
        );
        final fill0 = find.byKey(const ValueKey('app-hbar-fill-0'));
        final fill1 = find.byKey(const ValueKey('app-hbar-fill-1'));
        expect(_decorationColor(tester, fill0), tk.pri);
        expect(
          tester.getSize(fill0).width,
          closeTo(tester.getSize(fill1).width / 2, 0.01),
        );
        expect(tester.getSize(fill0).height, 16);
        expect(find.text('5'), findsOneWidget);
        expect(find.text('10 em'), findsOneWidget);
      });

      testWidgets('AppLineChart: tooltip theo hover chuột và chạm', (
        tester,
      ) async {
        await _pump(
          tester,
          theme,
          const AppLineChart(
            labels: ['T8', 'T9', 'T10'],
            values: [7.1, 7.3, 7.4],
            min: 6,
            max: 8,
            height: 200,
          ),
          textScale: 1,
        );
        final chart = find.byKey(const ValueKey('app-line-chart'));
        AppLineChartPainter painter() =>
            tester.widget<CustomPaint>(chart).painter! as AppLineChartPainter;
        expect(painter().hoverIndex, isNull);
        expect(painter().tokens.navy, tk.navy);

        final origin = tester.getTopLeft(chart);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: origin + const Offset(5, 100));
        await mouse.moveTo(origin + const Offset(5, 100));
        await tester.pump();
        expect(painter().hoverIndex, 0);
        await mouse.moveTo(origin + const Offset(270, 100));
        await tester.pump();
        expect(painter().hoverIndex, 2);
        await mouse.moveTo(const Offset(1, 690));
        await tester.pump();
        expect(painter().hoverIndex, isNull);

        final touch = await tester.startGesture(
          origin + const Offset(150, 100),
        );
        await tester.pump();
        expect(painter().hoverIndex, 1);
        await touch.up();
        await tester.pump();
        expect(painter().hoverIndex, isNull);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'AppLineChart: không lỗi với dữ liệu rỗng, 1 điểm, max<=min',
        (tester) async {
          for (final chart in [
            const AppLineChart(labels: [], values: []),
            const AppLineChart(labels: ['T8'], values: [7]),
            const AppLineChart(
              labels: ['a', 'b'],
              values: [1, 2],
              min: 5,
              max: 5,
            ),
            const AppLineChart(labels: ['a', 'b', 'c'], values: [1]),
          ]) {
            await _pump(tester, theme, chart, textScale: 1);
            expect(tester.takeException(), isNull);
          }
        },
      );

      testWidgets('AppGradeCell: kích thước và trạng thái', (tester) async {
        final c = TextEditingController(text: '7.5');
        addTearDown(c.dispose);
        final changed = <String>[];
        await _pump(
          tester,
          theme,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppGradeCell(
                key: const ValueKey('normal'),
                controller: c,
                onChanged: changed.add,
              ),
              AppGradeCell(
                key: const ValueKey('changed'),
                controller: c,
                isChanged: true,
              ),
              AppGradeCell(
                key: const ValueKey('image'),
                controller: c,
                fromImage: true,
              ),
              AppGradeCell(
                key: const ValueKey('invalid'),
                controller: c,
                isInvalid: true,
              ),
              AppGradeCell(
                key: const ValueKey('readonly'),
                controller: c,
                readOnly: true,
              ),
              AppGradeCell(
                key: const ValueKey('mobile'),
                controller: c,
                mobile: true,
              ),
            ],
          ),
          size: const Size(800, 600),
          textScale: 1,
        );
        Finder boxOf(String k) => find.descendant(
          of: find.byKey(ValueKey(k)),
          matching: find.byKey(const ValueKey('app-grade-cell-box')),
        );
        expect(
          tester.getSize(find.byKey(const ValueKey('normal'))),
          const Size(64, 36),
        );
        expect(
          tester.getSize(find.byKey(const ValueKey('mobile'))),
          const Size(80, 48),
        );

        expect(_decorationColor(tester, boxOf('normal')), Colors.transparent);
        expect(_decorationColor(tester, boxOf('changed')), tk.accSoft);
        expect(
          _decorationBorder(tester, boxOf('changed')).top.color,
          tk.warnLine,
        );
        expect(_decorationColor(tester, boxOf('invalid')), tk.badSoft);
        expect(_decorationBorder(tester, boxOf('invalid')).top.color, tk.bad);
        expect(_decorationColor(tester, boxOf('mobile')), tk.subtle);
        expect(_decorationBorder(tester, boxOf('mobile')).top.color, tk.line2);

        // Chấm "nhập từ ảnh" chỉ có ở ô fromImage, màu ok.
        final dot = find.byKey(const ValueKey('app-grade-cell-image-dot'));
        expect(dot, findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('image')),
            matching: dot,
          ),
          findsOneWidget,
        );
        expect(_decorationColor(tester, dot), tk.ok);

        // Chỉ đọc: TextField readOnly; ô thường vẫn gõ được và báo onChanged.
        final readOnlyField = find.descendant(
          of: find.byKey(const ValueKey('readonly')),
          matching: find.byType(TextField),
        );
        expect(tester.widget<TextField>(readOnlyField).readOnly, isTrue);
        await tester.enterText(
          find.descendant(
            of: find.byKey(const ValueKey('normal')),
            matching: find.byType(TextField),
          ),
          '9',
        );
        expect(changed, ['9']);
      });

      testWidgets('AppGradeCell: không tự validate giá trị', (tester) async {
        final c = TextEditingController(text: '99');
        addTearDown(c.dispose);
        await _pump(tester, theme, AppGradeCell(controller: c), textScale: 1);
        // Giá trị ngoài 0..10 vẫn hiển thị bình thường; cờ isInvalid do màn cha.
        expect(
          _decorationColor(
            tester,
            find.byKey(const ValueKey('app-grade-cell-box')),
          ),
          Colors.transparent,
        );
        expect(find.text('99'), findsOneWidget);
      });
    });
  }

  test('AppPager.pagesToShow rút gọn bằng dấu …', () {
    expect(AppPager.pagesToShow(1, 5, 7), [1, 2, 3, 4, 5]);
    expect(AppPager.pagesToShow(1, 20, 7), [1, 2, 3, 4, 5, 6, null, 20]);
    expect(AppPager.pagesToShow(10, 20, 7), [
      1,
      null,
      8,
      9,
      10,
      11,
      12,
      null,
      20,
    ]);
    expect(AppPager.pagesToShow(20, 20, 7), [1, null, 15, 16, 17, 18, 19, 20]);
  });
}
