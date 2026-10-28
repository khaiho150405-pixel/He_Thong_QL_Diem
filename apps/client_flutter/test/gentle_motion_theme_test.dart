import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/app/page_transitions.dart';
import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/features/connection/connection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _buildTransition({required bool disableAnimations}) {
  final route = MaterialPageRoute<void>(builder: (_) => const SizedBox());
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Builder(
      builder: (context) =>
          const GentleFadePageTransitionsBuilder().buildTransitions<void>(
            route,
            context,
            const AlwaysStoppedAnimation<double>(0.5),
            const AlwaysStoppedAnimation<double>(0),
            const Text('trang mới', textDirection: TextDirection.ltr),
          ),
    ),
  );
}

/// Widget zoom/scale bọc quanh nội dung trang: `ScaleTransition` hoặc các
/// widget `_Zoom...` của `ZoomPageTransitionsBuilder`. Các ScaleTransition nội
/// bộ khác (ví dụ của Scaffold) không bọc nội dung nên không bị tính.
Finder _scaleAboveText(String text) => find.ancestor(
  of: find.text(text),
  matching: find.byWidgetPredicate(
    (w) => w is ScaleTransition || w.runtimeType.toString().contains('Zoom'),
  ),
);

void main() {
  group('PageTransitionsTheme', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      test('${theme.brightness}: mọi nền tảng dùng chuyển trang mờ dần', () {
        final builders = theme.pageTransitionsTheme.builders;
        for (final platform in TargetPlatform.values) {
          expect(
            builders[platform],
            isA<GentleFadePageTransitionsBuilder>(),
            reason: '$platform',
          );
        }
        expect(
          builders.values.whereType<ZoomPageTransitionsBuilder>(),
          isEmpty,
        );
        expect(
          builders.values.whereType<CupertinoPageTransitionsBuilder>(),
          isEmpty,
        );
      });
    }

    test('thời lượng ngắn, trong khoảng 200-250 ms', () {
      const builder = GentleFadePageTransitionsBuilder();
      expect(
        builder.transitionDuration.inMilliseconds,
        inInclusiveRange(200, 250),
      );
      expect(
        builder.reverseTransitionDuration.inMilliseconds,
        inInclusiveRange(200, 250),
      );
    });
  });

  group('GentleFadePageTransitionsBuilder', () {
    testWidgets('chỉ có FadeTransition, không scale/slide', (tester) async {
      await tester.pumpWidget(_buildTransition(disableAnimations: false));
      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(ScaleTransition), findsNothing);
      expect(find.byType(SlideTransition), findsNothing);
      expect(find.byType(RotationTransition), findsNothing);
      expect(find.text('trang mới'), findsOneWidget);
    });

    testWidgets('giảm chuyển động của hệ điều hành: không có hiệu ứng', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTransition(disableAnimations: true));
      expect(find.byType(FadeTransition), findsNothing);
      expect(find.byType(ScaleTransition), findsNothing);
      expect(find.byType(SlideTransition), findsNothing);
      expect(find.text('trang mới'), findsOneWidget);
    });
  });

  group('điều hướng thật', () {
    testWidgets('đối chứng: theme mặc định của Material có ScaleTransition', (
      tester,
    ) async {
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          theme: ThemeData(),
          home: const Scaffold(body: Text('trang một')),
        ),
      );
      key.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('trang hai')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_scaleAboveText('trang hai'), findsWidgets);
      await tester.pumpAndSettle();
    });

    testWidgets('AppTheme: đi giữa hai trang không có ScaleTransition', (
      tester,
    ) async {
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          theme: AppTheme.light(),
          home: const Scaffold(body: Text('trang một')),
        ),
      );
      key.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('trang hai')),
        ),
      );
      await tester.pump();
      for (final ms in [50, 50, 50]) {
        await tester.pump(Duration(milliseconds: ms));
        expect(_scaleAboveText('trang hai'), findsNothing);
        expect(find.byType(SlideTransition), findsNothing);
      }
      await tester.pumpAndSettle();
      expect(find.text('trang hai'), findsOneWidget);
    });

    testWidgets('go_router: /login sang /connection không zoom', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [connectionProvider.overrideWith((ref) async {})],
          child: const GradebookApp(initialLocation: '/login'),
        ),
      );
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.text('Đăng nhập').first)).push('/connection');
      await tester.pump();
      for (final ms in [40, 60, 60, 60]) {
        await tester.pump(Duration(milliseconds: ms));
        expect(_scaleAboveText('Kết nối thành công'), findsNothing);
        expect(find.byType(SlideTransition), findsNothing);
      }
      await tester.pumpAndSettle();
      expect(find.text('Kết nối thành công'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
