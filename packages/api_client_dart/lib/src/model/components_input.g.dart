// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'components_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComponentsInputCWProxy {
  ComponentsInput maMon(num maMon);

  ComponentsInput tenThanhPhan(String tenThanhPhan);

  ComponentsInput heSo(String heSo);

  ComponentsInput batBuoc(bool batBuoc);

  ComponentsInput thuTuHienThi(num thuTuHienThi);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComponentsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComponentsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ComponentsInput call({
    num maMon,
    String tenThanhPhan,
    String heSo,
    bool batBuoc,
    num thuTuHienThi,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfComponentsInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfComponentsInput.copyWith.fieldName(...)`
class _$ComponentsInputCWProxyImpl implements _$ComponentsInputCWProxy {
  const _$ComponentsInputCWProxyImpl(this._value);

  final ComponentsInput _value;

  @override
  ComponentsInput maMon(num maMon) => this(maMon: maMon);

  @override
  ComponentsInput tenThanhPhan(String tenThanhPhan) =>
      this(tenThanhPhan: tenThanhPhan);

  @override
  ComponentsInput heSo(String heSo) => this(heSo: heSo);

  @override
  ComponentsInput batBuoc(bool batBuoc) => this(batBuoc: batBuoc);

  @override
  ComponentsInput thuTuHienThi(num thuTuHienThi) =>
      this(thuTuHienThi: thuTuHienThi);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComponentsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComponentsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ComponentsInput call({
    Object? maMon = const $CopyWithPlaceholder(),
    Object? tenThanhPhan = const $CopyWithPlaceholder(),
    Object? heSo = const $CopyWithPlaceholder(),
    Object? batBuoc = const $CopyWithPlaceholder(),
    Object? thuTuHienThi = const $CopyWithPlaceholder(),
  }) {
    return ComponentsInput(
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
    );
  }
}

extension $ComponentsInputCopyWith on ComponentsInput {
  /// Returns a callable class that can be used as follows: `instanceOfComponentsInput.copyWith(...)` or like so:`instanceOfComponentsInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComponentsInputCWProxy get copyWith => _$ComponentsInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComponentsInput _$ComponentsInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ComponentsInput',
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
          ],
        );
        final val = ComponentsInput(
          maMon: $checkedConvert('ma_mon', (v) => v as num),
          tenThanhPhan: $checkedConvert('ten_thanh_phan', (v) => v as String),
          heSo: $checkedConvert('he_so', (v) => v as String),
          batBuoc: $checkedConvert('bat_buoc', (v) => v as bool),
          thuTuHienThi: $checkedConvert('thu_tu_hien_thi', (v) => v as num),
        );
        return val;
      },
      fieldKeyMap: const {
        'maMon': 'ma_mon',
        'tenThanhPhan': 'ten_thanh_phan',
        'heSo': 'he_so',
        'batBuoc': 'bat_buoc',
        'thuTuHienThi': 'thu_tu_hien_thi',
      },
    );

Map<String, dynamic> _$ComponentsInputToJson(ComponentsInput instance) =>
    <String, dynamic>{
      'ma_mon': instance.maMon,
      'ten_thanh_phan': instance.tenThanhPhan,
      'he_so': instance.heSo,
      'bat_buoc': instance.batBuoc,
      'thu_tu_hien_thi': instance.thuTuHienThi,
    };
