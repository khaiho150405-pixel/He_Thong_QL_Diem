//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'classification_criterion_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ClassificationCriterionDto {
  /// Returns a new [ClassificationCriterionDto] instance.
  ClassificationCriterionDto({
    required this.code,

    required this.minimum,

    required this.passing,

    required this.order,
  });

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'minimum', required: true, includeIfNull: false)
  final String minimum;

  @JsonKey(name: r'passing', required: true, includeIfNull: false)
  final bool passing;

  @JsonKey(name: r'order', required: true, includeIfNull: false)
  final num order;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassificationCriterionDto &&
          other.code == code &&
          other.minimum == minimum &&
          other.passing == passing &&
          other.order == order;

  @override
  int get hashCode =>
      code.hashCode + minimum.hashCode + passing.hashCode + order.hashCode;

  factory ClassificationCriterionDto.fromJson(Map<String, dynamic> json) =>
      _$ClassificationCriterionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ClassificationCriterionDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
