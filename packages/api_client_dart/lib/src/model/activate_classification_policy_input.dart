//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/classification_criterion_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activate_classification_policy_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActivateClassificationPolicyInput {
  /// Returns a new [ActivateClassificationPolicyInput] instance.
  ActivateClassificationPolicyInput({
    required this.version,

    required this.name,

    required this.roundingDigits,

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

  @JsonKey(name: r'criteria', required: true, includeIfNull: false)
  final List<ClassificationCriterionDto> criteria;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivateClassificationPolicyInput &&
          other.version == version &&
          other.name == name &&
          other.roundingDigits == roundingDigits &&
          other.criteria == criteria;

  @override
  int get hashCode =>
      version.hashCode +
      name.hashCode +
      roundingDigits.hashCode +
      criteria.hashCode;

  factory ActivateClassificationPolicyInput.fromJson(
    Map<String, dynamic> json,
  ) => _$ActivateClassificationPolicyInputFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ActivateClassificationPolicyInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
