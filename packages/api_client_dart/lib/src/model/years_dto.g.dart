// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'years_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$YearsDtoCWProxy {
  YearsDto ten(String ten);

  YearsDto ngayBatDau(String ngayBatDau);

  YearsDto ngayKetThuc(String ngayKetThuc);

  YearsDto hienHanh(bool hienHanh);

  YearsDto label(String label);

  YearsDto maNamHoc(num maNamHoc);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  YearsDto call({
    String ten,
    String ngayBatDau,
    String ngayKetThuc,
    bool hienHanh,
    String label,
    num maNamHoc,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfYearsDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfYearsDto.copyWith.fieldName(...)`
class _$YearsDtoCWProxyImpl implements _$YearsDtoCWProxy {
  const _$YearsDtoCWProxyImpl(this._value);

  final YearsDto _value;

  @override
  YearsDto ten(String ten) => this(ten: ten);

  @override
  YearsDto ngayBatDau(String ngayBatDau) => this(ngayBatDau: ngayBatDau);

  @override
  YearsDto ngayKetThuc(String ngayKetThuc) => this(ngayKetThuc: ngayKetThuc);

  @override
  YearsDto hienHanh(bool hienHanh) => this(hienHanh: hienHanh);

  @override
  YearsDto label(String label) => this(label: label);

  @override
  YearsDto maNamHoc(num maNamHoc) => this(maNamHoc: maNamHoc);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  YearsDto call({
    Object? ten = const $CopyWithPlaceholder(),
    Object? ngayBatDau = const $CopyWithPlaceholder(),
    Object? ngayKetThuc = const $CopyWithPlaceholder(),
    Object? hienHanh = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? maNamHoc = const $CopyWithPlaceholder(),
  }) {
    return YearsDto(
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
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      maNamHoc: maNamHoc == const $CopyWithPlaceholder()
          ? _value.maNamHoc
          // ignore: cast_nullable_to_non_nullable
          : maNamHoc as num,
    );
  }
}

extension $YearsDtoCopyWith on YearsDto {
  /// Returns a callable class that can be used as follows: `instanceOfYearsDto.copyWith(...)` or like so:`instanceOfYearsDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$YearsDtoCWProxy get copyWith => _$YearsDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YearsDto _$YearsDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'YearsDto',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'ten',
        'ngay_bat_dau',
        'ngay_ket_thuc',
        'hien_hanh',
        'label',
        'ma_nam_hoc',
      ],
    );
    final val = YearsDto(
      ten: $checkedConvert('ten', (v) => v as String),
      ngayBatDau: $checkedConvert('ngay_bat_dau', (v) => v as String),
      ngayKetThuc: $checkedConvert('ngay_ket_thuc', (v) => v as String),
      hienHanh: $checkedConvert('hien_hanh', (v) => v as bool),
      label: $checkedConvert('label', (v) => v as String),
      maNamHoc: $checkedConvert('ma_nam_hoc', (v) => v as num),
    );
    return val;
  },
  fieldKeyMap: const {
    'ngayBatDau': 'ngay_bat_dau',
    'ngayKetThuc': 'ngay_ket_thuc',
    'hienHanh': 'hien_hanh',
    'maNamHoc': 'ma_nam_hoc',
  },
);

Map<String, dynamic> _$YearsDtoToJson(YearsDto instance) => <String, dynamic>{
  'ten': instance.ten,
  'ngay_bat_dau': instance.ngayBatDau,
  'ngay_ket_thuc': instance.ngayKetThuc,
  'hien_hanh': instance.hienHanh,
  'label': instance.label,
  'ma_nam_hoc': instance.maNamHoc,
};
