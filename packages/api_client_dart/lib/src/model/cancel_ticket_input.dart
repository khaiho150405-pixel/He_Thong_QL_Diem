//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cancel_ticket_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CancelTicketInput {
  /// Returns a new [CancelTicketInput] instance.
  CancelTicketInput({required this.expectedVersion, required this.reason});

  // minimum: 0
  @JsonKey(name: r'expectedVersion', required: true, includeIfNull: false)
  final num expectedVersion;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CancelTicketInput &&
          other.expectedVersion == expectedVersion &&
          other.reason == reason;

  @override
  int get hashCode => expectedVersion.hashCode + reason.hashCode;

  factory CancelTicketInput.fromJson(Map<String, dynamic> json) =>
      _$CancelTicketInputFromJson(json);

  Map<String, dynamic> toJson() => _$CancelTicketInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
