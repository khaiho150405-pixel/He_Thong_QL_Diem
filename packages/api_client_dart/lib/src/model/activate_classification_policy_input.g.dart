// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activate_classification_policy_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ActivateClassificationPolicyInputCWProxy {
  ActivateClassificationPolicyInput version(String version);

  ActivateClassificationPolicyInput name(String name);

  ActivateClassificationPolicyInput roundingDigits(num roundingDigits);

  ActivateClassificationPolicyInput criteria(
    List<ClassificationCriterionDto> criteria,
  );

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ActivateClassificationPolicyInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ActivateClassificationPolicyInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ActivateClassificationPolicyInput call({
    String version,
    String name,
    num roundingDigits,
    List<ClassificationCriterionDto> criteria,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfActivateClassificationPolicyInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfActivateClassificationPolicyInput.copyWith.fieldName(...)`
class _$ActivateClassificationPolicyInputCWProxyImpl
    implements _$ActivateClassificationPolicyInputCWProxy {
  const _$ActivateClassificationPolicyInputCWProxyImpl(this._value);

  final ActivateClassificationPolicyInput _value;

  @override
  ActivateClassificationPolicyInput version(String version) =>
      this(version: version);

  @override
  ActivateClassificationPolicyInput name(String name) => this(name: name);

  @override
  ActivateClassificationPolicyInput roundingDigits(num roundingDigits) =>
      this(roundingDigits: roundingDigits);

  @override
  ActivateClassificationPolicyInput criteria(
    List<ClassificationCriterionDto> criteria,
  ) => this(criteria: criteria);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ActivateClassificationPolicyInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ActivateClassificationPolicyInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ActivateClassificationPolicyInput call({
    Object? version = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? roundingDigits = const $CopyWithPlaceholder(),
    Object? criteria = const $CopyWithPlaceholder(),
  }) {
    return ActivateClassificationPolicyInput(
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
      criteria: criteria == const $CopyWithPlaceholder()
          ? _value.criteria
          // ignore: cast_nullable_to_non_nullable
          : criteria as List<ClassificationCriterionDto>,
    );
  }
}

extension $ActivateClassificationPolicyInputCopyWith
    on ActivateClassificationPolicyInput {
  /// Returns a callable class that can be used as follows: `instanceOfActivateClassificationPolicyInput.copyWith(...)` or like so:`instanceOfActivateClassificationPolicyInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ActivateClassificationPolicyInputCWProxy get copyWith =>
      _$ActivateClassificationPolicyInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivateClassificationPolicyInput _$ActivateClassificationPolicyInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ActivateClassificationPolicyInput', json, (
  $checkedConvert,
) {
  $checkKeys(
    json,
    requiredKeys: const ['version', 'name', 'roundingDigits', 'criteria'],
  );
  final val = ActivateClassificationPolicyInput(
    version: $checkedConvert('version', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    roundingDigits: $checkedConvert('roundingDigits', (v) => v as num),
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

Map<String, dynamic> _$ActivateClassificationPolicyInputToJson(
  ActivateClassificationPolicyInput instance,
) => <String, dynamic>{
  'version': instance.version,
  'name': instance.name,
  'roundingDigits': instance.roundingDigits,
  'criteria': instance.criteria.map((e) => e.toJson()).toList(),
};
