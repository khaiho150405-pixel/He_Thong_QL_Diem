// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subjects_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SubjectsDtoCWProxy {
  SubjectsDto tenMon(String tenMon);

  SubjectsDto soTietTuan(num soTietTuan);

  SubjectsDto label(String label);

  SubjectsDto maMon(num maMon);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SubjectsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SubjectsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  SubjectsDto call({String tenMon, num soTietTuan, String label, num maMon});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSubjectsDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSubjectsDto.copyWith.fieldName(...)`
class _$SubjectsDtoCWProxyImpl implements _$SubjectsDtoCWProxy {
  const _$SubjectsDtoCWProxyImpl(this._value);

  final SubjectsDto _value;

  @override
  SubjectsDto tenMon(String tenMon) => this(tenMon: tenMon);

  @override
  SubjectsDto soTietTuan(num soTietTuan) => this(soTietTuan: soTietTuan);

  @override
  SubjectsDto label(String label) => this(label: label);

  @override
  SubjectsDto maMon(num maMon) => this(maMon: maMon);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SubjectsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SubjectsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  SubjectsDto call({
    Object? tenMon = const $CopyWithPlaceholder(),
    Object? soTietTuan = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? maMon = const $CopyWithPlaceholder(),
  }) {
    return SubjectsDto(
      tenMon: tenMon == const $CopyWithPlaceholder()
          ? _value.tenMon
          // ignore: cast_nullable_to_non_nullable
          : tenMon as String,
      soTietTuan: soTietTuan == const $CopyWithPlaceholder()
          ? _value.soTietTuan
          // ignore: cast_nullable_to_non_nullable
          : soTietTuan as num,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      maMon: maMon == const $CopyWithPlaceholder()
          ? _value.maMon
          // ignore: cast_nullable_to_non_nullable
          : maMon as num,
    );
  }
}

extension $SubjectsDtoCopyWith on SubjectsDto {
  /// Returns a callable class that can be used as follows: `instanceOfSubjectsDto.copyWith(...)` or like so:`instanceOfSubjectsDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SubjectsDtoCWProxy get copyWith => _$SubjectsDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectsDto _$SubjectsDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'SubjectsDto',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['ten_mon', 'so_tiet_tuan', 'label', 'ma_mon'],
    );
    final val = SubjectsDto(
      tenMon: $checkedConvert('ten_mon', (v) => v as String),
      soTietTuan: $checkedConvert('so_tiet_tuan', (v) => v as num),
      label: $checkedConvert('label', (v) => v as String),
      maMon: $checkedConvert('ma_mon', (v) => v as num),
    );
    return val;
  },
  fieldKeyMap: const {
    'tenMon': 'ten_mon',
    'soTietTuan': 'so_tiet_tuan',
    'maMon': 'ma_mon',
  },
);

Map<String, dynamic> _$SubjectsDtoToJson(SubjectsDto instance) =>
    <String, dynamic>{
      'ten_mon': instance.tenMon,
      'so_tiet_tuan': instance.soTietTuan,
      'label': instance.label,
      'ma_mon': instance.maMon,
    };
