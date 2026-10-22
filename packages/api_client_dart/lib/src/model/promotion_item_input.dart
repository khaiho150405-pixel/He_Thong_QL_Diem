//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'promotion_item_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PromotionItemInput {
  /// Returns a new [PromotionItemInput] instance.
  PromotionItemInput({
    required this.studentId,

    required this.action,

    this.targetClassId,

    this.reason,
  });

  @JsonKey(name: r'studentId', required: true, includeIfNull: false)
  final num studentId;

  @JsonKey(name: r'action', required: true, includeIfNull: false)
  final PromotionItemInputActionEnum action;

  /// Bắt buộc với LEN_LOP/LUU_BAN; không được gửi với TOT_NGHIEP/NGHI_HOC
  @JsonKey(name: r'targetClassId', required: false, includeIfNull: false)
  final num? targetClassId;

  @JsonKey(name: r'reason', required: false, includeIfNull: false)
  final String? reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromotionItemInput &&
          other.studentId == studentId &&
          other.action == action &&
          other.targetClassId == targetClassId &&
          other.reason == reason;

  @override
  int get hashCode =>
      studentId.hashCode +
      action.hashCode +
      (targetClassId == null ? 0 : targetClassId.hashCode) +
      (reason == null ? 0 : reason.hashCode);

  factory PromotionItemInput.fromJson(Map<String, dynamic> json) =>
      _$PromotionItemInputFromJson(json);

  Map<String, dynamic> toJson() => _$PromotionItemInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PromotionItemInputActionEnum {
  @JsonValue(r'LEN_LOP')
  LEN_LOP(r'LEN_LOP'),
  @JsonValue(r'LUU_BAN')
  LUU_BAN(r'LUU_BAN'),
  @JsonValue(r'TOT_NGHIEP')
  TOT_NGHIEP(r'TOT_NGHIEP'),
  @JsonValue(r'NGHI_HOC')
  NGHI_HOC(r'NGHI_HOC');

  const PromotionItemInputActionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
