//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recognition_batch_ticket_receipt_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecognitionBatchTicketReceiptDto {
  /// Returns a new [RecognitionBatchTicketReceiptDto] instance.
  RecognitionBatchTicketReceiptDto({
    required this.ticketId,

    required this.componentId,
  });

  /// bigint recognition ticket ID
  @JsonKey(name: r'ticketId', required: true, includeIfNull: false)
  final String ticketId;

  @JsonKey(name: r'componentId', required: true, includeIfNull: false)
  final num componentId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecognitionBatchTicketReceiptDto &&
          other.ticketId == ticketId &&
          other.componentId == componentId;

  @override
  int get hashCode => ticketId.hashCode + componentId.hashCode;

  factory RecognitionBatchTicketReceiptDto.fromJson(
    Map<String, dynamic> json,
  ) => _$RecognitionBatchTicketReceiptDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$RecognitionBatchTicketReceiptDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
