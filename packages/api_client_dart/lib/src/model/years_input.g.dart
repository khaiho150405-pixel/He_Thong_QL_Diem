// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'years_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$YearsInputCWProxy {
  YearsInput ten(String ten);

  YearsInput ngayBatDau(String ngayBatDau);

  YearsInput ngayKetThuc(String ngayKetThuc);

  YearsInput hienHanh(bool hienHanh);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  YearsInput call({
    String ten,
    String ngayBatDau,
    String ngayKetThuc,
    bool hienHanh,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfYearsInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfYearsInput.copyWith.fieldName(...)`
class _$YearsInputCWProxyImpl implements _$YearsInputCWProxy {
  const _$YearsInputCWProxyImpl(this._value);

  final YearsInput _value;

  @override
  YearsInput ten(String ten) => this(ten: ten);

  @override
  YearsInput ngayBatDau(String ngayBatDau) => this(ngayBatDau: ngayBatDau);

  @override
  YearsInput ngayKetThuc(String ngayKetThuc) => this(ngayKetThuc: ngayKetThuc);

  @override
  YearsInput hienHanh(bool hienHanh) => this(hienHanh: hienHanh);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  YearsInput call({
    Object? ten = const $CopyWithPlaceholder(),
    Object? ngayBatDau = const $CopyWithPlaceholder(),
    Object? ngayKetThuc = const $CopyWithPlaceholder(),
    Object? hienHanh = const $CopyWithPlaceholder(),
  }) {
    return YearsInput(
      ten: ten == const $CopyWithPlaceholder()
          ? _value.ten
          // ignore: cast_nullable_to_non_nullable
          : ten as String,
      ngayBatDau: ngayBatDau == const $CopyWithPlaceholder()
          ? _value.ngayBatDau
          // ignore: cast_nullable_to_non_nullable
          : ngayBatDau as String,
      ngayKetThuc: ngayKetThuc == const $CopyWithPlaceholder()
          ? _value.ngayKetThuc
          // ignore: cast_nullable_to_non_nullable
          : ngayKetThuc as String,
      hienHanh: hienHanh == const $CopyWithPlaceholder()
          ? _value.hienHanh
          // ignore: cast_nullable_to_non_nullable
          : hienHanh as bool,
    );
  }
}

extension $YearsInputCopyWith on YearsInput {
  /// Returns a callable class that can be used as follows: `instanceOfYearsInput.copyWith(...)` or like so:`instanceOfYearsInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$YearsInputCWProxy get copyWith => _$YearsInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YearsInput _$YearsInputFromJson(Map<String, dynamic> json) => $checkedCreate(
  'YearsInput',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['ten', 'ngay_bat_dau', 'ngay_ket_thuc', 'hien_hanh'],
    );
    final val = YearsInput(
      ten: $checkedConvert('ten', (v) => v as String),
      ngayBatDau: $checkedConvert('ngay_bat_dau', (v) => v as String),
      ngayKetThuc: $checkedConvert('ngay_ket_thuc', (v) => v as String),
      hienHanh: $checkedConvert('hien_hanh', (v) => v as bool),
    );
    return val;
  },
  fieldKeyMap: const {
    'ngayBatDau': 'ngay_bat_dau',
    'ngayKetThuc': 'ngay_ket_thuc',
    'hienHanh': 'hien_hanh',
  },
);

Map<String, dynamic> _$YearsInputToJson(YearsInput instance) =>
    <String, dynamic>{
      'ten': instance.ten,
      'ngay_bat_dau': instance.ngayBatDau,
      'ngay_ket_thuc': instance.ngayKetThuc,
      'hien_hanh': instance.hienHanh,
    };
