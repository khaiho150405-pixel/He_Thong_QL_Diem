// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_timetable_item_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateTimetableItemInputCWProxy {
  CreateTimetableItemInput maLop(num maLop);

  CreateTimetableItemInput maMon(num maMon);

  CreateTimetableItemInput maGiaoVien(num maGiaoVien);

  CreateTimetableItemInput maHocKy(num maHocKy);

  CreateTimetableItemInput thu(num thu);

  CreateTimetableItemInput tiet(num tiet);

  CreateTimetableItemInput phongHoc(String? phongHoc);

  CreateTimetableItemInput ghiChu(String? ghiChu);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateTimetableItemInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateTimetableItemInput(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateTimetableItemInput call({
    num maLop,
    num maMon,
    num maGiaoVien,
    num maHocKy,
    num thu,
    num tiet,
    String? phongHoc,
    String? ghiChu,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCreateTimetableItemInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCreateTimetableItemInput.copyWith.fieldName(...)`
class _$CreateTimetableItemInputCWProxyImpl
    implements _$CreateTimetableItemInputCWProxy {
  const _$CreateTimetableItemInputCWProxyImpl(this._value);

  final CreateTimetableItemInput _value;

  @override
  CreateTimetableItemInput maLop(num maLop) => this(maLop: maLop);

  @override
  CreateTimetableItemInput maMon(num maMon) => this(maMon: maMon);

  @override
  CreateTimetableItemInput maGiaoVien(num maGiaoVien) =>
      this(maGiaoVien: maGiaoVien);

  @override
  CreateTimetableItemInput maHocKy(num maHocKy) => this(maHocKy: maHocKy);

  @override
  CreateTimetableItemInput thu(num thu) => this(thu: thu);

  @override
  CreateTimetableItemInput tiet(num tiet) => this(tiet: tiet);

  @override
  CreateTimetableItemInput phongHoc(String? phongHoc) =>
      this(phongHoc: phongHoc);

  @override
  CreateTimetableItemInput ghiChu(String? ghiChu) => this(ghiChu: ghiChu);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateTimetableItemInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateTimetableItemInput(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateTimetableItemInput call({
    Object? maLop = const $CopyWithPlaceholder(),
    Object? maMon = const $CopyWithPlaceholder(),
    Object? maGiaoVien = const $CopyWithPlaceholder(),
    Object? maHocKy = const $CopyWithPlaceholder(),
    Object? thu = const $CopyWithPlaceholder(),
    Object? tiet = const $CopyWithPlaceholder(),
    Object? phongHoc = const $CopyWithPlaceholder(),
    Object? ghiChu = const $CopyWithPlaceholder(),
  }) {
    return CreateTimetableItemInput(
      maLop: maLop == const $CopyWithPlaceholder()
          ? _value.maLop
          // ignore: cast_nullable_to_non_nullable
          : maLop as num,
      maMon: maMon == const $CopyWithPlaceholder()
          ? _value.maMon
          // ignore: cast_nullable_to_non_nullable
          : maMon as num,
      maGiaoVien: maGiaoVien == const $CopyWithPlaceholder()
          ? _value.maGiaoVien
          // ignore: cast_nullable_to_non_nullable
          : maGiaoVien as num,
      maHocKy: maHocKy == const $CopyWithPlaceholder()
          ? _value.maHocKy
          // ignore: cast_nullable_to_non_nullable
          : maHocKy as num,
      thu: thu == const $CopyWithPlaceholder()
          ? _value.thu
          // ignore: cast_nullable_to_non_nullable
          : thu as num,
      tiet: tiet == const $CopyWithPlaceholder()
          ? _value.tiet
          // ignore: cast_nullable_to_non_nullable
          : tiet as num,
      phongHoc: phongHoc == const $CopyWithPlaceholder()
          ? _value.phongHoc
          // ignore: cast_nullable_to_non_nullable
          : phongHoc as String?,
      ghiChu: ghiChu == const $CopyWithPlaceholder()
          ? _value.ghiChu
          // ignore: cast_nullable_to_non_nullable
          : ghiChu as String?,
    );
  }
}

extension $CreateTimetableItemInputCopyWith on CreateTimetableItemInput {
  /// Returns a callable class that can be used as follows: `instanceOfCreateTimetableItemInput.copyWith(...)` or like so:`instanceOfCreateTimetableItemInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateTimetableItemInputCWProxy get copyWith =>
      _$CreateTimetableItemInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateTimetableItemInput _$CreateTimetableItemInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CreateTimetableItemInput',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'ma_lop',
        'ma_mon',
        'ma_giao_vien',
        'ma_hoc_ky',
        'thu',
        'tiet',
      ],
    );
    final val = CreateTimetableItemInput(
      maLop: $checkedConvert('ma_lop', (v) => v as num),
      maMon: $checkedConvert('ma_mon', (v) => v as num),
      maGiaoVien: $checkedConvert('ma_giao_vien', (v) => v as num),
      maHocKy: $checkedConvert('ma_hoc_ky', (v) => v as num),
      thu: $checkedConvert('thu', (v) => v as num),
      tiet: $checkedConvert('tiet', (v) => v as num),
      phongHoc: $checkedConvert('phong_hoc', (v) => v as String?),
      ghiChu: $checkedConvert('ghi_chu', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'maLop': 'ma_lop',
    'maMon': 'ma_mon',
    'maGiaoVien': 'ma_giao_vien',
    'maHocKy': 'ma_hoc_ky',
    'phongHoc': 'phong_hoc',
    'ghiChu': 'ghi_chu',
  },
);

Map<String, dynamic> _$CreateTimetableItemInputToJson(
  CreateTimetableItemInput instance,
) => <String, dynamic>{
  'ma_lop': instance.maLop,
  'ma_mon': instance.maMon,
  'ma_giao_vien': instance.maGiaoVien,
  'ma_hoc_ky': instance.maHocKy,
  'thu': instance.thu,
  'tiet': instance.tiet,
  'phong_hoc': ?instance.phongHoc,
  'ghi_chu': ?instance.ghiChu,
};
