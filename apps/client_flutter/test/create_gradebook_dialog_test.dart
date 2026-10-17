import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/features/academic_catalog/academic_year_scope.dart';
import 'package:client_flutter/features/academic_catalog/repository.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/gradebooks/gradebooks_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> makeClass(num id, String name, num yearId) => {
  'ma_lop': id,
  'ten_lop': name,
  'ma_nam_hoc': yearId,
  'ma_gv_chu_nhiem': 10,
  'khoi': 10,
  'label': name,
};

Map<String, dynamic> makeSubject(num id, String name) => {
  'ma_mon': id,
  'ten_mon': name,
  'so_tiet_tuan': 3,
  'label': name,
};

Map<String, dynamic> makeSemester(num id, String name, num yearId) => {
  'ma_hoc_ky': id,
  'ten': name,
  'ma_nam_hoc': yearId,
  'thu_tu': 1,
  'ngay_bat_dau': '2025-09-01',
  'ngay_ket_thuc': '2026-01-15',
  'label': name,
};

Map<String, dynamic> makeAssignment(
  num id,
  num classId,
  num subId,
  num termId,
) => {
  'ma_phan_cong': id,
  'ma_giao_vien': 10,
  'ma_lop': classId,
  'ma_mon': subId,
  'ma_hoc_ky': termId,
  'ngay_phan_cong': '2025-09-01',
  'label': 'Phân công $id',
};

class _FakeDialogServer implements HttpClientAdapter {
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> semesters = [];
  List<Map<String, dynamic>> assignments = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    Map<String, dynamic> body = {};

    if (path.endsWith('/catalog/classes')) {
      body = {'items': classes, 'nextCursor': null};
    } else if (path.endsWith('/catalog/subjects')) {
      body = {'items': subjects, 'nextCursor': null};
    } else if (path.endsWith('/catalog/semesters')) {
      body = {'items': semesters, 'nextCursor': null};
    } else if (path.endsWith('/catalog/assignments')) {
      body = {'items': assignments, 'nextCursor': null};
    } else {
      body = {'items': [], 'nextCursor': null};
    }

    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

class _FakeSessionController extends StateNotifier<SessionDto?>
    implements SessionController {
  _FakeSessionController(super.state);

  @override
  ApiClientDart get api => throw UnimplementedError();

  @override
  Timer? get expiry => null;

  @override
  set expiry(Timer? _) {}

  @override
  void clear() => state = null;

  @override
  Future<void> login(String username, String password) async {}

  @override
  Future<void> logout() async => state = null;

  @override
  Future<void> restore() async {}

  @override
  void touch() {}
}

class _FakeViewingYearNotifier extends StateNotifier<ViewingYear?>
    implements ViewingYearNotifier {
  _FakeViewingYearNotifier(super.state);

  @override
  Ref get ref => throw UnimplementedError();

  @override
  void selectYear(ViewingYear? year) => state = year ?? ViewingYear.all;

  @override
  void setYear(ViewingYear year) => state = year;

  @override
  void setYearFromRow(Json row) => state = ViewingYear.fromRow(row);

  @override
  void resetToCurrent() {}
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  required _FakeDialogServer server,
  ViewingYear? viewingYear,
}) async {
  final dio = Dio();
  dio.httpClientAdapter = server;
  final api = ApiClientDart(dio: dio);

  final session = SessionDto(
    id: 10,
    username: '0901234567',
    role: SessionDtoRoleEnum.GIAO_VIEN,
    active: true,
    token: 'fake-token',
    csrf: 'fake-csrf',
  );

  final container = ProviderContainer(
    overrides: [
      apiProvider.overrideWithValue(api),
      sessionProvider.overrideWith((ref) => _FakeSessionController(session)),
      if (viewingYear != null)
        viewingYearProvider.overrideWith(
          (ref) => _FakeViewingYearNotifier(viewingYear),
        ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: CreateGradebookDialog(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Giáo viên không có phân công: hiện thông báo lỗi đỏ và nút Tạo bị tắt',
    (tester) async {
      final server = _FakeDialogServer();
      server.classes = [makeClass(1, '10A1', 1)];
      server.subjects = [makeSubject(1, 'Toán')];
      server.semesters = [makeSemester(1, 'Học kỳ 1', 1)];
      server.assignments = []; // Không có phân công nào

      await _pumpDialog(
        tester,
        server: server,
        viewingYear: const ViewingYear(id: 1, name: '2025-2026'),
      );

      expect(
        find.text(
          'Bạn chưa được phân công giảng dạy lớp nào trong năm học này.',
        ),
        findsOneWidget,
      );

      final confirmButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('app-dialog-confirm')),
      );
      expect(confirmButton.onPressed, isNull);
    },
  );

  testWidgets(
    'Có phân công: Lớp chỉ hiện lớp được phân công, dropdown mở ra có chữ đầy đủ',
    (tester) async {
      final server = _FakeDialogServer();
      server.classes = [
        makeClass(1, '10A1', 1),
        makeClass(2, '10A2', 1),
        makeClass(3, '11B1', 1),
      ];
      server.subjects = [
        makeSubject(1, 'Toán'),
        makeSubject(2, 'Văn'),
      ];
      server.semesters = [
        makeSemester(1, 'Học kỳ 1', 1),
        makeSemester(2, 'Học kỳ 2', 1),
      ];
      // Giáo viên chỉ được phân công lớp 1 (Toán, HK1 & HK2) và lớp 2 (Văn, HK1)
      server.assignments = [
        makeAssignment(1, 1, 1, 1),
        makeAssignment(2, 1, 1, 2),
        makeAssignment(3, 2, 2, 1),
      ];

      await _pumpDialog(
        tester,
        server: server,
        viewingYear: const ViewingYear(id: 1, name: '2025-2026'),
      );

      // Lớp 10A1 được chọn mặc định
      expect(find.text('10A1'), findsWidgets);
      // Môn học chỉ có 1 môn (Toán) cho 10A1 -> tự động chọn Toán
      expect(find.text('Toán'), findsWidgets);
      // Học kỳ có 2 kỳ (HK1 và HK2) -> HK1 khớp năm học
      expect(find.text('Học kỳ 1'), findsWidgets);

      // Mở dropdown Lớp kiểm tra xem các dòng menu có chữ không (không bị dòng trống)
      await tester.tap(find.widgetWithText(DropdownMenu<num?>, 'Lớp'));
      await tester.pumpAndSettle();

      // Kiểm tra 10A1 và 10A2 hiển thị có chữ trong menu
      expect(find.text('10A1'), findsWidgets);
      expect(find.text('10A2'), findsWidgets);
      // Lớp 11B1 không có phân công nên không xuất hiện
      expect(find.text('11B1'), findsNothing);
    },
  );

  testWidgets(
    'Chuyển lớp thì lọc đúng môn học phân công, tự chọn khi chỉ có 1 lựa chọn',
    (tester) async {
      final server = _FakeDialogServer();
      server.classes = [
        makeClass(1, '10A1', 1),
        makeClass(2, '10A2', 1),
      ];
      server.subjects = [
        makeSubject(1, 'Toán'),
        makeSubject(2, 'Văn'),
      ];
      server.semesters = [
        makeSemester(1, 'Học kỳ 1', 1),
      ];
      // 10A1 -> Toán; 10A2 -> Văn
      server.assignments = [
        makeAssignment(1, 1, 1, 1),
        makeAssignment(2, 2, 2, 1),
      ];

      await _pumpDialog(
        tester,
        server: server,
        viewingYear: const ViewingYear(id: 1, name: '2025-2026'),
      );

      // Ban đầu 10A1 -> Toán tự chọn -> Học kỳ 1 tự chọn
      expect(find.text('10A1'), findsWidgets);
      expect(find.text('Toán'), findsWidgets);
      expect(find.text('Học kỳ 1'), findsWidgets);

      // Đổi sang lớp 10A2
      await tester.tap(find.widgetWithText(DropdownMenu<num?>, 'Lớp'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('10A2').last);
      await tester.pumpAndSettle();

      // Môn học tự động chuyển thành Văn (vì 10A2 chỉ phân công Văn)
      expect(find.text('Văn'), findsWidgets);
      expect(find.text('Học kỳ 1'), findsWidgets);

      // Nút Tạo được bật
      final confirmButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('app-dialog-confirm')),
      );
      expect(confirmButton.onPressed, isNotNull);
    },
  );

  testWidgets(
    'Chưa chọn lớp thì ô Môn học và Học kỳ bị tắt với hint "Chọn lớp trước"',
    (tester) async {
      final server = _FakeDialogServer();
      server.classes = [
        makeClass(1, '10A1', 1),
        makeClass(2, '10A2', 2),
      ];
      server.subjects = [
        makeSubject(1, 'Toán'),
        makeSubject(2, 'Văn'),
      ];
      server.semesters = [
        makeSemester(1, 'Học kỳ 1', 1),
      ];
      server.assignments = [
        makeAssignment(1, 1, 1, 1),
        makeAssignment(2, 2, 2, 1),
      ];

      // Khi viewingYear là "Tất cả các năm" (id == null), có nhiều lớp nên chưa auto-select lớp
      await _pumpDialog(
        tester,
        server: server,
        viewingYear: ViewingYear.all,
      );

      // Ô Môn học có hint 'Chọn lớp trước'
      expect(find.text('Chọn lớp trước'), findsWidgets);

      // Cả 2 dropdown Môn học và Học kỳ đều disabled (enabled: false)
      final subjectMenu = tester.widget<DropdownMenu<num?>>(
        find.widgetWithText(DropdownMenu<num?>, 'Môn học'),
      );
      expect(subjectMenu.enabled, isFalse);

      final termMenu = tester.widget<DropdownMenu<num?>>(
        find.widgetWithText(DropdownMenu<num?>, 'Học kỳ'),
      );
      expect(termMenu.enabled, isFalse);

      // Nút Tạo bị tắt
      final confirmButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('app-dialog-confirm')),
      );
      expect(confirmButton.onPressed, isNull);
    },
  );
}
