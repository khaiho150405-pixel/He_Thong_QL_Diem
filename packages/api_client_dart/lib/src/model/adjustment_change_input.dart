//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'adjustment_change_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdjustmentChangeInput {
  /// Returns a new [AdjustmentChangeInput] instance.
  AdjustmentChangeInput({
    required this.cellId,

    required this.value,

    required this.exempt,

    required this.note,
  });

  /// bigint cell ID
  @JsonKey(name: r'cellId', required: true, includeIfNull: false)
  final String cellId;

  /// Giá trị mới 0.0–10.0; null khi exempt = true
  @JsonKey(name: r'value', required: true, includeIfNull: true)
  final String? value;

  /// true = đặt Miễn (value = null); false = value bắt buộc
  @JsonKey(name: r'exempt', required: true, includeIfNull: false)
  final bool exempt;

  @JsonKey(name: r'note', required: true, includeIfNull: true)
  final String? note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdjustmentChangeInput &&
          other.cellId == cellId &&
          other.value == value &&
          other.exempt == exempt &&
          other.note == note;

  @override
  int get hashCode =>
      cellId.hashCode +
      (value == null ? 0 : value.hashCode) +
      exempt.hashCode +
      (note == null ? 0 : note.hashCode);

  factory AdjustmentChangeInput.fromJson(Map<String, dynamic> json) =>
      _$AdjustmentChangeInputFromJson(json);

  Map<String, dynamic> toJson() => _$AdjustmentChangeInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
