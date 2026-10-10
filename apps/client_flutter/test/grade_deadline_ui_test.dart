import 'dart:convert';
import 'dart:typed_data';
import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/gradebooks/grade_deadlines_panel.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class DeadlineServer implements HttpClientAdapter {
  Map<String, dynamic>? saved;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(options.method, 'PUT');
    expect(options.path, endsWith('/gradebooks/7/components/201/deadline'));
    saved = options.data is String
        ? jsonDecode(options.data as String) as Map<String, dynamic>
        : options.data as Map<String, dynamic>;
    return ResponseBody.fromString('', 204);
  }
}

GradeCellDto column() => GradeCellDto.fromJson({
  'id': '1',
  'studentId': 1,
  'studentName': 'Fixture',
  'stt': 1,
  'active': true,
  'componentId': 201,
  'componentName': 'Thường xuyên lần 1',
  'coefficient': '1.00',
  'required': true,
  'displayOrder': 1,
  'value': null,
  'status': 'CHUA_CO',
  'source': 'NHAP_TAY',
  'deadlineVersion': 0,
});

void main() {
  testWidgets(
    'school deadlines stay on one horizontally scrollable row on desktop',
    (tester) async {
      tester.view.physicalSize = const Size(700, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final second = GradeCellDto.fromJson({
        ...column().toJson(),
        'componentId': 202,
        'componentName': 'Cuối kỳ',
        'displayOrder': 2,
      });
      final third = GradeCellDto.fromJson({
        ...column().toJson(),
        'componentId': 203,
        'componentName': 'Thường xuyên lần 2',
        'displayOrder': 3,
      });
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GradeDeadlinesPanel(
                bookId: 7,
                components: [column(), second, third],
                isAdmin: true,
                locked: false,
                onReload: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Thường xuyên lần 1')).dy,
        tester.getTopLeft(find.text('Cuối kỳ')).dy,
      );
      final scroll = find.byKey(const ValueKey('grade-deadlines-horizontal'));
      final before = tester.getTopLeft(find.text('Thường xuyên lần 2')).dx;
      await tester.drag(scroll, const Offset(-150, 0));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Thường xuyên lần 2')).dx,
        lessThan(before),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('school deadlines render as a vertical list on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final second = GradeCellDto.fromJson({
      ...column().toJson(),
      'componentId': 202,
      'componentName': 'Cuối kỳ',
      'displayOrder': 2,
    });
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GradeDeadlinesPanel(
              bookId: 7,
              components: [column(), second],
              isAdmin: true,
              locked: false,
              onReload: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Thường xuyên lần 1')).dy,
      lessThan(tester.getTopLeft(find.text('Cuối kỳ')).dy),
    );
    expect(
      find.byKey(const ValueKey('grade-deadlines-vertical')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets('admin deadline dialog saves UTC contract at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final server = DeadlineServer();
      var reloads = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiProvider.overrideWithValue(
              ApiClientDart(dio: Dio()..httpClientAdapter = server),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: GradeDeadlinesPanel(
                  bookId: 7,
                  components: [column()],
                  isAdmin: true,
                  locked: false,
                  onReload: () => reloads++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Đặt lịch'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Hạn nhập:'), findsOneWidget);
      await tester.tap(find.text('Lưu lịch nhập'));
      await tester.pumpAndSettle();
      expect(server.saved!['opensAt'].toString(), endsWith('Z'));
      expect(server.saved!['closesAt'].toString(), endsWith('Z'));
      expect(server.saved!['expectedVersion'], 0);
      expect(reloads, 1);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'teacher sees school deadline without manual lock or schedule editing',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GradeDeadlinesPanel(
                bookId: 7,
                components: [column()],
                isAdmin: false,
                locked: false,
                onReload: () {},
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Lịch nhập điểm của nhà trường'));
      await tester.pumpAndSettle();
      expect(find.text('Đặt lịch'), findsNothing);
      expect(find.textContaining('Chốt cột'), findsNothing);
      expect(find.textContaining('Chưa đặt lịch'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
