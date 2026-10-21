//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'initialized_gradebook_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InitializedGradebookDto {
  /// Returns a new [InitializedGradebookDto] instance.
  InitializedGradebookDto({
    required this.gradebookId,

    required this.classId,

    required this.className,

    required this.subjectId,

    required this.subjectName,
  });

  @JsonKey(name: r'gradebookId', required: true, includeIfNull: false)
  final num gradebookId;

  @JsonKey(name: r'classId', required: true, includeIfNull: false)
  final num classId;

  @JsonKey(name: r'className', required: true, includeIfNull: false)
  final String className;

  @JsonKey(name: r'subjectId', required: true, includeIfNull: false)
  final num subjectId;

  @JsonKey(name: r'subjectName', required: true, includeIfNull: false)
  final String subjectName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InitializedGradebookDto &&
          other.gradebookId == gradebookId &&
          other.classId == classId &&
          other.className == className &&
          other.subjectId == subjectId &&
          other.subjectName == subjectName;

  @override
  int get hashCode =>
      gradebookId.hashCode +
      classId.hashCode +
      className.hashCode +
      subjectId.hashCode +
      subjectName.hashCode;

  factory InitializedGradebookDto.fromJson(Map<String, dynamic> json) =>
      _$InitializedGradebookDtoFromJson(json);

  Map<String, dynamic> toJson() => _$InitializedGradebookDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
