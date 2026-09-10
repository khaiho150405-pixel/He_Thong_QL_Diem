// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semesters_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SemestersInputCWProxy {
  SemestersInput maNamHoc(num maNamHoc);

  SemestersInput ten(String ten);

  SemestersInput thuTu(num thuTu);

  SemestersInput ngayBatDau(String ngayBatDau);

  SemestersInput ngayKetThuc(String ngayKetThuc);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SemestersInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SemestersInput(...).copyWith(id: 12, name: "My name")
  /// ````
  SemestersInput call({
    num maNamHoc,
    String ten,
    num thuTu,
    String ngayBatDau,
    String ngayKetThuc,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSemestersInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSemestersInput.copyWith.fieldName(...)`
class _$SemestersInputCWProxyImpl implements _$SemestersInputCWProxy {
  const _$SemestersInputCWProxyImpl(this._value);

  final SemestersInput _value;

  @override
  SemestersInput maNamHoc(num maNamHoc) => this(maNamHoc: maNamHoc);

  @override
  SemestersInput ten(String ten) => this(ten: ten);

  @override
  SemestersInput thuTu(num thuTu) => this(thuTu: thuTu);

  @override
  SemestersInput ngayBatDau(String ngayBatDau) => this(ngayBatDau: ngayBatDau);

  @override
  SemestersInput ngayKetThuc(String ngayKetThuc) =>
      this(ngayKetThuc: ngayKetThuc);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SemestersInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SemestersInput(...).copyWith(id: 12, name: "My name")
  /// ````
  SemestersInput call({
    Object? maNamHoc = const $CopyWithPlaceholder(),
    Object? ten = const $CopyWithPlaceholder(),
    Object? thuTu = const $CopyWithPlaceholder(),
    Object? ngayBatDau = const $CopyWithPlaceholder(),
    Object? ngayKetThuc = const $CopyWithPlaceholder(),
  }) {
    return SemestersInput(
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
    );
  }
}

extension $SemestersInputCopyWith on SemestersInput {
  /// Returns a callable class that can be used as follows: `instanceOfSemestersInput.copyWith(...)` or like so:`instanceOfSemestersInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SemestersInputCWProxy get copyWith => _$SemestersInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SemestersInput _$SemestersInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SemestersInput',
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
          ],
        );
        final val = SemestersInput(
          maNamHoc: $checkedConvert('ma_nam_hoc', (v) => v as num),
          ten: $checkedConvert('ten', (v) => v as String),
          thuTu: $checkedConvert('thu_tu', (v) => v as num),
          ngayBatDau: $checkedConvert('ngay_bat_dau', (v) => v as String),
          ngayKetThuc: $checkedConvert('ngay_ket_thuc', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'maNamHoc': 'ma_nam_hoc',
        'thuTu': 'thu_tu',
        'ngayBatDau': 'ngay_bat_dau',
        'ngayKetThuc': 'ngay_ket_thuc',
      },
    );

Map<String, dynamic> _$SemestersInputToJson(SemestersInput instance) =>
    <String, dynamic>{
      'ma_nam_hoc': instance.maNamHoc,
      'ten': instance.ten,
      'thu_tu': instance.thuTu,
      'ngay_bat_dau': instance.ngayBatDau,
      'ngay_ket_thuc': instance.ngayKetThuc,
    };
