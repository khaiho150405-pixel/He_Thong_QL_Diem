// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'students_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StudentsDtoCWProxy {
  StudentsDto maNguoiDung(num? maNguoiDung);

  StudentsDto maLop(num maLop);

  StudentsDto hoTen(String hoTen);

  StudentsDto ngaySinh(String ngaySinh);

  StudentsDto dangTheoHoc(bool dangTheoHoc);

  StudentsDto label(String label);

  StudentsDto maHocSinh(num maHocSinh);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentsDto call({
    num? maNguoiDung,
    num maLop,
    String hoTen,
    String ngaySinh,
    bool dangTheoHoc,
    String label,
    num maHocSinh,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStudentsDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStudentsDto.copyWith.fieldName(...)`
class _$StudentsDtoCWProxyImpl implements _$StudentsDtoCWProxy {
  const _$StudentsDtoCWProxyImpl(this._value);

  final StudentsDto _value;

  @override
  StudentsDto maNguoiDung(num? maNguoiDung) => this(maNguoiDung: maNguoiDung);

  @override
  StudentsDto maLop(num maLop) => this(maLop: maLop);

  @override
  StudentsDto hoTen(String hoTen) => this(hoTen: hoTen);

  @override
  StudentsDto ngaySinh(String ngaySinh) => this(ngaySinh: ngaySinh);

  @override
  StudentsDto dangTheoHoc(bool dangTheoHoc) => this(dangTheoHoc: dangTheoHoc);

  @override
  StudentsDto label(String label) => this(label: label);

  @override
  StudentsDto maHocSinh(num maHocSinh) => this(maHocSinh: maHocSinh);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentsDto call({
    Object? maNguoiDung = const $CopyWithPlaceholder(),
    Object? maLop = const $CopyWithPlaceholder(),
    Object? hoTen = const $CopyWithPlaceholder(),
    Object? ngaySinh = const $CopyWithPlaceholder(),
    Object? dangTheoHoc = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? maHocSinh = const $CopyWithPlaceholder(),
  }) {
    return StudentsDto(
      maNguoiDung: maNguoiDung == const $CopyWithPlaceholder()
          ? _value.maNguoiDung
          // ignore: cast_nullable_to_non_nullable
          : maNguoiDung as num?,
      maLop: maLop == const $CopyWithPlaceholder()
          ? _value.maLop
          // ignore: cast_nullable_to_non_nullable
          : maLop as num,
      hoTen: hoTen == const $CopyWithPlaceholder()
          ? _value.hoTen
          // ignore: cast_nullable_to_non_nullable
          : hoTen as String,
      ngaySinh: ngaySinh == const $CopyWithPlaceholder()
          ? _value.ngaySinh
          // ignore: cast_nullable_to_non_nullable
          : ngaySinh as String,
      dangTheoHoc: dangTheoHoc == const $CopyWithPlaceholder()
          ? _value.dangTheoHoc
          // ignore: cast_nullable_to_non_nullable
          : dangTheoHoc as bool,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      maHocSinh: maHocSinh == const $CopyWithPlaceholder()
          ? _value.maHocSinh
          // ignore: cast_nullable_to_non_nullable
          : maHocSinh as num,
    );
  }
}

extension $StudentsDtoCopyWith on StudentsDto {
  /// Returns a callable class that can be used as follows: `instanceOfStudentsDto.copyWith(...)` or like so:`instanceOfStudentsDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StudentsDtoCWProxy get copyWith => _$StudentsDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentsDto _$StudentsDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'StudentsDto',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'ma_nguoi_dung',
        'ma_lop',
        'ho_ten',
        'ngay_sinh',
        'dang_theo_hoc',
        'label',
        'ma_hoc_sinh',
      ],
    );
    final val = StudentsDto(
      maNguoiDung: $checkedConvert('ma_nguoi_dung', (v) => v as num?),
      maLop: $checkedConvert('ma_lop', (v) => v as num),
      hoTen: $checkedConvert('ho_ten', (v) => v as String),
      ngaySinh: $checkedConvert('ngay_sinh', (v) => v as String),
      dangTheoHoc: $checkedConvert('dang_theo_hoc', (v) => v as bool),
      label: $checkedConvert('label', (v) => v as String),
      maHocSinh: $checkedConvert('ma_hoc_sinh', (v) => v as num),
    );
    return val;
  },
  fieldKeyMap: const {
    'maNguoiDung': 'ma_nguoi_dung',
    'maLop': 'ma_lop',
    'hoTen': 'ho_ten',
    'ngaySinh': 'ngay_sinh',
    'dangTheoHoc': 'dang_theo_hoc',
    'maHocSinh': 'ma_hoc_sinh',
  },
);

Map<String, dynamic> _$StudentsDtoToJson(StudentsDto instance) =>
    <String, dynamic>{
      'ma_nguoi_dung': instance.maNguoiDung,
      'ma_lop': instance.maLop,
      'ho_ten': instance.hoTen,
      'ngay_sinh': instance.ngaySinh,
      'dang_theo_hoc': instance.dangTheoHoc,
      'label': instance.label,
      'ma_hoc_sinh': instance.maHocSinh,
    };
