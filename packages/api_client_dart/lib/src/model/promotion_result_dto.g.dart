// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_result_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PromotionResultDtoCWProxy {
  PromotionResultDto processed(num processed);

  PromotionResultDto promoted(num promoted);

  PromotionResultDto retained(num retained);

  PromotionResultDto graduated(num graduated);

  PromotionResultDto withdrawn(num withdrawn);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PromotionResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PromotionResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  PromotionResultDto call({
    num processed,
    num promoted,
    num retained,
    num graduated,
    num withdrawn,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPromotionResultDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPromotionResultDto.copyWith.fieldName(...)`
class _$PromotionResultDtoCWProxyImpl implements _$PromotionResultDtoCWProxy {
  const _$PromotionResultDtoCWProxyImpl(this._value);

  final PromotionResultDto _value;

  @override
  PromotionResultDto processed(num processed) => this(processed: processed);

  @override
  PromotionResultDto promoted(num promoted) => this(promoted: promoted);

  @override
  PromotionResultDto retained(num retained) => this(retained: retained);

  @override
  PromotionResultDto graduated(num graduated) => this(graduated: graduated);

  @override
  PromotionResultDto withdrawn(num withdrawn) => this(withdrawn: withdrawn);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PromotionResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PromotionResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  PromotionResultDto call({
    Object? processed = const $CopyWithPlaceholder(),
    Object? promoted = const $CopyWithPlaceholder(),
    Object? retained = const $CopyWithPlaceholder(),
    Object? graduated = const $CopyWithPlaceholder(),
    Object? withdrawn = const $CopyWithPlaceholder(),
  }) {
    return PromotionResultDto(
      processed: processed == const $CopyWithPlaceholder()
          ? _value.processed
          // ignore: cast_nullable_to_non_nullable
          : processed as num,
      promoted: promoted == const $CopyWithPlaceholder()
          ? _value.promoted
          // ignore: cast_nullable_to_non_nullable
          : promoted as num,
      retained: retained == const $CopyWithPlaceholder()
          ? _value.retained
          // ignore: cast_nullable_to_non_nullable
          : retained as num,
      graduated: graduated == const $CopyWithPlaceholder()
          ? _value.graduated
          // ignore: cast_nullable_to_non_nullable
          : graduated as num,
      withdrawn: withdrawn == const $CopyWithPlaceholder()
          ? _value.withdrawn
          // ignore: cast_nullable_to_non_nullable
          : withdrawn as num,
    );
  }
}

extension $PromotionResultDtoCopyWith on PromotionResultDto {
  /// Returns a callable class that can be used as follows: `instanceOfPromotionResultDto.copyWith(...)` or like so:`instanceOfPromotionResultDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PromotionResultDtoCWProxy get copyWith =>
      _$PromotionResultDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromotionResultDto _$PromotionResultDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PromotionResultDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'processed',
          'promoted',
          'retained',
          'graduated',
          'withdrawn',
        ],
      );
      final val = PromotionResultDto(
        processed: $checkedConvert('processed', (v) => v as num),
        promoted: $checkedConvert('promoted', (v) => v as num),
        retained: $checkedConvert('retained', (v) => v as num),
        graduated: $checkedConvert('graduated', (v) => v as num),
        withdrawn: $checkedConvert('withdrawn', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$PromotionResultDtoToJson(PromotionResultDto instance) =>
    <String, dynamic>{
      'processed': instance.processed,
      'promoted': instance.promoted,
      'retained': instance.retained,
      'graduated': instance.graduated,
      'withdrawn': instance.withdrawn,
    };
