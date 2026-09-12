import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/app/app.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:client_flutter/features/recognition/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRecognitionPicker implements RecognitionImagePicker {
  @override
  Future<RecognitionImage?> pick() async => RecognitionImage(
    name: 'bang-diem.png',
    bytes: Uint8List.fromList([
      137,
      80,
      78,
      71,
      13,
      10,
      26,
      10,
      0,
      0,
      0,
      0,
      73,
      72,
      68,
      82,
      0,
      0,
      0,
      100,
      0,
      0,
      0,
      100,
    ]),
  );
}

class RecognitionFakeServer implements HttpClientAdapter {
  bool uploaded = false;
  int detailCalls = 0;
  FormData? uploadedForm;
  Map<String, dynamic>? approvalBody;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object body;
    var status = 200;
    if (options.path.endsWith('/login')) {
      body = {
        'id': 2,
        'username': 'giao_vien_test',
        'role': 'GIAO_VIEN',
        'active': true,
        'token': 'test-token',
        'csrf': 'test-csrf',
      };
    } else if (options.path.endsWith('/gradebooks/7/cells')) {
      body = {
        'book': {
          'id': 7,
          'classId': 10,
          'subjectId': 20,
          'termId': 30,
          'status': 'DANG_NHAP_LIEU',
          'version': 1,
        },
        'items': [_cell('9001', 101, 'An'), _cell('9002', 102, 'Bình')],
        'nextCursor': null,
      };
    } else if (options.path.endsWith('/recognition-tickets') &&
        options.method == 'POST') {
      uploadedForm = options.data as FormData;
      uploaded = true;
      body = {
        'ticketId': '42',
        'jobId': 'recognition-42',
        'status': 'DANG_XU_LY',
      };
      status = 202;
    } else if (options.path.endsWith('/recognition-tickets') &&
        options.method == 'GET') {
      body = uploaded ? [_ticket()] : <Object>[];
    } else if (options.path.endsWith('/recognition-tickets/42/approve')) {
      approvalBody = jsonDecode(options.data as String) as Map<String, dynamic>;
      body = {
        'ticketId': '42',
        'ticketVersion': 2,
        'gradebookId': 7,
        'gradebookVersion': 2,
        'reviewedRows': 1,
        'machineMatchedRows': 1,
        'humanCorrectedRows': 0,
        'errorRows': 0,
        'status': 'DA_DUYET',
      };
    } else if (options.path.endsWith('/recognition-tickets/42')) {
      detailCalls++;
      body = {
        ..._ticket(),
        'sourceImageUrl': 'https://storage.test/source-$detailCalls.png',
        'imageUrlExpiresInSeconds': 300,
        'rows': [
          {
            'rowId': '51',
            'order': 1,
            'studentId': 101,
            'studentName': 'An',
            'numericRaw': '0.0',
            'numericValue': '0.0',
            'numericConfidence': '0.9500',
            'writtenRaw': 'không',
            'writtenValue': '0.0',
            'writtenConfidence': '0.9300',
            'comparison': 'KHOP',
            'reviewLevel': 'XANH',
            'finalValue': null,
            'numericCropUrl': 'https://storage.test/numeric.png',
            'writtenCropUrl': 'https://storage.test/written.png',
          },
        ],
      };
    } else {
      status = 404;
      body = <String, Object>{};
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  Map<String, Object?> _ticket() => {
    'ticketId': '42',
    'gradebookId': 7,
    'componentId': 201,
    'componentName': 'Điểm ảnh',
    'declaredRows': 2,
    'detectedRows': 2,
    'status': 'CHO_DOI_CHIEU',
    'errorCode': null,
    'modelVersion': 'fake-dev-v1',
    'version': 1,
    'createdAt': '2026-09-12T01:02:03.000Z',
  };

  Map<String, Object?> _cell(String id, int studentId, String name) => {
    'id': id,
    'studentId': studentId,
    'studentName': name,
    'active': true,
    'componentId': 201,
    'componentName': 'Điểm ảnh',
    'coefficient': '1.0',
    'required': true,
    'displayOrder': 1,
    'value': null,
    'status': 'CHUA_CO',
    'source': 'NHAP_TAY',
  };
}

void main() {
  testWidgets('teacher uploads an image and sees recognition evidence', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final server = RecognitionFakeServer();
    final api = ApiClientDart(dio: Dio()..httpClientAdapter = server);
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWithValue(api),
        recognitionImagePickerProvider.overrideWithValue(
          FakeRecognitionPicker(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(
      () => container
          .read(sessionProvider.notifier)
          .login('giao_vien_test', 'fake-password'),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const GradebookApp(initialLocation: '/gradebooks/7'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nhận dạng bảng điểm từ ảnh'), findsOneWidget);
    await tester.tap(find.text('Nhận dạng bảng điểm từ ảnh'));
    await tester.pumpAndSettle();
    expect(find.text('Số dòng khai báo: 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('recognition-pick')));
    await tester.pumpAndSettle();
    expect(find.text('bang-diem.png'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('recognition-upload')));
    await tester.pumpAndSettle();
    final fields = Map.fromEntries(server.uploadedForm!.fields);
    expect(fields['componentId'], '201');
    expect(fields['declaredRows'], '2');
    expect(server.uploadedForm?.files.single.key, 'image');
    expect(find.textContaining('Chờ đối chiếu'), findsOneWidget);

    await tester.tap(find.textContaining('Phiếu #42'));
    await tester.pumpAndSettle();
    expect(find.textContaining('An · XANH'), findsOneWidget);
    expect(find.textContaining('Giá trị: 0.0'), findsNWidgets(2));
    await tester.enterText(
      find.byKey(const ValueKey('review-value-51')),
      '0.1',
    );
    await tester.tap(find.byKey(const ValueKey('review-refresh-source')));
    await tester.pumpAndSettle();
    expect(server.detailCalls, 2);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('review-value-51')))
          .controller
          ?.text,
      '0.1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('review-value-51')),
      '0.0',
    );
    await tester.tap(find.byKey(const ValueKey('review-confirm-all')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('review-approve')));
    await tester.pumpAndSettle();
    expect(server.approvalBody?['expectedTicketVersion'], 1);
    expect(server.approvalBody?['expectedGradebookVersion'], 1);
    final decisions = server.approvalBody?['decisions'] as List<dynamic>;
    expect(decisions.single['rowId'], '51');
    expect(decisions.single['value'], '0.0');
    expect(find.text('Phiếu nhận dạng #42'), findsNothing);
  });
}
