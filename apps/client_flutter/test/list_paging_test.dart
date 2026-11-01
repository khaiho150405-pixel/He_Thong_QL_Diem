import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/app/widgets/app_list_footer.dart';
import 'package:client_flutter/core/progressive_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pageSlice cắt đúng trang và ép trang vào khoảng hợp lệ', () {
    final rows = List<int>.generate(25, (i) => i);
    expect(pageSlice(rows, 1, 10), rows.sublist(0, 10));
    expect(pageSlice(rows, 3, 10), rows.sublist(20, 25));
    expect(pageSlice(rows, 99, 10), rows.sublist(20, 25));
    expect(pageSlice(rows, 0, 10), rows.sublist(0, 10));
    expect(appPageCount(0, 10), 1);
    expect(appPageCount(25, 10), 3);
    expect(appPageSizes, [10, 30, 50]);
  });

  test(
    'ProgressiveLoader trả trang đầu ngay rồi nối các trang sau dưới nền',
    () async {
      var notified = 0;
      final loader = ProgressiveLoader<int, int>(onChanged: () => notified++);
      final pages = {
        null: const LoadedChunk<int, int>([1, 2], 1),
        1: const LoadedChunk<int, int>([3, 4], 2),
        2: const LoadedChunk<int, int>([5], null),
      };
      await loader.start('k', (cursor) async => pages[cursor]!);
      expect(loader.items, [1, 2]);
      expect(loader.loadingMore, isTrue);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(loader.items, [1, 2, 3, 4, 5]);
      expect(loader.loadingMore, isFalse);
      expect(loader.key, 'k');
      expect(notified, greaterThanOrEqualTo(2));
    },
  );

  test(
    'ProgressiveLoader: bắt đầu lần mới thì phần tải nền cũ bị bỏ',
    () async {
      final loader = ProgressiveLoader<int, int>(onChanged: () {});
      await loader.start(
        'a',
        (cursor) async => cursor == null
            ? const LoadedChunk([1], 1)
            : const LoadedChunk([2], null),
      );
      await loader.start('b', (cursor) async => const LoadedChunk([9], null));
      await Future<void>.delayed(Duration.zero);
      expect(loader.items, [9]);
      expect(loader.key, 'b');
    },
  );

  testWidgets('AppListFooter đổi cỡ trang và trang', (tester) async {
    int? size;
    int? page;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppListFooter(
            total: 95,
            page: 2,
            pageSize: 10,
            onPageChanged: (p) => page = p,
            onPageSizeChanged: (s) => size = s,
            loadingMore: true,
          ),
        ),
      ),
    );
    expect(find.textContaining('95 mục'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('app-list-footer-loading')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('app-pager-3')));
    expect(page, 3);
    await tester.tap(find.byKey(const ValueKey('app-page-size')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('30').last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(size, 30);
    expect(tester.takeException(), isNull);
  });
}
