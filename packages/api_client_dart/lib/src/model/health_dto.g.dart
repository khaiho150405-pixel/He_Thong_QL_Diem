// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HealthDtoCWProxy {
  HealthDto status(HealthDtoStatusEnum status);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HealthDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HealthDto(...).copyWith(id: 12, name: "My name")
  /// ````
  HealthDto call({HealthDtoStatusEnum status});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHealthDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHealthDto.copyWith.fieldName(...)`
class _$HealthDtoCWProxyImpl implements _$HealthDtoCWProxy {
  const _$HealthDtoCWProxyImpl(this._value);

  final HealthDto _value;

  @override
  HealthDto status(HealthDtoStatusEnum status) => this(status: status);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HealthDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HealthDto(...).copyWith(id: 12, name: "My name")
  /// ````
  HealthDto call({Object? status = const $CopyWithPlaceholder()}) {
    return HealthDto(
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as HealthDtoStatusEnum,
    );
  }
}

extension $HealthDtoCopyWith on HealthDto {
  /// Returns a callable class that can be used as follows: `instanceOfHealthDto.copyWith(...)` or like so:`instanceOfHealthDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HealthDtoCWProxy get copyWith => _$HealthDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthDto _$HealthDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HealthDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['status']);
      final val = HealthDto(
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$HealthDtoStatusEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$HealthDtoToJson(HealthDto instance) => <String, dynamic>{
  'status': _$HealthDtoStatusEnumEnumMap[instance.status]!,
};

const _$HealthDtoStatusEnumEnumMap = {HealthDtoStatusEnum.ok: 'ok'};
