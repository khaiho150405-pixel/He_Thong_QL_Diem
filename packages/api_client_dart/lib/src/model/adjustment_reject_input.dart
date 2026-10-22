//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'adjustment_reject_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdjustmentRejectInput {
  /// Returns a new [AdjustmentRejectInput] instance.
  AdjustmentRejectInput({required this.expectedVersion, required this.reason});

  /// Version phiếu
  // minimum: 0
  @JsonKey(name: r'expectedVersion', required: true, includeIfNull: false)
  final num expectedVersion;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdjustmentRejectInput &&
          other.expectedVersion == expectedVersion &&
          other.reason == reason;

  @override
  int get hashCode => expectedVersion.hashCode + reason.hashCode;

  factory AdjustmentRejectInput.fromJson(Map<String, dynamic> json) =>
      _$AdjustmentRejectInputFromJson(json);

  Map<String, dynamic> toJson() => _$AdjustmentRejectInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
