// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable_semester_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TimetableSemesterDtoCWProxy {
  TimetableSemesterDto id(num id);

  TimetableSemesterDto name(String name);

  TimetableSemesterDto yearName(String yearName);

  TimetableSemesterDto startDate(String startDate);

  TimetableSemesterDto endDate(String endDate);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TimetableSemesterDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TimetableSemesterDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TimetableSemesterDto call({
    num id,
    String name,
    String yearName,
    String startDate,
    String endDate,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTimetableSemesterDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTimetableSemesterDto.copyWith.fieldName(...)`
class _$TimetableSemesterDtoCWProxyImpl
    implements _$TimetableSemesterDtoCWProxy {
  const _$TimetableSemesterDtoCWProxyImpl(this._value);

  final TimetableSemesterDto _value;

  @override
  TimetableSemesterDto id(num id) => this(id: id);

  @override
  TimetableSemesterDto name(String name) => this(name: name);

  @override
  TimetableSemesterDto yearName(String yearName) => this(yearName: yearName);

  @override
  TimetableSemesterDto startDate(String startDate) =>
      this(startDate: startDate);

  @override
  TimetableSemesterDto endDate(String endDate) => this(endDate: endDate);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TimetableSemesterDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TimetableSemesterDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TimetableSemesterDto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? yearName = const $CopyWithPlaceholder(),
    Object? startDate = const $CopyWithPlaceholder(),
    Object? endDate = const $CopyWithPlaceholder(),
  }) {
    return TimetableSemesterDto(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as num,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      yearName: yearName == const $CopyWithPlaceholder()
          ? _value.yearName
          // ignore: cast_nullable_to_non_nullable
          : yearName as String,
      startDate: startDate == const $CopyWithPlaceholder()
          ? _value.startDate
          // ignore: cast_nullable_to_non_nullable
          : startDate as String,
      endDate: endDate == const $CopyWithPlaceholder()
          ? _value.endDate
          // ignore: cast_nullable_to_non_nullable
          : endDate as String,
    );
  }
}

extension $TimetableSemesterDtoCopyWith on TimetableSemesterDto {
  /// Returns a callable class that can be used as follows: `instanceOfTimetableSemesterDto.copyWith(...)` or like so:`instanceOfTimetableSemesterDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TimetableSemesterDtoCWProxy get copyWith =>
      _$TimetableSemesterDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimetableSemesterDto _$TimetableSemesterDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('TimetableSemesterDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'name', 'yearName', 'startDate', 'endDate'],
  );
  final val = TimetableSemesterDto(
    id: $checkedConvert('id', (v) => v as num),
    name: $checkedConvert('name', (v) => v as String),
    yearName: $checkedConvert('yearName', (v) => v as String),
    startDate: $checkedConvert('startDate', (v) => v as String),
    endDate: $checkedConvert('endDate', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$TimetableSemesterDtoToJson(
  TimetableSemesterDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'yearName': instance.yearName,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
};
