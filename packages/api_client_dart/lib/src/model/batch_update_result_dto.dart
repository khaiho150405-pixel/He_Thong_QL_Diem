//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/updated_cell_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'batch_update_result_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BatchUpdateResultDto {
  /// Returns a new [BatchUpdateResultDto] instance.
  BatchUpdateResultDto({
    required this.items,

    required this.bookId,

    required this.version,
  });

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<UpdatedCellDto> items;

  @JsonKey(name: r'bookId', required: true, includeIfNull: false)
  final num bookId;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final num version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchUpdateResultDto &&
          other.items == items &&
          other.bookId == bookId &&
          other.version == version;

  @override
  int get hashCode => items.hashCode + bookId.hashCode + version.hashCode;

  factory BatchUpdateResultDto.fromJson(Map<String, dynamic> json) =>
      _$BatchUpdateResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$BatchUpdateResultDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
