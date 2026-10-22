import 'dart:convert';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../academic_catalog/semester_deadlines_repository.dart';
import '../authentication/session.dart';

final adjustmentsRepositoryProvider = Provider(
  (ref) => AdjustmentsRepository(ref.watch(apiProvider)),
);

/// Thông điệp tiếng Việt thân thiện theo trường code lỗi của nghiệp vụ điều chỉnh điểm.
String adjustmentErrorMessage(Object error) {
  final code = apiErrorCode(error);
  return switch (code) {
    'CELL_NOT_LOCKED' => 'Cột này chưa chốt — nhập điểm trực tiếp',
    'ADJUSTMENT_PENDING_EXISTS' => 'Bảng đã có phiếu điều chỉnh chờ duyệt',
    'ADJUSTMENT_NO_CHANGE' => 'Chưa có ô nào thay đổi',
    'ADJUSTMENT_STALE' =>
      'Điểm đã thay đổi sau khi gửi phiếu; yêu cầu giáo viên soạn lại',
    'ADJUSTMENT_NOT_PENDING' => 'Phiếu không còn ở trạng thái chờ duyệt',
    'TERM_ALREADY_PUBLISHED' => 'Học kỳ đã công bố',
    'INVALID_GRADE' => 'Điểm không hợp lệ (từ 0.0 đến 10.0)',
    'PASS_FAIL_VALUE_REQUIRED' =>
      'Môn Đạt/Không đạt chỉ nhận Đạt hoặc Không đạt',
    'COLUMN_LOCKED' => 'Cột đã chốt',
    'RESULTS_OUTDATED' => 'Điểm đã được điều chỉnh — cần tính lại tổng kết',
    'ADJUSTMENT_PENDING' => 'Còn phiếu điều chỉnh điểm chờ duyệt',
    _ => deadlineErrorMessage(error),
  };
}

class AdjustmentsRepository {
  AdjustmentsRepository(this.api);

  final ApiClientDart api;
  static int _keySequence = 0;
  final _pendingSignatures = <String, String>{};
  final _pendingKeys = <String, String>{};

  String _key(String operation, String signature) {
    if (_pendingSignatures[operation] == signature) {
      return _pendingKeys[operation]!;
    }
    final key =
        'flutter-adj-$operation-${DateTime.now().microsecondsSinceEpoch}-${_keySequence++}';
    _pendingSignatures[operation] = signature;
    _pendingKeys[operation] = key;
    return key;
  }

  void _complete(String operation, String key) {
    if (_pendingKeys[operation] == key) {
      _pendingSignatures.remove(operation);
      _pendingKeys.remove(operation);
    }
  }

  /// Lấy danh sách phiếu điều chỉnh của một bảng điểm (mới nhất trước, không kèm lines).
  Future<List<AdjustmentDto>> listForBook(num bookId) async {
    final res = await api
        .getAdjustmentsApi()
        .gradebookAdjustmentsListForBook(id: bookId);
    return res.data?.items.toList() ?? const [];
  }

  /// Giáo viên gửi phiếu điều chỉnh điểm cho các ô thuộc cột đã chốt.
  Future<AdjustmentDto> submitAdjustment({
    required num bookId,
    required num expectedVersion,
    required String reason,
    required List<AdjustmentChangeInput> changes,
  }) async {
    final input = AdjustmentInput(
      expectedVersion: expectedVersion,
      reason: reason,
      changes: changes,
    );
    final key = _key('submit', '$bookId:${jsonEncode(input)}');
    final res = await api.getAdjustmentsApi().gradebookAdjustmentsSubmit(
          xIdempotencyKey: key,
          id: bookId,
          adjustmentInput: input,
        );
    _complete('submit', key);
    return res.data!;
  }

  /// Quản trị viên lấy danh sách phiếu điều chỉnh (có lọc trạng thái, phân trang cursor).
  Future<AdjustmentPageDto> listAdjustments({
    AdjustmentDtoStatusEnum? status,
    String? cursor,
  }) async {
    final res = await api.getAdjustmentsApi().adjustmentsList(
          status: status?.value,
          cursor: cursor,
        );
    return res.data!;
  }

  /// Lấy chi tiết một phiếu điều chỉnh (kèm danh sách các dòng).
  Future<AdjustmentDto> getDetail(String adjId) async {
    final res =
        await api.getAdjustmentsApi().adjustmentsDetail(adjId: adjId);
    return res.data!;
  }

  /// Quản trị viên duyệt cả phiếu điều chỉnh.
  Future<AdjustmentDto> approve({
    required String adjId,
    required num expectedVersion,
  }) async {
    final input = AdjustmentVersionInput(expectedVersion: expectedVersion);
    final key = _key('approve', '$adjId:${jsonEncode(input)}');
    final res = await api.getAdjustmentsApi().adjustmentsApprove(
          xIdempotencyKey: key,
          adjId: adjId,
          adjustmentVersionInput: input,
        );
    _complete('approve', key);
    return res.data!;
  }

  /// Quản trị viên từ chối phiếu điều chỉnh (lý do bắt buộc).
  Future<AdjustmentDto> reject({
    required String adjId,
    required num expectedVersion,
    required String reason,
  }) async {
    final input = AdjustmentRejectInput(
      expectedVersion: expectedVersion,
      reason: reason,
    );
    final key = _key('reject', '$adjId:${jsonEncode(input)}');
    final res = await api.getAdjustmentsApi().adjustmentsReject(
          xIdempotencyKey: key,
          adjId: adjId,
          adjustmentRejectInput: input,
        );
    _complete('reject', key);
    return res.data!;
  }

  /// Giáo viên đã gửi hủy phiếu điều chỉnh đang chờ duyệt.
  Future<AdjustmentDto> cancel({
    required String adjId,
    required num expectedVersion,
  }) async {
    final input = AdjustmentVersionInput(expectedVersion: expectedVersion);
    final key = _key('cancel', '$adjId:${jsonEncode(input)}');
    final res = await api.getAdjustmentsApi().adjustmentsCancel(
          xIdempotencyKey: key,
          adjId: adjId,
          adjustmentVersionInput: input,
        );
    _complete('cancel', key);
    return res.data!;
  }
}
