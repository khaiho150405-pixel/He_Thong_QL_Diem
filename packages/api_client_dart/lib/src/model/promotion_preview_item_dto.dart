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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromotionPreviewItemDto &&
          other.studentId == studentId &&
          other.studentName == studentName &&
          other.order == order &&
          other.suggestedAction == suggestedAction &&
          other.suggestedTargetClassId == suggestedTargetClassId &&
          other.alreadyEnrolledInTargetYear == alreadyEnrolledInTargetYear;

  @override
  int get hashCode =>
      studentId.hashCode +
      studentName.hashCode +
      order.hashCode +
      suggestedAction.hashCode +
      (suggestedTargetClassId == null ? 0 : suggestedTargetClassId.hashCode) +
      alreadyEnrolledInTargetYear.hashCode;

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
