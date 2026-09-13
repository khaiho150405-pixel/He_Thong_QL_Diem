//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/student_approved_component_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'student_subject_result_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StudentSubjectResultDto {
  /// Returns a new [StudentSubjectResultDto] instance.
  StudentSubjectResultDto({
    required this.gradebookId,

    required this.subjectId,

    required this.subjectName,

    required this.termId,

    required this.termName,

    required this.components,

    required this.finalScore,

    required this.classification,

    required this.calculatedAt,
  });

  @JsonKey(name: r'gradebookId', required: true, includeIfNull: false)
  final num gradebookId;

  @JsonKey(name: r'subjectId', required: true, includeIfNull: false)
  final num subjectId;

  @JsonKey(name: r'subjectName', required: true, includeIfNull: false)
  final String subjectName;

  @JsonKey(name: r'termId', required: true, includeIfNull: false)
  final num termId;

  @JsonKey(name: r'termName', required: true, includeIfNull: false)
  final String termName;

  @JsonKey(name: r'components', required: true, includeIfNull: false)
  final List<StudentApprovedComponentDto> components;

  @JsonKey(name: r'finalScore', required: true, includeIfNull: true)
  final String? finalScore;

  @JsonKey(name: r'classification', required: true, includeIfNull: true)
  final String? classification;

  @JsonKey(name: r'calculatedAt', required: true, includeIfNull: true)
  final DateTime? calculatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentSubjectResultDto &&
          other.gradebookId == gradebookId &&
          other.subjectId == subjectId &&
          other.subjectName == subjectName &&
          other.termId == termId &&
          other.termName == termName &&
          other.components == components &&
          other.finalScore == finalScore &&
          other.classification == classification &&
          other.calculatedAt == calculatedAt;

  @override
  int get hashCode =>
      gradebookId.hashCode +
      subjectId.hashCode +
      subjectName.hashCode +
      termId.hashCode +
      termName.hashCode +
      components.hashCode +
      (finalScore == null ? 0 : finalScore.hashCode) +
      (classification == null ? 0 : classification.hashCode) +
      (calculatedAt == null ? 0 : calculatedAt.hashCode);

  factory StudentSubjectResultDto.fromJson(Map<String, dynamic> json) =>
      _$StudentSubjectResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$StudentSubjectResultDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
