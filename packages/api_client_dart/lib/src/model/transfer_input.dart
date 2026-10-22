//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transfer_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TransferInput {
  /// Returns a new [TransferInput] instance.
  TransferInput({
    required this.targetClassId,

    required this.effectiveDate,

    required this.reason,
  });

  @JsonKey(name: r'targetClassId', required: true, includeIfNull: false)
  final num targetClassId;

  @JsonKey(name: r'effectiveDate', required: true, includeIfNull: false)
  final String effectiveDate;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferInput &&
          other.targetClassId == targetClassId &&
          other.effectiveDate == effectiveDate &&
          other.reason == reason;

  @override
  int get hashCode =>
      targetClassId.hashCode + effectiveDate.hashCode + reason.hashCode;

  factory TransferInput.fromJson(Map<String, dynamic> json) =>
      _$TransferInputFromJson(json);

  Map<String, dynamic> toJson() => _$TransferInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
