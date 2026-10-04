// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semester_weights_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SemesterWeightsDtoCWProxy {
  SemesterWeightsDto loaiHeSo(SemesterWeightsDtoLoaiHeSoEnum loaiHeSo);

  SemesterWeightsDto maHocKy(num maHocKy);

  SemesterWeightsDto heSo(String heSo);

  SemesterWeightsDto label(String label);

  SemesterWeightsDto maHeSo(num maHeSo);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SemesterWeightsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SemesterWeightsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  SemesterWeightsDto call({
    SemesterWeightsDtoLoaiHeSoEnum loaiHeSo,
    num maHocKy,
    String heSo,
    String label,
    num maHeSo,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSemesterWeightsDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSemesterWeightsDto.copyWith.fieldName(...)`
class _$SemesterWeightsDtoCWProxyImpl implements _$SemesterWeightsDtoCWProxy {
  const _$SemesterWeightsDtoCWProxyImpl(this._value);

  final SemesterWeightsDto _value;

  @override
  SemesterWeightsDto loaiHeSo(SemesterWeightsDtoLoaiHeSoEnum loaiHeSo) =>
      this(loaiHeSo: loaiHeSo);

  @override
  SemesterWeightsDto maHocKy(num maHocKy) => this(maHocKy: maHocKy);

  @override
  SemesterWeightsDto heSo(String heSo) => this(heSo: heSo);

  @override
  SemesterWeightsDto label(String label) => this(label: label);

  @override
  SemesterWeightsDto maHeSo(num maHeSo) => this(maHeSo: maHeSo);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SemesterWeightsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SemesterWeightsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  SemesterWeightsDto call({
    Object? loaiHeSo = const $CopyWithPlaceholder(),
    Object? maHocKy = const $CopyWithPlaceholder(),
    Object? heSo = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? maHeSo = const $CopyWithPlaceholder(),
  }) {
    return SemesterWeightsDto(
      loaiHeSo: loaiHeSo == const $CopyWithPlaceholder()
          ? _value.loaiHeSo
          // ignore: cast_nullable_to_non_nullable
          : loaiHeSo as SemesterWeightsDtoLoaiHeSoEnum,
      maHocKy: maHocKy == const $CopyWithPlaceholder()
          ? _value.maHocKy
          // ignore: cast_nullable_to_non_nullable
          : maHocKy as num,
      heSo: heSo == const $CopyWithPlaceholder()
          ? _value.heSo
          // ignore: cast_nullable_to_non_nullable
          : heSo as String,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      maHeSo: maHeSo == const $CopyWithPlaceholder()
          ? _value.maHeSo
          // ignore: cast_nullable_to_non_nullable
          : maHeSo as num,
    );
  }
}

extension $SemesterWeightsDtoCopyWith on SemesterWeightsDto {
  /// Returns a callable class that can be used as follows: `instanceOfSemesterWeightsDto.copyWith(...)` or like so:`instanceOfSemesterWeightsDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SemesterWeightsDtoCWProxy get copyWith =>
      _$SemesterWeightsDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SemesterWeightsDto _$SemesterWeightsDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SemesterWeightsDto',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'loai_he_so',
            'ma_hoc_ky',
            'he_so',
            'label',
            'ma_he_so',
          ],
        );
        final val = SemesterWeightsDto(
          loaiHeSo: $checkedConvert(
            'loai_he_so',
            (v) => $enumDecode(_$SemesterWeightsDtoLoaiHeSoEnumEnumMap, v),
          ),
          maHocKy: $checkedConvert('ma_hoc_ky', (v) => v as num),
          heSo: $checkedConvert('he_so', (v) => v as String),
          label: $checkedConvert('label', (v) => v as String),
          maHeSo: $checkedConvert('ma_he_so', (v) => v as num),
        );
        return val;
      },
      fieldKeyMap: const {
        'loaiHeSo': 'loai_he_so',
        'maHocKy': 'ma_hoc_ky',
        'heSo': 'he_so',
        'maHeSo': 'ma_he_so',
      },
    );

Map<String, dynamic> _$SemesterWeightsDtoToJson(SemesterWeightsDto instance) =>
    <String, dynamic>{
      'loai_he_so': _$SemesterWeightsDtoLoaiHeSoEnumEnumMap[instance.loaiHeSo]!,
      'ma_hoc_ky': instance.maHocKy,
      'he_so': instance.heSo,
      'label': instance.label,
      'ma_he_so': instance.maHeSo,
    };

const _$SemesterWeightsDtoLoaiHeSoEnumEnumMap = {
  SemesterWeightsDtoLoaiHeSoEnum.TX: 'TX',
  SemesterWeightsDtoLoaiHeSoEnum.GK: 'GK',
  SemesterWeightsDtoLoaiHeSoEnum.CK: 'CK',
};
