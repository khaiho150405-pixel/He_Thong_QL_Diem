//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recognition_receipt_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecognitionReceiptDto {
  /// Returns a new [RecognitionReceiptDto] instance.
  RecognitionReceiptDto({
    required this.ticketId,

    required this.jobId,

    required this.status,
  });

  /// bigint recognition ticket ID
  @JsonKey(name: r'ticketId', required: true, includeIfNull: false)
  final String ticketId;

  @JsonKey(name: r'jobId', required: true, includeIfNull: false)
  final String jobId;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final RecognitionReceiptDtoStatusEnum status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecognitionReceiptDto &&
          other.ticketId == ticketId &&
          other.jobId == jobId &&
          other.status == status;

  @override
  int get hashCode => ticketId.hashCode + jobId.hashCode + status.hashCode;

  factory RecognitionReceiptDto.fromJson(Map<String, dynamic> json) =>
      _$RecognitionReceiptDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RecognitionReceiptDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecognitionReceiptDtoStatusEnum {
  @JsonValue(r'DANG_XU_LY')
  DANG_XU_LY(r'DANG_XU_LY');

  const RecognitionReceiptDtoStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
