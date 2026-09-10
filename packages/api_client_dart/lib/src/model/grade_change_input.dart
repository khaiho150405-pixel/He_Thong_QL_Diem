//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'grade_change_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GradeChangeInput {
  /// Returns a new [GradeChangeInput] instance.
  GradeChangeInput({
    required this.cellId,

    required this.value,

    required this.reason,
  });

  /// bigint cell ID
  @JsonKey(name: r'cellId', required: true, includeIfNull: false)
  final String cellId;

  /// 0.0–10.0 step 0.1, or null to clear
  @JsonKey(name: r'value', required: true, includeIfNull: true)
  final String? value;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeChangeInput &&
          other.cellId == cellId &&
          other.value == value &&
          other.reason == reason;

  @override
  int get hashCode =>
      cellId.hashCode + (value == null ? 0 : value.hashCode) + reason.hashCode;

  factory GradeChangeInput.fromJson(Map<String, dynamic> json) =>
      _$GradeChangeInputFromJson(json);

  Map<String, dynamic> toJson() => _$GradeChangeInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
