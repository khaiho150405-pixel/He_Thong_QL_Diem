//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'try_grade_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TryGradeDto {
  /// Returns a new [TryGradeDto] instance.
  TryGradeDto({
    required this.key,

    required this.numericValue,

    required this.numericConfidence,

    required this.writtenValue,

    required this.writtenConfidence,

    required this.comparison,

    required this.reviewLevel,

    required this.suggestedSource,
  });

  /// Định danh cột điểm, ví dụ TX1
  @JsonKey(name: r'key', required: true, includeIfNull: false)
  final String key;

  @JsonKey(name: r'numericValue', required: true, includeIfNull: true)
  final String? numericValue;

  @JsonKey(name: r'numericConfidence', required: true, includeIfNull: true)
  final String? numericConfidence;

  /// null với cột chỉ có kênh điểm số
  @JsonKey(name: r'writtenValue', required: true, includeIfNull: true)
  final String? writtenValue;

  @JsonKey(name: r'writtenConfidence', required: true, includeIfNull: true)
  final String? writtenConfidence;

  @JsonKey(name: r'comparison', required: true, includeIfNull: false)
  final TryGradeDtoComparisonEnum comparison;

  @JsonKey(name: r'reviewLevel', required: true, includeIfNull: false)
  final TryGradeDtoReviewLevelEnum reviewLevel;

  @JsonKey(name: r'suggestedSource', required: true, includeIfNull: true)
  final TryGradeDtoSuggestedSourceEnum? suggestedSource;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TryGradeDto &&
          other.key == key &&
          other.numericValue == numericValue &&
          other.numericConfidence == numericConfidence &&
          other.writtenValue == writtenValue &&
          other.writtenConfidence == writtenConfidence &&
          other.comparison == comparison &&
          other.reviewLevel == reviewLevel &&
          other.suggestedSource == suggestedSource;

  @override
  int get hashCode =>
      key.hashCode +
      (numericValue == null ? 0 : numericValue.hashCode) +
      (numericConfidence == null ? 0 : numericConfidence.hashCode) +
      (writtenValue == null ? 0 : writtenValue.hashCode) +
      (writtenConfidence == null ? 0 : writtenConfidence.hashCode) +
      comparison.hashCode +
      reviewLevel.hashCode +
      (suggestedSource == null ? 0 : suggestedSource.hashCode);

  factory TryGradeDto.fromJson(Map<String, dynamic> json) =>
      _$TryGradeDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TryGradeDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum TryGradeDtoComparisonEnum {
  @JsonValue(r'KHOP')
  KHOP(r'KHOP'),
  @JsonValue(r'LECH')
  LECH(r'LECH'),
  @JsonValue(r'MOT_KENH')
  MOT_KENH(r'MOT_KENH'),
  @JsonValue(r'KHONG_DOC_DUOC')
  KHONG_DOC_DUOC(r'KHONG_DOC_DUOC');

  const TryGradeDtoComparisonEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum TryGradeDtoReviewLevelEnum {
  @JsonValue(r'XANH')
  XANH(r'XANH'),
  @JsonValue(r'VANG')
  VANG(r'VANG'),
  @JsonValue(r'DO')
  DO(r'DO');

  const TryGradeDtoReviewLevelEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum TryGradeDtoSuggestedSourceEnum {
  @JsonValue(r'SO')
  SO(r'SO'),
  @JsonValue(r'CHU')
  CHU(r'CHU');

  const TryGradeDtoSuggestedSourceEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
