// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recognition_ticket_detail_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecognitionTicketDetailDtoCWProxy {
  RecognitionTicketDetailDto ticketId(String ticketId);

  RecognitionTicketDetailDto gradebookId(num gradebookId);

  RecognitionTicketDetailDto componentId(num componentId);

  RecognitionTicketDetailDto componentName(String componentName);

  RecognitionTicketDetailDto declaredRows(num declaredRows);

  RecognitionTicketDetailDto detectedRows(num? detectedRows);

  RecognitionTicketDetailDto status(
    RecognitionTicketDetailDtoStatusEnum status,
  );

  RecognitionTicketDetailDto errorCode(String? errorCode);

  RecognitionTicketDetailDto modelVersion(String? modelVersion);

  RecognitionTicketDetailDto version(num version);

  RecognitionTicketDetailDto createdAt(DateTime createdAt);

  RecognitionTicketDetailDto sourceImageUrl(String sourceImageUrl);

  RecognitionTicketDetailDto imageUrlExpiresInSeconds(
    num imageUrlExpiresInSeconds,
  );

  RecognitionTicketDetailDto rows(List<RecognitionEvidenceRowDto> rows);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecognitionTicketDetailDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecognitionTicketDetailDto(...).copyWith(id: 12, name: "My name")
  /// ````
  RecognitionTicketDetailDto call({
    String ticketId,
    num gradebookId,
    num componentId,
    String componentName,
    num declaredRows,
    num? detectedRows,
    RecognitionTicketDetailDtoStatusEnum status,
    String? errorCode,
    String? modelVersion,
    num version,
    DateTime createdAt,
    String sourceImageUrl,
    num imageUrlExpiresInSeconds,
    List<RecognitionEvidenceRowDto> rows,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecognitionTicketDetailDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecognitionTicketDetailDto.copyWith.fieldName(...)`
class _$RecognitionTicketDetailDtoCWProxyImpl
    implements _$RecognitionTicketDetailDtoCWProxy {
  const _$RecognitionTicketDetailDtoCWProxyImpl(this._value);

  final RecognitionTicketDetailDto _value;

  @override
  RecognitionTicketDetailDto ticketId(String ticketId) =>
      this(ticketId: ticketId);

  @override
  RecognitionTicketDetailDto gradebookId(num gradebookId) =>
      this(gradebookId: gradebookId);

  @override
  RecognitionTicketDetailDto componentId(num componentId) =>
      this(componentId: componentId);

  @override
  RecognitionTicketDetailDto componentName(String componentName) =>
      this(componentName: componentName);

  @override
  RecognitionTicketDetailDto declaredRows(num declaredRows) =>
      this(declaredRows: declaredRows);

  @override
  RecognitionTicketDetailDto detectedRows(num? detectedRows) =>
      this(detectedRows: detectedRows);

  @override
  RecognitionTicketDetailDto status(
    RecognitionTicketDetailDtoStatusEnum status,
  ) => this(status: status);

  @override
  RecognitionTicketDetailDto errorCode(String? errorCode) =>
      this(errorCode: errorCode);

  @override
  RecognitionTicketDetailDto modelVersion(String? modelVersion) =>
      this(modelVersion: modelVersion);

  @override
  RecognitionTicketDetailDto version(num version) => this(version: version);

  @override
  RecognitionTicketDetailDto createdAt(DateTime createdAt) =>
      this(createdAt: createdAt);

  @override
  RecognitionTicketDetailDto sourceImageUrl(String sourceImageUrl) =>
      this(sourceImageUrl: sourceImageUrl);

  @override
  RecognitionTicketDetailDto imageUrlExpiresInSeconds(
    num imageUrlExpiresInSeconds,
  ) => this(imageUrlExpiresInSeconds: imageUrlExpiresInSeconds);

  @override
  RecognitionTicketDetailDto rows(List<RecognitionEvidenceRowDto> rows) =>
      this(rows: rows);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecognitionTicketDetailDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecognitionTicketDetailDto(...).copyWith(id: 12, name: "My name")
  /// ````
  RecognitionTicketDetailDto call({
    Object? ticketId = const $CopyWithPlaceholder(),
    Object? gradebookId = const $CopyWithPlaceholder(),
    Object? componentId = const $CopyWithPlaceholder(),
    Object? componentName = const $CopyWithPlaceholder(),
    Object? declaredRows = const $CopyWithPlaceholder(),
    Object? detectedRows = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? errorCode = const $CopyWithPlaceholder(),
    Object? modelVersion = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? sourceImageUrl = const $CopyWithPlaceholder(),
    Object? imageUrlExpiresInSeconds = const $CopyWithPlaceholder(),
    Object? rows = const $CopyWithPlaceholder(),
  }) {
    return RecognitionTicketDetailDto(
      ticketId: ticketId == const $CopyWithPlaceholder()
          ? _value.ticketId
          // ignore: cast_nullable_to_non_nullable
          : ticketId as String,
      gradebookId: gradebookId == const $CopyWithPlaceholder()
          ? _value.gradebookId
          // ignore: cast_nullable_to_non_nullable
          : gradebookId as num,
      componentId: componentId == const $CopyWithPlaceholder()
          ? _value.componentId
          // ignore: cast_nullable_to_non_nullable
          : componentId as num,
      componentName: componentName == const $CopyWithPlaceholder()
          ? _value.componentName
          // ignore: cast_nullable_to_non_nullable
          : componentName as String,
      declaredRows: declaredRows == const $CopyWithPlaceholder()
          ? _value.declaredRows
          // ignore: cast_nullable_to_non_nullable
          : declaredRows as num,
      detectedRows: detectedRows == const $CopyWithPlaceholder()
          ? _value.detectedRows
          // ignore: cast_nullable_to_non_nullable
          : detectedRows as num?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as RecognitionTicketDetailDtoStatusEnum,
      errorCode: errorCode == const $CopyWithPlaceholder()
          ? _value.errorCode
          // ignore: cast_nullable_to_non_nullable
          : errorCode as String?,
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
      sourceImageUrl: sourceImageUrl == const $CopyWithPlaceholder()
          ? _value.sourceImageUrl
          // ignore: cast_nullable_to_non_nullable
          : sourceImageUrl as String,
      imageUrlExpiresInSeconds:
          imageUrlExpiresInSeconds == const $CopyWithPlaceholder()
          ? _value.imageUrlExpiresInSeconds
          // ignore: cast_nullable_to_non_nullable
          : imageUrlExpiresInSeconds as num,
      rows: rows == const $CopyWithPlaceholder()
          ? _value.rows
          // ignore: cast_nullable_to_non_nullable
          : rows as List<RecognitionEvidenceRowDto>,
    );
  }
}

extension $RecognitionTicketDetailDtoCopyWith on RecognitionTicketDetailDto {
  /// Returns a callable class that can be used as follows: `instanceOfRecognitionTicketDetailDto.copyWith(...)` or like so:`instanceOfRecognitionTicketDetailDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecognitionTicketDetailDtoCWProxy get copyWith =>
      _$RecognitionTicketDetailDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecognitionTicketDetailDto _$RecognitionTicketDetailDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecognitionTicketDetailDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'ticketId',
      'gradebookId',
      'componentId',
      'componentName',
      'declaredRows',
      'detectedRows',
      'status',
      'errorCode',
      'modelVersion',
      'version',
      'createdAt',
      'sourceImageUrl',
      'imageUrlExpiresInSeconds',
      'rows',
    ],
  );
  final val = RecognitionTicketDetailDto(
    ticketId: $checkedConvert('ticketId', (v) => v as String),
    gradebookId: $checkedConvert('gradebookId', (v) => v as num),
    componentId: $checkedConvert('componentId', (v) => v as num),
    componentName: $checkedConvert('componentName', (v) => v as String),
    declaredRows: $checkedConvert('declaredRows', (v) => v as num),
    detectedRows: $checkedConvert('detectedRows', (v) => v as num?),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$RecognitionTicketDetailDtoStatusEnumEnumMap, v),
    ),
    errorCode: $checkedConvert('errorCode', (v) => v as String?),
    modelVersion: $checkedConvert('modelVersion', (v) => v as String?),
    version: $checkedConvert('version', (v) => v as num),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    sourceImageUrl: $checkedConvert('sourceImageUrl', (v) => v as String),
    imageUrlExpiresInSeconds: $checkedConvert(
      'imageUrlExpiresInSeconds',
      (v) => v as num,
    ),
    rows: $checkedConvert(
      'rows',
      (v) => (v as List<dynamic>)
          .map(
            (e) =>
                RecognitionEvidenceRowDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$RecognitionTicketDetailDtoToJson(
  RecognitionTicketDetailDto instance,
) => <String, dynamic>{
  'ticketId': instance.ticketId,
  'gradebookId': instance.gradebookId,
  'componentId': instance.componentId,
  'componentName': instance.componentName,
  'declaredRows': instance.declaredRows,
  'detectedRows': instance.detectedRows,
  'status': _$RecognitionTicketDetailDtoStatusEnumEnumMap[instance.status]!,
  'errorCode': instance.errorCode,
  'modelVersion': instance.modelVersion,
  'version': instance.version,
  'createdAt': instance.createdAt.toIso8601String(),
  'sourceImageUrl': instance.sourceImageUrl,
  'imageUrlExpiresInSeconds': instance.imageUrlExpiresInSeconds,
  'rows': instance.rows.map((e) => e.toJson()).toList(),
};

const _$RecognitionTicketDetailDtoStatusEnumEnumMap = {
  RecognitionTicketDetailDtoStatusEnum.DANG_XU_LY: 'DANG_XU_LY',
  RecognitionTicketDetailDtoStatusEnum.CHO_DOI_CHIEU: 'CHO_DOI_CHIEU',
  RecognitionTicketDetailDtoStatusEnum.DA_DUYET: 'DA_DUYET',
  RecognitionTicketDetailDtoStatusEnum.LOI: 'LOI',
};
