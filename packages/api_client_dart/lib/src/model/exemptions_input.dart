//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/exemption_change_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'exemptions_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExemptionsInput {
  /// Returns a new [ExemptionsInput] instance.
  ExemptionsInput({required this.expectedVersion, required this.changes});

  // minimum: 0
  @JsonKey(name: r'expectedVersion', required: true, includeIfNull: false)
  final num expectedVersion;

  @JsonKey(name: r'changes', required: true, includeIfNull: false)
  final List<ExemptionChangeInput> changes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExemptionsInput &&
          other.expectedVersion == expectedVersion &&
          other.changes == changes;

  @override
  int get hashCode => expectedVersion.hashCode + changes.hashCode;

  factory ExemptionsInput.fromJson(Map<String, dynamic> json) =>
      _$ExemptionsInputFromJson(json);

  Map<String, dynamic> toJson() => _$ExemptionsInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
