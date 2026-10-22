//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'withdraw_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WithdrawInput {
  /// Returns a new [WithdrawInput] instance.
  WithdrawInput({required this.effectiveDate, required this.reason});

  @JsonKey(name: r'effectiveDate', required: true, includeIfNull: false)
  final String effectiveDate;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WithdrawInput &&
          other.effectiveDate == effectiveDate &&
          other.reason == reason;

  @override
  int get hashCode => effectiveDate.hashCode + reason.hashCode;

  factory WithdrawInput.fromJson(Map<String, dynamic> json) =>
      _$WithdrawInputFromJson(json);

  Map<String, dynamic> toJson() => _$WithdrawInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
