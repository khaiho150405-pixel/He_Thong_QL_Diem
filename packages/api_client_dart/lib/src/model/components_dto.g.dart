// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'components_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComponentsDtoCWProxy {
  ComponentsDto maMon(num maMon);

  ComponentsDto tenThanhPhan(String tenThanhPhan);

  ComponentsDto heSo(String heSo);

  ComponentsDto batBuoc(bool batBuoc);

  ComponentsDto thuTuHienThi(num thuTuHienThi);

  ComponentsDto label(String label);

  ComponentsDto maThanhPhan(num maThanhPhan);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComponentsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComponentsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  ComponentsDto call({
    num maMon,
    String tenThanhPhan,
    String heSo,
    bool batBuoc,
    num thuTuHienThi,
    String label,
    num maThanhPhan,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfComponentsDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfComponentsDto.copyWith.fieldName(...)`
class _$ComponentsDtoCWProxyImpl implements _$ComponentsDtoCWProxy {
  const _$ComponentsDtoCWProxyImpl(this._value);

  final ComponentsDto _value;

  @override
  ComponentsDto maMon(num maMon) => this(maMon: maMon);

  @override
  ComponentsDto tenThanhPhan(String tenThanhPhan) =>
      this(tenThanhPhan: tenThanhPhan);

  @override
  ComponentsDto heSo(String heSo) => this(heSo: heSo);

  @override
  ComponentsDto batBuoc(bool batBuoc) => this(batBuoc: batBuoc);

  @override
  ComponentsDto thuTuHienThi(num thuTuHienThi) =>
      this(thuTuHienThi: thuTuHienThi);

  @override
  ComponentsDto label(String label) => this(label: label);

  @override
  ComponentsDto maThanhPhan(num maThanhPhan) => this(maThanhPhan: maThanhPhan);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComponentsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComponentsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  ComponentsDto call({
    Object? maMon = const $CopyWithPlaceholder(),
    Object? tenThanhPhan = const $CopyWithPlaceholder(),
    Object? heSo = const $CopyWithPlaceholder(),
    Object? batBuoc = const $CopyWithPlaceholder(),
    Object? thuTuHienThi = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? maThanhPhan = const $CopyWithPlaceholder(),
  }) {
    return ComponentsDto(
      maMon: maMon == const $CopyWithPlaceholder()
          ? _value.maMon
          // ignore: cast_nullable_to_non_nullable
          : maMon as num,
      tenThanhPhan: tenThanhPhan == const $CopyWithPlaceholder()
          ? _value.tenThanhPhan
          // ignore: cast_nullable_to_non_nullable
          : tenThanhPhan as String,
      heSo: heSo == const $CopyWithPlaceholder()
          ? _value.heSo
          // ignore: cast_nullable_to_non_nullable
          : heSo as String,
      batBuoc: batBuoc == const $CopyWithPlaceholder()
          ? _value.batBuoc
          // ignore: cast_nullable_to_non_nullable
          : batBuoc as bool,
      thuTuHienThi: thuTuHienThi == const $CopyWithPlaceholder()
          ? _value.thuTuHienThi
          // ignore: cast_nullable_to_non_nullable
          : thuTuHienThi as num,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      maThanhPhan: maThanhPhan == const $CopyWithPlaceholder()
          ? _value.maThanhPhan
          // ignore: cast_nullable_to_non_nullable
          : maThanhPhan as num,
    );
  }
}

extension $ComponentsDtoCopyWith on ComponentsDto {
  /// Returns a callable class that can be used as follows: `instanceOfComponentsDto.copyWith(...)` or like so:`instanceOfComponentsDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComponentsDtoCWProxy get copyWith => _$ComponentsDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComponentsDto _$ComponentsDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ComponentsDto',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'ma_mon',
            'ten_thanh_phan',
            'he_so',
            'bat_buoc',
            'thu_tu_hien_thi',
            'label',
            'ma_thanh_phan',
          ],
        );
        final val = ComponentsDto(
          maMon: $checkedConvert('ma_mon', (v) => v as num),
          tenThanhPhan: $checkedConvert('ten_thanh_phan', (v) => v as String),
          heSo: $checkedConvert('he_so', (v) => v as String),
          batBuoc: $checkedConvert('bat_buoc', (v) => v as bool),
          thuTuHienThi: $checkedConvert('thu_tu_hien_thi', (v) => v as num),
          label: $checkedConvert('label', (v) => v as String),
          maThanhPhan: $checkedConvert('ma_thanh_phan', (v) => v as num),
        );
        return val;
      },
      fieldKeyMap: const {
        'maMon': 'ma_mon',
        'tenThanhPhan': 'ten_thanh_phan',
        'heSo': 'he_so',
        'batBuoc': 'bat_buoc',
        'thuTuHienThi': 'thu_tu_hien_thi',
        'maThanhPhan': 'ma_thanh_phan',
      },
    );

Map<String, dynamic> _$ComponentsDtoToJson(ComponentsDto instance) =>
    <String, dynamic>{
      'ma_mon': instance.maMon,
      'ten_thanh_phan': instance.tenThanhPhan,
      'he_so': instance.heSo,
      'bat_buoc': instance.batBuoc,
      'thu_tu_hien_thi': instance.thuTuHienThi,
      'label': instance.label,
      'ma_thanh_phan': instance.maThanhPhan,
    };
