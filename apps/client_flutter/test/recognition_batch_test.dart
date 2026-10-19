import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/recognition/batch_repository.dart';
import 'package:client_flutter/features/recognition/image_picker.dart';
import 'package:client_flutter/features/recognition/recognition_panel.dart';
import 'package:client_flutter/features/recognition/review_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'phase3_recognition_test.dart'
    show FakeRecognitionPicker, RecognitionFakeServer;

/// Máy chủ giả của luồng cũ, thêm phiếu "43" dùng chung dữ liệu với phiếu "42".
class _TwoTicketServer implements HttpClientAdapter {
  // Danh sách phiếu của máy chủ cũ luôn có phiếu "42" (lô giả không gọi nó).
  final RecognitionFakeServer inner = RecognitionFakeServer()..uploaded = true;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    options.path = options.path.replaceAll(
      '/recognition-tickets/43',
      '/recognition-tickets/42',
    );
    return inner.fetch(options, requestStream, cancelFuture);
  }
}

MappingItemDto _item(
  int index,
  String key, {
  int order = 1,
  MappingItemDtoChannelsEnum channels = MappingItemDtoChannelsEnum.SO_CHU,
  num? componentId,
  String? componentName,
  bool locked = false,
  bool pending = false,
}) => MappingItemDto(
  templateColumnIndex: index,
  key: key,
  group: MappingItemDtoGroupEnum.TX,
  order: order,
  channels: channels,
  componentId: componentId,
  componentName: componentName,
  locked: locked,
  pending: pending,
);

RecognitionBatchTicketDto _ticket(
  String id,
  num componentId,
  String name,
  int column, {
  RecognitionBatchTicketDtoStatusEnum status =
      RecognitionBatchTicketDtoStatusEnum.CHO_DOI_CHIEU,
  int green = 0,
  int yellow = 0,
  int red = 0,
}) => RecognitionBatchTicketDto(
  ticketId: id,
  componentId: componentId,
  componentName: name,
  templateColumnIndex: column,
  status: status,
  errorCode: null,
  version: 1,
  greenRows: green,
  yellowRows: yellow,
  redRows: red,
);

RecognitionBatchDto _batch(
  RecognitionBatchDtoStatusEnum status, {
  String? errorCode,
  int? errorPage,
  String? cancelReason,
  List<RecognitionBatchTicketDto>? tickets,
}) => RecognitionBatchDto(
  batchId: '9',
  gradebookId: 7,
  templateId: 5,
  pageCount: 2,
  status: status,
  errorCode: errorCode,
  errorPage: errorPage,
  modelVersion: null,
  version: 1,
  createdAt: DateTime.utc(2026, 10, 19),
  cancelReason: cancelReason,
  cancelledAt: null,
  imageUrlExpiresInSeconds: 300,
  pages: const [],
  tickets:
      tickets ??
      [
        _ticket(
          '42',
          201,
          'Kiểm tra thường xuyên 1',
          3,
          green: 5,
          yellow: 2,
          red: 1,
        ),
        _ticket(
          '43',
          202,
          'Kiểm tra thường xuyên 2',
          4,
          green: 4,
          yellow: 3,
          red: 0,
        ),
      ],
);

class _FakeBatchRepository implements RecognitionBatchRepository {
  List<TemplateSummaryDto> templates = [
    TemplateSummaryDto(
      id: 5,
      name: 'Mẫu THPT mô phỏng',
      description: null,
      status: TemplateSummaryDtoStatusEnum.DANG_DUNG,
      revision: 1,
      rootTemplateId: null,
      columnCount: 8,
      gradeColumnCount: 4,
      version: 1,
      createdAt: DateTime.utc(2026, 10, 18),
    ),
  ];
  MappingDto mappingResult = MappingDto(
    gradebookId: 7,
    templateId: 5,
    items: [
      _item(
        3,
        'TX1',
        componentId: 201,
        componentName: 'Kiểm tra thường xuyên 1',
      ),
      _item(
        4,
        'TX2',
        order: 2,
        channels: MappingItemDtoChannelsEnum.SO,
        componentId: 202,
        componentName: 'Kiểm tra thường xuyên 2',
      ),
      _item(
        5,
        'TX3',
        order: 3,
        componentId: 203,
        componentName: 'Kiểm tra thường xuyên 3',
        locked: true,
      ),
      _item(
        6,
        'TX4',
        order: 4,
        componentId: 204,
        componentName: 'Kiểm tra thường xuyên 4',
        pending: true,
      ),
      _item(7, 'GK', order: 5),
    ],
  );
  Object? submitError;
  Object? cancelError;
  final List<RecognitionBatchDto> detailQueue = [];
  RecognitionBatchDto? lastDetail;
  int mappingCalls = 0;
  int detailCalls = 0;
  int submitCalls = 0;
  int cancelCalls = 0;
  String? cancelReason;
  List<RecognitionImage>? submittedImages;
  List<BatchComponentChoice>? submittedChoices;
  num? submittedTemplateId;

  @override
  Future<List<TemplateSummaryDto>> activeTemplates() async => templates;

  @override
  Future<MappingDto> mapping({
    required num gradebookId,
    required num templateId,
  }) async {
    mappingCalls++;
    return mappingResult;
  }

  @override
  Future<RecognitionBatchReceiptDto> submit({
    required num gradebookId,
    required num templateId,
    required List<RecognitionImage> images,
    required List<BatchComponentChoice> components,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    submitCalls++;
    final error = submitError;
    if (error != null) throw error;
    submittedImages = images;
    submittedChoices = components;
    submittedTemplateId = templateId;
    onSendProgress?.call(50, 100);
    onSendProgress?.call(100, 100);
    return RecognitionBatchReceiptDto(
      batchId: '9',
      jobId: 'recognition-batch-9',
      status: RecognitionBatchReceiptDtoStatusEnum.DANG_XU_LY,
      tickets: [
        for (final c in components)
          RecognitionBatchTicketReceiptDto(
            ticketId: '${c.componentId.toInt() - 159}',
            componentId: c.componentId,
          ),
      ],
    );
  }

  @override
  Future<RecognitionBatchDto> detail({
    required num gradebookId,
    required String batchId,
  }) async {
    detailCalls++;
    if (detailQueue.isNotEmpty) lastDetail = detailQueue.removeAt(0);
    return lastDetail ?? _batch(RecognitionBatchDtoStatusEnum.DANG_XU_LY);
  }

  @override
  Future<RecognitionBatchDto> cancel({
    required num gradebookId,
    required String batchId,
    required String reason,
  }) async {
    cancelCalls++;
    final error = cancelError;
    if (error != null) throw error;
    cancelReason = reason;
    lastDetail = _batch(
      RecognitionBatchDtoStatusEnum.DA_HUY,
      cancelReason: reason,
      tickets: [
        _ticket(
          '42',
          201,
          'Kiểm tra thường xuyên 1',
          3,
          status: RecognitionBatchTicketDtoStatusEnum.DA_HUY,
        ),
      ],
    );
    detailQueue.clear();
    return lastDetail!;
  }
}

void _useView(WidgetTester tester, Size size, [double scale = 1.0]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _pumpPanel(
  WidgetTester tester,
  _FakeBatchRepository repo, {
  Size size = const Size(1280, 1800),
  double scale = 1.0,
  List<Override> overrides = const [],
}) async {
  _useView(tester, size, scale);
  final api = ApiClientDart(dio: Dio()..httpClientAdapter = _TwoTicketServer());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiProvider.overrideWithValue(api),
        recognitionImagePickerProvider.overrideWithValue(
          FakeRecognitionPicker(),
        ),
        recognitionBatchRepositoryProvider.overrideWithValue(repo),
        ...overrides,
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecognitionPanel(
              gradebookId: 7,
              components: const [RecognitionComponentOption(201, 'Giữa kỳ')],
              gradebookVersion: 1,
              enabled: true,
              embedded: true,
              classSubjectLabel: '10A1 · Toán',
              onApproved: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Thay `pumpAndSettle` khi trên màn có vòng quay tiến độ chạy mãi (lô đang xử lý).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _chooseTemplate(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('recognition-template-select-0')));
  await _settle(tester);
  await tester.tap(find.text('Mẫu THPT mô phỏng').last);
  await _settle(tester);
}

Future<void> _expandGreenGroup(WidgetTester tester) async {
  final group = find.byKey(const ValueKey('review-green-group'));
  await tester.ensureVisible(group);
  await tester.tap(group);
  await tester.pumpAndSettle();
}

Future<void> _addPage(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.tap(find.byKey(const ValueKey('batch-add-page')));
    // Bộ giải mã ảnh của engine chạy ngoài đồng hồ giả.
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await _settle(tester);
}

Finder get _submit => find.byKey(const ValueKey('batch-submit'));

bool _enabled(WidgetTester tester) =>
    tester
        .widget<FilledButton>(
          find.descendant(
            of: _submit,
            matching: find.byWidgetPredicate((w) => w is FilledButton),
          ),
        )
        .onPressed !=
    null;

void main() {
  group('Nhận dạng theo mẫu (ADR-0016 mục 5)', () {
    testWidgets(
      'AC-2: mẫu → 2 ảnh → 2 cột → gửi → lô xong → 2 tab → đối chiếu',
      (tester) async {
        final repo = _FakeBatchRepository()
          ..detailQueue.addAll([
            _batch(RecognitionBatchDtoStatusEnum.DANG_XU_LY),
            _batch(RecognitionBatchDtoStatusEnum.XONG),
          ]);
        await _pumpPanel(tester, repo);

        // Mặc định chưa chọn mẫu: luồng cũ, có ô chọn mẫu "Không dùng mẫu".
        expect(find.text('Không dùng mẫu (mẫu E0330113 cũ)'), findsOneWidget);
        expect(find.byKey(const ValueKey('recognition-pick')), findsOneWidget);
        expect(find.byKey(const ValueKey('batch-section')), findsNothing);

        await _chooseTemplate(tester);
        expect(find.byKey(const ValueKey('batch-section')), findsOneWidget);
        expect(find.byKey(const ValueKey('recognition-pick')), findsNothing);
        expect(repo.mappingCalls, 1);

        // Danh sách cột: "Cột TX1 → Kiểm tra thường xuyên 1 · số + chữ".
        expect(
          find.text('Cột TX1 → Kiểm tra thường xuyên 1 · số + chữ'),
          findsOneWidget,
        );
        expect(
          find.text('Cột TX2 → Kiểm tra thường xuyên 2 · chỉ số'),
          findsOneWidget,
        );

        // AC-3: chưa có ảnh, chưa chọn cột → không gửi được.
        expect(_enabled(tester), isFalse);
        expect(find.byKey(const ValueKey('batch-submit-hint')), findsOneWidget);

        // Có ảnh nhưng chưa chọn cột → vẫn không gửi được.
        await _addPage(tester);
        expect(
          find.byKey(const ValueKey('batch-page-label-0')),
          findsOneWidget,
        );
        expect(_enabled(tester), isFalse);

        // Có cột nhưng bỏ hết ảnh → không gửi được.
        await tester.tap(find.byKey(const ValueKey('batch-column-3')));
        await tester.pumpAndSettle();
        expect(_enabled(tester), isTrue);
        await tester.tap(find.byKey(const ValueKey('batch-page-remove-0')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('batch-page-0')), findsNothing);
        expect(_enabled(tester), isFalse);

        // 2 ảnh, mỗi ảnh có thẻ "Trang n", đổi thứ tự được.
        await _addPage(tester);
        await _addPage(tester);
        expect(find.text('Trang 1'), findsOneWidget);
        expect(find.text('Trang 2'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('batch-page-down-0')));
        await tester.pumpAndSettle();
        expect(find.text('Trang 2'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('batch-column-4')));
        await tester.pumpAndSettle();
        expect(_enabled(tester), isTrue);

        await tester.ensureVisible(_submit);
        await tester.tap(_submit);
        await tester.pump();
        await tester.pump();

        expect(repo.submitCalls, 1);
        expect(repo.submittedTemplateId, 5);
        expect(repo.submittedImages, hasLength(2));
        expect(
          [
            for (final c in repo.submittedChoices!)
              (c.templateColumnIndex, c.componentId),
          ],
          [(3, 201), (4, 202)],
        );
        expect(find.byKey(const ValueKey('batch-status-card')), findsOneWidget);
        // Thẻ phiếu trong danh sách gần đây: "N ảnh · tên mẫu".
        await tester.pump(const Duration(milliseconds: 50));
        expect(
          find.byKey(const ValueKey('recognition-ticket-batch-42')),
          findsOneWidget,
        );
        expect(find.text('2 ảnh · Mẫu THPT mô phỏng'), findsOneWidget);

        // Polling 3 giây: lần đầu còn DANG_XU_LY, lần sau XONG và tự mở kết quả.
        expect(repo.detailCalls, 0);
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
        expect(repo.detailCalls, 1);
        expect(find.text('Đang xử lý'), findsWidgets);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(repo.detailCalls, greaterThanOrEqualTo(2));

        // Màn kết quả: 2 tab theo thành phần, mỗi tab có số Xanh/Vàng/Đỏ.
        expect(
          find.byKey(const ValueKey('batch-result-screen')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('batch-tab-42')), findsOneWidget);
        expect(find.byKey(const ValueKey('batch-tab-43')), findsOneWidget);
        expect(find.text('5 Xanh'), findsOneWidget);
        expect(find.text('2 Vàng'), findsOneWidget);
        expect(find.text('1 Đỏ'), findsOneWidget);
        expect(find.text('4 Xanh'), findsOneWidget);
        expect(find.text('3 Vàng'), findsOneWidget);
        expect(find.text('0 Đỏ'), findsOneWidget);

        // AC-4: bấm tab mở đúng màn đối chiếu hiện có của phiếu đó.
        await tester.tap(find.byKey(const ValueKey('batch-tab-43')));
        await tester.pumpAndSettle();
        final review = tester.widget<ReviewScreen>(find.byType(ReviewScreen));
        expect(review.ticketId, '43');
        expect(review.gradebookId, 7);
        expect(review.showPageLabels, isTrue);
        // Dòng của phiếu thuộc lô có nhãn trang trong thẻ dòng.
        await _expandGreenGroup(tester);
        expect(find.textContaining('Trang 1'), findsWidgets);
      },
    );

    testWidgets(
      'AC-3: cột khóa / đang chờ / chưa ánh xạ không chọn được, có lý do',
      (tester) async {
        final repo = _FakeBatchRepository();
        await _pumpPanel(tester, repo);
        await _chooseTemplate(tester);
        await _addPage(tester);

        for (final index in [5, 6, 7]) {
          expect(
            tester
                .widget<CheckboxListTile>(
                  find.byKey(ValueKey('batch-column-$index')),
                )
                .onChanged,
            isNull,
            reason: 'cột $index phải bị vô hiệu',
          );
          expect(
            find.byKey(ValueKey('batch-column-reason-$index')),
            findsOneWidget,
          );
        }
        expect(find.textContaining('Cột đã khóa'), findsOneWidget);
        expect(find.textContaining('Đang có phiếu chờ'), findsOneWidget);
        expect(find.textContaining('không có thành phần điểm'), findsOneWidget);

        // Bấm vào cột khóa không làm gì: vẫn không gửi được.
        await tester.tap(
          find.byKey(const ValueKey('batch-column-5')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<CheckboxListTile>(
                find.byKey(const ValueKey('batch-column-5')),
              )
              .value,
          isFalse,
        );
        expect(_enabled(tester), isFalse);
      },
    );

    testWidgets('quá 4 ảnh hiện thông báo và không thêm trang thứ 5', (
      tester,
    ) async {
      final repo = _FakeBatchRepository();
      await _pumpPanel(tester, repo);
      await _chooseTemplate(tester);
      for (var i = 0; i < 4; i++) {
        await _addPage(tester);
      }
      expect(find.byKey(const ValueKey('batch-page-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('batch-too-many')), findsNothing);
      await _addPage(tester);
      expect(find.byKey(const ValueKey('batch-too-many')), findsOneWidget);
      expect(find.byKey(const ValueKey('batch-page-4')), findsNothing);
      expect(find.textContaining('tối đa 4 trang'), findsOneWidget);
    });

    testWidgets('lô lỗi TEMPLATE_MISMATCH hiện thông báo theo mã kèm số trang', (
      tester,
    ) async {
      final repo = _FakeBatchRepository()
        ..detailQueue.add(
          _batch(
            RecognitionBatchDtoStatusEnum.LOI,
            errorCode: 'TEMPLATE_MISMATCH',
            errorPage: 2,
            tickets: const [],
          ),
        );
      await _pumpPanel(
        tester,
        repo,
        overrides: [trackedBatchProvider(7).overrideWith((ref) => '9')],
      );
      await _chooseTemplate(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      final error = tester.widget<Text>(
        find.byKey(const ValueKey('batch-error')),
      );
      expect(
        error.data,
        'Trang 2: Ảnh không khớp lưới của mẫu đã chọn. Chọn đúng loại tờ hoặc đổi sang mẫu khác.',
      );
      // Đóng thông báo để gửi lại.
      await tester.tap(find.byKey(const ValueKey('batch-dismiss')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('batch-status-card')), findsNothing);
    });

    for (final (code, snippet) in [
      ('TOO_MANY_PAGES', 'tối đa 4 trang'),
      ('COMPONENT_NOT_MAPPABLE', 'không ánh xạ được'),
      ('TEMPLATE_INACTIVE', 'ngừng dùng'),
      ('TEMPLATE_MISMATCH', 'không khớp lưới'),
    ]) {
      testWidgets(
        'gửi lô bị API từ chối $code hiện thông báo, giữ ảnh và cột',
        (tester) async {
          final repo = _FakeBatchRepository()
            ..submitError = DioException(
              requestOptions: RequestOptions(path: '/x'),
              response: Response(
                requestOptions: RequestOptions(path: '/x'),
                statusCode: 400,
                data: {'code': code, 'message': 'x'},
              ),
            );
          await _pumpPanel(tester, repo);
          await _chooseTemplate(tester);
          await _addPage(tester);
          await tester.tap(find.byKey(const ValueKey('batch-column-3')));
          await tester.pumpAndSettle();
          await tester.ensureVisible(_submit);
          await tester.tap(_submit);
          await tester.pumpAndSettle();
          expect(repo.submitCalls, 1);
          final text = tester.widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('batch-submit-error')),
              matching: find.byType(Text),
            ),
          );
          expect(text.data, contains(snippet));
          expect(find.byKey(const ValueKey('batch-page-0')), findsOneWidget);
          expect(
            tester
                .widget<CheckboxListTile>(
                  find.byKey(const ValueKey('batch-column-3')),
                )
                .value,
            isTrue,
          );
        },
      );
    }

    testWidgets('hủy lô đang xử lý: hỏi lý do, gọi hủy, hiện "Đã hủy"', (
      tester,
    ) async {
      final repo = _FakeBatchRepository()
        ..detailQueue.add(_batch(RecognitionBatchDtoStatusEnum.DANG_XU_LY));
      await _pumpPanel(
        tester,
        repo,
        overrides: [trackedBatchProvider(7).overrideWith((ref) => '9')],
      );
      await _chooseTemplate(tester);
      await _settle(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('batch-cancel')));
      await tester.tap(find.byKey(const ValueKey('batch-cancel')));
      await _settle(tester);
      expect(find.byKey(const ValueKey('cancel-batch-dialog')), findsOneWidget);
      // Chưa chọn lý do thì chưa hủy được.
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('confirm-cancel-batch')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(
        find.byKey(const ValueKey('cancel-batch-reason-Chọn nhầm ảnh')),
      );
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('confirm-cancel-batch')));
      await _settle(tester);
      expect(repo.cancelCalls, 1);
      expect(repo.cancelReason, 'Chọn nhầm ảnh');
      expect(find.byKey(const ValueKey('cancel-batch-dialog')), findsNothing);
      expect(find.text('Đã hủy'), findsOneWidget);
      expect(find.textContaining('Lý do: Chọn nhầm ảnh'), findsOneWidget);
    });

    testWidgets('hủy lô lỗi (đã duyệt hết) hiện thông báo và giữ hộp thoại', (
      tester,
    ) async {
      final repo = _FakeBatchRepository()
        ..cancelError = DioException(
          requestOptions: RequestOptions(path: '/x'),
          response: Response(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 409,
            data: {'code': 'BATCH_ALREADY_APPROVED', 'message': 'x'},
          ),
        );
      await _pumpPanel(
        tester,
        repo,
        overrides: [trackedBatchProvider(7).overrideWith((ref) => '9')],
      );
      await _chooseTemplate(tester);
      await _settle(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('batch-cancel')));
      await tester.tap(find.byKey(const ValueKey('batch-cancel')));
      await _settle(tester);
      await tester.tap(
        find.byKey(const ValueKey('cancel-batch-reason-Chọn nhầm ảnh')),
      );
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('confirm-cancel-batch')));
      await _settle(tester);
      expect(find.byKey(const ValueKey('cancel-batch-dialog')), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('cancel-batch-error')))
            .data,
        'Mọi phiếu của lô đã được duyệt nên không thể hủy lô.',
      );
    });

    testWidgets('"Không dùng mẫu" giữ nguyên luồng một ảnh cũ', (tester) async {
      final repo = _FakeBatchRepository();
      await _pumpPanel(tester, repo);
      await _chooseTemplate(tester);
      expect(find.byKey(const ValueKey('batch-section')), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('recognition-template-select-5')),
      );
      await _settle(tester);
      await tester.tap(find.text('Không dùng mẫu (mẫu E0330113 cũ)').last);
      await _settle(tester);
      expect(find.byKey(const ValueKey('batch-section')), findsNothing);
      expect(find.byKey(const ValueKey('recognition-pick')), findsOneWidget);
      expect(find.byKey(const ValueKey('recognition-upload')), findsOneWidget);
    });

    testWidgets('mẫu đã chọn được nhớ theo bảng điểm trong phiên', (
      tester,
    ) async {
      final repo = _FakeBatchRepository();
      await _pumpPanel(tester, repo);
      await _chooseTemplate(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(RecognitionPanel)),
      );
      expect(container.read(selectedTemplateProvider(7)), 5);
      expect(container.read(selectedTemplateProvider(8)), isNull);
    });

    testWidgets('panel dựng lại vẫn ở mẫu đã nhớ của bảng điểm', (
      tester,
    ) async {
      final repo = _FakeBatchRepository();
      await _pumpPanel(
        tester,
        repo,
        overrides: [selectedTemplateProvider(7).overrideWith((ref) => 5)],
      );
      expect(find.byKey(const ValueKey('batch-section')), findsOneWidget);
      expect(find.byKey(const ValueKey('recognition-pick')), findsNothing);
    });

    testWidgets(
      'không có mẫu DANG_DUNG: panel y hệt luồng cũ, không có ô chọn mẫu',
      (tester) async {
        final repo = _FakeBatchRepository()..templates = [];
        await _pumpPanel(tester, repo);
        expect(find.text('Mẫu bảng điểm'), findsNothing);
        expect(find.byKey(const ValueKey('recognition-pick')), findsOneWidget);
      },
    );

    for (final width in [320.0, 390.0, 1280.0]) {
      testWidgets('responsive ${width.toInt()} px, chữ 1,3×: không tràn', (
        tester,
      ) async {
        final repo = _FakeBatchRepository()
          ..detailQueue.add(_batch(RecognitionBatchDtoStatusEnum.DANG_XU_LY));
        await _pumpPanel(
          tester,
          repo,
          size: Size(width, 2400),
          scale: 1.3,
          overrides: [trackedBatchProvider(7).overrideWith((ref) => '9')],
        );
        await _chooseTemplate(tester);
        await _addPage(tester);
        await _addPage(tester);
        await tester.tap(find.byKey(const ValueKey('batch-column-3')));
        await _settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('batch-status-card')), findsOneWidget);
      });
    }
  });

  group('Nhãn trang trên màn đối chiếu', () {
    testWidgets('phiếu không thuộc lô: không có nhãn "Trang n"', (
      tester,
    ) async {
      _useView(tester, const Size(1280, 1000));
      final api = ApiClientDart(
        dio: Dio()..httpClientAdapter = RecognitionFakeServer(),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiProvider.overrideWithValue(api)],
          child: const MaterialApp(
            home: ReviewScreen(gradebookId: 7, ticketId: '42'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _expandGreenGroup(tester);
      expect(find.textContaining('Trang '), findsNothing);
    });

    testWidgets('phiếu thuộc lô: thẻ dòng có "Trang n"', (tester) async {
      _useView(tester, const Size(1280, 1000));
      final api = ApiClientDart(
        dio: Dio()..httpClientAdapter = RecognitionFakeServer(),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiProvider.overrideWithValue(api)],
          child: const MaterialApp(
            home: ReviewScreen(
              gradebookId: 7,
              ticketId: '42',
              showPageLabels: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _expandGreenGroup(tester);
      expect(find.textContaining('Trang 1'), findsWidgets);
    });
  });
}
