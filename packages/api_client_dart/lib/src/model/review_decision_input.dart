//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'review_decision_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReviewDecisionInput {
  /// Returns a new [ReviewDecisionInput] instance.
  ReviewDecisionInput({
    required this.rowId,

    required this.value,

    required this.reason,
  });

  /// bigint recognition row ID
  @JsonKey(name: r'rowId', required: true, includeIfNull: false)
  final String rowId;

  @JsonKey(name: r'value', required: true, includeIfNull: true)
  final String? value;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewDecisionInput &&
          other.rowId == rowId &&
          other.value == value &&
          other.reason == reason;

  @override
  int get hashCode =>
      rowId.hashCode + (value == null ? 0 : value.hashCode) + reason.hashCode;

  factory ReviewDecisionInput.fromJson(Map<String, dynamic> json) =>
      _$ReviewDecisionInputFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewDecisionInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
