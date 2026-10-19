//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cancel_batch_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CancelBatchInput {
  /// Returns a new [CancelBatchInput] instance.
  CancelBatchInput({required this.reason});

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CancelBatchInput && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  factory CancelBatchInput.fromJson(Map<String, dynamic> json) =>
      _$CancelBatchInputFromJson(json);

  Map<String, dynamic> toJson() => _$CancelBatchInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
