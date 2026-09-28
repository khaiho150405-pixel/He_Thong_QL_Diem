//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_grade_distribution_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminGradeDistributionDto {
  /// Returns a new [AdminGradeDistributionDto] instance.
  AdminGradeDistributionDto({
    required this.label,

    required this.code,

    required this.count,

    required this.percentage,

    required this.color,
  });

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'count', required: true, includeIfNull: false)
  final num count;

  @JsonKey(name: r'percentage', required: true, includeIfNull: false)
  final num percentage;

  @JsonKey(name: r'color', required: true, includeIfNull: false)
  final String color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminGradeDistributionDto &&
          other.label == label &&
          other.code == code &&
          other.count == count &&
          other.percentage == percentage &&
          other.color == color;

  @override
  int get hashCode =>
      label.hashCode +
      code.hashCode +
      count.hashCode +
      percentage.hashCode +
      color.hashCode;

  factory AdminGradeDistributionDto.fromJson(Map<String, dynamic> json) =>
      _$AdminGradeDistributionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AdminGradeDistributionDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
