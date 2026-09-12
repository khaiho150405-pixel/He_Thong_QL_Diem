//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recognition_ticket_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecognitionTicketDto {
  /// Returns a new [RecognitionTicketDto] instance.
  RecognitionTicketDto({
    required this.ticketId,

    required this.gradebookId,

    required this.componentId,

    required this.componentName,

    required this.declaredRows,

    required this.detectedRows,

    required this.status,

    required this.errorCode,

    required this.modelVersion,

    required this.version,

    required this.createdAt,
  });

  @JsonKey(name: r'ticketId', required: true, includeIfNull: false)
  final String ticketId;

  @JsonKey(name: r'gradebookId', required: true, includeIfNull: false)
  final num gradebookId;

  @JsonKey(name: r'componentId', required: true, includeIfNull: false)
  final num componentId;

  @JsonKey(name: r'componentName', required: true, includeIfNull: false)
  final String componentName;

  @JsonKey(name: r'declaredRows', required: true, includeIfNull: false)
  final num declaredRows;

  @JsonKey(name: r'detectedRows', required: true, includeIfNull: true)
  final num? detectedRows;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final RecognitionTicketDtoStatusEnum status;

  @JsonKey(name: r'errorCode', required: true, includeIfNull: true)
  final String? errorCode;

  @JsonKey(name: r'modelVersion', required: true, includeIfNull: true)
  final String? modelVersion;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final num version;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecognitionTicketDto &&
          other.ticketId == ticketId &&
          other.gradebookId == gradebookId &&
          other.componentId == componentId &&
          other.componentName == componentName &&
          other.declaredRows == declaredRows &&
          other.detectedRows == detectedRows &&
          other.status == status &&
          other.errorCode == errorCode &&
          other.modelVersion == modelVersion &&
          other.version == version &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      ticketId.hashCode +
      gradebookId.hashCode +
      componentId.hashCode +
      componentName.hashCode +
      declaredRows.hashCode +
      (detectedRows == null ? 0 : detectedRows.hashCode) +
      status.hashCode +
      (errorCode == null ? 0 : errorCode.hashCode) +
      (modelVersion == null ? 0 : modelVersion.hashCode) +
      version.hashCode +
      createdAt.hashCode;

  factory RecognitionTicketDto.fromJson(Map<String, dynamic> json) =>
      _$RecognitionTicketDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RecognitionTicketDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecognitionTicketDtoStatusEnum {
  @JsonValue(r'DANG_XU_LY')
  DANG_XU_LY(r'DANG_XU_LY'),
  @JsonValue(r'CHO_DOI_CHIEU')
  CHO_DOI_CHIEU(r'CHO_DOI_CHIEU'),
  @JsonValue(r'DA_DUYET')
  DA_DUYET(r'DA_DUYET'),
  @JsonValue(r'LOI')
  LOI(r'LOI');

  const RecognitionTicketDtoStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
