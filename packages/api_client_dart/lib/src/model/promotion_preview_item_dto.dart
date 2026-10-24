//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'promotion_preview_item_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PromotionPreviewItemDto {
  /// Returns a new [PromotionPreviewItemDto] instance.
  PromotionPreviewItemDto({
    required this.studentId,

    required this.studentName,

    required this.order,

    required this.suggestedAction,

    required this.suggestedTargetClassId,

    required this.alreadyEnrolledInTargetYear,

    required this.processedStatus,

    required this.targetClassName,
  });

  @JsonKey(name: r'studentId', required: true, includeIfNull: false)
  final num studentId;

  @JsonKey(name: r'studentName', required: true, includeIfNull: false)
  final String studentName;

  /// STT trong lớp nguồn
  @JsonKey(name: r'order', required: true, includeIfNull: false)
  final num order;

  @JsonKey(name: r'suggestedAction', required: true, includeIfNull: false)
  final PromotionPreviewItemDtoSuggestedActionEnum suggestedAction;

  /// Lớp khối +1 cùng hậu tố (10A1 → 11A1); null nếu không có
  @JsonKey(name: r'suggestedTargetClassId', required: true, includeIfNull: true)
  final num? suggestedTargetClassId;

  @JsonKey(
    name: r'alreadyEnrolledInTargetYear',
    required: true,
    includeIfNull: false,
  )
  final bool alreadyEnrolledInTargetYear;

  /// Trạng thái ghi danh nguồn nếu đã đóng; null nếu em còn DANG_HOC (chỉ dòng này mới gửi lên lớp được)
  @JsonKey(name: r'processedStatus', required: true, includeIfNull: true)
  final PromotionPreviewItemDtoProcessedStatusEnum? processedStatus;

  /// Lớp ghi danh của em ở năm đích (nếu có)
  @JsonKey(name: r'targetClassName', required: true, includeIfNull: true)
  final String? targetClassName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromotionPreviewItemDto &&
          other.studentId == studentId &&
          other.studentName == studentName &&
          other.order == order &&
          other.suggestedAction == suggestedAction &&
          other.suggestedTargetClassId == suggestedTargetClassId &&
          other.alreadyEnrolledInTargetYear == alreadyEnrolledInTargetYear &&
          other.processedStatus == processedStatus &&
          other.targetClassName == targetClassName;

  @override
  int get hashCode =>
      studentId.hashCode +
      studentName.hashCode +
      order.hashCode +
      suggestedAction.hashCode +
      (suggestedTargetClassId == null ? 0 : suggestedTargetClassId.hashCode) +
      alreadyEnrolledInTargetYear.hashCode +
      (processedStatus == null ? 0 : processedStatus.hashCode) +
      (targetClassName == null ? 0 : targetClassName.hashCode);

  factory PromotionPreviewItemDto.fromJson(Map<String, dynamic> json) =>
      _$PromotionPreviewItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PromotionPreviewItemDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PromotionPreviewItemDtoSuggestedActionEnum {
  @JsonValue(r'LEN_LOP')
  LEN_LOP(r'LEN_LOP'),
  @JsonValue(r'TOT_NGHIEP')
  TOT_NGHIEP(r'TOT_NGHIEP');

  const PromotionPreviewItemDtoSuggestedActionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

/// Trạng thái ghi danh nguồn nếu đã đóng; null nếu em còn DANG_HOC (chỉ dòng này mới gửi lên lớp được)
enum PromotionPreviewItemDtoProcessedStatusEnum {
  /// Trạng thái ghi danh nguồn nếu đã đóng; null nếu em còn DANG_HOC (chỉ dòng này mới gửi lên lớp được)
  @JsonValue(r'LEN_LOP')
  LEN_LOP(r'LEN_LOP'),

  /// Trạng thái ghi danh nguồn nếu đã đóng; null nếu em còn DANG_HOC (chỉ dòng này mới gửi lên lớp được)
  @JsonValue(r'LUU_BAN')
  LUU_BAN(r'LUU_BAN'),

  /// Trạng thái ghi danh nguồn nếu đã đóng; null nếu em còn DANG_HOC (chỉ dòng này mới gửi lên lớp được)
  @JsonValue(r'TOT_NGHIEP')
  TOT_NGHIEP(r'TOT_NGHIEP'),

  /// Trạng thái ghi danh nguồn nếu đã đóng; null nếu em còn DANG_HOC (chỉ dòng này mới gửi lên lớp được)
  @JsonValue(r'NGHI_HOC')
  NGHI_HOC(r'NGHI_HOC'),

  /// Trạng thái ghi danh nguồn nếu đã đóng; null nếu em còn DANG_HOC (chỉ dòng này mới gửi lên lớp được)
  @JsonValue(r'DA_CHUYEN_LOP')
  DA_CHUYEN_LOP(r'DA_CHUYEN_LOP');

  const PromotionPreviewItemDtoProcessedStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
