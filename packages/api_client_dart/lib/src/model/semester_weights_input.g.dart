// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semester_weights_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SemesterWeightsInputCWProxy {
  SemesterWeightsInput loaiHeSo(SemesterWeightsInputLoaiHeSoEnum loaiHeSo);

  SemesterWeightsInput maHocKy(num maHocKy);

  SemesterWeightsInput heSo(String heSo);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SemesterWeightsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SemesterWeightsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  SemesterWeightsInput call({
    SemesterWeightsInputLoaiHeSoEnum loaiHeSo,
    num maHocKy,
    String heSo,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSemesterWeightsInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSemesterWeightsInput.copyWith.fieldName(...)`
class _$SemesterWeightsInputCWProxyImpl
    implements _$SemesterWeightsInputCWProxy {
  const _$SemesterWeightsInputCWProxyImpl(this._value);

  final SemesterWeightsInput _value;

  @override
  SemesterWeightsInput loaiHeSo(SemesterWeightsInputLoaiHeSoEnum loaiHeSo) =>
      this(loaiHeSo: loaiHeSo);

  @override
  SemesterWeightsInput maHocKy(num maHocKy) => this(maHocKy: maHocKy);

  @override
  SemesterWeightsInput heSo(String heSo) => this(heSo: heSo);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SemesterWeightsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SemesterWeightsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  SemesterWeightsInput call({
    Object? loaiHeSo = const $CopyWithPlaceholder(),
    Object? maHocKy = const $CopyWithPlaceholder(),
    Object? heSo = const $CopyWithPlaceholder(),
  }) {
    return SemesterWeightsInput(
      loaiHeSo: loaiHeSo == const $CopyWithPlaceholder()
          ? _value.loaiHeSo
          // ignore: cast_nullable_to_non_nullable
          : loaiHeSo as SemesterWeightsInputLoaiHeSoEnum,
      maHocKy: maHocKy == const $CopyWithPlaceholder()
          ? _value.maHocKy
          // ignore: cast_nullable_to_non_nullable
          : maHocKy as num,
      heSo: heSo == const $CopyWithPlaceholder()
          ? _value.heSo
          // ignore: cast_nullable_to_non_nullable
          : heSo as String,
    );
  }
}

extension $SemesterWeightsInputCopyWith on SemesterWeightsInput {
  /// Returns a callable class that can be used as follows: `instanceOfSemesterWeightsInput.copyWith(...)` or like so:`instanceOfSemesterWeightsInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SemesterWeightsInputCWProxy get copyWith =>
      _$SemesterWeightsInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SemesterWeightsInput _$SemesterWeightsInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SemesterWeightsInput',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['loai_he_so', 'ma_hoc_ky', 'he_so']);
    final val = SemesterWeightsInput(
      loaiHeSo: $checkedConvert(
        'loai_he_so',
        (v) => $enumDecode(_$SemesterWeightsInputLoaiHeSoEnumEnumMap, v),
      ),
      maHocKy: $checkedConvert('ma_hoc_ky', (v) => v as num),
      heSo: $checkedConvert('he_so', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'loaiHeSo': 'loai_he_so',
    'maHocKy': 'ma_hoc_ky',
    'heSo': 'he_so',
  },
);

Map<String, dynamic> _$SemesterWeightsInputToJson(
  SemesterWeightsInput instance,
) => <String, dynamic>{
  'loai_he_so': _$SemesterWeightsInputLoaiHeSoEnumEnumMap[instance.loaiHeSo]!,
  'ma_hoc_ky': instance.maHocKy,
  'he_so': instance.heSo,
};

const _$SemesterWeightsInputLoaiHeSoEnumEnumMap = {
  SemesterWeightsInputLoaiHeSoEnum.TX: 'TX',
  SemesterWeightsInputLoaiHeSoEnum.GK: 'GK',
  SemesterWeightsInputLoaiHeSoEnum.CK: 'CK',
};
