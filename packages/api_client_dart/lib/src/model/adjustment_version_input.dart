//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'adjustment_version_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdjustmentVersionInput {
  /// Returns a new [AdjustmentVersionInput] instance.
  AdjustmentVersionInput({required this.expectedVersion});

  /// Version phiếu
  // minimum: 0
  @JsonKey(name: r'expectedVersion', required: true, includeIfNull: false)
  final num expectedVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdjustmentVersionInput &&
          other.expectedVersion == expectedVersion;

  @override
  int get hashCode => expectedVersion.hashCode;

  factory AdjustmentVersionInput.fromJson(Map<String, dynamic> json) =>
      _$AdjustmentVersionInputFromJson(json);

  Map<String, dynamic> toJson() => _$AdjustmentVersionInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
