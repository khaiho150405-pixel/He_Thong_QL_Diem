//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/recognition_batch_page_dto.dart';
import 'package:api_client_dart/src/model/recognition_batch_ticket_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recognition_batch_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecognitionBatchDto {
  /// Returns a new [RecognitionBatchDto] instance.
  RecognitionBatchDto({
    required this.batchId,

    required this.gradebookId,

    required this.templateId,

    required this.pageCount,

    required this.status,

    required this.errorCode,

    required this.errorPage,

    required this.modelVersion,

    required this.version,

    required this.createdAt,

    required this.cancelReason,

    required this.cancelledAt,

    required this.imageUrlExpiresInSeconds,

    required this.pages,

    required this.tickets,
  });

  @JsonKey(name: r'batchId', required: true, includeIfNull: false)
  final String batchId;

  @JsonKey(name: r'gradebookId', required: true, includeIfNull: false)
  final num gradebookId;

  @JsonKey(name: r'templateId', required: true, includeIfNull: false)
  final num templateId;

  @JsonKey(name: r'pageCount', required: true, includeIfNull: false)
  final num pageCount;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final RecognitionBatchDtoStatusEnum status;

  /// Mã lỗi chung của lô; mọi phiếu LOI của lô mang cùng mã
  @JsonKey(name: r'errorCode', required: true, includeIfNull: true)
  final String? errorCode;

  /// Trang gây lỗi (1..pageCount); null khi lỗi không gắn với trang
  @JsonKey(name: r'errorPage', required: true, includeIfNull: true)
  final num? errorPage;

  @JsonKey(name: r'modelVersion', required: true, includeIfNull: true)
  final String? modelVersion;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final num version;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  @JsonKey(name: r'cancelReason', required: true, includeIfNull: true)
  final String? cancelReason;

  @JsonKey(name: r'cancelledAt', required: true, includeIfNull: true)
  final DateTime? cancelledAt;

  @JsonKey(
    name: r'imageUrlExpiresInSeconds',
    required: true,
    includeIfNull: false,
  )
  final num imageUrlExpiresInSeconds;

  @JsonKey(name: r'pages', required: true, includeIfNull: false)
  final List<RecognitionBatchPageDto> pages;

  @JsonKey(name: r'tickets', required: true, includeIfNull: false)
  final List<RecognitionBatchTicketDto> tickets;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecognitionBatchDto &&
          other.batchId == batchId &&
          other.gradebookId == gradebookId &&
          other.templateId == templateId &&
          other.pageCount == pageCount &&
          other.status == status &&
          other.errorCode == errorCode &&
          other.errorPage == errorPage &&
          other.modelVersion == modelVersion &&
          other.version == version &&
          other.createdAt == createdAt &&
          other.cancelReason == cancelReason &&
          other.cancelledAt == cancelledAt &&
          other.imageUrlExpiresInSeconds == imageUrlExpiresInSeconds &&
          other.pages == pages &&
          other.tickets == tickets;

  @override
  int get hashCode =>
      batchId.hashCode +
      gradebookId.hashCode +
      templateId.hashCode +
      pageCount.hashCode +
      status.hashCode +
      (errorCode == null ? 0 : errorCode.hashCode) +
      (errorPage == null ? 0 : errorPage.hashCode) +
      (modelVersion == null ? 0 : modelVersion.hashCode) +
      version.hashCode +
      createdAt.hashCode +
      (cancelReason == null ? 0 : cancelReason.hashCode) +
      (cancelledAt == null ? 0 : cancelledAt.hashCode) +
      imageUrlExpiresInSeconds.hashCode +
      pages.hashCode +
      tickets.hashCode;

  factory RecognitionBatchDto.fromJson(Map<String, dynamic> json) =>
      _$RecognitionBatchDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RecognitionBatchDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecognitionBatchDtoStatusEnum {
  @JsonValue(r'DANG_XU_LY')
  DANG_XU_LY(r'DANG_XU_LY'),
  @JsonValue(r'XONG')
  XONG(r'XONG'),
  @JsonValue(r'LOI')
  LOI(r'LOI'),
  @JsonValue(r'DA_HUY')
  DA_HUY(r'DA_HUY');

  const RecognitionBatchDtoStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
