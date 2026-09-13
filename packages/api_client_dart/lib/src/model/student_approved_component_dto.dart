//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'student_approved_component_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StudentApprovedComponentDto {
  /// Returns a new [StudentApprovedComponentDto] instance.
  StudentApprovedComponentDto({
    required this.componentId,

    required this.componentName,

    required this.coefficient,

    required this.value,
  });

  @JsonKey(name: r'componentId', required: true, includeIfNull: false)
  final num componentId;

  @JsonKey(name: r'componentName', required: true, includeIfNull: false)
  final String componentName;

  @JsonKey(name: r'coefficient', required: true, includeIfNull: false)
  final String coefficient;

  @JsonKey(name: r'value', required: true, includeIfNull: false)
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentApprovedComponentDto &&
          other.componentId == componentId &&
          other.componentName == componentName &&
          other.coefficient == coefficient &&
          other.value == value;

  @override
  int get hashCode =>
      componentId.hashCode +
      componentName.hashCode +
      coefficient.hashCode +
      value.hashCode;

  factory StudentApprovedComponentDto.fromJson(Map<String, dynamic> json) =>
      _$StudentApprovedComponentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$StudentApprovedComponentDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
