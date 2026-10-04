//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'grade_deadline_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GradeDeadlineInput {
  /// Returns a new [GradeDeadlineInput] instance.
  GradeDeadlineInput({
    required this.opensAt,

    required this.closesAt,

    required this.expectedVersion,
  });

  @JsonKey(name: r'opensAt', required: true, includeIfNull: false)
  final DateTime opensAt;

  @JsonKey(name: r'closesAt', required: true, includeIfNull: false)
  final DateTime closesAt;

  // minimum: 0
  @JsonKey(name: r'expectedVersion', required: true, includeIfNull: false)
  final num expectedVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeDeadlineInput &&
          other.opensAt == opensAt &&
          other.closesAt == closesAt &&
          other.expectedVersion == expectedVersion;

  @override
  int get hashCode =>
      opensAt.hashCode + closesAt.hashCode + expectedVersion.hashCode;

  factory GradeDeadlineInput.fromJson(Map<String, dynamic> json) =>
      _$GradeDeadlineInputFromJson(json);

  Map<String, dynamic> toJson() => _$GradeDeadlineInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
