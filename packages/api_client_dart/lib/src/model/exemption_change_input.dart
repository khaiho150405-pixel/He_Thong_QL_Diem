//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'exemption_change_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExemptionChangeInput {
  /// Returns a new [ExemptionChangeInput] instance.
  ExemptionChangeInput({
    required this.cellId,

    required this.exempt,

    required this.reason,
  });

  /// bigint cell ID
  @JsonKey(name: r'cellId', required: true, includeIfNull: false)
  final String cellId;

  /// true = miễn, false = bỏ miễn
  @JsonKey(name: r'exempt', required: true, includeIfNull: false)
  final bool exempt;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExemptionChangeInput &&
          other.cellId == cellId &&
          other.exempt == exempt &&
          other.reason == reason;

  @override
  int get hashCode => cellId.hashCode + exempt.hashCode + reason.hashCode;

  factory ExemptionChangeInput.fromJson(Map<String, dynamic> json) =>
      _$ExemptionChangeInputFromJson(json);

  Map<String, dynamic> toJson() => _$ExemptionChangeInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
