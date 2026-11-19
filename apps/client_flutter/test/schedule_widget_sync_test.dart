import 'dart:convert';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/timetable/schedule_widget_sync.dart';
import 'package:client_flutter/features/timetable/timetable_model.dart';
import 'package:client_flutter/features/timetable/timetable_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSession extends StateNotifier<SessionDto?>
    implements SessionController {
  _FakeSession(super.state);

  void set(SessionDto? next) => state = next;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRepository implements TimetableRepository {
  _FakeRepository(this.result);
  final TimetableResult result;
  int calls = 0;

  @override
  Future<TimetableResult> getTimetable({
    num? classId,
    num? teacherId,
    num? semesterId,
    int? dayOfWeek,
  }) async {
    calls++;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingBridge implements ScheduleWidgetBridge {
  final saved = <Map<String, dynamic>>[];
  int cleared = 0;

  @override
  bool get supported => true;

  @override
  Future<void> save(Map<String, dynamic> payload) async => saved.add(payload);

  @override
  Future<void> clear() async => cleared++;
}

SessionDto _session(SessionDtoRoleEnum role, {num id = 1}) => SessionDto(
  id: id,
  username: 'u',
  role: role,
  active: true,
  token: 'tok',
  csrf: 'csrf',
);

TimetableItem _item({
  int thu = 2,
  int tiet = 1,
  String mon = 'Toán',
  String lop = '10A1',
  String giaoVien = 'Cô Lan',
  String? phong = 'A101',
}) => TimetableItem(
  maTietHoc: 1,
  maLop: 1,
  tenLop: lop,
  maMon: 1,
  tenMon: mon,
  maGiaoVien: 1,
  tenGiaoVien: giaoVien,
  maHocKy: 1,
  tenHocKy: 'Học kỳ 1',
  thu: thu,
  tiet: tiet,
  phongHoc: phong,
);

final _semester = TimetableSemester(
  id: 1,
  name: 'Học kỳ 1',
  yearName: '2026-2027',
  startDate: DateTime.utc(2026, 9, 5),
  endDate: DateTime.utc(2027, 1, 15),
);

void main() {
  group('buildScheduleWidgetPayload', () {
    test('học sinh: tiêu đề theo lớp, hiện giáo viên, không có phòng học', () {
      final payload = buildScheduleWidgetPayload(
        role: SessionDtoRoleEnum.HOC_SINH,
        result: TimetableResult([_item(), _item(thu: 3, tiet: 6)], _semester),
      )!;
      expect(payload['role'], 'HOC_SINH');
      expect(payload['title'], 'Thời khóa biểu 10A1');
      final lessons = payload['lessons'] as List;
      expect(lessons, hasLength(2));
      final first = lessons.first as Map<String, dynamic>;
      expect(first['subject'], 'Toán');
      expect(first['detail'], 'Cô Lan');
      expect(first['start'], '07:00');
      expect(first['end'], '07:45');
      expect(jsonEncode(payload).contains('A101'), isFalse);
      expect(payload['semester'], {
        'name': 'Học kỳ 1 · 2026-2027',
        'start': '2026-09-05',
        'end': '2027-01-15',
      });
    });

    test('giáo viên: tiêu đề Lịch dạy, chi tiết gồm lớp và phòng', () {
      final payload = buildScheduleWidgetPayload(
        role: SessionDtoRoleEnum.GIAO_VIEN,
        result: TimetableResult([_item(), _item(tiet: 2, phong: null)], null),
      )!;
      expect(payload['title'], 'Lịch dạy');
      expect(payload['semester'], isNull);
      final lessons = payload['lessons'] as List;
      expect((lessons[0] as Map)['detail'], 'Lớp 10A1 · Phòng A101');
      expect((lessons[1] as Map)['detail'], 'Lớp 10A1');
    });

    test('tiết ngoài khung giờ chuẩn không có giờ bắt đầu và kết thúc', () {
      final payload = buildScheduleWidgetPayload(
        role: SessionDtoRoleEnum.GIAO_VIEN,
        result: TimetableResult([_item(tiet: 12)], null),
      )!;
      final lesson = (payload['lessons'] as List).single as Map;
      expect(lesson['start'], isNull);
      expect(lesson['end'], isNull);
    });

    test('quản trị viên không có widget', () {
      expect(
        buildScheduleWidgetPayload(
          role: SessionDtoRoleEnum.QUAN_TRI_VIEN,
          result: TimetableResult([_item()], null),
        ),
        isNull,
      );
    });
  });

  group('ScheduleWidgetHost', () {
    late _FakeSession session;
    late _FakeRepository repository;
    late _RecordingBridge bridge;

    Future<void> pump(WidgetTester tester, SessionDto? initial) async {
      session = _FakeSession(initial);
      repository = _FakeRepository(TimetableResult([_item()], _semester));
      bridge = _RecordingBridge();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith((ref) => session),
            timetableRepositoryProvider.overrideWithValue(repository),
            scheduleWidgetBridgeProvider.overrideWithValue(bridge),
          ],
          child: const MaterialApp(
            home: ScheduleWidgetHost(child: Text('app')),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('đăng nhập học sinh thì đẩy lịch xuống widget', (tester) async {
      await pump(tester, null);
      expect(bridge.saved, isEmpty);

      session.set(_session(SessionDtoRoleEnum.HOC_SINH));
      await tester.pump();
      await tester.pump();

      expect(repository.calls, 1);
      expect(bridge.saved, hasLength(1));
      expect(bridge.saved.single['role'], 'HOC_SINH');
    });

    testWidgets('quản trị viên đăng nhập thì không gọi thời khóa biểu', (
      tester,
    ) async {
      await pump(tester, null);
      session.set(_session(SessionDtoRoleEnum.QUAN_TRI_VIEN));
      await tester.pump();
      await tester.pump();

      expect(repository.calls, 0);
      expect(bridge.saved, isEmpty);
      expect(bridge.cleared, 1);
    });

    testWidgets('đăng xuất thì xóa dữ liệu widget', (tester) async {
      await pump(tester, null);
      session.set(_session(SessionDtoRoleEnum.GIAO_VIEN));
      await tester.pump();
      await tester.pump();
      expect(bridge.saved, hasLength(1));

      session.set(null);
      await tester.pump();

      expect(bridge.cleared, 1);
    });

    testWidgets('khởi động chưa có phiên thì không xóa widget', (tester) async {
      await pump(tester, null);
      await tester.pump();
      expect(bridge.cleared, 0);
      expect(bridge.saved, isEmpty);
    });
  });
}
