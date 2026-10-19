import 'dart:convert';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../authentication/session.dart';
import '../recognition/image_picker.dart';

/// Cổng duy nhất của màn Mẫu bảng điểm tới API (`/api/v1/catalog/form-templates`).
/// Widget không gọi Dio; test thay bằng bản giả qua [formTemplatesRepositoryProvider].
abstract interface class FormTemplatesRepository {
  Future<List<TemplateSummaryDto>> list();
  Future<TemplateDetailDto> detail(num id);
  Future<AnalyzeResultDto> analyze(RecognitionImage image);
  Future<TemplateDetailDto> create({
    required RecognitionImage image,
    required String name,
    required String? description,
    required List<TemplateColumnDto> columns,
  });
  Future<TemplateDetailDto> update({
    required num id,
    required num expectedVersion,
    required String name,
    required String? description,
    required List<TemplateColumnDto> columns,
  });
  Future<TemplateDetailDto> createVersion({
    required num id,
    required num expectedVersion,
    required String name,
    required String? description,
    required List<TemplateColumnDto> columns,
  });
  Future<TemplateDetailDto> activate({
    required num id,
    required num expectedVersion,
  });
  Future<TemplateDetailDto> retire({
    required num id,
    required num expectedVersion,
  });

  /// "Thử nhận dạng": chỉ đọc, backend không ghép học sinh và không lưu gì.
  Future<TryResultDto> tryTemplate({
    required num id,
    required RecognitionImage image,
  });
}

final formTemplatesRepositoryProvider = Provider<FormTemplatesRepository>(
  (ref) => ApiFormTemplatesRepository(ref.read(apiProvider)),
);

/// Chi tiết một mẫu; tải lại bằng `ref.invalidate`.
final templateDetailProvider = FutureProvider.autoDispose
    .family<TemplateDetailDto, num>(
      (ref, id) => ref.read(formTemplatesRepositoryProvider).detail(id),
    );

class ApiFormTemplatesRepository implements FormTemplatesRepository {
  ApiFormTemplatesRepository(this.api);

  final ApiClientDart api;

  FormTemplatesApi get _api => api.getFormTemplatesApi();

  static const _base = '/api/v1/catalog/form-templates';

  @override
  Future<List<TemplateSummaryDto>> list() async {
    final items = <TemplateSummaryDto>[];
    final seen = <String>{};
    String? cursor;
    do {
      final page = (await _api.formTemplatesList(cursor: cursor)).data!;
      items.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor != null && !seen.add(cursor)) break;
    } while (cursor != null);
    return items;
  }

  @override
  Future<TemplateDetailDto> detail(num id) async =>
      (await _api.formTemplatesDetail(id: id)).data!;

  // Client sinh (dart-dio) bỏ trống thân multipart nên ba lệnh có ảnh gửi
  // FormData trực tiếp bằng Dio của client; phần còn lại dùng hàm sinh sẵn.
  Future<MultipartFile> _file(RecognitionImage image) async {
    final mime = recognitionImageMime(image);
    return MultipartFile.fromBytes(
      image.bytes,
      filename: image.name,
      contentType: DioMediaType('image', mime),
    );
  }

  @override
  Future<AnalyzeResultDto> analyze(RecognitionImage image) async {
    final response = await api.dio.post<Object>(
      '$_base/analyze',
      data: FormData.fromMap({'image': await _file(image)}),
    );
    return AnalyzeResultDto.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<TemplateDetailDto> create({
    required RecognitionImage image,
    required String name,
    required String? description,
    required List<TemplateColumnDto> columns,
  }) async {
    final response = await api.dio.post<Object>(
      _base,
      data: FormData.fromMap({
        'image': await _file(image),
        'definition': jsonEncode({
          'name': name,
          'description': description,
          'columns': [for (final c in columns) c.toJson()],
        }),
      }),
    );
    return TemplateDetailDto.fromJson(response.data! as Map<String, dynamic>);
  }

  VersionedDefinitionInput _definition(
    num expectedVersion,
    String name,
    String? description,
    List<TemplateColumnDto> columns,
  ) => VersionedDefinitionInput(
    name: name,
    description: description,
    columns: columns,
    expectedVersion: expectedVersion,
  );

  @override
  Future<TemplateDetailDto> update({
    required num id,
    required num expectedVersion,
    required String name,
    required String? description,
    required List<TemplateColumnDto> columns,
  }) async => (await _api.formTemplatesUpdate(
    id: id,
    versionedDefinitionInput: _definition(
      expectedVersion,
      name,
      description,
      columns,
    ),
  )).data!;

  @override
  Future<TemplateDetailDto> createVersion({
    required num id,
    required num expectedVersion,
    required String name,
    required String? description,
    required List<TemplateColumnDto> columns,
  }) async => (await _api.formTemplatesCreateVersion(
    id: id,
    versionedDefinitionInput: _definition(
      expectedVersion,
      name,
      description,
      columns,
    ),
  )).data!;

  @override
  Future<TemplateDetailDto> activate({
    required num id,
    required num expectedVersion,
  }) async => (await _api.formTemplatesActivate(
    id: id,
    expectedVersionInput: ExpectedVersionInput(
      expectedVersion: expectedVersion,
    ),
  )).data!;

  @override
  Future<TemplateDetailDto> retire({
    required num id,
    required num expectedVersion,
  }) async => (await _api.formTemplatesRetire(
    id: id,
    expectedVersionInput: ExpectedVersionInput(
      expectedVersion: expectedVersion,
    ),
  )).data!;

  @override
  Future<TryResultDto> tryTemplate({
    required num id,
    required RecognitionImage image,
  }) async {
    final response = await api.dio.post<Object>(
      '$_base/$id/try',
      data: FormData.fromMap({'image': await _file(image)}),
      options: Options(receiveTimeout: const Duration(seconds: 100)),
    );
    return TryResultDto.fromJson(response.data! as Map<String, dynamic>);
  }
}

/// Mã lỗi ổn định trong envelope lỗi của API (`{code, message, details, requestId}`).
String? apiErrorCode(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final code = data['code'];
    if (code is String && code.isNotEmpty) return code;
  }
  return null;
}

/// Thông điệp thân thiện cho mã lỗi backend của mẫu bảng điểm (ADR-0016 mục 4).
/// Mã lạ thì rơi về [errorMessage] chung để không lộ chi tiết kỹ thuật.
String templateErrorMessage(Object error) {
  if (error is RecognitionImageException) return error.message;
  return switch (apiErrorCode(error)) {
    'INVALID_TEMPLATE_DEFINITION' =>
      'Khai báo cột chưa hợp lệ. Kiểm tra lại vai trò, nhóm và thứ tự của các cột.',
    'TEMPLATE_COLUMN_COUNT_MISMATCH' =>
      'Số cột khai báo khác số cột máy đọc được từ ảnh. Phân tích lại ảnh mẫu.',
    'TEMPLATE_NOT_FOUND' =>
      'Không tìm thấy mẫu. Có thể mẫu đã bị đổi; tải lại danh sách.',
    'TEMPLATE_IN_USE' =>
      'Mẫu đã được phiếu nhận dạng sử dụng nên không sửa tại chỗ. Hãy tạo phiên bản mới.',
    'TEMPLATE_INACTIVE' => 'Mẫu không ở trạng thái cho phép thao tác này.',
    'VERSION_CONFLICT' =>
      'Mẫu vừa được thay đổi ở nơi khác. Tải lại rồi thử lại.',
    'TEMPLATE_MISMATCH' =>
      'Ảnh không khớp lưới của mẫu. Chọn ảnh đúng loại tờ hoặc chọn mẫu khác.',
    'IMAGE_UNREADABLE' => 'Không đọc được tệp ảnh. Chọn ảnh PNG/JPEG khác.',
    'IMAGE_QUALITY_LOW' =>
      'Ảnh mờ hoặc độ phân giải thấp. Chụp lại gần hơn, đủ sáng, không rung.',
    'GRID_NOT_FOUND' =>
      'Không tìm thấy bảng kẻ ô trong ảnh. Chụp thẳng, đủ toàn bộ bảng.',
    'NOT_A_GRADEBOOK' => 'Ảnh không giống bảng điểm. Kiểm tra lại ảnh.',
    'SCORE_COLUMN_NOT_FOUND' =>
      'Không tìm thấy cột điểm trong ảnh. Chụp rõ hàng tiêu đề của bảng.',
    'MODEL_UNAVAILABLE' =>
      'Dịch vụ nhận dạng chưa sẵn sàng. Thử lại sau hoặc liên hệ quản trị hệ thống.',
    'RECOGNITION_TIMEOUT' =>
      'Dịch vụ nhận dạng không trả lời kịp. Thử lại sau.',
    'RECOGNITION_SERVICE_ERROR' ||
    'MALFORMED_RESPONSE' ||
    'INVALID_LAYOUT' => 'Dịch vụ nhận dạng gặp lỗi. Thử lại sau.',
    _ => errorMessage(error),
  };
}
