//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/missing_component_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'skipped_student_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SkippedStudentDto {
  /// Returns a new [SkippedStudentDto] instance.
  SkippedStudentDto({
    required this.studentId,

    required this.studentName,

    required this.missingComponents,
  });

  @JsonKey(name: r'studentId', required: true, includeIfNull: false)
  final num studentId;

  @JsonKey(name: r'studentName', required: true, includeIfNull: false)
  final String studentName;

  @JsonKey(name: r'missingComponents', required: true, includeIfNull: false)
  final List<MissingComponentDto> missingComponents;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkippedStudentDto &&
          other.studentId == studentId &&
          other.studentName == studentName &&
          other.missingComponents == missingComponents;

  @override
  int get hashCode =>
      studentId.hashCode + studentName.hashCode + missingComponents.hashCode;

  factory SkippedStudentDto.fromJson(Map<String, dynamic> json) =>
      _$SkippedStudentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SkippedStudentDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
