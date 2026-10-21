//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'missing_student_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MissingStudentDto {
  /// Returns a new [MissingStudentDto] instance.
  MissingStudentDto({required this.studentId, required this.studentName});

  @JsonKey(name: r'studentId', required: true, includeIfNull: false)
  final num studentId;

  @JsonKey(name: r'studentName', required: true, includeIfNull: false)
  final String studentName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MissingStudentDto &&
          other.studentId == studentId &&
          other.studentName == studentName;

  @override
  int get hashCode => studentId.hashCode + studentName.hashCode;

  factory MissingStudentDto.fromJson(Map<String, dynamic> json) =>
      _$MissingStudentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MissingStudentDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
