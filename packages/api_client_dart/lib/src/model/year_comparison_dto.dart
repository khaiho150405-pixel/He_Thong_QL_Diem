//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/year_comparison_item_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'year_comparison_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class YearComparisonDto {
  /// Returns a new [YearComparisonDto] instance.
  YearComparisonDto({required this.items});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<YearComparisonItemDto> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearComparisonDto && other.items == items;

  @override
  int get hashCode => items.hashCode;

  factory YearComparisonDto.fromJson(Map<String, dynamic> json) =>
      _$YearComparisonDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YearComparisonDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
