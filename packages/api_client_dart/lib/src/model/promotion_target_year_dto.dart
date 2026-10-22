//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'promotion_target_year_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PromotionTargetYearDto {
  /// Returns a new [PromotionTargetYearDto] instance.
  PromotionTargetYearDto({
    required this.id,

    required this.name,

    required this.startDate,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final num id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'startDate', required: true, includeIfNull: false)
  final String startDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromotionTargetYearDto &&
          other.id == id &&
          other.name == name &&
          other.startDate == startDate;

  @override
  int get hashCode => id.hashCode + name.hashCode + startDate.hashCode;

  factory PromotionTargetYearDto.fromJson(Map<String, dynamic> json) =>
      _$PromotionTargetYearDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PromotionTargetYearDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
