// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recognition_batch_ticket_receipt_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecognitionBatchTicketReceiptDtoCWProxy {
  RecognitionBatchTicketReceiptDto ticketId(String ticketId);

  RecognitionBatchTicketReceiptDto componentId(num componentId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecognitionBatchTicketReceiptDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecognitionBatchTicketReceiptDto(...).copyWith(id: 12, name: "My name")
  /// ````
  RecognitionBatchTicketReceiptDto call({String ticketId, num componentId});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecognitionBatchTicketReceiptDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecognitionBatchTicketReceiptDto.copyWith.fieldName(...)`
class _$RecognitionBatchTicketReceiptDtoCWProxyImpl
    implements _$RecognitionBatchTicketReceiptDtoCWProxy {
  const _$RecognitionBatchTicketReceiptDtoCWProxyImpl(this._value);

  final RecognitionBatchTicketReceiptDto _value;

  @override
  RecognitionBatchTicketReceiptDto ticketId(String ticketId) =>
      this(ticketId: ticketId);

  @override
  RecognitionBatchTicketReceiptDto componentId(num componentId) =>
      this(componentId: componentId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecognitionBatchTicketReceiptDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecognitionBatchTicketReceiptDto(...).copyWith(id: 12, name: "My name")
  /// ````
  RecognitionBatchTicketReceiptDto call({
    Object? ticketId = const $CopyWithPlaceholder(),
    Object? componentId = const $CopyWithPlaceholder(),
  }) {
    return RecognitionBatchTicketReceiptDto(
      ticketId: ticketId == const $CopyWithPlaceholder()
          ? _value.ticketId
          // ignore: cast_nullable_to_non_nullable
          : ticketId as String,
      componentId: componentId == const $CopyWithPlaceholder()
          ? _value.componentId
          // ignore: cast_nullable_to_non_nullable
          : componentId as num,
    );
  }
}

extension $RecognitionBatchTicketReceiptDtoCopyWith
    on RecognitionBatchTicketReceiptDto {
  /// Returns a callable class that can be used as follows: `instanceOfRecognitionBatchTicketReceiptDto.copyWith(...)` or like so:`instanceOfRecognitionBatchTicketReceiptDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecognitionBatchTicketReceiptDtoCWProxy get copyWith =>
      _$RecognitionBatchTicketReceiptDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecognitionBatchTicketReceiptDto _$RecognitionBatchTicketReceiptDtoFromJson(
  Map<String, dynamic> json,
) =>
    $checkedCreate('RecognitionBatchTicketReceiptDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['ticketId', 'componentId']);
      final val = RecognitionBatchTicketReceiptDto(
        ticketId: $checkedConvert('ticketId', (v) => v as String),
        componentId: $checkedConvert('componentId', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$RecognitionBatchTicketReceiptDtoToJson(
  RecognitionBatchTicketReceiptDto instance,
) => <String, dynamic>{
  'ticketId': instance.ticketId,
  'componentId': instance.componentId,
};
