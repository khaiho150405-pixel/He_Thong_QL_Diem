import 'dart:convert';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../authentication/session.dart';

/// Mã lỗi ổn định trong envelope lỗi của API (`{code, message, details, requestId}`).
String? apiErrorCode(Object error) {
  if (error is! DioException) return null;
  var data = error.response?.data;
  if (data is String) {
    try {
      data = jsonDecode(data);
    } catch (_) {}
  }
  if (data is Map<String, dynamic>) {
    final code = data['code'];
    if (code is String && code.isNotEmpty) return code;
  }
  return null;
}

/// Chi tiết lỗi trong envelope lỗi của API (`details`).
Map<String, dynamic>? apiErrorDetails(Object error) {
  if (error is! DioException) return null;
  var data = error.response?.data;
  if (data is String) {
    try {
      data = jsonDecode(data);
    } catch (_) {}
  }
  if (data is Map<String, dynamic>) {
    final details = data['details'];
    if (details is Map<String, dynamic>) return details;
  }
  return null;
}

/// Thông điệp tiếng Việt thân thiện theo trường code lỗi của backend.
String deadlineErrorMessage(Object error) {
  return switch (apiErrorCode(error)) {
    'STUDENT_CLASS_VIA_ENROLLMENT' =>
      'Không đổi lớp trực tiếp ở đây; dùng chức năng xếp lớp/chuyển lớp',
    'TARGET_YEAR_NOT_AFTER' => 'Năm học đích phải sau năm học hiện tại',
    'TARGET_CLASS_WRONG_YEAR' => 'Lớp đích không thuộc năm học đích',
    'PROMOTION_GRADE_MISMATCH' =>
      'Khối của lớp đích không khớp với hành động lên lớp/lưu ban',
    'GRADUATION_ONLY_GRADE_12' => 'Chỉ học sinh khối 12 mới được xét tốt nghiệp',
    'TARGET_CLASS_REQUIRED' => 'Vui lòng chọn lớp đích',
    'TARGET_CLASS_NOT_ALLOWED' => 'Hành động này không được chọn lớp đích',
    'STUDENT_ALREADY_ENROLLED' =>
      'Học sinh đã có ghi danh trong năm học đích hoặc từng học lớp này',
    'ENROLLMENT_NOT_ACTIVE' => 'Ghi danh của học sinh không còn hiệu lực',
    'DUPLICATE_STUDENT' => 'Học sinh bị trùng lặp trong danh sách',
    'TRANSFER_SAME_CLASS' => 'Lớp chuyển đến phải khác lớp hiện tại',
    'TRANSFER_GRADE_MISMATCH' => 'Chỉ được chuyển sang lớp cùng khối',
    'TRANSFER_HAS_LATER_GRADES' =>
      'Học sinh đã có điểm ở lớp sau thời điểm chuyển',
    'EFFECTIVE_DATE_OUT_OF_RANGE' =>
      'Ngày hiệu lực phải sau ngày bắt đầu ghi danh hiện tại và trong năm học',
    'DEADLINE_VERSION_CONFLICT' => 'Lịch vừa được thay đổi, hãy tải lại',
    'COLUMN_LOCKED' => 'Lịch đã qua hạn, không sửa được',
    'INVALID_ENTRY_WINDOW' => 'Hạn nhập phải sau giờ mở và ở tương lai',
    'TERM_ALREADY_PUBLISHED' => 'Học kỳ đã công bố',
    'CELL_HAS_VALUE' => 'Ô đã có điểm, hãy xóa điểm trước khi miễn',
    'CELL_NOT_EXEMPT' => 'Ô này không ở trạng thái miễn',
    'COLUMN_NOT_OPEN' => 'Cột không còn mở để thay đổi',
    'RECOGNITION_PENDING' => 'Cột đang có phiếu nhận dạng chờ duyệt',
    'CELL_EXEMPT' => 'Học sinh được miễn cột này, không nhập điểm',
    'ROW_STUDENT_EXEMPT' => 'Học sinh được miễn cột này, hãy để trống',
    'STUDENT_NOT_IN_CLASS' => 'Học sinh không thuộc lớp này',
    'GRADE_ENTRY_WINDOW_CLOSED' =>
      'Chưa đến thời gian nhập hoặc đã hết hạn; không thể lưu điểm',
    'VERSION_OR_STATE_CONFLICT' =>
      'Bảng điểm vừa thay đổi hoặc đã chốt, hãy tải lại',
    'VERSION_CONFLICT' =>
      'Bảng điểm vừa thay đổi hoặc đã chốt, hãy tải lại',
    'CONFLICT' => () {
        if (error is DioException) {
          var data = error.response?.data;
          if (data is String) {
            try {
              data = jsonDecode(data);
            } catch (_) {}
          }
          if (data is Map<String, dynamic> &&
              data['message'] is String &&
              (data['message'] as String).isNotEmpty) {
            return data['message'] as String;
          }
        }
        return 'Dữ liệu vừa thay đổi hoặc đã chốt, hãy tải lại';
      }(),
    'GRADEBOOK_NOT_EDITABLE' =>
      'Bảng điểm đã khóa, không thể sửa',
    _ => errorMessage(error),
  };
}

abstract class SemesterDeadlinesRepository {
  Future<List<SemestersDto>> listSemesters({num? yearId});
  Future<SemesterDeadlinesDto> getDeadlines(num semesterId);
  Future<SemesterDeadlineDto> setDeadline({
    required num semesterId,
    required String type,
    required DateTime opensAt,
    required DateTime closesAt,
    required num expectedVersion,
  });
  Future<InitializeGradebooksResultDto> initializeGradebooks({
    required num semesterId,
    required String idempotencyKey,
  });
  Future<PublishReadinessDto> publishReadiness(num semesterId);
}

class ApiSemesterDeadlinesRepository implements SemesterDeadlinesRepository {
  const ApiSemesterDeadlinesRepository(this._api);
  final ApiClientDart _api;

  @override
  Future<List<SemestersDto>> listSemesters({num? yearId}) async {
    final items = <SemestersDto>[];
    String? cursor;
    final seen = <String>{};
    do {
      final res = await _api.getSemestersApi().semestersList(
            yearId: yearId,
            cursor: cursor,
          );
      final page = res.data;
      if (page != null) {
        items.addAll(page.items);
        cursor = page.nextCursor;
        if (cursor != null && !seen.add(cursor)) break;
      } else {
        break;
      }
    } while (cursor != null);
    return items;
  }

  @override
  Future<SemesterDeadlinesDto> getDeadlines(num semesterId) async {
    final res =
        await _api.getSemestersApi().semesterDeadlinesList(id: semesterId);
    return res.data!;
  }

  @override
  Future<SemesterDeadlineDto> setDeadline({
    required num semesterId,
    required String type,
    required DateTime opensAt,
    required DateTime closesAt,
    required num expectedVersion,
  }) async {
    final res = await _api.getSemestersApi().semesterDeadlinesSet(
      id: semesterId,
      type: type,
      semesterDeadlineInput: SemesterDeadlineInput(
        opensAt: opensAt,
        closesAt: closesAt,
        expectedVersion: expectedVersion,
      ),
    );
    return res.data!;
  }

  @override
  Future<InitializeGradebooksResultDto> initializeGradebooks({
    required num semesterId,
    required String idempotencyKey,
  }) async {
    final res = await _api.getSemestersApi().semesterDeadlinesInitialize(
      id: semesterId,
      xIdempotencyKey: idempotencyKey,
    );
    return res.data!;
  }

  @override
  Future<PublishReadinessDto> publishReadiness(num semesterId) async {
    final res = await _api.getSemestersApi().semesterDeadlinesPublishReadiness(
      id: semesterId,
    );
    return res.data!;
  }
}

final semesterDeadlinesRepositoryProvider =
    Provider<SemesterDeadlinesRepository>((ref) {
      return ApiSemesterDeadlinesRepository(ref.watch(apiProvider));
    });
