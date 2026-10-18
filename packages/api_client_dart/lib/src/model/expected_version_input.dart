//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'expected_version_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExpectedVersionInput {
  /// Returns a new [ExpectedVersionInput] instance.
  ExpectedVersionInput({required this.expectedVersion});

  // minimum: 0
  @JsonKey(name: r'expectedVersion', required: true, includeIfNull: false)
  final num expectedVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpectedVersionInput && other.expectedVersion == expectedVersion;

  @override
  int get hashCode => expectedVersion.hashCode;

  factory ExpectedVersionInput.fromJson(Map<String, dynamic> json) =>
      _$ExpectedVersionInputFromJson(json);

  Map<String, dynamic> toJson() => _$ExpectedVersionInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
