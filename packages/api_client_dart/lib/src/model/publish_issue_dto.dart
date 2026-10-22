//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'publish_issue_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublishIssueDto {
  /// Returns a new [PublishIssueDto] instance.
  PublishIssueDto({
    required this.code,

    required this.severity,

    required this.classId,

    required this.className,

    required this.subjectId,

    required this.subjectName,

    required this.gradebookId,

    required this.studentIds,

    required this.count,
  });

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final PublishIssueDtoCodeEnum code;

  @JsonKey(name: r'severity', required: true, includeIfNull: false)
  final PublishIssueDtoSeverityEnum severity;

  @JsonKey(name: r'classId', required: true, includeIfNull: false)
  final num classId;

  @JsonKey(name: r'className', required: true, includeIfNull: false)
  final String className;

  @JsonKey(name: r'subjectId', required: true, includeIfNull: false)
  final num subjectId;

  @JsonKey(name: r'subjectName', required: true, includeIfNull: false)
  final String subjectName;

  @JsonKey(name: r'gradebookId', required: true, includeIfNull: true)
  final num? gradebookId;

  @JsonKey(name: r'studentIds', required: true, includeIfNull: true)
  final List<num>? studentIds;

  @JsonKey(name: r'count', required: true, includeIfNull: true)
  final num? count;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublishIssueDto &&
          other.code == code &&
          other.severity == severity &&
          other.classId == classId &&
          other.className == className &&
          other.subjectId == subjectId &&
          other.subjectName == subjectName &&
          other.gradebookId == gradebookId &&
          other.studentIds == studentIds &&
          other.count == count;

  @override
  int get hashCode =>
      code.hashCode +
      severity.hashCode +
      classId.hashCode +
      className.hashCode +
      subjectId.hashCode +
      subjectName.hashCode +
      (gradebookId == null ? 0 : gradebookId.hashCode) +
      (studentIds == null ? 0 : studentIds.hashCode) +
      (count == null ? 0 : count.hashCode);

  factory PublishIssueDto.fromJson(Map<String, dynamic> json) =>
      _$PublishIssueDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PublishIssueDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PublishIssueDtoCodeEnum {
  @JsonValue(r'GRADEBOOK_MISSING')
  GRADEBOOK_MISSING(r'GRADEBOOK_MISSING'),
  @JsonValue(r'GRADEBOOK_NOT_LOCKED')
  GRADEBOOK_NOT_LOCKED(r'GRADEBOOK_NOT_LOCKED'),
  @JsonValue(r'RECOGNITION_PENDING')
  RECOGNITION_PENDING(r'RECOGNITION_PENDING'),
  @JsonValue(r'STUDENT_NOT_IN_GRADEBOOK')
  STUDENT_NOT_IN_GRADEBOOK(r'STUDENT_NOT_IN_GRADEBOOK'),
  @JsonValue(r'RESULTS_MISSING')
  RESULTS_MISSING(r'RESULTS_MISSING'),
  @JsonValue(r'RESULTS_OUTDATED')
  RESULTS_OUTDATED(r'RESULTS_OUTDATED'),
  @JsonValue(r'ADJUSTMENT_PENDING')
  ADJUSTMENT_PENDING(r'ADJUSTMENT_PENDING'),
  @JsonValue(r'COLUMNS_WITHOUT_DEADLINE')
  COLUMNS_WITHOUT_DEADLINE(r'COLUMNS_WITHOUT_DEADLINE');

  const PublishIssueDtoCodeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum PublishIssueDtoSeverityEnum {
  @JsonValue(r'BLOCKING')
  BLOCKING(r'BLOCKING'),
  @JsonValue(r'WARNING')
  WARNING(r'WARNING');

  const PublishIssueDtoSeverityEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
