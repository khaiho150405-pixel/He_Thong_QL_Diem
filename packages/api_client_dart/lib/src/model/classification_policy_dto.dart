//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/classification_criterion_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'classification_policy_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ClassificationPolicyDto {
  /// Returns a new [ClassificationPolicyDto] instance.
  ClassificationPolicyDto({
    required this.version,

    required this.name,

    required this.roundingDigits,

    required this.active,

    required this.criteria,
  });

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final String version;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  // minimum: 0
  // maximum: 1
  @JsonKey(name: r'roundingDigits', required: true, includeIfNull: false)
  final num roundingDigits;

  @JsonKey(name: r'active', required: true, includeIfNull: false)
  final bool active;

  @JsonKey(name: r'criteria', required: true, includeIfNull: false)
  final List<ClassificationCriterionDto> criteria;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassificationPolicyDto &&
          other.version == version &&
          other.name == name &&
          other.roundingDigits == roundingDigits &&
          other.active == active &&
          other.criteria == criteria;

  @override
  int get hashCode =>
      version.hashCode +
      name.hashCode +
      roundingDigits.hashCode +
      active.hashCode +
      criteria.hashCode;

  factory ClassificationPolicyDto.fromJson(Map<String, dynamic> json) =>
      _$ClassificationPolicyDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ClassificationPolicyDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
