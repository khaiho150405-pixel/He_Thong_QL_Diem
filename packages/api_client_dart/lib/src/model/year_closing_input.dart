//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'year_closing_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class YearClosingInput {
  /// Returns a new [YearClosingInput] instance.
  YearClosingInput({required this.reason});

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearClosingInput && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  factory YearClosingInput.fromJson(Map<String, dynamic> json) =>
      _$YearClosingInputFromJson(json);

  Map<String, dynamic> toJson() => _$YearClosingInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
