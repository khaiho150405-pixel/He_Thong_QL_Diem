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
    this.passFail,

    required this.subjectName,

    required this.termName,

    required this.yearId,

    required this.yearName,

    required this.className,

    required this.components,

    required this.finalScore,

    required this.classification,
  });

  @JsonKey(name: r'passFail', required: false, includeIfNull: false)
  final bool? passFail;

  @JsonKey(name: r'subjectName', required: true, includeIfNull: false)
  final String subjectName;

  @JsonKey(name: r'termName', required: true, includeIfNull: false)
  final String termName;

  @JsonKey(name: r'yearId', required: true, includeIfNull: false)
  final num yearId;

  @JsonKey(name: r'yearName', required: true, includeIfNull: false)
  final String yearName;

  /// Lớp của em trong học kỳ này (theo ghi danh)
  @JsonKey(name: r'className', required: true, includeIfNull: false)
  final String className;

  @JsonKey(name: r'components', required: true, includeIfNull: false)
  final List<StudentApprovedComponentDto> components;

  @JsonKey(name: r'finalScore', required: true, includeIfNull: true)
  final String? finalScore;

  @JsonKey(name: r'classification', required: true, includeIfNull: true)
  final String? classification;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentSubjectResultDto &&
          other.passFail == passFail &&
          other.subjectName == subjectName &&
          other.termName == termName &&
          other.yearId == yearId &&
          other.yearName == yearName &&
          other.className == className &&
          other.components == components &&
          other.finalScore == finalScore &&
          other.classification == classification;

  @override
  int get hashCode =>
      passFail.hashCode +
      subjectName.hashCode +
      termName.hashCode +
      yearId.hashCode +
      yearName.hashCode +
      className.hashCode +
      components.hashCode +
      (finalScore == null ? 0 : finalScore.hashCode) +
      (classification == null ? 0 : classification.hashCode);

  factory StudentSubjectResultDto.fromJson(Map<String, dynamic> json) =>
      _$StudentSubjectResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$StudentSubjectResultDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
