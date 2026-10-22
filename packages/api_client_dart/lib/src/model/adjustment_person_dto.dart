//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'adjustment_person_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdjustmentPersonDto {
  /// Returns a new [AdjustmentPersonDto] instance.
  AdjustmentPersonDto({required this.id, required this.name});

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final num id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdjustmentPersonDto && other.id == id && other.name == name;

  @override
  int get hashCode => id.hashCode + name.hashCode;

  factory AdjustmentPersonDto.fromJson(Map<String, dynamic> json) =>
      _$AdjustmentPersonDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AdjustmentPersonDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
