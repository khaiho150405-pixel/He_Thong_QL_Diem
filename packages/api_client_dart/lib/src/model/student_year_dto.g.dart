// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_year_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StudentYearDtoCWProxy {
  StudentYearDto id(num id);

  StudentYearDto name(String name);

  StudentYearDto className(String className);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentYearDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentYearDto(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentYearDto call({num id, String name, String className});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStudentYearDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStudentYearDto.copyWith.fieldName(...)`
class _$StudentYearDtoCWProxyImpl implements _$StudentYearDtoCWProxy {
  const _$StudentYearDtoCWProxyImpl(this._value);

  final StudentYearDto _value;

  @override
  StudentYearDto id(num id) => this(id: id);

  @override
  StudentYearDto name(String name) => this(name: name);

  @override
  StudentYearDto className(String className) => this(className: className);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentYearDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentYearDto(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentYearDto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? className = const $CopyWithPlaceholder(),
  }) {
    return StudentYearDto(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as num,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      className: className == const $CopyWithPlaceholder()
          ? _value.className
          // ignore: cast_nullable_to_non_nullable
          : className as String,
    );
  }
}

extension $StudentYearDtoCopyWith on StudentYearDto {
  /// Returns a callable class that can be used as follows: `instanceOfStudentYearDto.copyWith(...)` or like so:`instanceOfStudentYearDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StudentYearDtoCWProxy get copyWith => _$StudentYearDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentYearDto _$StudentYearDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StudentYearDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'name', 'className']);
      final val = StudentYearDto(
        id: $checkedConvert('id', (v) => v as num),
        name: $checkedConvert('name', (v) => v as String),
        className: $checkedConvert('className', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$StudentYearDtoToJson(StudentYearDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'className': instance.className,
    };
