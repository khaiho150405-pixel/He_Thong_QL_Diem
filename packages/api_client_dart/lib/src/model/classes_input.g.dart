// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classes_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ClassesInputCWProxy {
  ClassesInput maNamHoc(num maNamHoc);

  ClassesInput maGvChuNhiem(num maGvChuNhiem);

  ClassesInput tenLop(String tenLop);

  ClassesInput khoi(num khoi);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClassesInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClassesInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ClassesInput call({num maNamHoc, num maGvChuNhiem, String tenLop, num khoi});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfClassesInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfClassesInput.copyWith.fieldName(...)`
class _$ClassesInputCWProxyImpl implements _$ClassesInputCWProxy {
  const _$ClassesInputCWProxyImpl(this._value);

  final ClassesInput _value;

  @override
  ClassesInput maNamHoc(num maNamHoc) => this(maNamHoc: maNamHoc);

  @override
  ClassesInput maGvChuNhiem(num maGvChuNhiem) =>
      this(maGvChuNhiem: maGvChuNhiem);

  @override
  ClassesInput tenLop(String tenLop) => this(tenLop: tenLop);

  @override
  ClassesInput khoi(num khoi) => this(khoi: khoi);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClassesInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClassesInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ClassesInput call({
    Object? maNamHoc = const $CopyWithPlaceholder(),
    Object? maGvChuNhiem = const $CopyWithPlaceholder(),
    Object? tenLop = const $CopyWithPlaceholder(),
    Object? khoi = const $CopyWithPlaceholder(),
  }) {
    return ClassesInput(
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
    );
  }
}

extension $ClassesInputCopyWith on ClassesInput {
  /// Returns a callable class that can be used as follows: `instanceOfClassesInput.copyWith(...)` or like so:`instanceOfClassesInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ClassesInputCWProxy get copyWith => _$ClassesInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassesInput _$ClassesInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ClassesInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'ma_nam_hoc',
            'ma_gv_chu_nhiem',
            'ten_lop',
            'khoi',
          ],
        );
        final val = ClassesInput(
          maNamHoc: $checkedConvert('ma_nam_hoc', (v) => v as num),
          maGvChuNhiem: $checkedConvert('ma_gv_chu_nhiem', (v) => v as num),
          tenLop: $checkedConvert('ten_lop', (v) => v as String),
          khoi: $checkedConvert('khoi', (v) => v as num),
        );
        return val;
      },
      fieldKeyMap: const {
        'maNamHoc': 'ma_nam_hoc',
        'maGvChuNhiem': 'ma_gv_chu_nhiem',
        'tenLop': 'ten_lop',
      },
    );

Map<String, dynamic> _$ClassesInputToJson(ClassesInput instance) =>
    <String, dynamic>{
      'ma_nam_hoc': instance.maNamHoc,
      'ma_gv_chu_nhiem': instance.maGvChuNhiem,
      'ten_lop': instance.tenLop,
      'khoi': instance.khoi,
    };
