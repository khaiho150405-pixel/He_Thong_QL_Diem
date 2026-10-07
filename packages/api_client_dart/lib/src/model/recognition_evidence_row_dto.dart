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

    required this.stt,

    required this.sttOnPaper,

    required this.studentId,

    required this.studentName,

    required this.nameRead,

    required this.matchConfidence,

    required this.matchNote,

    required this.numericRaw,

    required this.numericValue,

    required this.numericConfidence,

    required this.writtenRaw,

    required this.writtenValue,

    required this.writtenConfidence,

    required this.comparison,

    required this.reviewLevel,

    required this.suggestedSource,

    required this.finalValue,

    required this.numericCropUrl,

    required this.writtenCropUrl,

    required this.nameCropUrl,
  });

  @JsonKey(name: r'rowId', required: true, includeIfNull: false)
  final String rowId;

  /// Vị trí dòng trên ảnh
  @JsonKey(name: r'order', required: true, includeIfNull: false)
  final num order;

  /// STT hệ thống trong danh sách lớp đã chốt của phiếu
  @JsonKey(name: r'stt', required: true, includeIfNull: true)
  final num? stt;

  /// STT in trên giấy đọc được
  @JsonKey(name: r'sttOnPaper', required: true, includeIfNull: true)
  final num? sttOnPaper;

  @JsonKey(name: r'studentId', required: true, includeIfNull: false)
  final num studentId;

  /// Họ tên học sinh theo danh sách lớp đã chốt
  @JsonKey(name: r'studentName', required: true, includeIfNull: false)
  final String studentName;

  /// Họ tên máy đọc được trên giấy
  @JsonKey(name: r'nameRead', required: true, includeIfNull: true)
  final String? nameRead;

  /// Độ tin cậy ghép dòng với học sinh, 0..1
  @JsonKey(name: r'matchConfidence', required: true, includeIfNull: true)
  final String? matchConfidence;

  @JsonKey(name: r'matchNote', required: true, includeIfNull: true)
  final String? matchNote;

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

  /// Kênh cho giá trị gợi ý (SO = điểm số, CHU = điểm chữ); null khi mức Đỏ: không gợi ý giá trị
  @JsonKey(name: r'suggestedSource', required: true, includeIfNull: true)
  final RecognitionEvidenceRowDtoSuggestedSourceEnum? suggestedSource;

  @JsonKey(name: r'finalValue', required: true, includeIfNull: true)
  final String? finalValue;

  @JsonKey(name: r'numericCropUrl', required: true, includeIfNull: true)
  final String? numericCropUrl;

  @JsonKey(name: r'writtenCropUrl', required: true, includeIfNull: true)
  final String? writtenCropUrl;

  /// Ảnh ô họ tên trên giấy (URL ký 300 giây)
  @JsonKey(name: r'nameCropUrl', required: true, includeIfNull: true)
  final String? nameCropUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecognitionEvidenceRowDto &&
          other.rowId == rowId &&
          other.order == order &&
          other.stt == stt &&
          other.sttOnPaper == sttOnPaper &&
          other.studentId == studentId &&
          other.studentName == studentName &&
          other.nameRead == nameRead &&
          other.matchConfidence == matchConfidence &&
          other.matchNote == matchNote &&
          other.numericRaw == numericRaw &&
          other.numericValue == numericValue &&
          other.numericConfidence == numericConfidence &&
          other.writtenRaw == writtenRaw &&
          other.writtenValue == writtenValue &&
          other.writtenConfidence == writtenConfidence &&
          other.comparison == comparison &&
          other.reviewLevel == reviewLevel &&
          other.suggestedSource == suggestedSource &&
          other.finalValue == finalValue &&
          other.numericCropUrl == numericCropUrl &&
          other.writtenCropUrl == writtenCropUrl &&
          other.nameCropUrl == nameCropUrl;

  @override
  int get hashCode =>
      rowId.hashCode +
      order.hashCode +
      (stt == null ? 0 : stt.hashCode) +
      (sttOnPaper == null ? 0 : sttOnPaper.hashCode) +
      studentId.hashCode +
      studentName.hashCode +
      (nameRead == null ? 0 : nameRead.hashCode) +
      (matchConfidence == null ? 0 : matchConfidence.hashCode) +
      (matchNote == null ? 0 : matchNote.hashCode) +
      (numericRaw == null ? 0 : numericRaw.hashCode) +
      (numericValue == null ? 0 : numericValue.hashCode) +
      (numericConfidence == null ? 0 : numericConfidence.hashCode) +
      (writtenRaw == null ? 0 : writtenRaw.hashCode) +
      (writtenValue == null ? 0 : writtenValue.hashCode) +
      (writtenConfidence == null ? 0 : writtenConfidence.hashCode) +
      comparison.hashCode +
      reviewLevel.hashCode +
      (suggestedSource == null ? 0 : suggestedSource.hashCode) +
      (finalValue == null ? 0 : finalValue.hashCode) +
      (numericCropUrl == null ? 0 : numericCropUrl.hashCode) +
      (writtenCropUrl == null ? 0 : writtenCropUrl.hashCode) +
      (nameCropUrl == null ? 0 : nameCropUrl.hashCode);

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

/// Kênh cho giá trị gợi ý (SO = điểm số, CHU = điểm chữ); null khi mức Đỏ: không gợi ý giá trị
enum RecognitionEvidenceRowDtoSuggestedSourceEnum {
  /// Kênh cho giá trị gợi ý (SO = điểm số, CHU = điểm chữ); null khi mức Đỏ: không gợi ý giá trị
  @JsonValue(r'SO')
  SO(r'SO'),

  /// Kênh cho giá trị gợi ý (SO = điểm số, CHU = điểm chữ); null khi mức Đỏ: không gợi ý giá trị
  @JsonValue(r'CHU')
  CHU(r'CHU');

  const RecognitionEvidenceRowDtoSuggestedSourceEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
