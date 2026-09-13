//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'missing_component_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MissingComponentDto {
  /// Returns a new [MissingComponentDto] instance.
  MissingComponentDto({required this.componentId, required this.name});

  @JsonKey(name: r'componentId', required: true, includeIfNull: false)
  final num componentId;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MissingComponentDto &&
          other.componentId == componentId &&
          other.name == name;

  @override
  int get hashCode => componentId.hashCode + name.hashCode;

  factory MissingComponentDto.fromJson(Map<String, dynamic> json) =>
      _$MissingComponentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MissingComponentDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
