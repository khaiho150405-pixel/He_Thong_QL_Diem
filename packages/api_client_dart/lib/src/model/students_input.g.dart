// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'students_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StudentsInputCWProxy {
  StudentsInput maNguoiDung(num? maNguoiDung);

  StudentsInput maLop(num maLop);

  StudentsInput hoTen(String hoTen);

  StudentsInput ngaySinh(String ngaySinh);

  StudentsInput dangTheoHoc(bool dangTheoHoc);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentsInput call({
    num? maNguoiDung,
    num maLop,
    String hoTen,
    String ngaySinh,
    bool dangTheoHoc,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStudentsInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStudentsInput.copyWith.fieldName(...)`
class _$StudentsInputCWProxyImpl implements _$StudentsInputCWProxy {
  const _$StudentsInputCWProxyImpl(this._value);

  final StudentsInput _value;

  @override
  StudentsInput maNguoiDung(num? maNguoiDung) => this(maNguoiDung: maNguoiDung);

  @override
  StudentsInput maLop(num maLop) => this(maLop: maLop);

  @override
  StudentsInput hoTen(String hoTen) => this(hoTen: hoTen);

  @override
  StudentsInput ngaySinh(String ngaySinh) => this(ngaySinh: ngaySinh);

  @override
  StudentsInput dangTheoHoc(bool dangTheoHoc) => this(dangTheoHoc: dangTheoHoc);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentsInput call({
    Object? maNguoiDung = const $CopyWithPlaceholder(),
    Object? maLop = const $CopyWithPlaceholder(),
    Object? hoTen = const $CopyWithPlaceholder(),
    Object? ngaySinh = const $CopyWithPlaceholder(),
    Object? dangTheoHoc = const $CopyWithPlaceholder(),
  }) {
    return StudentsInput(
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
    );
  }
}

extension $StudentsInputCopyWith on StudentsInput {
  /// Returns a callable class that can be used as follows: `instanceOfStudentsInput.copyWith(...)` or like so:`instanceOfStudentsInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StudentsInputCWProxy get copyWith => _$StudentsInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentsInput _$StudentsInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'StudentsInput',
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
          ],
        );
        final val = StudentsInput(
          maNguoiDung: $checkedConvert('ma_nguoi_dung', (v) => v as num?),
          maLop: $checkedConvert('ma_lop', (v) => v as num),
          hoTen: $checkedConvert('ho_ten', (v) => v as String),
          ngaySinh: $checkedConvert('ngay_sinh', (v) => v as String),
          dangTheoHoc: $checkedConvert('dang_theo_hoc', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'maNguoiDung': 'ma_nguoi_dung',
        'maLop': 'ma_lop',
        'hoTen': 'ho_ten',
        'ngaySinh': 'ngay_sinh',
        'dangTheoHoc': 'dang_theo_hoc',
      },
    );

Map<String, dynamic> _$StudentsInputToJson(StudentsInput instance) =>
    <String, dynamic>{
      'ma_nguoi_dung': instance.maNguoiDung,
      'ma_lop': instance.maLop,
      'ho_ten': instance.hoTen,
      'ngay_sinh': instance.ngaySinh,
      'dang_theo_hoc': instance.dangTheoHoc,
    };
