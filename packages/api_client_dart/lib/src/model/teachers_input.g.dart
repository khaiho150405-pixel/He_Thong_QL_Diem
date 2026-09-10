// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teachers_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TeachersInputCWProxy {
  TeachersInput maGiaoVien(num maGiaoVien);

  TeachersInput hoTen(String hoTen);

  TeachersInput toChuyenMon(String? toChuyenMon);

  TeachersInput email(String? email);

  TeachersInput dienThoai(String? dienThoai);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TeachersInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TeachersInput(...).copyWith(id: 12, name: "My name")
  /// ````
  TeachersInput call({
    num maGiaoVien,
    String hoTen,
    String? toChuyenMon,
    String? email,
    String? dienThoai,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTeachersInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTeachersInput.copyWith.fieldName(...)`
class _$TeachersInputCWProxyImpl implements _$TeachersInputCWProxy {
  const _$TeachersInputCWProxyImpl(this._value);

  final TeachersInput _value;

  @override
  TeachersInput maGiaoVien(num maGiaoVien) => this(maGiaoVien: maGiaoVien);

  @override
  TeachersInput hoTen(String hoTen) => this(hoTen: hoTen);

  @override
  TeachersInput toChuyenMon(String? toChuyenMon) =>
      this(toChuyenMon: toChuyenMon);

  @override
  TeachersInput email(String? email) => this(email: email);

  @override
  TeachersInput dienThoai(String? dienThoai) => this(dienThoai: dienThoai);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TeachersInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TeachersInput(...).copyWith(id: 12, name: "My name")
  /// ````
  TeachersInput call({
    Object? maGiaoVien = const $CopyWithPlaceholder(),
    Object? hoTen = const $CopyWithPlaceholder(),
    Object? toChuyenMon = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? dienThoai = const $CopyWithPlaceholder(),
  }) {
    return TeachersInput(
      maGiaoVien: maGiaoVien == const $CopyWithPlaceholder()
          ? _value.maGiaoVien
          // ignore: cast_nullable_to_non_nullable
          : maGiaoVien as num,
      hoTen: hoTen == const $CopyWithPlaceholder()
          ? _value.hoTen
          // ignore: cast_nullable_to_non_nullable
          : hoTen as String,
      toChuyenMon: toChuyenMon == const $CopyWithPlaceholder()
          ? _value.toChuyenMon
          // ignore: cast_nullable_to_non_nullable
          : toChuyenMon as String?,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String?,
      dienThoai: dienThoai == const $CopyWithPlaceholder()
          ? _value.dienThoai
          // ignore: cast_nullable_to_non_nullable
          : dienThoai as String?,
    );
  }
}

extension $TeachersInputCopyWith on TeachersInput {
  /// Returns a callable class that can be used as follows: `instanceOfTeachersInput.copyWith(...)` or like so:`instanceOfTeachersInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TeachersInputCWProxy get copyWith => _$TeachersInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeachersInput _$TeachersInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'TeachersInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'ma_giao_vien',
            'ho_ten',
            'to_chuyen_mon',
            'email',
            'dien_thoai',
          ],
        );
        final val = TeachersInput(
          maGiaoVien: $checkedConvert('ma_giao_vien', (v) => v as num),
          hoTen: $checkedConvert('ho_ten', (v) => v as String),
          toChuyenMon: $checkedConvert('to_chuyen_mon', (v) => v as String?),
          email: $checkedConvert('email', (v) => v as String?),
          dienThoai: $checkedConvert('dien_thoai', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'maGiaoVien': 'ma_giao_vien',
        'hoTen': 'ho_ten',
        'toChuyenMon': 'to_chuyen_mon',
        'dienThoai': 'dien_thoai',
      },
    );

Map<String, dynamic> _$TeachersInputToJson(TeachersInput instance) =>
    <String, dynamic>{
      'ma_giao_vien': instance.maGiaoVien,
      'ho_ten': instance.hoTen,
      'to_chuyen_mon': instance.toChuyenMon,
      'email': instance.email,
      'dien_thoai': instance.dienThoai,
    };
