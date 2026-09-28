//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/timetable_item_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'timetable_list_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TimetableListDto {
  /// Returns a new [TimetableListDto] instance.
  TimetableListDto({required this.items, required this.total});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<TimetableItemDto> items;

  @JsonKey(name: r'total', required: true, includeIfNull: false)
  final num total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableListDto && other.items == items && other.total == total;

  @override
  int get hashCode => items.hashCode + total.hashCode;

  factory TimetableListDto.fromJson(Map<String, dynamic> json) =>
      _$TimetableListDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TimetableListDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
