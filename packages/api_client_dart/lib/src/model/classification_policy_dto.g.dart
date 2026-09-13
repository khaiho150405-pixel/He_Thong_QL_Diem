// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classification_policy_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ClassificationPolicyDtoCWProxy {
  ClassificationPolicyDto version(String version);

  ClassificationPolicyDto name(String name);

  ClassificationPolicyDto roundingDigits(num roundingDigits);

  ClassificationPolicyDto active(bool active);

  ClassificationPolicyDto criteria(List<ClassificationCriterionDto> criteria);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClassificationPolicyDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClassificationPolicyDto(...).copyWith(id: 12, name: "My name")
  /// ````
  ClassificationPolicyDto call({
    String version,
    String name,
    num roundingDigits,
    bool active,
    List<ClassificationCriterionDto> criteria,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfClassificationPolicyDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfClassificationPolicyDto.copyWith.fieldName(...)`
class _$ClassificationPolicyDtoCWProxyImpl
    implements _$ClassificationPolicyDtoCWProxy {
  const _$ClassificationPolicyDtoCWProxyImpl(this._value);

  final ClassificationPolicyDto _value;

  @override
  ClassificationPolicyDto version(String version) => this(version: version);

  @override
  ClassificationPolicyDto name(String name) => this(name: name);

  @override
  ClassificationPolicyDto roundingDigits(num roundingDigits) =>
      this(roundingDigits: roundingDigits);

  @override
  ClassificationPolicyDto active(bool active) => this(active: active);

  @override
  ClassificationPolicyDto criteria(List<ClassificationCriterionDto> criteria) =>
      this(criteria: criteria);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClassificationPolicyDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClassificationPolicyDto(...).copyWith(id: 12, name: "My name")
  /// ````
  ClassificationPolicyDto call({
    Object? version = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? roundingDigits = const $CopyWithPlaceholder(),
    Object? active = const $CopyWithPlaceholder(),
    Object? criteria = const $CopyWithPlaceholder(),
  }) {
    return ClassificationPolicyDto(
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      roundingDigits: roundingDigits == const $CopyWithPlaceholder()
          ? _value.roundingDigits
          // ignore: cast_nullable_to_non_nullable
          : roundingDigits as num,
      active: active == const $CopyWithPlaceholder()
          ? _value.active
          // ignore: cast_nullable_to_non_nullable
          : active as bool,
      criteria: criteria == const $CopyWithPlaceholder()
          ? _value.criteria
          // ignore: cast_nullable_to_non_nullable
          : criteria as List<ClassificationCriterionDto>,
    );
  }
}

extension $ClassificationPolicyDtoCopyWith on ClassificationPolicyDto {
  /// Returns a callable class that can be used as follows: `instanceOfClassificationPolicyDto.copyWith(...)` or like so:`instanceOfClassificationPolicyDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ClassificationPolicyDtoCWProxy get copyWith =>
      _$ClassificationPolicyDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassificationPolicyDto _$ClassificationPolicyDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ClassificationPolicyDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'version',
      'name',
      'roundingDigits',
      'active',
      'criteria',
    ],
  );
  final val = ClassificationPolicyDto(
    version: $checkedConvert('version', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    roundingDigits: $checkedConvert('roundingDigits', (v) => v as num),
    active: $checkedConvert('active', (v) => v as bool),
    criteria: $checkedConvert(
      'criteria',
      (v) => (v as List<dynamic>)
          .map(
            (e) =>
                ClassificationCriterionDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$ClassificationPolicyDtoToJson(
  ClassificationPolicyDto instance,
) => <String, dynamic>{
  'version': instance.version,
  'name': instance.name,
  'roundingDigits': instance.roundingDigits,
  'active': instance.active,
  'criteria': instance.criteria.map((e) => e.toJson()).toList(),
};
