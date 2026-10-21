//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'late_student_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LateStudentInput {
  /// Returns a new [LateStudentInput] instance.
  LateStudentInput({required this.studentId, required this.reason});

  @JsonKey(name: r'studentId', required: true, includeIfNull: false)
  final num studentId;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LateStudentInput &&
          other.studentId == studentId &&
          other.reason == reason;

  @override
  int get hashCode => studentId.hashCode + reason.hashCode;

  factory LateStudentInput.fromJson(Map<String, dynamic> json) =>
      _$LateStudentInputFromJson(json);

  Map<String, dynamic> toJson() => _$LateStudentInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
