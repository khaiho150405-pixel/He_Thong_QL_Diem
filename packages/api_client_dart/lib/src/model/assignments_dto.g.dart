// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignments_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AssignmentsDtoCWProxy {
  AssignmentsDto maGiaoVien(num maGiaoVien);

  AssignmentsDto maLop(num maLop);

  AssignmentsDto maMon(num maMon);

  AssignmentsDto maHocKy(num maHocKy);

  AssignmentsDto ngayPhanCong(String ngayPhanCong);

  AssignmentsDto label(String label);

  AssignmentsDto maPhanCong(num maPhanCong);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AssignmentsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AssignmentsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AssignmentsDto call({
    num maGiaoVien,
    num maLop,
    num maMon,
    num maHocKy,
    String ngayPhanCong,
    String label,
    num maPhanCong,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAssignmentsDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAssignmentsDto.copyWith.fieldName(...)`
class _$AssignmentsDtoCWProxyImpl implements _$AssignmentsDtoCWProxy {
  const _$AssignmentsDtoCWProxyImpl(this._value);

  final AssignmentsDto _value;

  @override
  AssignmentsDto maGiaoVien(num maGiaoVien) => this(maGiaoVien: maGiaoVien);

  @override
  AssignmentsDto maLop(num maLop) => this(maLop: maLop);

  @override
  AssignmentsDto maMon(num maMon) => this(maMon: maMon);

  @override
  AssignmentsDto maHocKy(num maHocKy) => this(maHocKy: maHocKy);

  @override
  AssignmentsDto ngayPhanCong(String ngayPhanCong) =>
      this(ngayPhanCong: ngayPhanCong);

  @override
  AssignmentsDto label(String label) => this(label: label);

  @override
  AssignmentsDto maPhanCong(num maPhanCong) => this(maPhanCong: maPhanCong);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AssignmentsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AssignmentsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AssignmentsDto call({
    Object? maGiaoVien = const $CopyWithPlaceholder(),
    Object? maLop = const $CopyWithPlaceholder(),
    Object? maMon = const $CopyWithPlaceholder(),
    Object? maHocKy = const $CopyWithPlaceholder(),
    Object? ngayPhanCong = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? maPhanCong = const $CopyWithPlaceholder(),
  }) {
    return AssignmentsDto(
      maGiaoVien: maGiaoVien == const $CopyWithPlaceholder()
          ? _value.maGiaoVien
          // ignore: cast_nullable_to_non_nullable
          : maGiaoVien as num,
      maLop: maLop == const $CopyWithPlaceholder()
          ? _value.maLop
          // ignore: cast_nullable_to_non_nullable
          : maLop as num,
      maMon: maMon == const $CopyWithPlaceholder()
          ? _value.maMon
          // ignore: cast_nullable_to_non_nullable
          : maMon as num,
      maHocKy: maHocKy == const $CopyWithPlaceholder()
          ? _value.maHocKy
          // ignore: cast_nullable_to_non_nullable
          : maHocKy as num,
      ngayPhanCong: ngayPhanCong == const $CopyWithPlaceholder()
          ? _value.ngayPhanCong
          // ignore: cast_nullable_to_non_nullable
          : ngayPhanCong as String,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      maPhanCong: maPhanCong == const $CopyWithPlaceholder()
          ? _value.maPhanCong
          // ignore: cast_nullable_to_non_nullable
          : maPhanCong as num,
    );
  }
}

extension $AssignmentsDtoCopyWith on AssignmentsDto {
  /// Returns a callable class that can be used as follows: `instanceOfAssignmentsDto.copyWith(...)` or like so:`instanceOfAssignmentsDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AssignmentsDtoCWProxy get copyWith => _$AssignmentsDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssignmentsDto _$AssignmentsDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AssignmentsDto',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'ma_giao_vien',
            'ma_lop',
            'ma_mon',
            'ma_hoc_ky',
            'ngay_phan_cong',
            'label',
            'ma_phan_cong',
          ],
        );
        final val = AssignmentsDto(
          maGiaoVien: $checkedConvert('ma_giao_vien', (v) => v as num),
          maLop: $checkedConvert('ma_lop', (v) => v as num),
          maMon: $checkedConvert('ma_mon', (v) => v as num),
          maHocKy: $checkedConvert('ma_hoc_ky', (v) => v as num),
          ngayPhanCong: $checkedConvert('ngay_phan_cong', (v) => v as String),
          label: $checkedConvert('label', (v) => v as String),
          maPhanCong: $checkedConvert('ma_phan_cong', (v) => v as num),
        );
        return val;
      },
      fieldKeyMap: const {
        'maGiaoVien': 'ma_giao_vien',
        'maLop': 'ma_lop',
        'maMon': 'ma_mon',
        'maHocKy': 'ma_hoc_ky',
        'ngayPhanCong': 'ngay_phan_cong',
        'maPhanCong': 'ma_phan_cong',
      },
    );

Map<String, dynamic> _$AssignmentsDtoToJson(AssignmentsDto instance) =>
    <String, dynamic>{
      'ma_giao_vien': instance.maGiaoVien,
      'ma_lop': instance.maLop,
      'ma_mon': instance.maMon,
      'ma_hoc_ky': instance.maHocKy,
      'ngay_phan_cong': instance.ngayPhanCong,
      'label': instance.label,
      'ma_phan_cong': instance.maPhanCong,
    };
