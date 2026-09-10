// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teachers_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TeachersDtoCWProxy {
  TeachersDto maGiaoVien(num maGiaoVien);

  TeachersDto hoTen(String hoTen);

  TeachersDto toChuyenMon(String? toChuyenMon);

  TeachersDto email(String? email);

  TeachersDto dienThoai(String? dienThoai);

  TeachersDto label(String label);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TeachersDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TeachersDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TeachersDto call({
    num maGiaoVien,
    String hoTen,
    String? toChuyenMon,
    String? email,
    String? dienThoai,
    String label,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTeachersDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTeachersDto.copyWith.fieldName(...)`
class _$TeachersDtoCWProxyImpl implements _$TeachersDtoCWProxy {
  const _$TeachersDtoCWProxyImpl(this._value);

  final TeachersDto _value;

  @override
  TeachersDto maGiaoVien(num maGiaoVien) => this(maGiaoVien: maGiaoVien);

  @override
  TeachersDto hoTen(String hoTen) => this(hoTen: hoTen);

  @override
  TeachersDto toChuyenMon(String? toChuyenMon) =>
      this(toChuyenMon: toChuyenMon);

  @override
  TeachersDto email(String? email) => this(email: email);

  @override
  TeachersDto dienThoai(String? dienThoai) => this(dienThoai: dienThoai);

  @override
  TeachersDto label(String label) => this(label: label);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TeachersDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TeachersDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TeachersDto call({
    Object? maGiaoVien = const $CopyWithPlaceholder(),
    Object? hoTen = const $CopyWithPlaceholder(),
    Object? toChuyenMon = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? dienThoai = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
  }) {
    return TeachersDto(
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
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
    );
  }
}

extension $TeachersDtoCopyWith on TeachersDto {
  /// Returns a callable class that can be used as follows: `instanceOfTeachersDto.copyWith(...)` or like so:`instanceOfTeachersDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TeachersDtoCWProxy get copyWith => _$TeachersDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeachersDto _$TeachersDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'TeachersDto',
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
        'label',
      ],
    );
    final val = TeachersDto(
      maGiaoVien: $checkedConvert('ma_giao_vien', (v) => v as num),
      hoTen: $checkedConvert('ho_ten', (v) => v as String),
      toChuyenMon: $checkedConvert('to_chuyen_mon', (v) => v as String?),
      email: $checkedConvert('email', (v) => v as String?),
      dienThoai: $checkedConvert('dien_thoai', (v) => v as String?),
      label: $checkedConvert('label', (v) => v as String),
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

Map<String, dynamic> _$TeachersDtoToJson(TeachersDto instance) =>
    <String, dynamic>{
      'ma_giao_vien': instance.maGiaoVien,
      'ho_ten': instance.hoTen,
      'to_chuyen_mon': instance.toChuyenMon,
      'email': instance.email,
      'dien_thoai': instance.dienThoai,
      'label': instance.label,
    };
