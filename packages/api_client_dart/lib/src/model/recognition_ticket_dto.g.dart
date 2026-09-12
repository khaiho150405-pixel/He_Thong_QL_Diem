// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recognition_ticket_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecognitionTicketDtoCWProxy {
  RecognitionTicketDto ticketId(String ticketId);

  RecognitionTicketDto gradebookId(num gradebookId);

  RecognitionTicketDto componentId(num componentId);

  RecognitionTicketDto componentName(String componentName);

  RecognitionTicketDto declaredRows(num declaredRows);

  RecognitionTicketDto detectedRows(num? detectedRows);

  RecognitionTicketDto status(RecognitionTicketDtoStatusEnum status);

  RecognitionTicketDto errorCode(String? errorCode);

  RecognitionTicketDto modelVersion(String? modelVersion);

  RecognitionTicketDto version(num version);

  RecognitionTicketDto createdAt(DateTime createdAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecognitionTicketDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecognitionTicketDto(...).copyWith(id: 12, name: "My name")
  /// ````
  RecognitionTicketDto call({
    String ticketId,
    num gradebookId,
    num componentId,
    String componentName,
    num declaredRows,
    num? detectedRows,
    RecognitionTicketDtoStatusEnum status,
    String? errorCode,
    String? modelVersion,
    num version,
    DateTime createdAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecognitionTicketDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecognitionTicketDto.copyWith.fieldName(...)`
class _$RecognitionTicketDtoCWProxyImpl
    implements _$RecognitionTicketDtoCWProxy {
  const _$RecognitionTicketDtoCWProxyImpl(this._value);

  final RecognitionTicketDto _value;

  @override
  RecognitionTicketDto ticketId(String ticketId) => this(ticketId: ticketId);

  @override
  RecognitionTicketDto gradebookId(num gradebookId) =>
      this(gradebookId: gradebookId);

  @override
  RecognitionTicketDto componentId(num componentId) =>
      this(componentId: componentId);

  @override
  RecognitionTicketDto componentName(String componentName) =>
      this(componentName: componentName);

  @override
  RecognitionTicketDto declaredRows(num declaredRows) =>
      this(declaredRows: declaredRows);

  @override
  RecognitionTicketDto detectedRows(num? detectedRows) =>
      this(detectedRows: detectedRows);

  @override
  RecognitionTicketDto status(RecognitionTicketDtoStatusEnum status) =>
      this(status: status);

  @override
  RecognitionTicketDto errorCode(String? errorCode) =>
      this(errorCode: errorCode);

  @override
  RecognitionTicketDto modelVersion(String? modelVersion) =>
      this(modelVersion: modelVersion);

  @override
  RecognitionTicketDto version(num version) => this(version: version);

  @override
  RecognitionTicketDto createdAt(DateTime createdAt) =>
      this(createdAt: createdAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecognitionTicketDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecognitionTicketDto(...).copyWith(id: 12, name: "My name")
  /// ````
  RecognitionTicketDto call({
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
  }) {
    return RecognitionTicketDto(
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
          : status as RecognitionTicketDtoStatusEnum,
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
    );
  }
}

extension $RecognitionTicketDtoCopyWith on RecognitionTicketDto {
  /// Returns a callable class that can be used as follows: `instanceOfRecognitionTicketDto.copyWith(...)` or like so:`instanceOfRecognitionTicketDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecognitionTicketDtoCWProxy get copyWith =>
      _$RecognitionTicketDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecognitionTicketDto _$RecognitionTicketDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecognitionTicketDto', json, ($checkedConvert) {
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
    ],
  );
  final val = RecognitionTicketDto(
    ticketId: $checkedConvert('ticketId', (v) => v as String),
    gradebookId: $checkedConvert('gradebookId', (v) => v as num),
    componentId: $checkedConvert('componentId', (v) => v as num),
    componentName: $checkedConvert('componentName', (v) => v as String),
    declaredRows: $checkedConvert('declaredRows', (v) => v as num),
    detectedRows: $checkedConvert('detectedRows', (v) => v as num?),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$RecognitionTicketDtoStatusEnumEnumMap, v),
    ),
    errorCode: $checkedConvert('errorCode', (v) => v as String?),
    modelVersion: $checkedConvert('modelVersion', (v) => v as String?),
    version: $checkedConvert('version', (v) => v as num),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
  );
  return val;
});

Map<String, dynamic> _$RecognitionTicketDtoToJson(
  RecognitionTicketDto instance,
) => <String, dynamic>{
  'ticketId': instance.ticketId,
  'gradebookId': instance.gradebookId,
  'componentId': instance.componentId,
  'componentName': instance.componentName,
  'declaredRows': instance.declaredRows,
  'detectedRows': instance.detectedRows,
  'status': _$RecognitionTicketDtoStatusEnumEnumMap[instance.status]!,
  'errorCode': instance.errorCode,
  'modelVersion': instance.modelVersion,
  'version': instance.version,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$RecognitionTicketDtoStatusEnumEnumMap = {
  RecognitionTicketDtoStatusEnum.DANG_XU_LY: 'DANG_XU_LY',
  RecognitionTicketDtoStatusEnum.CHO_DOI_CHIEU: 'CHO_DOI_CHIEU',
  RecognitionTicketDtoStatusEnum.DA_DUYET: 'DA_DUYET',
  RecognitionTicketDtoStatusEnum.LOI: 'LOI',
};
