// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignments_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AssignmentsInputCWProxy {
  AssignmentsInput maGiaoVien(num maGiaoVien);

  AssignmentsInput maLop(num maLop);

  AssignmentsInput maMon(num maMon);

  AssignmentsInput maHocKy(num maHocKy);

  AssignmentsInput ngayPhanCong(String ngayPhanCong);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AssignmentsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AssignmentsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  AssignmentsInput call({
    num maGiaoVien,
    num maLop,
    num maMon,
    num maHocKy,
    String ngayPhanCong,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAssignmentsInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAssignmentsInput.copyWith.fieldName(...)`
class _$AssignmentsInputCWProxyImpl implements _$AssignmentsInputCWProxy {
  const _$AssignmentsInputCWProxyImpl(this._value);

  final AssignmentsInput _value;

  @override
  AssignmentsInput maGiaoVien(num maGiaoVien) => this(maGiaoVien: maGiaoVien);

  @override
  AssignmentsInput maLop(num maLop) => this(maLop: maLop);

  @override
  AssignmentsInput maMon(num maMon) => this(maMon: maMon);

  @override
  AssignmentsInput maHocKy(num maHocKy) => this(maHocKy: maHocKy);

  @override
  AssignmentsInput ngayPhanCong(String ngayPhanCong) =>
      this(ngayPhanCong: ngayPhanCong);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AssignmentsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AssignmentsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  AssignmentsInput call({
    Object? maGiaoVien = const $CopyWithPlaceholder(),
    Object? maLop = const $CopyWithPlaceholder(),
    Object? maMon = const $CopyWithPlaceholder(),
    Object? maHocKy = const $CopyWithPlaceholder(),
    Object? ngayPhanCong = const $CopyWithPlaceholder(),
  }) {
    return AssignmentsInput(
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
    );
  }
}

extension $AssignmentsInputCopyWith on AssignmentsInput {
  /// Returns a callable class that can be used as follows: `instanceOfAssignmentsInput.copyWith(...)` or like so:`instanceOfAssignmentsInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AssignmentsInputCWProxy get copyWith => _$AssignmentsInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssignmentsInput _$AssignmentsInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AssignmentsInput',
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
          ],
        );
        final val = AssignmentsInput(
          maGiaoVien: $checkedConvert('ma_giao_vien', (v) => v as num),
          maLop: $checkedConvert('ma_lop', (v) => v as num),
          maMon: $checkedConvert('ma_mon', (v) => v as num),
          maHocKy: $checkedConvert('ma_hoc_ky', (v) => v as num),
          ngayPhanCong: $checkedConvert('ngay_phan_cong', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'maGiaoVien': 'ma_giao_vien',
        'maLop': 'ma_lop',
        'maMon': 'ma_mon',
        'maHocKy': 'ma_hoc_ky',
        'ngayPhanCong': 'ngay_phan_cong',
      },
    );

Map<String, dynamic> _$AssignmentsInputToJson(AssignmentsInput instance) =>
    <String, dynamic>{
      'ma_giao_vien': instance.maGiaoVien,
      'ma_lop': instance.maLop,
      'ma_mon': instance.maMon,
      'ma_hoc_ky': instance.maHocKy,
      'ngay_phan_cong': instance.ngayPhanCong,
    };
