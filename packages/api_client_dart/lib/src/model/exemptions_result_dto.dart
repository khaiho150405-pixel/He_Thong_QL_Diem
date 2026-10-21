//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/grade_cell_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'exemptions_result_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExemptionsResultDto {
  /// Returns a new [ExemptionsResultDto] instance.
  ExemptionsResultDto({
    required this.bookId,

    required this.version,

    required this.items,
  });

  @JsonKey(name: r'bookId', required: true, includeIfNull: false)
  final num bookId;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final num version;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<GradeCellDto> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExemptionsResultDto &&
          other.bookId == bookId &&
          other.version == version &&
          other.items == items;

  @override
  int get hashCode => bookId.hashCode + version.hashCode + items.hashCode;

  factory ExemptionsResultDto.fromJson(Map<String, dynamic> json) =>
      _$ExemptionsResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ExemptionsResultDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
