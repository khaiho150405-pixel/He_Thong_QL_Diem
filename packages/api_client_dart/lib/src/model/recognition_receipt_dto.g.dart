// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recognition_receipt_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecognitionReceiptDtoCWProxy {
  RecognitionReceiptDto ticketId(String ticketId);

  RecognitionReceiptDto jobId(String jobId);

  RecognitionReceiptDto status(RecognitionReceiptDtoStatusEnum status);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecognitionReceiptDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecognitionReceiptDto(...).copyWith(id: 12, name: "My name")
  /// ````
  RecognitionReceiptDto call({
    String ticketId,
    String jobId,
    RecognitionReceiptDtoStatusEnum status,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecognitionReceiptDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecognitionReceiptDto.copyWith.fieldName(...)`
class _$RecognitionReceiptDtoCWProxyImpl
    implements _$RecognitionReceiptDtoCWProxy {
  const _$RecognitionReceiptDtoCWProxyImpl(this._value);

  final RecognitionReceiptDto _value;

  @override
  RecognitionReceiptDto ticketId(String ticketId) => this(ticketId: ticketId);

  @override
  RecognitionReceiptDto jobId(String jobId) => this(jobId: jobId);

  @override
  RecognitionReceiptDto status(RecognitionReceiptDtoStatusEnum status) =>
      this(status: status);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecognitionReceiptDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecognitionReceiptDto(...).copyWith(id: 12, name: "My name")
  /// ````
  RecognitionReceiptDto call({
    Object? ticketId = const $CopyWithPlaceholder(),
    Object? jobId = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return RecognitionReceiptDto(
      ticketId: ticketId == const $CopyWithPlaceholder()
          ? _value.ticketId
          // ignore: cast_nullable_to_non_nullable
          : ticketId as String,
      jobId: jobId == const $CopyWithPlaceholder()
          ? _value.jobId
          // ignore: cast_nullable_to_non_nullable
          : jobId as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as RecognitionReceiptDtoStatusEnum,
    );
  }
}

extension $RecognitionReceiptDtoCopyWith on RecognitionReceiptDto {
  /// Returns a callable class that can be used as follows: `instanceOfRecognitionReceiptDto.copyWith(...)` or like so:`instanceOfRecognitionReceiptDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecognitionReceiptDtoCWProxy get copyWith =>
      _$RecognitionReceiptDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecognitionReceiptDto _$RecognitionReceiptDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecognitionReceiptDto', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['ticketId', 'jobId', 'status']);
  final val = RecognitionReceiptDto(
    ticketId: $checkedConvert('ticketId', (v) => v as String),
    jobId: $checkedConvert('jobId', (v) => v as String),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$RecognitionReceiptDtoStatusEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$RecognitionReceiptDtoToJson(
  RecognitionReceiptDto instance,
) => <String, dynamic>{
  'ticketId': instance.ticketId,
  'jobId': instance.jobId,
  'status': _$RecognitionReceiptDtoStatusEnumEnumMap[instance.status]!,
};

const _$RecognitionReceiptDtoStatusEnumEnumMap = {
  RecognitionReceiptDtoStatusEnum.DANG_XU_LY: 'DANG_XU_LY',
};
