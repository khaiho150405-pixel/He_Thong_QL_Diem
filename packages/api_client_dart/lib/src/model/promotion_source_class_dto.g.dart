// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_source_class_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PromotionSourceClassDtoCWProxy {
  PromotionSourceClassDto id(num id);

  PromotionSourceClassDto name(String name);

  PromotionSourceClassDto grade(num grade);

  PromotionSourceClassDto yearId(num yearId);

  PromotionSourceClassDto yearName(String yearName);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PromotionSourceClassDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PromotionSourceClassDto(...).copyWith(id: 12, name: "My name")
  /// ````
  PromotionSourceClassDto call({
    num id,
    String name,
    num grade,
    num yearId,
    String yearName,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPromotionSourceClassDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPromotionSourceClassDto.copyWith.fieldName(...)`
class _$PromotionSourceClassDtoCWProxyImpl
    implements _$PromotionSourceClassDtoCWProxy {
  const _$PromotionSourceClassDtoCWProxyImpl(this._value);

  final PromotionSourceClassDto _value;

  @override
  PromotionSourceClassDto id(num id) => this(id: id);

  @override
  PromotionSourceClassDto name(String name) => this(name: name);

  @override
  PromotionSourceClassDto grade(num grade) => this(grade: grade);

  @override
  PromotionSourceClassDto yearId(num yearId) => this(yearId: yearId);

  @override
  PromotionSourceClassDto yearName(String yearName) => this(yearName: yearName);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PromotionSourceClassDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PromotionSourceClassDto(...).copyWith(id: 12, name: "My name")
  /// ````
  PromotionSourceClassDto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? grade = const $CopyWithPlaceholder(),
    Object? yearId = const $CopyWithPlaceholder(),
    Object? yearName = const $CopyWithPlaceholder(),
  }) {
    return PromotionSourceClassDto(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as num,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      grade: grade == const $CopyWithPlaceholder()
          ? _value.grade
          // ignore: cast_nullable_to_non_nullable
          : grade as num,
      yearId: yearId == const $CopyWithPlaceholder()
          ? _value.yearId
          // ignore: cast_nullable_to_non_nullable
          : yearId as num,
      yearName: yearName == const $CopyWithPlaceholder()
          ? _value.yearName
          // ignore: cast_nullable_to_non_nullable
          : yearName as String,
    );
  }
}

extension $PromotionSourceClassDtoCopyWith on PromotionSourceClassDto {
  /// Returns a callable class that can be used as follows: `instanceOfPromotionSourceClassDto.copyWith(...)` or like so:`instanceOfPromotionSourceClassDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PromotionSourceClassDtoCWProxy get copyWith =>
      _$PromotionSourceClassDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromotionSourceClassDto _$PromotionSourceClassDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PromotionSourceClassDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'name', 'grade', 'yearId', 'yearName'],
  );
  final val = PromotionSourceClassDto(
    id: $checkedConvert('id', (v) => v as num),
    name: $checkedConvert('name', (v) => v as String),
    grade: $checkedConvert('grade', (v) => v as num),
    yearId: $checkedConvert('yearId', (v) => v as num),
    yearName: $checkedConvert('yearName', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$PromotionSourceClassDtoToJson(
  PromotionSourceClassDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'grade': instance.grade,
  'yearId': instance.yearId,
  'yearName': instance.yearName,
};
