// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analyzed_column_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AnalyzedColumnDtoCWProxy {
  AnalyzedColumnDto index(num index);

  AnalyzedColumnDto x0(num x0);

  AnalyzedColumnDto x1(num x1);

  AnalyzedColumnDto widthMm(num widthMm);

  AnalyzedColumnDto headerText(String headerText);

  AnalyzedColumnDto suggestedRole(
    AnalyzedColumnDtoSuggestedRoleEnum? suggestedRole,
  );

  AnalyzedColumnDto suggestedGroup(
    AnalyzedColumnDtoSuggestedGroupEnum? suggestedGroup,
  );

  AnalyzedColumnDto suggestedOrder(num? suggestedOrder);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AnalyzedColumnDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AnalyzedColumnDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AnalyzedColumnDto call({
    num index,
    num x0,
    num x1,
    num widthMm,
    String headerText,
    AnalyzedColumnDtoSuggestedRoleEnum? suggestedRole,
    AnalyzedColumnDtoSuggestedGroupEnum? suggestedGroup,
    num? suggestedOrder,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAnalyzedColumnDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAnalyzedColumnDto.copyWith.fieldName(...)`
class _$AnalyzedColumnDtoCWProxyImpl implements _$AnalyzedColumnDtoCWProxy {
  const _$AnalyzedColumnDtoCWProxyImpl(this._value);

  final AnalyzedColumnDto _value;

  @override
  AnalyzedColumnDto index(num index) => this(index: index);

  @override
  AnalyzedColumnDto x0(num x0) => this(x0: x0);

  @override
  AnalyzedColumnDto x1(num x1) => this(x1: x1);

  @override
  AnalyzedColumnDto widthMm(num widthMm) => this(widthMm: widthMm);

  @override
  AnalyzedColumnDto headerText(String headerText) =>
      this(headerText: headerText);

  @override
  AnalyzedColumnDto suggestedRole(
    AnalyzedColumnDtoSuggestedRoleEnum? suggestedRole,
  ) => this(suggestedRole: suggestedRole);

  @override
  AnalyzedColumnDto suggestedGroup(
    AnalyzedColumnDtoSuggestedGroupEnum? suggestedGroup,
  ) => this(suggestedGroup: suggestedGroup);

  @override
  AnalyzedColumnDto suggestedOrder(num? suggestedOrder) =>
      this(suggestedOrder: suggestedOrder);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AnalyzedColumnDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AnalyzedColumnDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AnalyzedColumnDto call({
    Object? index = const $CopyWithPlaceholder(),
    Object? x0 = const $CopyWithPlaceholder(),
    Object? x1 = const $CopyWithPlaceholder(),
    Object? widthMm = const $CopyWithPlaceholder(),
    Object? headerText = const $CopyWithPlaceholder(),
    Object? suggestedRole = const $CopyWithPlaceholder(),
    Object? suggestedGroup = const $CopyWithPlaceholder(),
    Object? suggestedOrder = const $CopyWithPlaceholder(),
  }) {
    return AnalyzedColumnDto(
      index: index == const $CopyWithPlaceholder()
          ? _value.index
          // ignore: cast_nullable_to_non_nullable
          : index as num,
      x0: x0 == const $CopyWithPlaceholder()
          ? _value.x0
          // ignore: cast_nullable_to_non_nullable
          : x0 as num,
      x1: x1 == const $CopyWithPlaceholder()
          ? _value.x1
          // ignore: cast_nullable_to_non_nullable
          : x1 as num,
      widthMm: widthMm == const $CopyWithPlaceholder()
          ? _value.widthMm
          // ignore: cast_nullable_to_non_nullable
          : widthMm as num,
      headerText: headerText == const $CopyWithPlaceholder()
          ? _value.headerText
          // ignore: cast_nullable_to_non_nullable
          : headerText as String,
      suggestedRole: suggestedRole == const $CopyWithPlaceholder()
          ? _value.suggestedRole
          // ignore: cast_nullable_to_non_nullable
          : suggestedRole as AnalyzedColumnDtoSuggestedRoleEnum?,
      suggestedGroup: suggestedGroup == const $CopyWithPlaceholder()
          ? _value.suggestedGroup
          // ignore: cast_nullable_to_non_nullable
          : suggestedGroup as AnalyzedColumnDtoSuggestedGroupEnum?,
      suggestedOrder: suggestedOrder == const $CopyWithPlaceholder()
          ? _value.suggestedOrder
          // ignore: cast_nullable_to_non_nullable
          : suggestedOrder as num?,
    );
  }
}

extension $AnalyzedColumnDtoCopyWith on AnalyzedColumnDto {
  /// Returns a callable class that can be used as follows: `instanceOfAnalyzedColumnDto.copyWith(...)` or like so:`instanceOfAnalyzedColumnDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AnalyzedColumnDtoCWProxy get copyWith =>
      _$AnalyzedColumnDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalyzedColumnDto _$AnalyzedColumnDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AnalyzedColumnDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'index',
      'x0',
      'x1',
      'widthMm',
      'headerText',
      'suggestedRole',
      'suggestedGroup',
      'suggestedOrder',
    ],
  );
  final val = AnalyzedColumnDto(
    index: $checkedConvert('index', (v) => v as num),
    x0: $checkedConvert('x0', (v) => v as num),
    x1: $checkedConvert('x1', (v) => v as num),
    widthMm: $checkedConvert('widthMm', (v) => v as num),
    headerText: $checkedConvert('headerText', (v) => v as String),
    suggestedRole: $checkedConvert(
      'suggestedRole',
      (v) =>
          $enumDecodeNullable(_$AnalyzedColumnDtoSuggestedRoleEnumEnumMap, v),
    ),
    suggestedGroup: $checkedConvert(
      'suggestedGroup',
      (v) =>
          $enumDecodeNullable(_$AnalyzedColumnDtoSuggestedGroupEnumEnumMap, v),
    ),
    suggestedOrder: $checkedConvert('suggestedOrder', (v) => v as num?),
  );
  return val;
});

Map<String, dynamic> _$AnalyzedColumnDtoToJson(AnalyzedColumnDto instance) =>
    <String, dynamic>{
      'index': instance.index,
      'x0': instance.x0,
      'x1': instance.x1,
      'widthMm': instance.widthMm,
      'headerText': instance.headerText,
      'suggestedRole':
          _$AnalyzedColumnDtoSuggestedRoleEnumEnumMap[instance.suggestedRole],
      'suggestedGroup':
          _$AnalyzedColumnDtoSuggestedGroupEnumEnumMap[instance.suggestedGroup],
      'suggestedOrder': instance.suggestedOrder,
    };

const _$AnalyzedColumnDtoSuggestedRoleEnumEnumMap = {
  AnalyzedColumnDtoSuggestedRoleEnum.STT: 'STT',
  AnalyzedColumnDtoSuggestedRoleEnum.HO_TEN: 'HO_TEN',
  AnalyzedColumnDtoSuggestedRoleEnum.DIEM: 'DIEM',
  AnalyzedColumnDtoSuggestedRoleEnum.DIEM_CHU: 'DIEM_CHU',
  AnalyzedColumnDtoSuggestedRoleEnum.BO_QUA: 'BO_QUA',
};

const _$AnalyzedColumnDtoSuggestedGroupEnumEnumMap = {
  AnalyzedColumnDtoSuggestedGroupEnum.TX: 'TX',
  AnalyzedColumnDtoSuggestedGroupEnum.GK: 'GK',
  AnalyzedColumnDtoSuggestedGroupEnum.CK: 'CK',
};
