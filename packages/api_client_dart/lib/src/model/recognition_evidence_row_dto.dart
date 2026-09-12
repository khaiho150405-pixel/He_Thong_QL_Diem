//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recognition_evidence_row_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecognitionEvidenceRowDto {
  /// Returns a new [RecognitionEvidenceRowDto] instance.
  RecognitionEvidenceRowDto({
    required this.rowId,

    required this.order,

    required this.studentId,

    required this.studentName,

    required this.numericRaw,

    required this.numericValue,

    required this.numericConfidence,

    required this.writtenRaw,

    required this.writtenValue,

    required this.writtenConfidence,

    required this.comparison,

    required this.reviewLevel,

    required this.finalValue,

    required this.numericCropUrl,

    required this.writtenCropUrl,
  });

  @JsonKey(name: r'rowId', required: true, includeIfNull: false)
  final String rowId;

  @JsonKey(name: r'order', required: true, includeIfNull: false)
  final num order;

  @JsonKey(name: r'studentId', required: true, includeIfNull: false)
  final num studentId;

  @JsonKey(name: r'studentName', required: true, includeIfNull: false)
  final String studentName;

  @JsonKey(name: r'numericRaw', required: true, includeIfNull: true)
  final String? numericRaw;

  @JsonKey(name: r'numericValue', required: true, includeIfNull: true)
  final String? numericValue;

  @JsonKey(name: r'numericConfidence', required: true, includeIfNull: true)
  final String? numericConfidence;

  @JsonKey(name: r'writtenRaw', required: true, includeIfNull: true)
  final String? writtenRaw;

  @JsonKey(name: r'writtenValue', required: true, includeIfNull: true)
  final String? writtenValue;

  @JsonKey(name: r'writtenConfidence', required: true, includeIfNull: true)
  final String? writtenConfidence;

  @JsonKey(name: r'comparison', required: true, includeIfNull: false)
  final RecognitionEvidenceRowDtoComparisonEnum comparison;

  @JsonKey(name: r'reviewLevel', required: true, includeIfNull: false)
  final RecognitionEvidenceRowDtoReviewLevelEnum reviewLevel;

  @JsonKey(name: r'finalValue', required: true, includeIfNull: true)
  final String? finalValue;

  @JsonKey(name: r'numericCropUrl', required: true, includeIfNull: true)
  final String? numericCropUrl;

  @JsonKey(name: r'writtenCropUrl', required: true, includeIfNull: true)
  final String? writtenCropUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecognitionEvidenceRowDto &&
          other.rowId == rowId &&
          other.order == order &&
          other.studentId == studentId &&
          other.studentName == studentName &&
          other.numericRaw == numericRaw &&
          other.numericValue == numericValue &&
          other.numericConfidence == numericConfidence &&
          other.writtenRaw == writtenRaw &&
          other.writtenValue == writtenValue &&
          other.writtenConfidence == writtenConfidence &&
          other.comparison == comparison &&
          other.reviewLevel == reviewLevel &&
          other.finalValue == finalValue &&
          other.numericCropUrl == numericCropUrl &&
          other.writtenCropUrl == writtenCropUrl;

  @override
  int get hashCode =>
      rowId.hashCode +
      order.hashCode +
      studentId.hashCode +
      studentName.hashCode +
      (numericRaw == null ? 0 : numericRaw.hashCode) +
      (numericValue == null ? 0 : numericValue.hashCode) +
      (numericConfidence == null ? 0 : numericConfidence.hashCode) +
      (writtenRaw == null ? 0 : writtenRaw.hashCode) +
      (writtenValue == null ? 0 : writtenValue.hashCode) +
      (writtenConfidence == null ? 0 : writtenConfidence.hashCode) +
      comparison.hashCode +
      reviewLevel.hashCode +
      (finalValue == null ? 0 : finalValue.hashCode) +
      (numericCropUrl == null ? 0 : numericCropUrl.hashCode) +
      (writtenCropUrl == null ? 0 : writtenCropUrl.hashCode);

  factory RecognitionEvidenceRowDto.fromJson(Map<String, dynamic> json) =>
      _$RecognitionEvidenceRowDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RecognitionEvidenceRowDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecognitionEvidenceRowDtoComparisonEnum {
  @JsonValue(r'KHOP')
  KHOP(r'KHOP'),
  @JsonValue(r'LECH')
  LECH(r'LECH'),
  @JsonValue(r'MOT_KENH')
  MOT_KENH(r'MOT_KENH'),
  @JsonValue(r'KHONG_DOC_DUOC')
  KHONG_DOC_DUOC(r'KHONG_DOC_DUOC');

  const RecognitionEvidenceRowDtoComparisonEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum RecognitionEvidenceRowDtoReviewLevelEnum {
  @JsonValue(r'XANH')
  XANH(r'XANH'),
  @JsonValue(r'VANG')
  VANG(r'VANG'),
  @JsonValue(r'DO')
  DO(r'DO');

  const RecognitionEvidenceRowDtoReviewLevelEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
