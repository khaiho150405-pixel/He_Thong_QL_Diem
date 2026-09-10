// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subjects_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SubjectsInputCWProxy {
  SubjectsInput tenMon(String tenMon);

  SubjectsInput soTietTuan(num soTietTuan);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SubjectsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SubjectsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  SubjectsInput call({String tenMon, num soTietTuan});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSubjectsInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSubjectsInput.copyWith.fieldName(...)`
class _$SubjectsInputCWProxyImpl implements _$SubjectsInputCWProxy {
  const _$SubjectsInputCWProxyImpl(this._value);

  final SubjectsInput _value;

  @override
  SubjectsInput tenMon(String tenMon) => this(tenMon: tenMon);

  @override
  SubjectsInput soTietTuan(num soTietTuan) => this(soTietTuan: soTietTuan);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SubjectsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SubjectsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  SubjectsInput call({
    Object? tenMon = const $CopyWithPlaceholder(),
    Object? soTietTuan = const $CopyWithPlaceholder(),
  }) {
    return SubjectsInput(
      tenMon: tenMon == const $CopyWithPlaceholder()
          ? _value.tenMon
          // ignore: cast_nullable_to_non_nullable
          : tenMon as String,
      soTietTuan: soTietTuan == const $CopyWithPlaceholder()
          ? _value.soTietTuan
          // ignore: cast_nullable_to_non_nullable
          : soTietTuan as num,
    );
  }
}

extension $SubjectsInputCopyWith on SubjectsInput {
  /// Returns a callable class that can be used as follows: `instanceOfSubjectsInput.copyWith(...)` or like so:`instanceOfSubjectsInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SubjectsInputCWProxy get copyWith => _$SubjectsInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectsInput _$SubjectsInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SubjectsInput',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['ten_mon', 'so_tiet_tuan']);
        final val = SubjectsInput(
          tenMon: $checkedConvert('ten_mon', (v) => v as String),
          soTietTuan: $checkedConvert('so_tiet_tuan', (v) => v as num),
        );
        return val;
      },
      fieldKeyMap: const {'tenMon': 'ten_mon', 'soTietTuan': 'so_tiet_tuan'},
    );

Map<String, dynamic> _$SubjectsInputToJson(SubjectsInput instance) =>
    <String, dynamic>{
      'ten_mon': instance.tenMon,
      'so_tiet_tuan': instance.soTietTuan,
    };
