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

    required this.termAverage,

    required this.termClassification,
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

  /// Điểm tổng kết môn; null cho tới khi học kỳ được công bố
  @JsonKey(name: r'finalScore', required: true, includeIfNull: true)
  final String? finalScore;

  /// Xếp loại môn; null cho tới khi học kỳ được công bố
  @JsonKey(name: r'classification', required: true, includeIfNull: true)
  final String? classification;

  /// Điểm TB học kỳ (cùng nguồn với summary.averageScore); null khi chưa công bố
  @JsonKey(name: r'termAverage', required: true, includeIfNull: true)
  final String? termAverage;

  /// Xếp loại chung theo chính sách đang áp dụng; null khi chưa công bố
  @JsonKey(name: r'termClassification', required: true, includeIfNull: true)
  final String? termClassification;

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
          other.classification == classification &&
          other.termAverage == termAverage &&
          other.termClassification == termClassification;

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
      (classification == null ? 0 : classification.hashCode) +
      (termAverage == null ? 0 : termAverage.hashCode) +
      (termClassification == null ? 0 : termClassification.hashCode);

  factory StudentSubjectResultDto.fromJson(Map<String, dynamic> json) =>
      _$StudentSubjectResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$StudentSubjectResultDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
