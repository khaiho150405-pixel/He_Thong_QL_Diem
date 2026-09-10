// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'updated_cell_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdatedCellDtoCWProxy {
  UpdatedCellDto id(String id);

  UpdatedCellDto value(String? value);

  UpdatedCellDto status(UpdatedCellDtoStatusEnum status);

  UpdatedCellDto source_(UpdatedCellDtoSource_Enum source_);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UpdatedCellDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UpdatedCellDto(...).copyWith(id: 12, name: "My name")
  /// ````
  UpdatedCellDto call({
    String id,
    String? value,
    UpdatedCellDtoStatusEnum status,
    UpdatedCellDtoSource_Enum source_,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfUpdatedCellDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfUpdatedCellDto.copyWith.fieldName(...)`
class _$UpdatedCellDtoCWProxyImpl implements _$UpdatedCellDtoCWProxy {
  const _$UpdatedCellDtoCWProxyImpl(this._value);

  final UpdatedCellDto _value;

  @override
  UpdatedCellDto id(String id) => this(id: id);

  @override
  UpdatedCellDto value(String? value) => this(value: value);

  @override
  UpdatedCellDto status(UpdatedCellDtoStatusEnum status) =>
      this(status: status);

  @override
  UpdatedCellDto source_(UpdatedCellDtoSource_Enum source_) =>
      this(source_: source_);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UpdatedCellDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UpdatedCellDto(...).copyWith(id: 12, name: "My name")
  /// ````
  UpdatedCellDto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
  }) {
    return UpdatedCellDto(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      value: value == const $CopyWithPlaceholder()
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as UpdatedCellDtoStatusEnum,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as UpdatedCellDtoSource_Enum,
    );
  }
}

extension $UpdatedCellDtoCopyWith on UpdatedCellDto {
  /// Returns a callable class that can be used as follows: `instanceOfUpdatedCellDto.copyWith(...)` or like so:`instanceOfUpdatedCellDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdatedCellDtoCWProxy get copyWith => _$UpdatedCellDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdatedCellDto _$UpdatedCellDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdatedCellDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'value', 'status', 'source']);
      final val = UpdatedCellDto(
        id: $checkedConvert('id', (v) => v as String),
        value: $checkedConvert('value', (v) => v as String?),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$UpdatedCellDtoStatusEnumEnumMap, v),
        ),
        source_: $checkedConvert(
          'source',
          (v) => $enumDecode(_$UpdatedCellDtoSource_EnumEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$UpdatedCellDtoToJson(UpdatedCellDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'value': instance.value,
      'status': _$UpdatedCellDtoStatusEnumEnumMap[instance.status]!,
      'source': _$UpdatedCellDtoSource_EnumEnumMap[instance.source_]!,
    };

const _$UpdatedCellDtoStatusEnumEnumMap = {
  UpdatedCellDtoStatusEnum.CHUA_CO: 'CHUA_CO',
  UpdatedCellDtoStatusEnum.CHO_DOI_CHIEU: 'CHO_DOI_CHIEU',
  UpdatedCellDtoStatusEnum.DA_DUYET: 'DA_DUYET',
};

const _$UpdatedCellDtoSource_EnumEnumMap = {
  UpdatedCellDtoSource_Enum.NHAP_TAY: 'NHAP_TAY',
  UpdatedCellDtoSource_Enum.NHAN_DIEN: 'NHAN_DIEN',
};
