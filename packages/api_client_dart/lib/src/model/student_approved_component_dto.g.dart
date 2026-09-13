// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_approved_component_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StudentApprovedComponentDtoCWProxy {
  StudentApprovedComponentDto componentId(num componentId);

  StudentApprovedComponentDto componentName(String componentName);

  StudentApprovedComponentDto coefficient(String coefficient);

  StudentApprovedComponentDto value(String value);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentApprovedComponentDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentApprovedComponentDto(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentApprovedComponentDto call({
    num componentId,
    String componentName,
    String coefficient,
    String value,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStudentApprovedComponentDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStudentApprovedComponentDto.copyWith.fieldName(...)`
class _$StudentApprovedComponentDtoCWProxyImpl
    implements _$StudentApprovedComponentDtoCWProxy {
  const _$StudentApprovedComponentDtoCWProxyImpl(this._value);

  final StudentApprovedComponentDto _value;

  @override
  StudentApprovedComponentDto componentId(num componentId) =>
      this(componentId: componentId);

  @override
  StudentApprovedComponentDto componentName(String componentName) =>
      this(componentName: componentName);

  @override
  StudentApprovedComponentDto coefficient(String coefficient) =>
      this(coefficient: coefficient);

  @override
  StudentApprovedComponentDto value(String value) => this(value: value);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentApprovedComponentDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentApprovedComponentDto(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentApprovedComponentDto call({
    Object? componentId = const $CopyWithPlaceholder(),
    Object? componentName = const $CopyWithPlaceholder(),
    Object? coefficient = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return StudentApprovedComponentDto(
      componentId: componentId == const $CopyWithPlaceholder()
          ? _value.componentId
          // ignore: cast_nullable_to_non_nullable
          : componentId as num,
      componentName: componentName == const $CopyWithPlaceholder()
          ? _value.componentName
          // ignore: cast_nullable_to_non_nullable
          : componentName as String,
      coefficient: coefficient == const $CopyWithPlaceholder()
          ? _value.coefficient
          // ignore: cast_nullable_to_non_nullable
          : coefficient as String,
      value: value == const $CopyWithPlaceholder()
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String,
    );
  }
}

extension $StudentApprovedComponentDtoCopyWith on StudentApprovedComponentDto {
  /// Returns a callable class that can be used as follows: `instanceOfStudentApprovedComponentDto.copyWith(...)` or like so:`instanceOfStudentApprovedComponentDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StudentApprovedComponentDtoCWProxy get copyWith =>
      _$StudentApprovedComponentDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentApprovedComponentDto _$StudentApprovedComponentDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('StudentApprovedComponentDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'componentId',
      'componentName',
      'coefficient',
      'value',
    ],
  );
  final val = StudentApprovedComponentDto(
    componentId: $checkedConvert('componentId', (v) => v as num),
    componentName: $checkedConvert('componentName', (v) => v as String),
    coefficient: $checkedConvert('coefficient', (v) => v as String),
    value: $checkedConvert('value', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$StudentApprovedComponentDtoToJson(
  StudentApprovedComponentDto instance,
) => <String, dynamic>{
  'componentId': instance.componentId,
  'componentName': instance.componentName,
  'coefficient': instance.coefficient,
  'value': instance.value,
};
