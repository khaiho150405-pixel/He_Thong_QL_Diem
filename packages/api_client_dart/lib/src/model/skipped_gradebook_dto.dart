//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'skipped_gradebook_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SkippedGradebookDto {
  /// Returns a new [SkippedGradebookDto] instance.
  SkippedGradebookDto({
    required this.classId,

    required this.className,

    required this.subjectId,

    required this.subjectName,

    required this.reason,
  });

  @JsonKey(name: r'classId', required: true, includeIfNull: false)
  final num classId;

  @JsonKey(name: r'className', required: true, includeIfNull: false)
  final String className;

  @JsonKey(name: r'subjectId', required: true, includeIfNull: false)
  final num subjectId;

  @JsonKey(name: r'subjectName', required: true, includeIfNull: false)
  final String subjectName;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final SkippedGradebookDtoReasonEnum reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkippedGradebookDto &&
          other.classId == classId &&
          other.className == className &&
          other.subjectId == subjectId &&
          other.subjectName == subjectName &&
          other.reason == reason;

  @override
  int get hashCode =>
      classId.hashCode +
      className.hashCode +
      subjectId.hashCode +
      subjectName.hashCode +
      reason.hashCode;

  factory SkippedGradebookDto.fromJson(Map<String, dynamic> json) =>
      _$SkippedGradebookDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SkippedGradebookDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum SkippedGradebookDtoReasonEnum {
  @JsonValue(r'EMPTY_ROSTER')
  EMPTY_ROSTER(r'EMPTY_ROSTER'),
  @JsonValue(r'NO_COMPONENTS')
  NO_COMPONENTS(r'NO_COMPONENTS');

  const SkippedGradebookDtoReasonEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
