import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/connection/connection.dart';
import 'package:client_flutter/features/school_profile/school_profile.dart';
import 'package:client_flutter/features/school_profile/school_profile_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_school_profile.dart';

class _FakeSession extends StateNotifier<SessionDto?>
    implements SessionController {
  _FakeSession(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SessionDto _session(SessionDtoRoleEnum role) => SessionDto(
  id: 1,
  username: 'tester',
  role: role,
  active: true,
  token: 'tok',
  csrf: 'csrf',
);

Future<void> _pump(
  WidgetTester tester, {
  required FakeSchoolProfileRepository repo,
  required String location,
  SessionDtoRoleEnum role = SessionDtoRoleEnum.QUAN_TRI_VIEN,
  bool withTerm = true,
}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        schoolProfileRepositoryProvider.overrideWithValue(repo),
        apiProvider.overrideWithValue(
          ApiClientDart(
            dio: Dio()..httpClientAdapter = FakeCatalogServer(withTerm: withTerm),
          ),
        ),
        sessionProvider.overrideWith((ref) => _FakeSession(_session(role))),
        connectionProvider.overrideWith((ref) async {}),
      ],
      child: GradebookApp(initialLocation: location),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sidebar hiện shortName in hoa từ schoolProfileProvider', (
    tester,
  ) async {
    await _pump(
      tester,
      repo: FakeSchoolProfileRepository(),
      location: '/admin/school-profile',
    );
    expect(find.text(fakeSchoolShortName.toUpperCase()), findsOneWidget);
    expect(find.text('Thông tin trường'), findsWidgets);
  });

  testWidgets('chưa tải được thông tin trường: sidebar không có dòng tên trường', (
    tester,
  ) async {
    final repo = FakeSchoolProfileRepository()..failFetch = true;
    await _pump(tester, repo: repo, location: '/admin/school-profile');
    expect(find.text('EduScore'), findsWidgets);
    expect(find.text(fakeSchoolShortName.toUpperCase()), findsNothing);
  });

  testWidgets('giáo viên và học sinh không vào được route Thông tin trường', (
    tester,
  ) async {
    for (final role in [
      SessionDtoRoleEnum.GIAO_VIEN,
      SessionDtoRoleEnum.HOC_SINH,
    ]) {
      await _pump(
        tester,
        repo: FakeSchoolProfileRepository(),
        location: '/admin/school-profile',
        role: role,
      );
      expect(find.byType(SchoolProfileScreen), findsNothing);
      expect(find.text('Thông tin trường'), findsNothing);
    }
  });

  testWidgets('validate trước khi gửi, không gọi API khi sai', (tester) async {
    final repo = FakeSchoolProfileRepository();
    await _pump(tester, repo: repo, location: '/admin/school-profile');

    Finder field(String label) => find.widgetWithText(TextFormField, label);
    await tester.enterText(field('Tên trường *'), '');
    await tester.enterText(field('Điện thoại'), '123');
    await tester.enterText(field('Email'), 'khong-hop-le');
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Bắt buộc nhập'), findsOneWidget);
    expect(find.text('Điện thoại gồm 10–11 chữ số'), findsOneWidget);
    expect(find.text('Email không đúng định dạng'), findsOneWidget);
    expect(repo.updates, 0);
  });

  testWidgets('lưu thành công: thông báo và sidebar đổi ngay', (tester) async {
    final repo = FakeSchoolProfileRepository();
    await _pump(tester, repo: repo, location: '/admin/school-profile');

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên ngắn *'),
      'THPT Mới',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();

    expect(repo.updates, 1);
    expect(find.text('Đã lưu thông tin trường'), findsOneWidget);
    expect(find.text('THPT MỚI'), findsOneWidget);
    expect(find.text(fakeSchoolShortName.toUpperCase()), findsNothing);
  });

  testWidgets('SCHOOL_PROFILE_VERSION_CONFLICT hiện đúng thông điệp', (
    tester,
  ) async {
    final repo = FakeSchoolProfileRepository()
      ..updateError = apiError('SCHOOL_PROFILE_VERSION_CONFLICT');
    await _pump(tester, repo: repo, location: '/admin/school-profile');

    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();

    expect(
      find.text('Thông tin trường vừa được người khác thay đổi, hãy tải lại'),
      findsOneWidget,
    );
  });

  testWidgets('INVALID_SCHOOL_PROFILE đánh dấu đúng ô theo details.fields', (
    tester,
  ) async {
    final repo = FakeSchoolProfileRepository()
      ..updateError = apiError(
        'INVALID_SCHOOL_PROFILE',
        status: 400,
        details: {
          'fields': ['principal'],
        },
      );
    await _pump(tester, repo: repo, location: '/admin/school-profile');

    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Thông tin trường không hợp lệ'), findsOneWidget);
    expect(find.text('Giá trị không hợp lệ'), findsOneWidget);
  });

  testWidgets('dashboard: eyebrow lấy học kỳ/năm hiện hành và shortName', (
    tester,
  ) async {
    await _pump(tester, repo: FakeSchoolProfileRepository(), location: '/');
    expect(
      find.text(
        'HỌC KỲ I, 2031-2032 · ${fakeSchoolShortName.toUpperCase()} · '
        'BẢNG ĐIỀU HÀNH THỐNG KÊ',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('2024'), findsNothing);
  });

  testWidgets('dashboard: không có học kỳ hiện hành thì chỉ ghi năm học', (
    tester,
  ) async {
    await _pump(
      tester,
      repo: FakeSchoolProfileRepository(),
      location: '/',
      withTerm: false,
    );
    expect(
      find.text(
        '2031-2032 · ${fakeSchoolShortName.toUpperCase()} · '
        'BẢNG ĐIỀU HÀNH THỐNG KÊ',
      ),
      findsOneWidget,
    );
  });
}
