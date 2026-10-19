// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recognition_batch_ticket_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecognitionBatchTicketDtoCWProxy {
  RecognitionBatchTicketDto ticketId(String ticketId);

  RecognitionBatchTicketDto componentId(num componentId);

  RecognitionBatchTicketDto componentName(String componentName);

  RecognitionBatchTicketDto templateColumnIndex(num templateColumnIndex);

  RecognitionBatchTicketDto status(RecognitionBatchTicketDtoStatusEnum status);

  RecognitionBatchTicketDto errorCode(String? errorCode);

  RecognitionBatchTicketDto version(num version);

  RecognitionBatchTicketDto greenRows(num greenRows);

  RecognitionBatchTicketDto yellowRows(num yellowRows);

  RecognitionBatchTicketDto redRows(num redRows);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecognitionBatchTicketDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecognitionBatchTicketDto(...).copyWith(id: 12, name: "My name")
  /// ````
  RecognitionBatchTicketDto call({
    String ticketId,
    num componentId,
    String componentName,
    num templateColumnIndex,
    RecognitionBatchTicketDtoStatusEnum status,
    String? errorCode,
    num version,
    num greenRows,
    num yellowRows,
    num redRows,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecognitionBatchTicketDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecognitionBatchTicketDto.copyWith.fieldName(...)`
class _$RecognitionBatchTicketDtoCWProxyImpl
    implements _$RecognitionBatchTicketDtoCWProxy {
  const _$RecognitionBatchTicketDtoCWProxyImpl(this._value);

  final RecognitionBatchTicketDto _value;

  @override
  RecognitionBatchTicketDto ticketId(String ticketId) =>
      this(ticketId: ticketId);

  @override
  RecognitionBatchTicketDto componentId(num componentId) =>
      this(componentId: componentId);

  @override
  RecognitionBatchTicketDto componentName(String componentName) =>
      this(componentName: componentName);

  @override
  RecognitionBatchTicketDto templateColumnIndex(num templateColumnIndex) =>
      this(templateColumnIndex: templateColumnIndex);

  @override
  RecognitionBatchTicketDto status(
    RecognitionBatchTicketDtoStatusEnum status,
  ) => this(status: status);

  @override
  RecognitionBatchTicketDto errorCode(String? errorCode) =>
      this(errorCode: errorCode);

  @override
  RecognitionBatchTicketDto version(num version) => this(version: version);

  @override
  RecognitionBatchTicketDto greenRows(num greenRows) =>
      this(greenRows: greenRows);

  @override
  RecognitionBatchTicketDto yellowRows(num yellowRows) =>
      this(yellowRows: yellowRows);

  @override
  RecognitionBatchTicketDto redRows(num redRows) => this(redRows: redRows);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecognitionBatchTicketDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecognitionBatchTicketDto(...).copyWith(id: 12, name: "My name")
  /// ````
  RecognitionBatchTicketDto call({
    Object? ticketId = const $CopyWithPlaceholder(),
    Object? componentId = const $CopyWithPlaceholder(),
    Object? componentName = const $CopyWithPlaceholder(),
    Object? templateColumnIndex = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? errorCode = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? greenRows = const $CopyWithPlaceholder(),
    Object? yellowRows = const $CopyWithPlaceholder(),
    Object? redRows = const $CopyWithPlaceholder(),
  }) {
    return RecognitionBatchTicketDto(
      ticketId: ticketId == const $CopyWithPlaceholder()
          ? _value.ticketId
          // ignore: cast_nullable_to_non_nullable
          : ticketId as String,
      componentId: componentId == const $CopyWithPlaceholder()
          ? _value.componentId
          // ignore: cast_nullable_to_non_nullable
          : componentId as num,
      componentName: componentName == const $CopyWithPlaceholder()
          ? _value.componentName
          // ignore: cast_nullable_to_non_nullable
          : componentName as String,
      templateColumnIndex: templateColumnIndex == const $CopyWithPlaceholder()
          ? _value.templateColumnIndex
          // ignore: cast_nullable_to_non_nullable
          : templateColumnIndex as num,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as RecognitionBatchTicketDtoStatusEnum,
      errorCode: errorCode == const $CopyWithPlaceholder()
          ? _value.errorCode
          // ignore: cast_nullable_to_non_nullable
          : errorCode as String?,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as num,
      greenRows: greenRows == const $CopyWithPlaceholder()
          ? _value.greenRows
          // ignore: cast_nullable_to_non_nullable
          : greenRows as num,
      yellowRows: yellowRows == const $CopyWithPlaceholder()
          ? _value.yellowRows
          // ignore: cast_nullable_to_non_nullable
          : yellowRows as num,
      redRows: redRows == const $CopyWithPlaceholder()
          ? _value.redRows
          // ignore: cast_nullable_to_non_nullable
          : redRows as num,
    );
  }
}

extension $RecognitionBatchTicketDtoCopyWith on RecognitionBatchTicketDto {
  /// Returns a callable class that can be used as follows: `instanceOfRecognitionBatchTicketDto.copyWith(...)` or like so:`instanceOfRecognitionBatchTicketDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecognitionBatchTicketDtoCWProxy get copyWith =>
      _$RecognitionBatchTicketDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecognitionBatchTicketDto _$RecognitionBatchTicketDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecognitionBatchTicketDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'ticketId',
      'componentId',
      'componentName',
      'templateColumnIndex',
      'status',
      'errorCode',
      'version',
      'greenRows',
      'yellowRows',
      'redRows',
    ],
  );
  final val = RecognitionBatchTicketDto(
    ticketId: $checkedConvert('ticketId', (v) => v as String),
    componentId: $checkedConvert('componentId', (v) => v as num),
    componentName: $checkedConvert('componentName', (v) => v as String),
    templateColumnIndex: $checkedConvert(
      'templateColumnIndex',
      (v) => v as num,
    ),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$RecognitionBatchTicketDtoStatusEnumEnumMap, v),
    ),
    errorCode: $checkedConvert('errorCode', (v) => v as String?),
    version: $checkedConvert('version', (v) => v as num),
    greenRows: $checkedConvert('greenRows', (v) => v as num),
    yellowRows: $checkedConvert('yellowRows', (v) => v as num),
    redRows: $checkedConvert('redRows', (v) => v as num),
  );
  return val;
});

Map<String, dynamic> _$RecognitionBatchTicketDtoToJson(
  RecognitionBatchTicketDto instance,
) => <String, dynamic>{
  'ticketId': instance.ticketId,
  'componentId': instance.componentId,
  'componentName': instance.componentName,
  'templateColumnIndex': instance.templateColumnIndex,
  'status': _$RecognitionBatchTicketDtoStatusEnumEnumMap[instance.status]!,
  'errorCode': instance.errorCode,
  'version': instance.version,
  'greenRows': instance.greenRows,
  'yellowRows': instance.yellowRows,
  'redRows': instance.redRows,
};

const _$RecognitionBatchTicketDtoStatusEnumEnumMap = {
  RecognitionBatchTicketDtoStatusEnum.DANG_XU_LY: 'DANG_XU_LY',
  RecognitionBatchTicketDtoStatusEnum.CHO_DOI_CHIEU: 'CHO_DOI_CHIEU',
  RecognitionBatchTicketDtoStatusEnum.DA_DUYET: 'DA_DUYET',
  RecognitionBatchTicketDtoStatusEnum.LOI: 'LOI',
  RecognitionBatchTicketDtoStatusEnum.DA_HUY: 'DA_HUY',
};
