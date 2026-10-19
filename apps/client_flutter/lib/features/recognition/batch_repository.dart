import 'dart:convert';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../authentication/session.dart';
import '../form_templates/repository.dart' show apiErrorCode;
import 'image_picker.dart';
import 'image_preview.dart';

/// Số trang tối đa mỗi lô (ADR-0016 mục 3, D-02).
const int kMaxBatchPages = 4;

/// Một cột mẫu đã chọn cùng thành phần điểm nhận kết quả.
class BatchComponentChoice {
  const BatchComponentChoice({
    required this.templateColumnIndex,
    required this.componentId,
  });

  final int templateColumnIndex;
  final num componentId;

  Map<String, Object> toJson() => {
    'templateColumnIndex': templateColumnIndex,
    'componentId': componentId.toInt(),
  };
}

/// Cổng duy nhất của panel nhận dạng theo mẫu tới API. Widget không gọi Dio;
/// test thay bằng bản giả qua [recognitionBatchRepositoryProvider].
abstract interface class RecognitionBatchRepository {
  /// Mẫu `DANG_DUNG` mà giáo viên được chọn.
  Future<List<TemplateSummaryDto>> activeTemplates();

  Future<MappingDto> mapping({
    required num gradebookId,
    required num templateId,
  });

  Future<RecognitionBatchReceiptDto> submit({
    required num gradebookId,
    required num templateId,
    required List<RecognitionImage> images,
    required List<BatchComponentChoice> components,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  });

  Future<RecognitionBatchDto> detail({
    required num gradebookId,
    required String batchId,
  });

  Future<RecognitionBatchDto> cancel({
    required num gradebookId,
    required String batchId,
    required String reason,
  });
}

final recognitionBatchRepositoryProvider = Provider<RecognitionBatchRepository>(
  (ref) => ApiRecognitionBatchRepository(ref.read(apiProvider)),
);

/// Danh sách mẫu `DANG_DUNG`. Lỗi (ví dụ máy chủ chưa có mẫu) thì panel ẩn
/// bộ chọn mẫu và hoạt động như luồng cũ. Không dùng `autoDispose`: panel tải
/// lại danh sách mỗi lần mở lại (xem `RecognitionPanel.initState`).
final activeTemplatesProvider = FutureProvider<List<TemplateSummaryDto>>(
  (ref) => ref.read(recognitionBatchRepositoryProvider).activeTemplates(),
);

/// Mẫu đã chọn cho từng bảng điểm, nhớ trong phiên chạy (không lưu ra đĩa).
/// `null` = "Không dùng mẫu (mẫu E0330113 cũ)".
final selectedTemplateProvider = StateProvider.family<num?, num>(
  (ref, gradebookId) => null,
);

/// Lô đang theo dõi của từng bảng điểm, để panel dựng lại vẫn theo dõi tiếp.
final trackedBatchProvider = StateProvider.family<String?, num>(
  (ref, gradebookId) => null,
);

/// Tăng mỗi khi một phiếu của lô được duyệt, để panel báo bảng điểm tải lại.
final batchApprovalTickProvider = StateProvider.family<int, num>(
  (ref, gradebookId) => 0,
);

/// Thông tin lô của phiếu, biết được trong phiên này (danh sách phiếu của API
/// chưa có `batchId`/số trang/tên mẫu — xem `docs/design/open-questions.md`).
class BatchTicketInfo {
  const BatchTicketInfo({
    required this.batchId,
    required this.pageCount,
    required this.templateId,
    this.templateName,
  });

  final String batchId;
  final int pageCount;
  final num templateId;
  final String? templateName;

  BatchTicketInfo withTemplateName(String? name) => BatchTicketInfo(
    batchId: batchId,
    pageCount: pageCount,
    templateId: templateId,
    templateName: name ?? templateName,
  );
}

final batchTicketInfoProvider = StateProvider<Map<String, BatchTicketInfo>>(
  (ref) => const {},
);

class ApiRecognitionBatchRepository implements RecognitionBatchRepository {
  ApiRecognitionBatchRepository(this.api);

  final ApiClientDart api;
  static int _keySequence = 0;
  String? _pendingSignature;
  String? _pendingKey;

  @override
  Future<List<TemplateSummaryDto>> activeTemplates() async {
    final items = <TemplateSummaryDto>[];
    final seen = <String>{};
    String? cursor;
    do {
      final page = (await api.getFormTemplatesApi().formTemplatesList(
        status: 'DANG_DUNG',
        cursor: cursor,
      )).data!;
      items.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor != null && !seen.add(cursor)) break;
    } while (cursor != null);
    return [
      for (final item in items)
        if (item.status == TemplateSummaryDtoStatusEnum.DANG_DUNG) item,
    ];
  }

  @override
  Future<MappingDto> mapping({
    required num gradebookId,
    required num templateId,
  }) async => (await api.getFormTemplatesApi().formTemplateMappingMapping(
    gradebookId: gradebookId,
    templateId: templateId,
  )).data!;

  // Client sinh (dart-dio) bỏ trống thân multipart nên lệnh tải lô gửi
  // FormData trực tiếp bằng Dio của client (cùng cách với form_templates).
  @override
  Future<RecognitionBatchReceiptDto> submit({
    required num gradebookId,
    required num templateId,
    required List<RecognitionImage> images,
    required List<BatchComponentChoice> components,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    final signature = [
      gradebookId,
      templateId,
      for (final image in images) identityHashCode(image),
      for (final c in components) '${c.templateColumnIndex}:${c.componentId}',
    ].join('|');
    if (_pendingSignature != signature) {
      _pendingSignature = signature;
      _pendingKey =
          'flutter-recognition-batch-${DateTime.now().microsecondsSinceEpoch}-${_keySequence++}';
    }
    final form = FormData();
    for (final image in images) {
      form.files.add(
        MapEntry(
          'images',
          MultipartFile.fromBytes(
            image.bytes,
            filename: image.name,
            contentType: DioMediaType('image', recognitionImageMime(image)),
          ),
        ),
      );
    }
    form.fields
      ..add(MapEntry('templateId', templateId.toInt().toString()))
      ..add(
        MapEntry(
          'components',
          jsonEncode([for (final c in components) c.toJson()]),
        ),
      );
    final response = await api.dio.post<Object>(
      '/api/v1/gradebooks/$gradebookId/recognition-batches',
      data: form,
      options: Options(headers: {'x-idempotency-key': _pendingKey}),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
    final receipt = RecognitionBatchReceiptDto.fromJson(
      response.data! as Map<String, dynamic>,
    );
    _pendingSignature = null;
    _pendingKey = null;
    return receipt;
  }

  @override
  Future<RecognitionBatchDto> detail({
    required num gradebookId,
    required String batchId,
  }) async => (await api.getRecognitionBatchesApi().recognitionBatchDetail(
    gradebookId: gradebookId,
    batchId: batchId,
  )).data!;

  @override
  Future<RecognitionBatchDto> cancel({
    required num gradebookId,
    required String batchId,
    required String reason,
  }) async => (await api.getRecognitionBatchesApi().recognitionBatchCancel(
    xIdempotencyKey:
        'flutter-batch-cancel-${DateTime.now().microsecondsSinceEpoch}-${_keySequence++}',
    gradebookId: gradebookId,
    batchId: batchId,
    cancelBatchInput: CancelBatchInput(reason: reason),
  )).data!;
}

/// Thông điệp khi lô báo lỗi: theo `errorCode`, kèm số trang gây lỗi nếu có.
String batchFailureMessage(String? code, num? page) {
  final message = recognitionFailureMessage(code);
  return page == null ? message : 'Trang ${page.toInt()}: $message';
}

/// Thông điệp khi gửi/hủy/tải lô thất bại ngay ở API (mã trong envelope lỗi).
String batchErrorMessage(Object error) {
  if (error is RecognitionImageException) return error.message;
  return switch (apiErrorCode(error)) {
    'TEMPLATE_MISMATCH' ||
    'TOO_MANY_PAGES' ||
    'COMPONENT_NOT_MAPPABLE' ||
    'TEMPLATE_INACTIVE' => recognitionFailureMessage(apiErrorCode(error)),
    'TEMPLATE_NOT_FOUND' => 'Không tìm thấy mẫu. Tải lại danh sách mẫu.',
    'RECOGNITION_ALREADY_PENDING' =>
      'Có cột đang chờ xử lý hoặc đối chiếu. Duyệt hoặc hủy phiếu đó trước.',
    'DUPLICATE_FILE' =>
      'Ảnh này đã được tải lên cho cột đã chọn (hoặc hai trang trùng nhau). Chọn ảnh khác.',
    'COLUMN_LOCKED' => 'Một cột đã khóa. Tải lại danh sách cột rồi chọn lại.',
    'GRADE_ENTRY_WINDOW_CLOSED' =>
      'Một cột đã hết thời gian nhập điểm. Tải lại danh sách cột rồi chọn lại.',
    'GRADEBOOK_NOT_EDITABLE' => 'Bảng điểm đã khóa, không thể gửi ảnh.',
    'BATCH_ALREADY_APPROVED' =>
      'Mọi phiếu của lô đã được duyệt nên không thể hủy lô.',
    'BATCH_NOT_FOUND' => 'Không tìm thấy lô nhận dạng.',
    'IDEMPOTENCY_MISMATCH' =>
      'Yêu cầu trùng khóa nhưng khác nội dung. Thử gửi lại từ đầu.',
    _ => errorMessage(error),
  };
}
