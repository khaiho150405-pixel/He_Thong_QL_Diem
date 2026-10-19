//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recognition_batch_ticket_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecognitionBatchTicketDto {
  /// Returns a new [RecognitionBatchTicketDto] instance.
  RecognitionBatchTicketDto({
    required this.ticketId,

    required this.componentId,

    required this.componentName,

    required this.templateColumnIndex,

    required this.status,

    required this.errorCode,

    required this.version,

    required this.greenRows,

    required this.yellowRows,

    required this.redRows,
  });

  @JsonKey(name: r'ticketId', required: true, includeIfNull: false)
  final String ticketId;

  @JsonKey(name: r'componentId', required: true, includeIfNull: false)
  final num componentId;

  @JsonKey(name: r'componentName', required: true, includeIfNull: false)
  final String componentName;

  /// Chỉ số cột điểm trong mẫu (chi_so_cot)
  @JsonKey(name: r'templateColumnIndex', required: true, includeIfNull: false)
  final num templateColumnIndex;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final RecognitionBatchTicketDtoStatusEnum status;

  @JsonKey(name: r'errorCode', required: true, includeIfNull: true)
  final String? errorCode;

  /// Dùng làm expectedVersion khi duyệt/hủy phiếu
  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final num version;

  /// Số dòng mức Xanh (mức cuối)
  @JsonKey(name: r'greenRows', required: true, includeIfNull: false)
  final num greenRows;

  /// Số dòng mức Vàng (mức cuối)
  @JsonKey(name: r'yellowRows', required: true, includeIfNull: false)
  final num yellowRows;

  /// Số dòng mức Đỏ (mức cuối)
  @JsonKey(name: r'redRows', required: true, includeIfNull: false)
  final num redRows;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecognitionBatchTicketDto &&
          other.ticketId == ticketId &&
          other.componentId == componentId &&
          other.componentName == componentName &&
          other.templateColumnIndex == templateColumnIndex &&
          other.status == status &&
          other.errorCode == errorCode &&
          other.version == version &&
          other.greenRows == greenRows &&
          other.yellowRows == yellowRows &&
          other.redRows == redRows;

  @override
  int get hashCode =>
      ticketId.hashCode +
      componentId.hashCode +
      componentName.hashCode +
      templateColumnIndex.hashCode +
      status.hashCode +
      (errorCode == null ? 0 : errorCode.hashCode) +
      version.hashCode +
      greenRows.hashCode +
      yellowRows.hashCode +
      redRows.hashCode;

  factory RecognitionBatchTicketDto.fromJson(Map<String, dynamic> json) =>
      _$RecognitionBatchTicketDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RecognitionBatchTicketDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecognitionBatchTicketDtoStatusEnum {
  @JsonValue(r'DANG_XU_LY')
  DANG_XU_LY(r'DANG_XU_LY'),
  @JsonValue(r'CHO_DOI_CHIEU')
  CHO_DOI_CHIEU(r'CHO_DOI_CHIEU'),
  @JsonValue(r'DA_DUYET')
  DA_DUYET(r'DA_DUYET'),
  @JsonValue(r'LOI')
  LOI(r'LOI'),
  @JsonValue(r'DA_HUY')
  DA_HUY(r'DA_HUY');

  const RecognitionBatchTicketDtoStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
