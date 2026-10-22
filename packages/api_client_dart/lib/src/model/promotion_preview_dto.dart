//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/promotion_class_dto.dart';
import 'package:api_client_dart/src/model/promotion_preview_item_dto.dart';
import 'package:api_client_dart/src/model/promotion_source_class_dto.dart';
import 'package:api_client_dart/src/model/promotion_target_year_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'promotion_preview_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PromotionPreviewDto {
  /// Returns a new [PromotionPreviewDto] instance.
  PromotionPreviewDto({
    required this.sourceClass,

    required this.targetYear,

    required this.targetClasses,

    required this.items,
  });

  @JsonKey(name: r'sourceClass', required: true, includeIfNull: false)
  final PromotionSourceClassDto sourceClass;

  @JsonKey(name: r'targetYear', required: true, includeIfNull: false)
  final PromotionTargetYearDto targetYear;

  @JsonKey(name: r'targetClasses', required: true, includeIfNull: false)
  final List<PromotionClassDto> targetClasses;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<PromotionPreviewItemDto> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromotionPreviewDto &&
          other.sourceClass == sourceClass &&
          other.targetYear == targetYear &&
          other.targetClasses == targetClasses &&
          other.items == items;

  @override
  int get hashCode =>
      sourceClass.hashCode +
      targetYear.hashCode +
      targetClasses.hashCode +
      items.hashCode;

  factory PromotionPreviewDto.fromJson(Map<String, dynamic> json) =>
      _$PromotionPreviewDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PromotionPreviewDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
