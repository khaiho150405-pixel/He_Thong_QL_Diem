//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/recognition_batch_ticket_receipt_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recognition_batch_receipt_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecognitionBatchReceiptDto {
  /// Returns a new [RecognitionBatchReceiptDto] instance.
  RecognitionBatchReceiptDto({
    required this.batchId,

    required this.jobId,

    required this.status,

    required this.tickets,
  });

  /// bigint recognition batch ID
  @JsonKey(name: r'batchId', required: true, includeIfNull: false)
  final String batchId;

  @JsonKey(name: r'jobId', required: true, includeIfNull: false)
  final String jobId;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final RecognitionBatchReceiptDtoStatusEnum status;

  /// Một phiếu cho mỗi thành phần được chọn
  @JsonKey(name: r'tickets', required: true, includeIfNull: false)
  final List<RecognitionBatchTicketReceiptDto> tickets;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecognitionBatchReceiptDto &&
          other.batchId == batchId &&
          other.jobId == jobId &&
          other.status == status &&
          other.tickets == tickets;

  @override
  int get hashCode =>
      batchId.hashCode + jobId.hashCode + status.hashCode + tickets.hashCode;

  factory RecognitionBatchReceiptDto.fromJson(Map<String, dynamic> json) =>
      _$RecognitionBatchReceiptDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RecognitionBatchReceiptDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecognitionBatchReceiptDtoStatusEnum {
  @JsonValue(r'DANG_XU_LY')
  DANG_XU_LY(r'DANG_XU_LY');

  const RecognitionBatchReceiptDtoStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
