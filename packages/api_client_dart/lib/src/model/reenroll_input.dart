//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reenroll_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReenrollInput {
  /// Returns a new [ReenrollInput] instance.
  ReenrollInput({
    required this.classId,

    required this.effectiveDate,

    required this.reason,
  });

  @JsonKey(name: r'classId', required: true, includeIfNull: false)
  final num classId;

  @JsonKey(name: r'effectiveDate', required: true, includeIfNull: false)
  final String effectiveDate;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReenrollInput &&
          other.classId == classId &&
          other.effectiveDate == effectiveDate &&
          other.reason == reason;

  @override
  int get hashCode =>
      classId.hashCode + effectiveDate.hashCode + reason.hashCode;

  factory ReenrollInput.fromJson(Map<String, dynamic> json) =>
      _$ReenrollInputFromJson(json);

  Map<String, dynamic> toJson() => _$ReenrollInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
