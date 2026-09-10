//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/grade_history_entry_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'grade_history_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GradeHistoryDto {
  /// Returns a new [GradeHistoryDto] instance.
  GradeHistoryDto({required this.items, required this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<GradeHistoryEntryDto> items;

  @JsonKey(name: r'nextCursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeHistoryDto &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory GradeHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$GradeHistoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GradeHistoryDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
