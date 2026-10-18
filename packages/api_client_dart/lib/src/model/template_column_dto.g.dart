// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_column_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TemplateColumnDtoCWProxy {
  TemplateColumnDto index(num index);

  TemplateColumnDto role(TemplateColumnDtoRoleEnum role);

  TemplateColumnDto group(TemplateColumnDtoGroupEnum? group);

  TemplateColumnDto order(num? order);

  TemplateColumnDto pairedWith(num? pairedWith);

  TemplateColumnDto headerText(String? headerText);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TemplateColumnDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TemplateColumnDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TemplateColumnDto call({
    num index,
    TemplateColumnDtoRoleEnum role,
    TemplateColumnDtoGroupEnum? group,
    num? order,
    num? pairedWith,
    String? headerText,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTemplateColumnDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTemplateColumnDto.copyWith.fieldName(...)`
class _$TemplateColumnDtoCWProxyImpl implements _$TemplateColumnDtoCWProxy {
  const _$TemplateColumnDtoCWProxyImpl(this._value);

  final TemplateColumnDto _value;

  @override
  TemplateColumnDto index(num index) => this(index: index);

  @override
  TemplateColumnDto role(TemplateColumnDtoRoleEnum role) => this(role: role);

  @override
  TemplateColumnDto group(TemplateColumnDtoGroupEnum? group) =>
      this(group: group);

  @override
  TemplateColumnDto order(num? order) => this(order: order);

  @override
  TemplateColumnDto pairedWith(num? pairedWith) => this(pairedWith: pairedWith);

  @override
  TemplateColumnDto headerText(String? headerText) =>
      this(headerText: headerText);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TemplateColumnDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TemplateColumnDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TemplateColumnDto call({
    Object? index = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? group = const $CopyWithPlaceholder(),
    Object? order = const $CopyWithPlaceholder(),
    Object? pairedWith = const $CopyWithPlaceholder(),
    Object? headerText = const $CopyWithPlaceholder(),
  }) {
    return TemplateColumnDto(
      index: index == const $CopyWithPlaceholder()
          ? _value.index
          // ignore: cast_nullable_to_non_nullable
          : index as num,
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as TemplateColumnDtoRoleEnum,
      group: group == const $CopyWithPlaceholder()
          ? _value.group
          // ignore: cast_nullable_to_non_nullable
          : group as TemplateColumnDtoGroupEnum?,
      order: order == const $CopyWithPlaceholder()
          ? _value.order
          // ignore: cast_nullable_to_non_nullable
          : order as num?,
      pairedWith: pairedWith == const $CopyWithPlaceholder()
          ? _value.pairedWith
          // ignore: cast_nullable_to_non_nullable
          : pairedWith as num?,
      headerText: headerText == const $CopyWithPlaceholder()
          ? _value.headerText
          // ignore: cast_nullable_to_non_nullable
          : headerText as String?,
    );
  }
}

extension $TemplateColumnDtoCopyWith on TemplateColumnDto {
  /// Returns a callable class that can be used as follows: `instanceOfTemplateColumnDto.copyWith(...)` or like so:`instanceOfTemplateColumnDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TemplateColumnDtoCWProxy get copyWith =>
      _$TemplateColumnDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TemplateColumnDto _$TemplateColumnDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TemplateColumnDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'index',
          'role',
          'group',
          'order',
          'pairedWith',
          'headerText',
        ],
      );
      final val = TemplateColumnDto(
        index: $checkedConvert('index', (v) => v as num),
        role: $checkedConvert(
          'role',
          (v) => $enumDecode(_$TemplateColumnDtoRoleEnumEnumMap, v),
        ),
        group: $checkedConvert(
          'group',
          (v) => $enumDecodeNullable(_$TemplateColumnDtoGroupEnumEnumMap, v),
        ),
        order: $checkedConvert('order', (v) => v as num?),
        pairedWith: $checkedConvert('pairedWith', (v) => v as num?),
        headerText: $checkedConvert('headerText', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$TemplateColumnDtoToJson(TemplateColumnDto instance) =>
    <String, dynamic>{
      'index': instance.index,
      'role': _$TemplateColumnDtoRoleEnumEnumMap[instance.role]!,
      'group': _$TemplateColumnDtoGroupEnumEnumMap[instance.group],
      'order': instance.order,
      'pairedWith': instance.pairedWith,
      'headerText': instance.headerText,
    };

const _$TemplateColumnDtoRoleEnumEnumMap = {
  TemplateColumnDtoRoleEnum.STT: 'STT',
  TemplateColumnDtoRoleEnum.HO_TEN: 'HO_TEN',
  TemplateColumnDtoRoleEnum.DIEM: 'DIEM',
  TemplateColumnDtoRoleEnum.DIEM_CHU: 'DIEM_CHU',
  TemplateColumnDtoRoleEnum.BO_QUA: 'BO_QUA',
};

const _$TemplateColumnDtoGroupEnumEnumMap = {
  TemplateColumnDtoGroupEnum.TX: 'TX',
  TemplateColumnDtoGroupEnum.GK: 'GK',
  TemplateColumnDtoGroupEnum.CK: 'CK',
};
