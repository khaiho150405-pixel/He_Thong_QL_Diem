import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/app/design_tokens.dart';
import 'package:client_flutter/app/theme_mode.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/form_templates/column_draft.dart';
import 'package:client_flutter/features/form_templates/repository.dart';
import 'package:client_flutter/features/recognition/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// PNG 1x1 hợp lệ: qua được bước kiểm sơ bộ ở máy và giải mã được thành ảnh.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);
const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

class _LoginServer implements HttpClientAdapter {
  _LoginServer(this.role);
  final String role;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final login = options.path.endsWith('/identity/login');
    return ResponseBody.fromString(
      jsonEncode(
        login
            ? {
                'id': 1,
                'username': 'tester',
                'role': role,
                'active': true,
                'token': 'token',
                'csrf': 'csrf',
              }
            : {},
      ),
      login ? 200 : 404,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

class _FakePicker implements RecognitionImagePicker {
  int picks = 0;
  @override
  Future<RecognitionImage?> pick() async {
    picks++;
    return RecognitionImage(name: 'sample.png', bytes: _png);
  }
}

DioException _apiError(int status, String code) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  response: Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: status,
    data: {'code': code, 'message': 'x', 'details': null, 'requestId': 'r'},
  ),
);

TemplateColumnDto _col(
  int index,
  TemplateColumnDtoRoleEnum role, {
  String? header,
  TemplateColumnDtoGroupEnum? group,
  int? order,
  int? pairedWith,
}) => TemplateColumnDto(
  index: index,
  role: role,
  group: group,
  order: order,
  pairedWith: pairedWith,
  headerText: header,
);

/// Mẫu hợp lệ: STT, Họ tên, TX1 (số + chữ), GK1 (chỉ số), cột bỏ qua.
List<TemplateColumnDto> _goodColumns() => [
  _col(0, TemplateColumnDtoRoleEnum.STT, header: 'STT'),
  _col(1, TemplateColumnDtoRoleEnum.HO_TEN, header: 'Họ và tên'),
  _col(
    2,
    TemplateColumnDtoRoleEnum.DIEM,
    header: 'ĐĐGtx',
    group: TemplateColumnDtoGroupEnum.TX,
    order: 1,
  ),
  _col(
    3,
    TemplateColumnDtoRoleEnum.DIEM_CHU,
    header: 'Điểm chữ',
    pairedWith: 2,
  ),
  _col(
    4,
    TemplateColumnDtoRoleEnum.DIEM,
    header: 'ĐĐGgk',
    group: TemplateColumnDtoGroupEnum.GK,
    order: 1,
  ),
  _col(5, TemplateColumnDtoRoleEnum.BO_QUA, header: 'Ghi chú'),
];

TemplateDetailDto _detail({
  num id = 5,
  String name = 'Sổ điểm THCS',
  TemplateDetailDtoStatusEnum status = TemplateDetailDtoStatusEnum.NHAP,
  List<TemplateColumnDto>? columns,
  num version = 1,
  num revision = 1,
}) {
  final cols = columns ?? _goodColumns();
  return TemplateDetailDto(
    id: id,
    name: name,
    description: 'Mẫu thử',
    status: status,
    revision: revision,
    rootTemplateId: null,
    columnCount: cols.length,
    gradeColumnCount: cols
        .where((c) => c.role == TemplateColumnDtoRoleEnum.DIEM)
        .length,
    version: version,
    createdAt: DateTime.utc(2026, 10, 18),
    columns: cols,
    imageUrl: 'http://127.0.0.1:9/template.png',
    imageUrlExpiresInSeconds: 300,
  );
}

TemplateSummaryDto _summary(TemplateDetailDto d) => TemplateSummaryDto(
  id: d.id,
  name: d.name,
  description: d.description,
  status: TemplateSummaryDtoStatusEnum.values.firstWhere(
    (s) => s.value == d.status.value,
  ),
  revision: d.revision,
  rootTemplateId: d.rootTemplateId,
  columnCount: d.columnCount,
  gradeColumnCount: d.gradeColumnCount,
  version: d.version,
  createdAt: d.createdAt,
);

AnalyzeResultDto _analysis() => AnalyzeResultDto(
  columnCount: 6,
  previewPngBase64: _pngBase64,
  columns: [
    for (final (i, role, group, order, header) in [
      (0, AnalyzedColumnDtoSuggestedRoleEnum.STT, null, null, 'STT'),
      (1, AnalyzedColumnDtoSuggestedRoleEnum.HO_TEN, null, null, 'Họ và tên'),
      (
        2,
        AnalyzedColumnDtoSuggestedRoleEnum.DIEM,
        AnalyzedColumnDtoSuggestedGroupEnum.TX,
        1,
        'ĐĐGtx',
      ),
      (3, AnalyzedColumnDtoSuggestedRoleEnum.DIEM_CHU, null, null, 'Điểm chữ'),
      (
        4,
        AnalyzedColumnDtoSuggestedRoleEnum.DIEM,
        AnalyzedColumnDtoSuggestedGroupEnum.GK,
        1,
        'ĐĐGgk',
      ),
      (5, null, null, null, ''),
    ])
      AnalyzedColumnDto(
        index: i,
        x0: i / 6,
        x1: (i + 1) / 6,
        widthMm: 20,
        headerText: header,
        suggestedRole: role,
        suggestedGroup: group,
        suggestedOrder: order,
      ),
  ],
);

TryResultDto _tryResult() => TryResultDto(
  templateId: 5,
  modelVersion: 'fake-1',
  templateMatchScore: 0.93,
  pageStartStt: 1,
  rows: [
    TryRowDto(
      rowIndex: 1,
      struck: false,
      sttRead: 1,
      nameRead: 'Học sinh A',
      grades: [
        TryGradeDto(
          key: 'TX1',
          numericValue: '8.5',
          numericConfidence: '0.9',
          writtenValue: '8.5',
          writtenConfidence: '0.9',
          comparison: TryGradeDtoComparisonEnum.KHOP,
          reviewLevel: TryGradeDtoReviewLevelEnum.XANH,
          suggestedSource: null,
        ),
        TryGradeDto(
          key: 'GK1',
          numericValue: '7.0',
          numericConfidence: '0.8',
          writtenValue: null,
          writtenConfidence: null,
          comparison: TryGradeDtoComparisonEnum.MOT_KENH,
          reviewLevel: TryGradeDtoReviewLevelEnum.VANG,
          suggestedSource: TryGradeDtoSuggestedSourceEnum.SO,
        ),
      ],
    ),
    TryRowDto(
      rowIndex: 2,
      struck: false,
      sttRead: 2,
      nameRead: 'Học sinh B',
      grades: [
        TryGradeDto(
          key: 'TX1',
          numericValue: null,
          numericConfidence: null,
          writtenValue: null,
          writtenConfidence: null,
          comparison: TryGradeDtoComparisonEnum.KHONG_DOC_DUOC,
          reviewLevel: TryGradeDtoReviewLevelEnum.DO,
          suggestedSource: null,
        ),
      ],
    ),
  ],
);

class _FakeTemplates implements FormTemplatesRepository {
  _FakeTemplates({List<TemplateDetailDto>? templates})
    : details = {for (final d in templates ?? []) d.id: d};

  final Map<num, TemplateDetailDto> details;
  final List<String> calls = [];
  Completer<List<TemplateSummaryDto>>? listGate;
  final List<Object> listFailures = [];
  Object? updateError;
  Object? tryError;
  String? lastName;
  List<TemplateColumnDto>? lastColumns;
  num nextId = 50;

  @override
  Future<List<TemplateSummaryDto>> list() async {
    calls.add('list');
    if (listFailures.isNotEmpty) throw listFailures.removeAt(0);
    if (listGate != null) return listGate!.future;
    return [for (final d in details.values) _summary(d)];
  }

  @override
  Future<TemplateDetailDto> detail(num id) async {
    calls.add('detail');
    final d = details[id];
    if (d == null) throw _apiError(404, 'TEMPLATE_NOT_FOUND');
    return d;
  }

  @override
  Future<AnalyzeResultDto> analyze(RecognitionImage image) async {
    calls.add('analyze');
    return _analysis();
  }

  @override
  Future<TemplateDetailDto> create({
    required RecognitionImage image,
    required String name,
    required String? description,
    required List<TemplateColumnDto> columns,
  }) async {
    calls.add('create');
    lastName = name;
    lastColumns = columns;
    final created = _detail(id: nextId++, name: name, columns: columns);
    details[created.id] = created;
    return created;
  }

  @override
  Future<TemplateDetailDto> update({
    required num id,
    required num expectedVersion,
    required String name,
    required String? description,
    required List<TemplateColumnDto> columns,
  }) async {
    calls.add('update');
    if (updateError != null) throw updateError!;
    lastName = name;
    lastColumns = columns;
    return details[id] = _detail(id: id, name: name, columns: columns);
  }

  @override
  Future<TemplateDetailDto> createVersion({
    required num id,
    required num expectedVersion,
    required String name,
    required String? description,
    required List<TemplateColumnDto> columns,
  }) async {
    calls.add('createVersion');
    lastName = name;
    lastColumns = columns;
    final created = _detail(
      id: nextId++,
      name: name,
      columns: columns,
      revision: 2,
    );
    details[created.id] = created;
    return created;
  }

  @override
  Future<TemplateDetailDto> activate({
    required num id,
    required num expectedVersion,
  }) async {
    calls.add('activate');
    final old = details[id]!;
    return details[id] = _detail(
      id: id,
      name: old.name,
      status: TemplateDetailDtoStatusEnum.DANG_DUNG,
      columns: old.columns,
      version: old.version + 1,
    );
  }

  @override
  Future<TemplateDetailDto> retire({
    required num id,
    required num expectedVersion,
  }) async {
    calls.add('retire');
    final old = details[id]!;
    return details[id] = _detail(
      id: id,
      name: old.name,
      status: TemplateDetailDtoStatusEnum.NGUNG,
      columns: old.columns,
      version: old.version + 1,
    );
  }

  @override
  Future<TryResultDto> tryTemplate({
    required num id,
    required RecognitionImage image,
  }) async {
    calls.add('tryTemplate');
    if (tryError != null) throw tryError!;
    return _tryResult();
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required _FakeTemplates fake,
  String role = 'QUAN_TRI_VIEN',
  String location = '/admin/form-templates',
  double width = 1280,
  double height = 3200,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  _FakePicker? picker,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final container = ProviderContainer(
    overrides: [
      themeModeProvider.overrideWith(
        (ref) =>
            brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      ),
      apiProvider.overrideWithValue(
        ApiClientDart(dio: Dio()..httpClientAdapter = _LoginServer(role)),
      ),
      formTemplatesRepositoryProvider.overrideWithValue(fake),
      recognitionImagePickerProvider.overrideWithValue(picker ?? _FakePicker()),
    ],
  );
  addTearDown(container.dispose);
  await tester.runAsync(
    () => container.read(sessionProvider.notifier).login('tester', 'x'),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: GradebookApp(initialLocation: location),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

String _pathOf(ProviderContainer container, String initial) => container
    .read(routerProvider(initial))
    .routeInformationProvider
    .value
    .uri
    .path;

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Chọn một mục trong `AppSelectField` (mở menu rồi chạm đúng nhãn).
Future<void> _choose(WidgetTester tester, String fieldKey, String label) async {
  await _tapKey(tester, fieldKey);
  // Mục menu nằm trong cây ngay dưới ô vừa mở, không phải mục cuối cây.
  await tester.tap(find.widgetWithText(MenuItemButton, label).last);
  await tester.pumpAndSettle();
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  group('luật hợp lệ (validateDrafts)', () {
    List<ColumnDraft> drafts(List<TemplateColumnDto> cols) => [
      for (final c in cols) ColumnDraft.fromTemplate(c),
    ];

    test('mẫu hợp lệ không có lỗi', () {
      expect(validateDrafts(drafts(_goodColumns())).isValid, isTrue);
    });

    test('luật 1: đúng một cột Họ tên', () {
      final none = _goodColumns()..removeAt(1);
      final noneResult = validateDrafts(drafts(none));
      expect(noneResult.has(DraftRule.hoTen), isTrue);
      expect(noneResult.general.map((i) => i.rule), contains(DraftRule.hoTen));

      final two = _goodColumns()
        ..[5] = _col(5, TemplateColumnDtoRoleEnum.HO_TEN, header: 'Tên 2');
      final twoResult = validateDrafts(drafts(two));
      expect(
        twoResult.issues
            .where((i) => i.rule == DraftRule.hoTen)
            .map((i) => i.column)
            .toSet(),
        {1, 5},
      );
    });

    test('luật 2: ít nhất một cột điểm', () {
      final cols = [
        _col(0, TemplateColumnDtoRoleEnum.HO_TEN),
        _col(1, TemplateColumnDtoRoleEnum.BO_QUA),
      ];
      expect(validateDrafts(drafts(cols)).has(DraftRule.noDiem), isTrue);
    });

    test('luật 3: không trùng (nhóm, thứ tự), chỉ đúng hai cột trùng', () {
      final cols = _goodColumns()
        ..[4] = _col(
          4,
          TemplateColumnDtoRoleEnum.DIEM,
          group: TemplateColumnDtoGroupEnum.TX,
          order: 1,
        );
      final result = validateDrafts(drafts(cols));
      expect(
        result.issues
            .where((i) => i.rule == DraftRule.groupOrderDuplicate)
            .map((i) => i.column)
            .toSet(),
        {2, 4},
      );
      expect(result.forColumn(1), isEmpty);
    });

    test('luật 4: cột chữ phải trỏ đúng một cột điểm', () {
      final unset = _goodColumns()
        ..[3] = _col(3, TemplateColumnDtoRoleEnum.DIEM_CHU);
      expect(
        validateDrafts(drafts(unset)).forColumn(3).single.rule,
        DraftRule.pairing,
      );

      final wrongTarget = _goodColumns()
        ..[3] = _col(3, TemplateColumnDtoRoleEnum.DIEM_CHU, pairedWith: 1);
      expect(
        validateDrafts(drafts(wrongTarget)).forColumn(3).single.rule,
        DraftRule.pairing,
      );

      final twoOnOne = _goodColumns()
        ..[5] = _col(5, TemplateColumnDtoRoleEnum.DIEM_CHU, pairedWith: 2);
      final result = validateDrafts(drafts(twoOnOne));
      expect(
        result.issues
            .where((i) => i.rule == DraftRule.pairing)
            .map((i) => i.column)
            .toSet(),
        {3, 5},
      );
    });

    test('đổi vai trò bỏ các trường không thuộc vai trò mới', () {
      final good = drafts(_goodColumns());
      final changed = good[2].withRole(Role.BO_QUA, others: good);
      expect(changed.group, isNull);
      expect(changed.order, isNull);
      final dto = changed.toDto();
      expect(dto.group, isNull);
      expect(dto.pairedWith, isNull);
    });
  });

  group('danh sách mẫu', () {
    testWidgets('đang tải', (tester) async {
      final fake = _FakeTemplates()..listGate = Completer();
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [
          apiProvider.overrideWithValue(
            ApiClientDart(
              dio: Dio()..httpClientAdapter = _LoginServer('QUAN_TRI_VIEN'),
            ),
          ),
          formTemplatesRepositoryProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);
      await tester.runAsync(
        () => container.read(sessionProvider.notifier).login('tester', 'x'),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const GradebookApp(initialLocation: '/admin/form-templates'),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('templates-loading')), findsOneWidget);
      fake.listGate!.complete([]);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('templates-loading')), findsNothing);
      await _finish(tester);
    });

    testWidgets('rỗng', (tester) async {
      final fake = _FakeTemplates();
      await _pump(tester, fake: fake);
      expect(find.byKey(const ValueKey('templates-empty')), findsOneWidget);
      expect(find.text('Chưa có mẫu bảng điểm'), findsOneWidget);
      expect(find.text('Tạo mẫu'), findsOneWidget);
      await _finish(tester);
    });

    testWidgets('lỗi rồi thử lại', (tester) async {
      final fake = _FakeTemplates(templates: [_detail()])
        ..listFailures.add(_apiError(502, 'RECOGNITION_SERVICE_ERROR'));
      await _pump(tester, fake: fake);
      expect(find.byKey(const ValueKey('templates-error')), findsOneWidget);
      expect(find.text('Không tải được danh sách mẫu'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('templates-error')), findsNothing);
      expect(find.byKey(const ValueKey('template-tile-5')), findsOneWidget);
      await _finish(tester);
    });

    testWidgets('hiện tên, phiên bản, trạng thái, số cột điểm, kiểu đọc', (
      tester,
    ) async {
      final fake = _FakeTemplates(
        templates: [
          _detail(),
          _detail(
            id: 6,
            name: 'Sổ điểm THPT',
            status: TemplateDetailDtoStatusEnum.DANG_DUNG,
            revision: 3,
            columns: [
              _col(0, TemplateColumnDtoRoleEnum.HO_TEN),
              _col(
                1,
                TemplateColumnDtoRoleEnum.DIEM,
                group: TemplateColumnDtoGroupEnum.TX,
                order: 1,
              ),
            ],
          ),
        ],
      );
      await _pump(tester, fake: fake);
      expect(find.text('Sổ điểm THCS'), findsOneWidget);
      expect(find.text('Sổ điểm THPT'), findsOneWidget);
      expect(find.text('Nháp'), findsOneWidget);
      expect(find.text('Đang dùng'), findsOneWidget);
      expect(find.text('Phiên bản 3'), findsOneWidget);
      expect(find.text('2 cột điểm'), findsOneWidget);
      expect(find.text('1 cột điểm'), findsOneWidget);
      // THCS: TX1 có cột chữ, GK1 không → nói rõ trộn; THPT: chỉ số.
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('template-readmode-5')))
            .data,
        'Số + chữ (1/2 cột)',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('template-readmode-6')))
            .data,
        'Chỉ số',
      );
      await _finish(tester);
    });
  });

  group('trình hướng dẫn tạo mẫu', () {
    testWidgets('AC-1: tạo từ đầu đến cuối với repository giả', (tester) async {
      final fake = _FakeTemplates();
      final picker = _FakePicker();
      final container = await _pump(
        tester,
        fake: fake,
        picker: picker,
        location: '/admin/form-templates/new',
      );
      // Bước 1: chưa có ảnh thì không phân tích được.
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('wizard-analyze')))
            .onPressed,
        isNull,
      );
      await _tapKey(tester, 'pick-image');
      expect(picker.picks, 1);
      expect(find.text('sample.png'), findsOneWidget);
      await _tapKey(tester, 'wizard-analyze');
      expect(fake.calls, contains('analyze'));

      // Bước 2: vai trò gợi ý chọn sẵn và có nhãn "Gợi ý"; cột không đọc được
      // tiêu đề thì "Bỏ qua" và không có nhãn.
      expect(find.byKey(const ValueKey('wizard-step-columns')), findsOneWidget);
      for (final i in [0, 1, 2, 3, 4]) {
        expect(find.byKey(ValueKey('column-suggested-$i')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('column-suggested-5')), findsNothing);
      expect(find.text('Gợi ý'), findsNWidgets(5));
      expect(find.text('Không đọc được tiêu đề'), findsOneWidget);
      // Cột chữ chưa trỏ cột nào → lỗi sát đúng cột 3.
      expect(
        find.byKey(const ValueKey('column-error-3-pairing-pairedWith')),
        findsOneWidget,
      );

      await _choose(tester, 'column-paired-3', 'Cột 2 · TX1');
      expect(find.byKey(const ValueKey('column-error-3')), findsNothing);

      await _tapKey(tester, 'wizard-next');
      // Bước 3: nhập tên rồi lưu.
      expect(find.byKey(const ValueKey('wizard-step-save')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('wizard-save')))
            .onPressed,
        isNull,
        reason: 'chưa có tên',
      );
      await tester.enterText(
        find.byKey(const ValueKey('wizard-name')),
        '  Sổ điểm mới ',
      );
      await tester.pump();
      await _tapKey(tester, 'wizard-save');

      expect(fake.calls, contains('create'));
      expect(fake.lastName, 'Sổ điểm mới');
      final saved = fake.lastColumns!;
      expect(saved.length, 6);
      expect(saved[3].role, TemplateColumnDtoRoleEnum.DIEM_CHU);
      expect(saved[3].pairedWith, 2);
      expect(saved[2].group, TemplateColumnDtoGroupEnum.TX);
      expect(saved[2].order, 1);
      expect(saved[5].role, TemplateColumnDtoRoleEnum.BO_QUA);
      // Lưu xong chuyển sang màn chi tiết của mẫu vừa tạo.
      expect(
        _pathOf(container, '/admin/form-templates/new'),
        '/admin/form-templates/50',
      );
      expect(find.byKey(const ValueKey('detail-name')), findsOneWidget);
      expect(find.text('Sổ điểm mới'), findsWidgets);
      await _finish(tester);
    });

    testWidgets('AC-2: lỗi hiện đúng cột và chặn nút Lưu', (tester) async {
      final fake = _FakeTemplates();
      await _pump(tester, fake: fake, location: '/admin/form-templates/new');
      await _tapKey(tester, 'pick-image');
      await _tapKey(tester, 'wizard-analyze');

      // Luật 4 (cột chữ chưa trỏ): lỗi ở cột 3, bước cuối chặn Lưu.
      await _tapKey(tester, 'wizard-next');
      await tester.enterText(
        find.byKey(const ValueKey('wizard-name')),
        'Mẫu lỗi',
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('wizard-invalid')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('wizard-save')))
            .onPressed,
        isNull,
      );
      await _tapKey(tester, 'wizard-fix-columns');
      expect(find.byKey(const ValueKey('wizard-step-columns')), findsOneWidget);

      // Luật 1: đổi cột 5 thành Họ tên → hai cột Họ tên đều báo lỗi.
      await _choose(tester, 'column-role-5', 'Họ tên');
      expect(
        find.byKey(const ValueKey('column-error-1-hoTen-role')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('column-error-5-hoTen-role')),
        findsOneWidget,
      );
      // Luật 1 (thiếu): đổi cả hai về "Bỏ qua" → lỗi chung.
      await _choose(tester, 'column-role-5', 'Bỏ qua');
      await _choose(tester, 'column-role-1', 'Bỏ qua');
      expect(find.byKey(const ValueKey('draft-general-hoTen')), findsOneWidget);
      await _choose(tester, 'column-role-1', 'Họ tên');
      expect(find.byKey(const ValueKey('draft-general-hoTen')), findsNothing);

      // Luật 3: đặt cột 4 thành TX thứ 1 → trùng với cột 2.
      await _choose(tester, 'column-group-4', 'Thường xuyên (TX)');
      await _choose(tester, 'column-order-4', '1');
      expect(
        find.byKey(const ValueKey('column-error-2-groupOrderDuplicate-order')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('column-error-4-groupOrderDuplicate-order')),
        findsOneWidget,
      );
      await _choose(tester, 'column-order-4', '2');
      expect(find.byKey(const ValueKey('column-error-4')), findsNothing);

      // Luật 2: không còn cột điểm nào.
      await _choose(tester, 'column-role-2', 'Bỏ qua');
      await _choose(tester, 'column-role-4', 'Bỏ qua');
      expect(
        find.byKey(const ValueKey('draft-general-noDiem')),
        findsOneWidget,
      );
      // Cột chữ 3 giờ trỏ vào cột không còn là điểm số → lỗi ở cột 3.
      expect(
        find.byKey(const ValueKey('column-error-3-pairing-pairedWith')),
        findsOneWidget,
      );
      await _tapKey(tester, 'wizard-next');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('wizard-save')))
            .onPressed,
        isNull,
      );
      expect(fake.calls, isNot(contains('create')));
      await _finish(tester);
    });

    testWidgets('lỗi backend khi phân tích hiện thông điệp thân thiện', (
      tester,
    ) async {
      final failing = _AnalyzeFails();
      await _pump(tester, fake: failing, location: '/admin/form-templates/new');
      await _tapKey(tester, 'pick-image');
      await _tapKey(tester, 'wizard-analyze');
      expect(
        find.text(
          'Không tìm thấy bảng kẻ ô trong ảnh. Chụp thẳng, đủ toàn bộ bảng.',
        ),
        findsOneWidget,
      );
      // Vẫn ở bước 1 để thử lại.
      expect(find.byKey(const ValueKey('wizard-step-image')), findsOneWidget);
      await _finish(tester);
    });
  });

  group('chi tiết mẫu', () {
    testWidgets('nút theo trạng thái; kích hoạt và ngừng', (tester) async {
      final fake = _FakeTemplates(templates: [_detail()]);
      await _pump(tester, fake: fake, location: '/admin/form-templates/5');
      expect(find.byKey(const ValueKey('detail-name')), findsOneWidget);
      expect(find.byKey(const ValueKey('act-activate')), findsOneWidget);
      expect(find.byKey(const ValueKey('act-retire')), findsNothing);
      expect(find.byKey(const ValueKey('act-edit')), findsOneWidget);
      expect(find.byKey(const ValueKey('act-new-version')), findsOneWidget);
      // Bảng cột: 6 cột, vai trò đúng.
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(ValueKey('detail-column-$i')), findsOneWidget);
      }

      await _tapKey(tester, 'act-activate');
      expect(fake.calls, contains('activate'));
      expect(find.byKey(const ValueKey('act-activate')), findsNothing);
      expect(find.byKey(const ValueKey('act-retire')), findsOneWidget);

      await _tapKey(tester, 'act-retire');
      await _tapKey(tester, 'confirm-retire');
      expect(fake.calls, contains('retire'));
      expect(find.byKey(const ValueKey('act-retire')), findsNothing);
      expect(find.text('Ngừng'), findsWidgets);
      await _finish(tester);
    });

    testWidgets('TEMPLATE_IN_USE ẩn nút Sửa kèm giải thích', (tester) async {
      final fake = _FakeTemplates(templates: [_detail()])
        ..updateError = _apiError(409, 'TEMPLATE_IN_USE');
      await _pump(tester, fake: fake, location: '/admin/form-templates/5');
      expect(find.byKey(const ValueKey('act-edit')), findsOneWidget);
      expect(find.byKey(const ValueKey('template-in-use-note')), findsNothing);

      await _tapKey(tester, 'act-edit');
      expect(find.byKey(const ValueKey('editor-save')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('editor-name')),
        'Sổ điểm đã sửa',
      );
      await tester.pump();
      await _tapKey(tester, 'editor-save');
      // Editor giữ nội dung và đổi sang lưu phiên bản mới.
      expect(fake.calls, contains('update'));
      expect(find.byKey(const ValueKey('editor-error')), findsOneWidget);
      expect(find.text('Lưu phiên bản mới'), findsOneWidget);

      // Lưu thành phiên bản mới → sang mẫu mới.
      await _tapKey(tester, 'editor-save');
      expect(fake.calls, contains('createVersion'));
      expect(fake.lastName, 'Sổ điểm đã sửa');
      expect(find.byKey(const ValueKey('detail-name')), findsOneWidget);
      await _finish(tester);
    });

    testWidgets('TEMPLATE_IN_USE: quay lại màn chi tiết thì Sửa đã ẩn', (
      tester,
    ) async {
      final fake = _FakeTemplates(templates: [_detail()])
        ..updateError = _apiError(409, 'TEMPLATE_IN_USE');
      await _pump(tester, fake: fake, location: '/admin/form-templates/5');
      await _tapKey(tester, 'act-edit');
      await _tapKey(tester, 'editor-save');
      expect(find.byKey(const ValueKey('editor-error')), findsOneWidget);
      await _tapKey(tester, 'editor-cancel');
      expect(find.byKey(const ValueKey('detail-name')), findsOneWidget);
      expect(find.byKey(const ValueKey('act-edit')), findsNothing);
      expect(
        find.byKey(const ValueKey('template-in-use-note')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('act-new-version')), findsOneWidget);
      await _finish(tester);
    });

    testWidgets('sửa tại chỗ thành công gọi update với cột đã sửa', (
      tester,
    ) async {
      final fake = _FakeTemplates(templates: [_detail()]);
      await _pump(tester, fake: fake, location: '/admin/form-templates/5');
      await _tapKey(tester, 'act-edit');
      await _choose(tester, 'column-role-5', 'Điểm số');
      // Cột điểm mới được gán sẵn TX và thứ tự còn trống (2).
      await _tapKey(tester, 'editor-save');
      expect(fake.calls, contains('update'));
      final saved = fake.lastColumns!;
      expect(saved[5].role, TemplateColumnDtoRoleEnum.DIEM);
      expect(saved[5].group, TemplateColumnDtoGroupEnum.TX);
      expect(saved[5].order, 2);
      expect(find.byKey(const ValueKey('detail-name')), findsOneWidget);
      await _finish(tester);
    });

    testWidgets('editor chặn Lưu khi khai báo sai và chỉ đúng cột sai', (
      tester,
    ) async {
      final bad = _goodColumns()
        ..[5] = _col(5, TemplateColumnDtoRoleEnum.HO_TEN, header: 'Tên 2');
      final fake = _FakeTemplates(templates: [_detail(columns: bad)]);
      await _pump(tester, fake: fake, location: '/admin/form-templates/5');
      await _tapKey(tester, 'act-edit');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('editor-save')))
            .onPressed,
        isNull,
      );
      expect(
        find.byKey(const ValueKey('column-error-1-hoTen-role')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('column-error-5-hoTen-role')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('column-error-2')), findsNothing);
      await _finish(tester);
    });

    testWidgets('AC-4: Thử nhận dạng hiện kết quả, không ghi gì', (
      tester,
    ) async {
      final fake = _FakeTemplates(templates: [_detail()]);
      await _pump(tester, fake: fake, location: '/admin/form-templates/5');
      expect(find.textContaining('Chỉ thử, không lưu'), findsOneWidget);
      await _tapKey(tester, 'pick-image');
      expect(fake.calls.where((c) => c == 'tryTemplate'), hasLength(1));
      expect(find.byKey(const ValueKey('try-result')), findsOneWidget);
      expect(find.text('Dòng 1'), findsOneWidget);
      expect(find.text('Họ tên đọc: Học sinh A'), findsOneWidget);
      expect(find.text('STT đọc: 1'), findsOneWidget);
      // Hai kênh, một kênh, không đọc được.
      expect(find.text('TX1 · Xanh'), findsOneWidget);
      expect(find.text('Số: 8.5 · Chữ: 8.5'), findsOneWidget);
      expect(find.text('GK1 · Vàng'), findsOneWidget);
      expect(find.text('Số: 7.0'), findsOneWidget);
      expect(find.text('Lấy theo điểm số'), findsOneWidget);
      expect(find.text('TX1 · Đỏ'), findsOneWidget);
      // Màu mức lấy từ token.
      final context = tester.element(find.byKey(const ValueKey('try-result')));
      final cell = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('try-grade-1-TX1')),
      );
      expect((cell.decoration as BoxDecoration).color, context.tokens.okSoft);
      // Chỉ gọi try; không có thao tác duyệt/ghi điểm trên màn.
      expect(fake.calls.where((c) => c != 'detail' && c != 'list'), [
        'tryTemplate',
      ]);
      for (final word in ['Duyệt', 'Ghi điểm', 'Lưu điểm', 'Chốt']) {
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('detail-try')),
            matching: find.textContaining(word),
          ),
          findsNothing,
          reason: word,
        );
      }
      await _finish(tester);
    });

    testWidgets('Thử nhận dạng lỗi hiện thông điệp và cho thử lại', (
      tester,
    ) async {
      final fake = _FakeTemplates(templates: [_detail()])
        ..tryError = _apiError(422, 'TEMPLATE_MISMATCH');
      await _pump(tester, fake: fake, location: '/admin/form-templates/5');
      await _tapKey(tester, 'pick-image');
      expect(find.byKey(const ValueKey('try-error')), findsOneWidget);
      expect(
        find.text(
          'Ảnh không khớp lưới của mẫu. Chọn ảnh đúng loại tờ hoặc chọn mẫu khác.',
        ),
        findsOneWidget,
      );
      fake.tryError = null;
      await _tapKey(tester, 'try-retry');
      expect(find.byKey(const ValueKey('try-error')), findsNothing);
      expect(find.byKey(const ValueKey('try-result')), findsOneWidget);
      await _finish(tester);
    });

    testWidgets('mẫu không tồn tại hiện lỗi và thử lại', (tester) async {
      final fake = _FakeTemplates();
      await _pump(tester, fake: fake, location: '/admin/form-templates/99');
      expect(find.byKey(const ValueKey('detail-error')), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
      await _finish(tester);
    });
  });

  group('AC-3: guard theo vai', () {
    for (final role in ['GIAO_VIEN', 'HOC_SINH']) {
      for (final path in [
        '/admin/form-templates',
        '/admin/form-templates/5',
        '/admin/form-templates/new',
      ]) {
        testWidgets('$role vào $path bị chuyển về /', (tester) async {
          final fake = _FakeTemplates(templates: [_detail()]);
          final container = await _pump(
            tester,
            fake: fake,
            role: role,
            location: path,
          );
          expect(_pathOf(container, path), '/');
          expect(fake.calls, isEmpty);
          await _finish(tester);
        });
      }
    }

    testWidgets('QTV vào được cả ba route', (tester) async {
      for (final path in [
        '/admin/form-templates',
        '/admin/form-templates/5',
        '/admin/form-templates/new',
      ]) {
        final fake = _FakeTemplates(templates: [_detail()]);
        final container = await _pump(tester, fake: fake, location: path);
        expect(_pathOf(container, path), path);
        await _finish(tester);
      }
    });

    testWidgets('mục sidebar "Mẫu bảng điểm" chỉ có ở QTV', (tester) async {
      final fake = _FakeTemplates();
      await _pump(tester, fake: fake);
      expect(find.text('Mẫu bảng điểm'), findsWidgets);
      await _finish(tester);
    });
  });

  group('responsive, chữ 1,3x, sáng/tối: không tràn', () {
    const widths = [320.0, 390.0, 1280.0];
    for (final width in widths) {
      for (final brightness in Brightness.values) {
        final tag = '${width.toInt()} px, ${brightness.name}';

        testWidgets('danh sách $tag', (tester) async {
          final fake = _FakeTemplates(
            templates: [
              _detail(name: 'Sổ điểm THCS rất dài để thử cắt chữ ở màn hẹp'),
              _detail(id: 6, status: TemplateDetailDtoStatusEnum.DANG_DUNG),
            ],
          );
          await _pump(
            tester,
            fake: fake,
            width: width,
            textScale: 1.3,
            brightness: brightness,
          );
          expect(tester.takeException(), isNull);
          expect(find.byKey(const ValueKey('template-tile-6')), findsOneWidget);
          final context = tester.element(
            find.byKey(const ValueKey('template-tile-6')),
          );
          expect(Theme.of(context).brightness, brightness);
          await _finish(tester);
        });

        testWidgets('trình hướng dẫn bước 2 và 3 $tag', (tester) async {
          final fake = _FakeTemplates();
          await _pump(
            tester,
            fake: fake,
            width: width,
            textScale: 1.3,
            brightness: brightness,
            location: '/admin/form-templates/new',
          );
          expect(tester.takeException(), isNull);
          await _tapKey(tester, 'pick-image');
          await _tapKey(tester, 'wizard-analyze');
          // Có lỗi cột chữ để chiều cao lỗi cũng được thử.
          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const ValueKey('column-error-3-pairing-pairedWith')),
            findsOneWidget,
          );
          await _tapKey(tester, 'wizard-next');
          expect(tester.takeException(), isNull);
          expect(find.byKey(const ValueKey('wizard-invalid')), findsOneWidget);
          await _finish(tester);
        });

        testWidgets('chi tiết kèm kết quả thử $tag', (tester) async {
          final fake = _FakeTemplates(templates: [_detail()]);
          await _pump(
            tester,
            fake: fake,
            width: width,
            textScale: 1.3,
            brightness: brightness,
            location: '/admin/form-templates/5',
          );
          expect(tester.takeException(), isNull);
          await _tapKey(tester, 'pick-image');
          expect(find.byKey(const ValueKey('try-result')), findsOneWidget);
          expect(tester.takeException(), isNull);
          final context = tester.element(
            find.byKey(const ValueKey('try-result')),
          );
          expect(context.tokens.brightness, brightness);
          await _finish(tester);
        });

        testWidgets('màn sửa $tag', (tester) async {
          final fake = _FakeTemplates(templates: [_detail()]);
          await _pump(
            tester,
            fake: fake,
            width: width,
            textScale: 1.3,
            brightness: brightness,
            location: '/admin/form-templates/5',
          );
          await _tapKey(tester, 'act-edit');
          expect(find.byKey(const ValueKey('editor-save')), findsOneWidget);
          expect(tester.takeException(), isNull);
          await _finish(tester);
        });
      }
    }
  });

  group('repository thật gửi multipart đúng', () {
    testWidgets('analyze, create, try gửi ảnh thật trong thân multipart', (
      tester,
    ) async {
      final adapter = _RecordingAdapter();
      final repo = ApiFormTemplatesRepository(
        ApiClientDart(dio: Dio()..httpClientAdapter = adapter),
      );
      final image = RecognitionImage(name: 'sample.png', bytes: _png);
      await tester.runAsync(() async {
        final analysis = await repo.analyze(image);
        expect(analysis.columnCount, 6);
        final created = await repo.create(
          image: image,
          name: 'Mẫu A',
          description: null,
          columns: _goodColumns(),
        );
        expect(created.id, 5);
        final tried = await repo.tryTemplate(id: 5, image: image);
        expect(tried.rows, hasLength(2));
      });
      expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
        'POST /api/v1/catalog/form-templates/analyze',
        'POST /api/v1/catalog/form-templates',
        'POST /api/v1/catalog/form-templates/5/try',
      ]);
      for (final r in adapter.requests) {
        expect(r.contentType, startsWith('multipart/form-data'));
        expect(r.body, contains('name="image"'));
        expect(r.body, contains('filename="sample.png"'));
        expect(r.body, contains('image/png'));
      }
      final create = adapter.requests[1].body;
      expect(create, contains('name="definition"'));
      expect(create, contains('"name":"Mẫu A"'));
      expect(create, contains('"role":"HO_TEN"'));
      expect(create, contains('"pairedWith":2'));
    });

    testWidgets('ảnh sai định dạng bị chặn trước khi gửi', (tester) async {
      final adapter = _RecordingAdapter();
      final repo = ApiFormTemplatesRepository(
        ApiClientDart(dio: Dio()..httpClientAdapter = adapter),
      );
      await tester.runAsync(() async {
        await expectLater(
          repo.analyze(
            RecognitionImage(name: 'x.png', bytes: Uint8List.fromList([1, 2])),
          ),
          throwsA(isA<RecognitionImageException>()),
        );
      });
      expect(adapter.requests, isEmpty);
    });
  });
}

/// Repository giả mà `analyze` luôn lỗi `GRID_NOT_FOUND`.
class _AnalyzeFails extends _FakeTemplates {
  @override
  Future<AnalyzeResultDto> analyze(RecognitionImage image) =>
      Future.error(_apiError(422, 'GRID_NOT_FOUND'));
}

class _Recorded {
  _Recorded(this.method, this.path, this.contentType, this.body);
  final String method;
  final String path;
  final String contentType;
  final String body;
}

class _RecordingAdapter implements HttpClientAdapter {
  final List<_Recorded> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }
    requests.add(
      _Recorded(
        options.method,
        options.path,
        options.headers['content-type']?.toString() ??
            options.contentType ??
            '',
        utf8.decode(bytes, allowMalformed: true),
      ),
    );
    final Object body = options.path.endsWith('/analyze')
        ? _analysis().toJson()
        : options.path.endsWith('/try')
        ? _tryResult().toJson()
        : _detail().toJson();
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}
