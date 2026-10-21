import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/widgets/app_controls.dart';
import 'package:client_flutter/features/academic_catalog/academic_year_scope.dart';
import 'package:client_flutter/features/academic_catalog/repository.dart';
import 'package:client_flutter/features/academic_catalog/subjects_weights_screen.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCatalogRepository extends CatalogRepository {
  _FakeCatalogRepository({
    this.subjects = const [],
    this.components = const [],
    this.weights = const [],
    this.semesters = const [],
    this.years = const [],
  }) : super(ApiClientDart());

  final List<Json> subjects;
  final List<Json> components;
  final List<Json> weights;
  final List<Json> semesters;
  final List<Json> years;

  @override
  Future<CatalogPageData> list(
    String resource, {
    String? cursor,
    String? q,
    num? yearId,
    num? activeInYearId,
  }) async {
    return switch (resource) {
      'subjects' => CatalogPageData(subjects, null),
      'components' => CatalogPageData(components, null),
      'semester-weights' => CatalogPageData(weights, null),
      'semesters' => CatalogPageData(semesters, null),
      'years' => CatalogPageData(years, null),
      _ => const CatalogPageData([], null),
    };
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
  testWidgets(
    'Màn Môn học & hệ số: khi semester-weights rỗng thì ô Học kỳ tự chọn học kỳ năm đang xem và hiện TX×1/GK×2/CK×3 kèm ghi chú mặc định',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeCatalogRepository(
        subjects: [
          {
            'ma_mon': 1,
            'ten_mon': 'Toán học',
            'so_tiet_tuan': 4,
            'danh_gia_dat': false,
          },
        ],
        components: [
          {
            'ma_thanh_phan': 1,
            'ma_mon': 1,
            'ten_thanh_phan': 'Kiểm tra thường xuyên',
            'loai_he_so': 'TX',
          },
          {
            'ma_thanh_phan': 2,
            'ma_mon': 1,
            'ten_thanh_phan': 'Kiểm tra giữa kỳ',
            'loai_he_so': 'GK',
          },
          {
            'ma_thanh_phan': 3,
            'ma_mon': 1,
            'ten_thanh_phan': 'Kiểm tra cuối kỳ',
            'loai_he_so': 'CK',
          },
        ],
        weights: [], // RỖNG: chưa cấu hình hệ số riêng
        years: [
          {
            'ma_nam_hoc': 1,
            'ten': '2024-2025',
            'ngay_bat_dau': '2024-09-01',
            'ngay_ket_thuc': '2025-05-31',
            'hien_hanh': true,
          },
          {
            'ma_nam_hoc': 2,
            'ten': '2025-2026',
            'ngay_bat_dau': '2025-09-01',
            'ngay_ket_thuc': '2026-05-31',
            'hien_hanh': false,
          },
        ],
        semesters: [
          {
            'ma_hoc_ky': 10,
            'ma_nam_hoc': 1,
            'ten': 'Học kỳ 1',
            'thu_tu': 1,
            'ngay_bat_dau': '2024-09-01',
            'ngay_ket_thuc': '2025-01-15',
          },
          {
            'ma_hoc_ky': 11,
            'ma_nam_hoc': 1,
            'ten': 'Học kỳ 2',
            'thu_tu': 2,
            'ngay_bat_dau': '2025-01-16',
            'ngay_ket_thuc': '2025-05-31',
          },
          {
            'ma_hoc_ky': 20,
            'ma_nam_hoc': 2,
            'ten': 'Học kỳ 1',
            'thu_tu': 1,
            'ngay_bat_dau': '2025-09-01',
            'ngay_ket_thuc': '2026-01-15',
          },
        ],
      );

      final container = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(fakeRepo),
          sessionProvider.overrideWith(
            (ref) => _FakeAdminSessionController(ref.read(apiProvider)),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Đặt năm đang xem là Năm 2024-2025 (id: 1)
      container.read(viewingYearProvider.notifier).selectYear(
        const ViewingYear(
          id: 1,
          name: 'Năm học 2024-2025',
          isCurrent: true,
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: [Locale('vi'), Locale('en')],
            locale: Locale('vi'),
            home: SubjectsWeightsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra thẻ Hệ số học kỳ hiển thị
      expect(find.byKey(const ValueKey('weights-card')), findsOneWidget);

      // Ô học kỳ tự động chọn học kỳ thuộc năm 2024-2025 (học kỳ 1, ma_hoc_ky: 10)
      final dropdown = tester.widget<AppFilterDropdown<num>>(
        find.byKey(const ValueKey('weights-semester-filter')),
      );
      expect(dropdown.value, 10);

      // Danh sách học kỳ trong dropdown chỉ gồm học kỳ của năm 2024-2025
      // và có nhãn định dạng "Học kỳ 1 · 2024-2025"
      expect(dropdown.items.length, 2);
      expect(dropdown.items.any((i) => i.value == 10), isTrue);
      expect(dropdown.items.any((i) => i.value == 11), isTrue);
      expect(dropdown.items.any((i) => i.value == 20), isFalse);

      // Hiển thị TX ×1, GK ×2, CK ×3 mặc định
      expect(find.byKey(const ValueKey('weight-TX')), findsOneWidget);
      expect(find.byKey(const ValueKey('weight-GK')), findsOneWidget);
      expect(find.byKey(const ValueKey('weight-CK')), findsOneWidget);
      expect(find.text('×1'), findsOneWidget);
      expect(find.text('×2'), findsOneWidget);
      expect(find.text('×3'), findsOneWidget);

      // Có dòng ghi chú nhỏ màu mờ
      expect(
        find.text(
          'Đang dùng hệ số mặc định (chưa cấu hình riêng cho học kỳ này).',
        ),
        findsOneWidget,
      );

      // Đổi năm đang xem sang Năm 2025-2026 (id: 2) -> chọn lại học kỳ mặc định của năm mới (ma_hoc_ky: 20)
      container.read(viewingYearProvider.notifier).selectYear(
        const ViewingYear(
          id: 2,
          name: 'Năm học 2025-2026',
          isCurrent: false,
        ),
      );
      await tester.pumpAndSettle();

      final updatedDropdown = tester.widget<AppFilterDropdown<num>>(
        find.byKey(const ValueKey('weights-semester-filter')),
      );
      expect(updatedDropdown.value, 20);
      expect(updatedDropdown.items.length, 1);
      expect(updatedDropdown.items.first.value, 20);
    },
  );

  testWidgets(
    'Màn Môn học & hệ số: khi có hệ số được cấu hình thì hiển thị đúng giá trị và không hiện ghi chú mặc định',
    (tester) async {
      final fakeRepo = _FakeCatalogRepository(
        subjects: [
          {
            'ma_mon': 1,
            'ten_mon': 'Văn học',
            'so_tiet_tuan': 4,
            'danh_gia_dat': false,
          },
        ],
        components: [
          {
            'ma_thanh_phan': 1,
            'ma_mon': 1,
            'ten_thanh_phan': 'TX1',
            'loai_he_so': 'TX',
          },
        ],
        weights: [
          {'ma_hoc_ky': 10, 'loai_he_so': 'TX', 'he_so': '2'},
          {'ma_hoc_ky': 10, 'loai_he_so': 'GK', 'he_so': '3'},
          {'ma_hoc_ky': 10, 'loai_he_so': 'CK', 'he_so': '5'},
        ],
        years: [
          {
            'ma_nam_hoc': 1,
            'ten': '2024-2025',
            'ngay_bat_dau': '2024-09-01',
            'ngay_ket_thuc': '2025-05-31',
            'hien_hanh': true,
          },
        ],
        semesters: [
          {
            'ma_hoc_ky': 10,
            'ma_nam_hoc': 1,
            'ten': 'Học kỳ 1',
            'thu_tu': 1,
            'ngay_bat_dau': '2024-09-01',
            'ngay_ket_thuc': '2025-01-15',
          },
        ],
      );

      final container = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(fakeRepo),
          sessionProvider.overrideWith(
            (ref) => _FakeAdminSessionController(ref.read(apiProvider)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: [Locale('vi'), Locale('en')],
            locale: Locale('vi'),
            home: SubjectsWeightsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('×2'), findsOneWidget);
      expect(find.text('×3'), findsOneWidget);
      expect(find.text('×5'), findsOneWidget);
      expect(
        find.text(
          'Đang dùng hệ số mặc định (chưa cấu hình riêng cho học kỳ này).',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Layout kiểm tra trên mobile 360px, tablet 768px, desktop 1280px và dark mode không tràn',
    (tester) async {
      final fakeRepo = _FakeCatalogRepository(
        subjects: [
          {
            'ma_mon': 1,
            'ten_mon': 'Toán học',
            'so_tiet_tuan': 4,
            'danh_gia_dat': false,
          },
        ],
        components: [
          {
            'ma_thanh_phan': 1,
            'ma_mon': 1,
            'ten_thanh_phan': 'TX1',
            'loai_he_so': 'TX',
          },
        ],
        weights: [],
        years: [
          {
            'ma_nam_hoc': 1,
            'ten': '2024-2025',
            'ngay_bat_dau': '2024-09-01',
            'ngay_ket_thuc': '2025-05-31',
            'hien_hanh': true,
          },
        ],
        semesters: [
          {
            'ma_hoc_ky': 10,
            'ma_nam_hoc': 1,
            'ten': 'Học kỳ 1',
            'thu_tu': 1,
            'ngay_bat_dau': '2024-09-01',
            'ngay_ket_thuc': '2025-01-15',
          },
        ],
      );

      for (final size in [
        const Size(360, 740),
        const Size(768, 1024),
        const Size(1280, 800),
      ]) {
        for (final brightness in [Brightness.light, Brightness.dark]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;

          final container = ProviderContainer(
            overrides: [
              catalogRepositoryProvider.overrideWithValue(fakeRepo),
              sessionProvider.overrideWith(
                (ref) => _FakeAdminSessionController(ref.read(apiProvider)),
              ),
            ],
          );

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: ThemeData(brightness: brightness),
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                supportedLocales: const [Locale('vi'), Locale('en')],
                locale: const Locale('vi'),
                home: const SubjectsWeightsScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byKey(const ValueKey('weights-card')), findsOneWidget);
          expect(tester.takeException(), isNull);
          container.dispose();
        }
      }
    },
  );
}
