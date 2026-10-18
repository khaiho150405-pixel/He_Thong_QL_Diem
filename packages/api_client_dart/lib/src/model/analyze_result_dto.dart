//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/analyzed_column_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'analyze_result_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AnalyzeResultDto {
  /// Returns a new [AnalyzeResultDto] instance.
  AnalyzeResultDto({
    required this.columnCount,

    required this.columns,

    required this.previewPngBase64,
  });

  @JsonKey(name: r'columnCount', required: true, includeIfNull: false)
  final num columnCount;

  @JsonKey(name: r'columns', required: true, includeIfNull: false)
  final List<AnalyzedColumnDto> columns;

  /// Ảnh PNG (base64) đã nắn, vẽ lưới và số thứ tự cột từ 0
  @JsonKey(name: r'previewPngBase64', required: true, includeIfNull: false)
  final String previewPngBase64;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyzeResultDto &&
          other.columnCount == columnCount &&
          other.columns == columns &&
          other.previewPngBase64 == previewPngBase64;

  @override
  int get hashCode =>
      columnCount.hashCode + columns.hashCode + previewPngBase64.hashCode;

  factory AnalyzeResultDto.fromJson(Map<String, dynamic> json) =>
      _$AnalyzeResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyzeResultDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
