//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/gradebook_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gradebook_list_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GradebookListDto {
  /// Returns a new [GradebookListDto] instance.
  GradebookListDto({required this.items, required this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<GradebookDto> items;

  @JsonKey(name: r'nextCursor', required: true, includeIfNull: true)
  final num? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradebookListDto &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory GradebookListDto.fromJson(Map<String, dynamic> json) =>
      _$GradebookListDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GradebookListDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
