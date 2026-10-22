//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/adjustment_change_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'adjustment_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdjustmentInput {
  /// Returns a new [AdjustmentInput] instance.
  AdjustmentInput({
    required this.expectedVersion,

    required this.reason,

    required this.changes,
  });

  // minimum: 0
  @JsonKey(name: r'expectedVersion', required: true, includeIfNull: false)
  final num expectedVersion;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @JsonKey(name: r'changes', required: true, includeIfNull: false)
  final List<AdjustmentChangeInput> changes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdjustmentInput &&
          other.expectedVersion == expectedVersion &&
          other.reason == reason &&
          other.changes == changes;

  @override
  int get hashCode =>
      expectedVersion.hashCode + reason.hashCode + changes.hashCode;

  factory AdjustmentInput.fromJson(Map<String, dynamic> json) =>
      _$AdjustmentInputFromJson(json);

  Map<String, dynamic> toJson() => _$AdjustmentInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
