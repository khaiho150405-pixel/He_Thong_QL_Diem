import 'dart:convert';
import 'dart:typed_data';
import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/timetable/timetable_screen.dart';
import 'package:client_flutter/features/timetable/timetable_edit_dialog.dart';
import 'package:client_flutter/features/timetable/timetable_model.dart';
import 'package:client_flutter/features/timetable/timetable_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'timetable_layout_test.dart' show TimetableFakeServer;

class GridServer extends TimetableFakeServer {
  GridServer(this.assignment);
  final Map<String, dynamic> assignment;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/catalog/assignments')) {
      return ResponseBody.fromString(
        jsonEncode({
          'items': [assignment],
          'nextCursor': null,
        }),
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    return super.fetch(options, requestStream, cancelFuture);
  }
}

class ScheduleServer implements HttpClientAdapter {
  RequestOptions? saved;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    saved = options;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

void main() {
  final assignment = <String, dynamic>{
    'ma_phan_cong': 1,
    'ma_lop': 1,
    'ma_mon': 2,
    'ma_giao_vien': 11,
    'ma_hoc_ky': 1,
    'ngay_phan_cong': '2026-10-04',
    'label': '10A1 · Ngữ văn · Giáo viên phụ trách · Học kỳ 1 năm 2026–2027',
  };
  testWidgets(
    'admin opens add from empty slot and actions from occupied slot',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [
          apiProvider.overrideWithValue(
            ApiClientDart(
              dio: Dio()..httpClientAdapter = GridServer(assignment),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.runAsync(
        () => container
            .read(sessionProvider.notifier)
            .login('admin', 'fixture-password'),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TimetableScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final empty = find.byKey(const ValueKey('add-slot-1-2-2'));
      await tester.ensureVisible(empty);
      await tester.tap(empty);
      await tester.pumpAndSettle();
      expect(find.text('Xếp tiết học'), findsOneWidget);
      final fields = tester
          .widgetList<DropdownButtonFormField<int>>(
            find.byType(DropdownButtonFormField<int>),
          )
          .toList();
      expect(fields[0].initialValue, 2);
      expect(fields[1].initialValue, 2);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).last, const Offset(0, 900));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Toán').first);
      await tester.pumpAndSettle();
      expect(find.text('Sửa môn / giáo viên'), findsOneWidget);
      expect(find.text('Chuyển ngày / tiết'), findsOneWidget);
      expect(find.text('Xóa khỏi lịch'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets('add schedule keeps selected grid slot at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final server = ScheduleServer();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: Scaffold(
            body: TimetableEditDialog(
              assignments: [assignment],
              repository: TimetableRepository(
                Dio()..httpClientAdapter = server,
              ),
              initialDay: 8,
              initialPeriod: 7,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Thêm vào lịch'));
      await tester.pumpAndSettle();
      expect(server.saved?.method, 'POST');
      final data = server.saved!.data is String
          ? jsonDecode(server.saved!.data as String)
          : server.saved!.data;
      expect(data['thu'], 8);
      expect(data['tiet'], 7);
      expect(data['ma_lop'], 1);
      expect(data['ma_mon'], 2);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'move keeps assignment and updates day without changing subject',
    (tester) async {
      final server = ScheduleServer();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimetableEditDialog(
              assignments: [assignment],
              repository: TimetableRepository(
                Dio()..httpClientAdapter = server,
              ),
              moving: true,
              item: const TimetableItem(
                maTietHoc: 5,
                maLop: 1,
                tenLop: '10A1',
                maMon: 2,
                tenMon: 'Ngữ văn',
                maGiaoVien: 11,
                tenGiaoVien: 'GV',
                maHocKy: 1,
                tenHocKy: 'HK1',
                thu: 2,
                tiet: 1,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<num>>(
              find.byType(DropdownButtonFormField<num>),
            )
            .onChanged,
        isNull,
      );
      await tester.tap(find.text('Thứ Hai').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chủ nhật').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(server.saved?.method, 'PUT');
      expect(server.saved?.path, '/api/v1/timetable/5');
      final data = server.saved!.data is String
          ? jsonDecode(server.saved!.data as String)
          : server.saved!.data;
      expect(data['thu'], 8);
      expect(data['ma_mon'], 2);
      expect(data['ma_giao_vien'], 11);
      expect(tester.takeException(), isNull);
    },
  );
}
