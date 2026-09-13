//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'calculate_final_results_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CalculateFinalResultsInput {
  /// Returns a new [CalculateFinalResultsInput] instance.
  CalculateFinalResultsInput({
    required this.expectedVersion,

    required this.reason,
  });

  // minimum: 0
  @JsonKey(name: r'expectedVersion', required: true, includeIfNull: false)
  final num expectedVersion;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculateFinalResultsInput &&
          other.expectedVersion == expectedVersion &&
          other.reason == reason;

  @override
  int get hashCode => expectedVersion.hashCode + reason.hashCode;

  factory CalculateFinalResultsInput.fromJson(Map<String, dynamic> json) =>
      _$CalculateFinalResultsInputFromJson(json);

  Map<String, dynamic> toJson() => _$CalculateFinalResultsInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
