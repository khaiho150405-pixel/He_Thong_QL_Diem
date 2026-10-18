//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/try_row_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'try_result_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TryResultDto {
  /// Returns a new [TryResultDto] instance.
  TryResultDto({
    required this.templateId,

    required this.modelVersion,

    required this.templateMatchScore,

    required this.pageStartStt,

    required this.rows,
  });

  @JsonKey(name: r'templateId', required: true, includeIfNull: false)
  final num templateId;

  @JsonKey(name: r'modelVersion', required: true, includeIfNull: false)
  final String modelVersion;

  /// Điểm khớp mẫu 0–1
  @JsonKey(name: r'templateMatchScore', required: true, includeIfNull: false)
  final num templateMatchScore;

  @JsonKey(name: r'pageStartStt', required: true, includeIfNull: true)
  final num? pageStartStt;

  @JsonKey(name: r'rows', required: true, includeIfNull: false)
  final List<TryRowDto> rows;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TryResultDto &&
          other.templateId == templateId &&
          other.modelVersion == modelVersion &&
          other.templateMatchScore == templateMatchScore &&
          other.pageStartStt == pageStartStt &&
          other.rows == rows;

  @override
  int get hashCode =>
      templateId.hashCode +
      modelVersion.hashCode +
      templateMatchScore.hashCode +
      (pageStartStt == null ? 0 : pageStartStt.hashCode) +
      rows.hashCode;

  factory TryResultDto.fromJson(Map<String, dynamic> json) =>
      _$TryResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TryResultDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
