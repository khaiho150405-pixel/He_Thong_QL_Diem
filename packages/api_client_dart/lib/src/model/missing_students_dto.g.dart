// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'missing_students_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MissingStudentsDtoCWProxy {
  MissingStudentsDto items(List<MissingStudentDto> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MissingStudentsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MissingStudentsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  MissingStudentsDto call({List<MissingStudentDto> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMissingStudentsDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMissingStudentsDto.copyWith.fieldName(...)`
class _$MissingStudentsDtoCWProxyImpl implements _$MissingStudentsDtoCWProxy {
  const _$MissingStudentsDtoCWProxyImpl(this._value);

  final MissingStudentsDto _value;

  @override
  MissingStudentsDto items(List<MissingStudentDto> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MissingStudentsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MissingStudentsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  MissingStudentsDto call({Object? items = const $CopyWithPlaceholder()}) {
    return MissingStudentsDto(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<MissingStudentDto>,
    );
  }
}

extension $MissingStudentsDtoCopyWith on MissingStudentsDto {
  /// Returns a callable class that can be used as follows: `instanceOfMissingStudentsDto.copyWith(...)` or like so:`instanceOfMissingStudentsDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MissingStudentsDtoCWProxy get copyWith =>
      _$MissingStudentsDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MissingStudentsDto _$MissingStudentsDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MissingStudentsDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = MissingStudentsDto(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => MissingStudentDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$MissingStudentsDtoToJson(MissingStudentsDto instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
