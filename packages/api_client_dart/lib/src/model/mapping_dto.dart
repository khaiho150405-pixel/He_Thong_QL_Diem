//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/mapping_item_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mapping_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MappingDto {
  /// Returns a new [MappingDto] instance.
  MappingDto({
    required this.gradebookId,

    required this.templateId,

    required this.items,
  });

  @JsonKey(name: r'gradebookId', required: true, includeIfNull: false)
  final num gradebookId;

  @JsonKey(name: r'templateId', required: true, includeIfNull: false)
  final num templateId;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<MappingItemDto> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MappingDto &&
          other.gradebookId == gradebookId &&
          other.templateId == templateId &&
          other.items == items;

  @override
  int get hashCode =>
      gradebookId.hashCode + templateId.hashCode + items.hashCode;

  factory MappingDto.fromJson(Map<String, dynamic> json) =>
      _$MappingDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MappingDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
