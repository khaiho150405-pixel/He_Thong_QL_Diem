// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classes_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ClassesDtoCWProxy {
  ClassesDto maNamHoc(num maNamHoc);

  ClassesDto maGvChuNhiem(num maGvChuNhiem);

  ClassesDto tenLop(String tenLop);

  ClassesDto khoi(num khoi);

  ClassesDto label(String label);

  ClassesDto maLop(num maLop);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClassesDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClassesDto(...).copyWith(id: 12, name: "My name")
  /// ````
  ClassesDto call({
    num maNamHoc,
    num maGvChuNhiem,
    String tenLop,
    num khoi,
    String label,
    num maLop,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfClassesDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfClassesDto.copyWith.fieldName(...)`
class _$ClassesDtoCWProxyImpl implements _$ClassesDtoCWProxy {
  const _$ClassesDtoCWProxyImpl(this._value);

  final ClassesDto _value;

  @override
  ClassesDto maNamHoc(num maNamHoc) => this(maNamHoc: maNamHoc);

  @override
  ClassesDto maGvChuNhiem(num maGvChuNhiem) => this(maGvChuNhiem: maGvChuNhiem);

  @override
  ClassesDto tenLop(String tenLop) => this(tenLop: tenLop);

  @override
  ClassesDto khoi(num khoi) => this(khoi: khoi);

  @override
  ClassesDto label(String label) => this(label: label);

  @override
  ClassesDto maLop(num maLop) => this(maLop: maLop);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClassesDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClassesDto(...).copyWith(id: 12, name: "My name")
  /// ````
  ClassesDto call({
    Object? maNamHoc = const $CopyWithPlaceholder(),
    Object? maGvChuNhiem = const $CopyWithPlaceholder(),
    Object? tenLop = const $CopyWithPlaceholder(),
    Object? khoi = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? maLop = const $CopyWithPlaceholder(),
  }) {
    return ClassesDto(
      maNamHoc: maNamHoc == const $CopyWithPlaceholder()
          ? _value.maNamHoc
          // ignore: cast_nullable_to_non_nullable
          : maNamHoc as num,
      maGvChuNhiem: maGvChuNhiem == const $CopyWithPlaceholder()
          ? _value.maGvChuNhiem
          // ignore: cast_nullable_to_non_nullable
          : maGvChuNhiem as num,
      tenLop: tenLop == const $CopyWithPlaceholder()
          ? _value.tenLop
          // ignore: cast_nullable_to_non_nullable
          : tenLop as String,
      khoi: khoi == const $CopyWithPlaceholder()
          ? _value.khoi
          // ignore: cast_nullable_to_non_nullable
          : khoi as num,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      maLop: maLop == const $CopyWithPlaceholder()
          ? _value.maLop
          // ignore: cast_nullable_to_non_nullable
          : maLop as num,
    );
  }
}

extension $ClassesDtoCopyWith on ClassesDto {
  /// Returns a callable class that can be used as follows: `instanceOfClassesDto.copyWith(...)` or like so:`instanceOfClassesDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ClassesDtoCWProxy get copyWith => _$ClassesDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassesDto _$ClassesDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ClassesDto',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'ma_nam_hoc',
        'ma_gv_chu_nhiem',
        'ten_lop',
        'khoi',
        'label',
        'ma_lop',
      ],
    );
    final val = ClassesDto(
      maNamHoc: $checkedConvert('ma_nam_hoc', (v) => v as num),
      maGvChuNhiem: $checkedConvert('ma_gv_chu_nhiem', (v) => v as num),
      tenLop: $checkedConvert('ten_lop', (v) => v as String),
      khoi: $checkedConvert('khoi', (v) => v as num),
      label: $checkedConvert('label', (v) => v as String),
      maLop: $checkedConvert('ma_lop', (v) => v as num),
    );
    return val;
  },
  fieldKeyMap: const {
    'maNamHoc': 'ma_nam_hoc',
    'maGvChuNhiem': 'ma_gv_chu_nhiem',
    'tenLop': 'ten_lop',
    'maLop': 'ma_lop',
  },
);

Map<String, dynamic> _$ClassesDtoToJson(ClassesDto instance) =>
    <String, dynamic>{
      'ma_nam_hoc': instance.maNamHoc,
      'ma_gv_chu_nhiem': instance.maGvChuNhiem,
      'ten_lop': instance.tenLop,
      'khoi': instance.khoi,
      'label': instance.label,
      'ma_lop': instance.maLop,
    };
