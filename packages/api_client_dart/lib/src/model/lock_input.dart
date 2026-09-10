//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lock_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LockInput {
  /// Returns a new [LockInput] instance.
  LockInput({required this.expectedVersion});

  @JsonKey(name: r'expectedVersion', required: true, includeIfNull: false)
  final num expectedVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LockInput && other.expectedVersion == expectedVersion;

  @override
  int get hashCode => expectedVersion.hashCode;

  factory LockInput.fromJson(Map<String, dynamic> json) =>
      _$LockInputFromJson(json);

  Map<String, dynamic> toJson() => _$LockInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
