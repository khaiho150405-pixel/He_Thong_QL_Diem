// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_target_year_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PromotionTargetYearDtoCWProxy {
  PromotionTargetYearDto id(num id);

  PromotionTargetYearDto name(String name);

  PromotionTargetYearDto startDate(String startDate);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PromotionTargetYearDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PromotionTargetYearDto(...).copyWith(id: 12, name: "My name")
  /// ````
  PromotionTargetYearDto call({num id, String name, String startDate});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPromotionTargetYearDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPromotionTargetYearDto.copyWith.fieldName(...)`
class _$PromotionTargetYearDtoCWProxyImpl
    implements _$PromotionTargetYearDtoCWProxy {
  const _$PromotionTargetYearDtoCWProxyImpl(this._value);

  final PromotionTargetYearDto _value;

  @override
  PromotionTargetYearDto id(num id) => this(id: id);

  @override
  PromotionTargetYearDto name(String name) => this(name: name);

  @override
  PromotionTargetYearDto startDate(String startDate) =>
      this(startDate: startDate);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PromotionTargetYearDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PromotionTargetYearDto(...).copyWith(id: 12, name: "My name")
  /// ````
  PromotionTargetYearDto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? startDate = const $CopyWithPlaceholder(),
  }) {
    return PromotionTargetYearDto(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as num,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      startDate: startDate == const $CopyWithPlaceholder()
          ? _value.startDate
          // ignore: cast_nullable_to_non_nullable
          : startDate as String,
    );
  }
}

extension $PromotionTargetYearDtoCopyWith on PromotionTargetYearDto {
  /// Returns a callable class that can be used as follows: `instanceOfPromotionTargetYearDto.copyWith(...)` or like so:`instanceOfPromotionTargetYearDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PromotionTargetYearDtoCWProxy get copyWith =>
      _$PromotionTargetYearDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromotionTargetYearDto _$PromotionTargetYearDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PromotionTargetYearDto', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['id', 'name', 'startDate']);
  final val = PromotionTargetYearDto(
    id: $checkedConvert('id', (v) => v as num),
    name: $checkedConvert('name', (v) => v as String),
    startDate: $checkedConvert('startDate', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$PromotionTargetYearDtoToJson(
  PromotionTargetYearDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'startDate': instance.startDate,
};
