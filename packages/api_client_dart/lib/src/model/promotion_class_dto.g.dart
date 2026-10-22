// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_class_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PromotionClassDtoCWProxy {
  PromotionClassDto id(num id);

  PromotionClassDto name(String name);

  PromotionClassDto grade(num grade);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PromotionClassDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PromotionClassDto(...).copyWith(id: 12, name: "My name")
  /// ````
  PromotionClassDto call({num id, String name, num grade});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPromotionClassDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPromotionClassDto.copyWith.fieldName(...)`
class _$PromotionClassDtoCWProxyImpl implements _$PromotionClassDtoCWProxy {
  const _$PromotionClassDtoCWProxyImpl(this._value);

  final PromotionClassDto _value;

  @override
  PromotionClassDto id(num id) => this(id: id);

  @override
  PromotionClassDto name(String name) => this(name: name);

  @override
  PromotionClassDto grade(num grade) => this(grade: grade);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PromotionClassDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PromotionClassDto(...).copyWith(id: 12, name: "My name")
  /// ````
  PromotionClassDto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? grade = const $CopyWithPlaceholder(),
  }) {
    return PromotionClassDto(
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
    );
  }
}

extension $PromotionClassDtoCopyWith on PromotionClassDto {
  /// Returns a callable class that can be used as follows: `instanceOfPromotionClassDto.copyWith(...)` or like so:`instanceOfPromotionClassDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PromotionClassDtoCWProxy get copyWith =>
      _$PromotionClassDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromotionClassDto _$PromotionClassDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PromotionClassDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'name', 'grade']);
      final val = PromotionClassDto(
        id: $checkedConvert('id', (v) => v as num),
        name: $checkedConvert('name', (v) => v as String),
        grade: $checkedConvert('grade', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$PromotionClassDtoToJson(PromotionClassDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'grade': instance.grade,
    };
