// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recognition_batch_receipt_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecognitionBatchReceiptDtoCWProxy {
  RecognitionBatchReceiptDto batchId(String batchId);

  RecognitionBatchReceiptDto jobId(String jobId);

  RecognitionBatchReceiptDto status(
    RecognitionBatchReceiptDtoStatusEnum status,
  );

  RecognitionBatchReceiptDto tickets(
    List<RecognitionBatchTicketReceiptDto> tickets,
  );

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecognitionBatchReceiptDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecognitionBatchReceiptDto(...).copyWith(id: 12, name: "My name")
  /// ````
  RecognitionBatchReceiptDto call({
    String batchId,
    String jobId,
    RecognitionBatchReceiptDtoStatusEnum status,
    List<RecognitionBatchTicketReceiptDto> tickets,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecognitionBatchReceiptDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecognitionBatchReceiptDto.copyWith.fieldName(...)`
class _$RecognitionBatchReceiptDtoCWProxyImpl
    implements _$RecognitionBatchReceiptDtoCWProxy {
  const _$RecognitionBatchReceiptDtoCWProxyImpl(this._value);

  final RecognitionBatchReceiptDto _value;

  @override
  RecognitionBatchReceiptDto batchId(String batchId) => this(batchId: batchId);

  @override
  RecognitionBatchReceiptDto jobId(String jobId) => this(jobId: jobId);

  @override
  RecognitionBatchReceiptDto status(
    RecognitionBatchReceiptDtoStatusEnum status,
  ) => this(status: status);

  @override
  RecognitionBatchReceiptDto tickets(
    List<RecognitionBatchTicketReceiptDto> tickets,
  ) => this(tickets: tickets);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecognitionBatchReceiptDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecognitionBatchReceiptDto(...).copyWith(id: 12, name: "My name")
  /// ````
  RecognitionBatchReceiptDto call({
    Object? batchId = const $CopyWithPlaceholder(),
    Object? jobId = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? tickets = const $CopyWithPlaceholder(),
  }) {
    return RecognitionBatchReceiptDto(
      batchId: batchId == const $CopyWithPlaceholder()
          ? _value.batchId
          // ignore: cast_nullable_to_non_nullable
          : batchId as String,
      jobId: jobId == const $CopyWithPlaceholder()
          ? _value.jobId
          // ignore: cast_nullable_to_non_nullable
          : jobId as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as RecognitionBatchReceiptDtoStatusEnum,
      tickets: tickets == const $CopyWithPlaceholder()
          ? _value.tickets
          // ignore: cast_nullable_to_non_nullable
          : tickets as List<RecognitionBatchTicketReceiptDto>,
    );
  }
}

extension $RecognitionBatchReceiptDtoCopyWith on RecognitionBatchReceiptDto {
  /// Returns a callable class that can be used as follows: `instanceOfRecognitionBatchReceiptDto.copyWith(...)` or like so:`instanceOfRecognitionBatchReceiptDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecognitionBatchReceiptDtoCWProxy get copyWith =>
      _$RecognitionBatchReceiptDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecognitionBatchReceiptDto _$RecognitionBatchReceiptDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecognitionBatchReceiptDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['batchId', 'jobId', 'status', 'tickets'],
  );
  final val = RecognitionBatchReceiptDto(
    batchId: $checkedConvert('batchId', (v) => v as String),
    jobId: $checkedConvert('jobId', (v) => v as String),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$RecognitionBatchReceiptDtoStatusEnumEnumMap, v),
    ),
    tickets: $checkedConvert(
      'tickets',
      (v) => (v as List<dynamic>)
          .map(
            (e) => RecognitionBatchTicketReceiptDto.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$RecognitionBatchReceiptDtoToJson(
  RecognitionBatchReceiptDto instance,
) => <String, dynamic>{
  'batchId': instance.batchId,
  'jobId': instance.jobId,
  'status': _$RecognitionBatchReceiptDtoStatusEnumEnumMap[instance.status]!,
  'tickets': instance.tickets.map((e) => e.toJson()).toList(),
};

const _$RecognitionBatchReceiptDtoStatusEnumEnumMap = {
  RecognitionBatchReceiptDtoStatusEnum.DANG_XU_LY: 'DANG_XU_LY',
};
