import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/widgets/app_date_field.dart';
import 'package:client_flutter/features/academic_catalog/edit_dialog.dart';
import 'package:client_flutter/features/academic_catalog/fields.dart';
import 'package:client_flutter/features/academic_catalog/repository.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCatalogRepository extends CatalogRepository {
  _FakeCatalogRepository() : super(ApiClientDart());
  bool saveCalled = false;

  @override
  Future<CatalogPageData> list(
    String resource, {
    String? cursor,
    String? q,
    num? yearId,
    num? activeInYearId,
  }) async {
    return const CatalogPageData([], null);
  }

  @override
  Future<Json> save(
    String resource,
    Map<String, dynamic> data, {
    num? id,
  }) async {
    saveCalled = true;
    return {'id': 1, ...data};
  }
}

class _FakeAdminSessionController extends SessionController {
  _FakeAdminSessionController(super.api) {
    state = SessionDto(
      id: 1,
      username: 'admin',
      role: SessionDtoRoleEnum.QUAN_TRI_VIEN,
      active: true,
      token: 'tok',
      csrf: 'csrf',
    );
  }
}

void main() {
  Widget wrapWithLocale(Widget child) {
    return MaterialApp(
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('vi'), Locale('en')],
      locale: const Locale('vi'),
      home: Scaffold(body: child),
    );
  }

  testWidgets('1. Giá trị 2024-09-05T00:00:00.000Z hiển thị 05/09/2024', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWithLocale(
        AppDateField(
          label: 'Ngày bắt đầu',
          value: '2024-09-05T00:00:00.000Z',
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('05/09/2024'), findsOneWidget);
  });

  testWidgets('2. Tap rồi chọn một ngày thì onChanged nhận đúng yyyy-MM-dd', (
    tester,
  ) async {
    String? changedValue;
    await tester.pumpWidget(
      wrapWithLocale(
        AppDateField(
          label: 'Ngày sinh',
          value: null,
          initialDateWhenEmpty: DateTime(2024, 9, 5),
          firstDate: DateTime(2020, 1, 1),
          lastDate: DateTime(2030, 12, 31),
          onChanged: (val) => changedValue = val,
        ),
      ),
    );
    await tester.tap(find.byType(AppDateField));
    await tester.pumpAndSettle();
    expect(find.text('Chọn'), findsOneWidget);
    await tester.tap(find.text('Chọn'));
    await tester.pumpAndSettle();
    expect(changedValue, '2024-09-05');
  });

  testWidgets('3. Tap rồi bấm Hủy thì giá trị không đổi', (tester) async {
    String? changedValue = '2024-09-05';
    await tester.pumpWidget(
      wrapWithLocale(
        AppDateField(
          label: 'Ngày sinh',
          value: '2024-09-05',
          onChanged: (val) => changedValue = val,
        ),
      ),
    );
    await tester.tap(find.byType(AppDateField));
    await tester.pumpAndSettle();
    expect(find.text('Hủy'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(changedValue, '2024-09-05');
    expect(find.text('05/09/2024'), findsOneWidget);
  });

  testWidgets('4. enabled: false thì tap không mở picker', (tester) async {
    await tester.pumpWidget(
      wrapWithLocale(
        AppDateField(
          label: 'Ngày sinh',
          value: '2024-09-05',
          enabled: false,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.byType(AppDateField));
    await tester.pumpAndSettle();
    expect(find.text('Chọn'), findsNothing);
    expect(find.text('Hủy'), findsNothing);
  });

  testWidgets(
    '5. Form năm học có ngày kết thúc <= ngày bắt đầu thì hiện lỗi và không gọi API',
    (tester) async {
      final fakeRepo = _FakeCatalogRepository();
      final yearSpec = resources.firstWhere((r) => r.key == 'years');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogRepositoryProvider.overrideWithValue(fakeRepo),
            sessionProvider.overrideWith(
              (ref) => _FakeAdminSessionController(ref.read(apiProvider)),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('vi'), Locale('en')],
            locale: const Locale('vi'),
            home: Scaffold(
              body: EditDialog(
                spec: yearSpec,
                row: const {
                  'ma_nam_hoc': 1,
                  'ten': '2024-2025',
                  'ngay_bat_dau': '2024-09-01',
                  'ngay_ket_thuc': '2024-08-01',
                  'hien_hanh': false,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('01/09/2024'), findsOneWidget);
      expect(find.text('01/08/2024'), findsOneWidget);

      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(find.text('Ngày kết thúc phải sau ngày bắt đầu'), findsOneWidget);
      expect(fakeRepo.saveCalled, isFalse);
    },
  );
}
