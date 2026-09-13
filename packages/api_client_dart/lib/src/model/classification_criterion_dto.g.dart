// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classification_criterion_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ClassificationCriterionDtoCWProxy {
  ClassificationCriterionDto code(String code);

  ClassificationCriterionDto minimum(String minimum);

  ClassificationCriterionDto passing(bool passing);

  ClassificationCriterionDto order(num order);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClassificationCriterionDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClassificationCriterionDto(...).copyWith(id: 12, name: "My name")
  /// ````
  ClassificationCriterionDto call({
    String code,
    String minimum,
    bool passing,
    num order,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfClassificationCriterionDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfClassificationCriterionDto.copyWith.fieldName(...)`
class _$ClassificationCriterionDtoCWProxyImpl
    implements _$ClassificationCriterionDtoCWProxy {
  const _$ClassificationCriterionDtoCWProxyImpl(this._value);

  final ClassificationCriterionDto _value;

  @override
  ClassificationCriterionDto code(String code) => this(code: code);

  @override
  ClassificationCriterionDto minimum(String minimum) => this(minimum: minimum);

  @override
  ClassificationCriterionDto passing(bool passing) => this(passing: passing);

  @override
  ClassificationCriterionDto order(num order) => this(order: order);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClassificationCriterionDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClassificationCriterionDto(...).copyWith(id: 12, name: "My name")
  /// ````
  ClassificationCriterionDto call({
    Object? code = const $CopyWithPlaceholder(),
    Object? minimum = const $CopyWithPlaceholder(),
    Object? passing = const $CopyWithPlaceholder(),
    Object? order = const $CopyWithPlaceholder(),
  }) {
    return ClassificationCriterionDto(
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      minimum: minimum == const $CopyWithPlaceholder()
          ? _value.minimum
          // ignore: cast_nullable_to_non_nullable
          : minimum as String,
      passing: passing == const $CopyWithPlaceholder()
          ? _value.passing
          // ignore: cast_nullable_to_non_nullable
          : passing as bool,
      order: order == const $CopyWithPlaceholder()
          ? _value.order
          // ignore: cast_nullable_to_non_nullable
          : order as num,
    );
  }
}

extension $ClassificationCriterionDtoCopyWith on ClassificationCriterionDto {
  /// Returns a callable class that can be used as follows: `instanceOfClassificationCriterionDto.copyWith(...)` or like so:`instanceOfClassificationCriterionDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ClassificationCriterionDtoCWProxy get copyWith =>
      _$ClassificationCriterionDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassificationCriterionDto _$ClassificationCriterionDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ClassificationCriterionDto', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['code', 'minimum', 'passing', 'order']);
  final val = ClassificationCriterionDto(
    code: $checkedConvert('code', (v) => v as String),
    minimum: $checkedConvert('minimum', (v) => v as String),
    passing: $checkedConvert('passing', (v) => v as bool),
    order: $checkedConvert('order', (v) => v as num),
  );
  return val;
});

Map<String, dynamic> _$ClassificationCriterionDtoToJson(
  ClassificationCriterionDto instance,
) => <String, dynamic>{
  'code': instance.code,
  'minimum': instance.minimum,
  'passing': instance.passing,
  'order': instance.order,
};
