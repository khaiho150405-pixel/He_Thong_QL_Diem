//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'exempted_student_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExemptedStudentDto {
  /// Returns a new [ExemptedStudentDto] instance.
  ExemptedStudentDto({required this.studentId, required this.studentName});

  @JsonKey(name: r'studentId', required: true, includeIfNull: false)
  final num studentId;

  @JsonKey(name: r'studentName', required: true, includeIfNull: false)
  final String studentName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExemptedStudentDto &&
          other.studentId == studentId &&
          other.studentName == studentName;

  @override
  int get hashCode => studentId.hashCode + studentName.hashCode;

  factory ExemptedStudentDto.fromJson(Map<String, dynamic> json) =>
      _$ExemptedStudentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ExemptedStudentDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
