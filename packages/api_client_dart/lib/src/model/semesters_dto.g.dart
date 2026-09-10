// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semesters_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SemestersDtoCWProxy {
  SemestersDto maNamHoc(num maNamHoc);

  SemestersDto ten(String ten);

  SemestersDto thuTu(num thuTu);

  SemestersDto ngayBatDau(String ngayBatDau);

  SemestersDto ngayKetThuc(String ngayKetThuc);

  SemestersDto label(String label);

  SemestersDto maHocKy(num maHocKy);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SemestersDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SemestersDto(...).copyWith(id: 12, name: "My name")
  /// ````
  SemestersDto call({
    num maNamHoc,
    String ten,
    num thuTu,
    String ngayBatDau,
    String ngayKetThuc,
    String label,
    num maHocKy,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSemestersDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSemestersDto.copyWith.fieldName(...)`
class _$SemestersDtoCWProxyImpl implements _$SemestersDtoCWProxy {
  const _$SemestersDtoCWProxyImpl(this._value);

  final SemestersDto _value;

  @override
  SemestersDto maNamHoc(num maNamHoc) => this(maNamHoc: maNamHoc);

  @override
  SemestersDto ten(String ten) => this(ten: ten);

  @override
  SemestersDto thuTu(num thuTu) => this(thuTu: thuTu);

  @override
  SemestersDto ngayBatDau(String ngayBatDau) => this(ngayBatDau: ngayBatDau);

  @override
  SemestersDto ngayKetThuc(String ngayKetThuc) =>
      this(ngayKetThuc: ngayKetThuc);

  @override
  SemestersDto label(String label) => this(label: label);

  @override
  SemestersDto maHocKy(num maHocKy) => this(maHocKy: maHocKy);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SemestersDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SemestersDto(...).copyWith(id: 12, name: "My name")
  /// ````
  SemestersDto call({
    Object? maNamHoc = const $CopyWithPlaceholder(),
    Object? ten = const $CopyWithPlaceholder(),
    Object? thuTu = const $CopyWithPlaceholder(),
    Object? ngayBatDau = const $CopyWithPlaceholder(),
    Object? ngayKetThuc = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? maHocKy = const $CopyWithPlaceholder(),
  }) {
    return SemestersDto(
      maNamHoc: maNamHoc == const $CopyWithPlaceholder()
          ? _value.maNamHoc
          // ignore: cast_nullable_to_non_nullable
          : maNamHoc as num,
      ten: ten == const $CopyWithPlaceholder()
          ? _value.ten
          // ignore: cast_nullable_to_non_nullable
          : ten as String,
      thuTu: thuTu == const $CopyWithPlaceholder()
          ? _value.thuTu
          // ignore: cast_nullable_to_non_nullable
          : thuTu as num,
      ngayBatDau: ngayBatDau == const $CopyWithPlaceholder()
          ? _value.ngayBatDau
          // ignore: cast_nullable_to_non_nullable
          : ngayBatDau as String,
      ngayKetThuc: ngayKetThuc == const $CopyWithPlaceholder()
          ? _value.ngayKetThuc
          // ignore: cast_nullable_to_non_nullable
          : ngayKetThuc as String,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      maHocKy: maHocKy == const $CopyWithPlaceholder()
          ? _value.maHocKy
          // ignore: cast_nullable_to_non_nullable
          : maHocKy as num,
    );
  }
}

extension $SemestersDtoCopyWith on SemestersDto {
  /// Returns a callable class that can be used as follows: `instanceOfSemestersDto.copyWith(...)` or like so:`instanceOfSemestersDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SemestersDtoCWProxy get copyWith => _$SemestersDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SemestersDto _$SemestersDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SemestersDto',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'ma_nam_hoc',
            'ten',
            'thu_tu',
            'ngay_bat_dau',
            'ngay_ket_thuc',
            'label',
            'ma_hoc_ky',
          ],
        );
        final val = SemestersDto(
          maNamHoc: $checkedConvert('ma_nam_hoc', (v) => v as num),
          ten: $checkedConvert('ten', (v) => v as String),
          thuTu: $checkedConvert('thu_tu', (v) => v as num),
          ngayBatDau: $checkedConvert('ngay_bat_dau', (v) => v as String),
          ngayKetThuc: $checkedConvert('ngay_ket_thuc', (v) => v as String),
          label: $checkedConvert('label', (v) => v as String),
          maHocKy: $checkedConvert('ma_hoc_ky', (v) => v as num),
        );
        return val;
      },
      fieldKeyMap: const {
        'maNamHoc': 'ma_nam_hoc',
        'thuTu': 'thu_tu',
        'ngayBatDau': 'ngay_bat_dau',
        'ngayKetThuc': 'ngay_ket_thuc',
        'maHocKy': 'ma_hoc_ky',
      },
    );

Map<String, dynamic> _$SemestersDtoToJson(SemestersDto instance) =>
    <String, dynamic>{
      'ma_nam_hoc': instance.maNamHoc,
      'ten': instance.ten,
      'thu_tu': instance.thuTu,
      'ngay_bat_dau': instance.ngayBatDau,
      'ngay_ket_thuc': instance.ngayKetThuc,
      'label': instance.label,
      'ma_hoc_ky': instance.maHocKy,
    };
