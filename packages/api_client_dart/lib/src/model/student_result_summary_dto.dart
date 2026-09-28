//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'student_result_summary_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StudentResultSummaryDto {
  /// Returns a new [StudentResultSummaryDto] instance.
  StudentResultSummaryDto({
    required this.termId,

    required this.termName,

    required this.className,

    required this.averageScore,

    required this.publishedSubjects,

    required this.totalSubjects,

    required this.classRank,

    required this.classSize,
  });

  @JsonKey(name: r'termId', required: true, includeIfNull: true)
  final num? termId;

  @JsonKey(name: r'termName', required: true, includeIfNull: true)
  final String? termName;

  @JsonKey(name: r'className', required: true, includeIfNull: false)
  final String className;

  @JsonKey(name: r'averageScore', required: true, includeIfNull: true)
  final String? averageScore;

  @JsonKey(name: r'publishedSubjects', required: true, includeIfNull: false)
  final num publishedSubjects;

  @JsonKey(name: r'totalSubjects', required: true, includeIfNull: false)
  final num totalSubjects;

  @JsonKey(name: r'classRank', required: true, includeIfNull: true)
  final num? classRank;

  @JsonKey(name: r'classSize', required: true, includeIfNull: false)
  final num classSize;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentResultSummaryDto &&
          other.termId == termId &&
          other.termName == termName &&
          other.className == className &&
          other.averageScore == averageScore &&
          other.publishedSubjects == publishedSubjects &&
          other.totalSubjects == totalSubjects &&
          other.classRank == classRank &&
          other.classSize == classSize;

  @override
  int get hashCode =>
      (termId == null ? 0 : termId.hashCode) +
      (termName == null ? 0 : termName.hashCode) +
      className.hashCode +
      (averageScore == null ? 0 : averageScore.hashCode) +
      publishedSubjects.hashCode +
      totalSubjects.hashCode +
      (classRank == null ? 0 : classRank.hashCode) +
      classSize.hashCode;

  factory StudentResultSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$StudentResultSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$StudentResultSummaryDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
