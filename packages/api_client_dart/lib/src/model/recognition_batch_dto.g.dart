// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recognition_batch_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecognitionBatchDtoCWProxy {
  RecognitionBatchDto batchId(String batchId);

  RecognitionBatchDto gradebookId(num gradebookId);

  RecognitionBatchDto templateId(num templateId);

  RecognitionBatchDto pageCount(num pageCount);

  RecognitionBatchDto status(RecognitionBatchDtoStatusEnum status);

  RecognitionBatchDto errorCode(String? errorCode);

  RecognitionBatchDto errorPage(num? errorPage);

  RecognitionBatchDto modelVersion(String? modelVersion);

  RecognitionBatchDto version(num version);

  RecognitionBatchDto createdAt(DateTime createdAt);

  RecognitionBatchDto cancelReason(String? cancelReason);

  RecognitionBatchDto cancelledAt(DateTime? cancelledAt);

  RecognitionBatchDto imageUrlExpiresInSeconds(num imageUrlExpiresInSeconds);

  RecognitionBatchDto pages(List<RecognitionBatchPageDto> pages);

  RecognitionBatchDto tickets(List<RecognitionBatchTicketDto> tickets);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecognitionBatchDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecognitionBatchDto(...).copyWith(id: 12, name: "My name")
  /// ````
  RecognitionBatchDto call({
    String batchId,
    num gradebookId,
    num templateId,
    num pageCount,
    RecognitionBatchDtoStatusEnum status,
    String? errorCode,
    num? errorPage,
    String? modelVersion,
    num version,
    DateTime createdAt,
    String? cancelReason,
    DateTime? cancelledAt,
    num imageUrlExpiresInSeconds,
    List<RecognitionBatchPageDto> pages,
    List<RecognitionBatchTicketDto> tickets,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecognitionBatchDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecognitionBatchDto.copyWith.fieldName(...)`
class _$RecognitionBatchDtoCWProxyImpl implements _$RecognitionBatchDtoCWProxy {
  const _$RecognitionBatchDtoCWProxyImpl(this._value);

  final RecognitionBatchDto _value;

  @override
  RecognitionBatchDto batchId(String batchId) => this(batchId: batchId);

  @override
  RecognitionBatchDto gradebookId(num gradebookId) =>
      this(gradebookId: gradebookId);

  @override
  RecognitionBatchDto templateId(num templateId) =>
      this(templateId: templateId);

  @override
  RecognitionBatchDto pageCount(num pageCount) => this(pageCount: pageCount);

  @override
  RecognitionBatchDto status(RecognitionBatchDtoStatusEnum status) =>
      this(status: status);

  @override
  RecognitionBatchDto errorCode(String? errorCode) =>
      this(errorCode: errorCode);

  @override
  RecognitionBatchDto errorPage(num? errorPage) => this(errorPage: errorPage);

  @override
  RecognitionBatchDto modelVersion(String? modelVersion) =>
      this(modelVersion: modelVersion);

  @override
  RecognitionBatchDto version(num version) => this(version: version);

  @override
  RecognitionBatchDto createdAt(DateTime createdAt) =>
      this(createdAt: createdAt);

  @override
  RecognitionBatchDto cancelReason(String? cancelReason) =>
      this(cancelReason: cancelReason);

  @override
  RecognitionBatchDto cancelledAt(DateTime? cancelledAt) =>
      this(cancelledAt: cancelledAt);

  @override
  RecognitionBatchDto imageUrlExpiresInSeconds(num imageUrlExpiresInSeconds) =>
      this(imageUrlExpiresInSeconds: imageUrlExpiresInSeconds);

  @override
  RecognitionBatchDto pages(List<RecognitionBatchPageDto> pages) =>
      this(pages: pages);

  @override
  RecognitionBatchDto tickets(List<RecognitionBatchTicketDto> tickets) =>
      this(tickets: tickets);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecognitionBatchDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecognitionBatchDto(...).copyWith(id: 12, name: "My name")
  /// ````
  RecognitionBatchDto call({
    Object? batchId = const $CopyWithPlaceholder(),
    Object? gradebookId = const $CopyWithPlaceholder(),
    Object? templateId = const $CopyWithPlaceholder(),
    Object? pageCount = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? errorCode = const $CopyWithPlaceholder(),
    Object? errorPage = const $CopyWithPlaceholder(),
    Object? modelVersion = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? cancelReason = const $CopyWithPlaceholder(),
    Object? cancelledAt = const $CopyWithPlaceholder(),
    Object? imageUrlExpiresInSeconds = const $CopyWithPlaceholder(),
    Object? pages = const $CopyWithPlaceholder(),
    Object? tickets = const $CopyWithPlaceholder(),
  }) {
    return RecognitionBatchDto(
      batchId: batchId == const $CopyWithPlaceholder()
          ? _value.batchId
          // ignore: cast_nullable_to_non_nullable
          : batchId as String,
      gradebookId: gradebookId == const $CopyWithPlaceholder()
          ? _value.gradebookId
          // ignore: cast_nullable_to_non_nullable
          : gradebookId as num,
      templateId: templateId == const $CopyWithPlaceholder()
          ? _value.templateId
          // ignore: cast_nullable_to_non_nullable
          : templateId as num,
      pageCount: pageCount == const $CopyWithPlaceholder()
          ? _value.pageCount
          // ignore: cast_nullable_to_non_nullable
          : pageCount as num,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as RecognitionBatchDtoStatusEnum,
      errorCode: errorCode == const $CopyWithPlaceholder()
          ? _value.errorCode
          // ignore: cast_nullable_to_non_nullable
          : errorCode as String?,
      errorPage: errorPage == const $CopyWithPlaceholder()
          ? _value.errorPage
          // ignore: cast_nullable_to_non_nullable
          : errorPage as num?,
      modelVersion: modelVersion == const $CopyWithPlaceholder()
          ? _value.modelVersion
          // ignore: cast_nullable_to_non_nullable
          : modelVersion as String?,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as num,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      cancelReason: cancelReason == const $CopyWithPlaceholder()
          ? _value.cancelReason
          // ignore: cast_nullable_to_non_nullable
          : cancelReason as String?,
      cancelledAt: cancelledAt == const $CopyWithPlaceholder()
          ? _value.cancelledAt
          // ignore: cast_nullable_to_non_nullable
          : cancelledAt as DateTime?,
      imageUrlExpiresInSeconds:
          imageUrlExpiresInSeconds == const $CopyWithPlaceholder()
          ? _value.imageUrlExpiresInSeconds
          // ignore: cast_nullable_to_non_nullable
          : imageUrlExpiresInSeconds as num,
      pages: pages == const $CopyWithPlaceholder()
          ? _value.pages
          // ignore: cast_nullable_to_non_nullable
          : pages as List<RecognitionBatchPageDto>,
      tickets: tickets == const $CopyWithPlaceholder()
          ? _value.tickets
          // ignore: cast_nullable_to_non_nullable
          : tickets as List<RecognitionBatchTicketDto>,
    );
  }
}

extension $RecognitionBatchDtoCopyWith on RecognitionBatchDto {
  /// Returns a callable class that can be used as follows: `instanceOfRecognitionBatchDto.copyWith(...)` or like so:`instanceOfRecognitionBatchDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecognitionBatchDtoCWProxy get copyWith =>
      _$RecognitionBatchDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecognitionBatchDto _$RecognitionBatchDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecognitionBatchDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'batchId',
      'gradebookId',
      'templateId',
      'pageCount',
      'status',
      'errorCode',
      'errorPage',
      'modelVersion',
      'version',
      'createdAt',
      'cancelReason',
      'cancelledAt',
      'imageUrlExpiresInSeconds',
      'pages',
      'tickets',
    ],
  );
  final val = RecognitionBatchDto(
    batchId: $checkedConvert('batchId', (v) => v as String),
    gradebookId: $checkedConvert('gradebookId', (v) => v as num),
    templateId: $checkedConvert('templateId', (v) => v as num),
    pageCount: $checkedConvert('pageCount', (v) => v as num),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$RecognitionBatchDtoStatusEnumEnumMap, v),
    ),
    errorCode: $checkedConvert('errorCode', (v) => v as String?),
    errorPage: $checkedConvert('errorPage', (v) => v as num?),
    modelVersion: $checkedConvert('modelVersion', (v) => v as String?),
    version: $checkedConvert('version', (v) => v as num),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    cancelReason: $checkedConvert('cancelReason', (v) => v as String?),
    cancelledAt: $checkedConvert(
      'cancelledAt',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
    imageUrlExpiresInSeconds: $checkedConvert(
      'imageUrlExpiresInSeconds',
      (v) => v as num,
    ),
    pages: $checkedConvert(
      'pages',
      (v) => (v as List<dynamic>)
          .map(
            (e) => RecognitionBatchPageDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    tickets: $checkedConvert(
      'tickets',
      (v) => (v as List<dynamic>)
          .map(
            (e) =>
                RecognitionBatchTicketDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$RecognitionBatchDtoToJson(
  RecognitionBatchDto instance,
) => <String, dynamic>{
  'batchId': instance.batchId,
  'gradebookId': instance.gradebookId,
  'templateId': instance.templateId,
  'pageCount': instance.pageCount,
  'status': _$RecognitionBatchDtoStatusEnumEnumMap[instance.status]!,
  'errorCode': instance.errorCode,
  'errorPage': instance.errorPage,
  'modelVersion': instance.modelVersion,
  'version': instance.version,
  'createdAt': instance.createdAt.toIso8601String(),
  'cancelReason': instance.cancelReason,
  'cancelledAt': instance.cancelledAt?.toIso8601String(),
  'imageUrlExpiresInSeconds': instance.imageUrlExpiresInSeconds,
  'pages': instance.pages.map((e) => e.toJson()).toList(),
  'tickets': instance.tickets.map((e) => e.toJson()).toList(),
};

const _$RecognitionBatchDtoStatusEnumEnumMap = {
  RecognitionBatchDtoStatusEnum.DANG_XU_LY: 'DANG_XU_LY',
  RecognitionBatchDtoStatusEnum.XONG: 'XONG',
  RecognitionBatchDtoStatusEnum.LOI: 'LOI',
  RecognitionBatchDtoStatusEnum.DA_HUY: 'DA_HUY',
};
