//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/grade_cell_dto.dart';
import 'package:api_client_dart/src/model/gradebook_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cells_response_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CellsResponseDto {
  /// Returns a new [CellsResponseDto] instance.
  CellsResponseDto({
    required this.book,

    required this.items,

    required this.nextCursor,
  });

  @JsonKey(name: r'book', required: true, includeIfNull: false)
  final GradebookDto book;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<GradeCellDto> items;

  @JsonKey(name: r'nextCursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellsResponseDto &&
          other.book == book &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      book.hashCode +
      items.hashCode +
      (nextCursor == null ? 0 : nextCursor.hashCode);

  factory CellsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CellsResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CellsResponseDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
