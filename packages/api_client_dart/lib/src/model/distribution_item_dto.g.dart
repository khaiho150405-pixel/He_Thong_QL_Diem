// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'distribution_item_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DistributionItemDtoCWProxy {
  DistributionItemDto classification(String classification);

  DistributionItemDto students(num students);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DistributionItemDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DistributionItemDto(...).copyWith(id: 12, name: "My name")
  /// ````
  DistributionItemDto call({String classification, num students});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDistributionItemDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDistributionItemDto.copyWith.fieldName(...)`
class _$DistributionItemDtoCWProxyImpl implements _$DistributionItemDtoCWProxy {
  const _$DistributionItemDtoCWProxyImpl(this._value);

  final DistributionItemDto _value;

  @override
  DistributionItemDto classification(String classification) =>
      this(classification: classification);

  @override
  DistributionItemDto students(num students) => this(students: students);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DistributionItemDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DistributionItemDto(...).copyWith(id: 12, name: "My name")
  /// ````
  DistributionItemDto call({
    Object? classification = const $CopyWithPlaceholder(),
    Object? students = const $CopyWithPlaceholder(),
  }) {
    return DistributionItemDto(
      classification: classification == const $CopyWithPlaceholder()
          ? _value.classification
          // ignore: cast_nullable_to_non_nullable
          : classification as String,
      students: students == const $CopyWithPlaceholder()
          ? _value.students
          // ignore: cast_nullable_to_non_nullable
          : students as num,
    );
  }
}

extension $DistributionItemDtoCopyWith on DistributionItemDto {
  /// Returns a callable class that can be used as follows: `instanceOfDistributionItemDto.copyWith(...)` or like so:`instanceOfDistributionItemDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DistributionItemDtoCWProxy get copyWith =>
      _$DistributionItemDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DistributionItemDto _$DistributionItemDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DistributionItemDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['classification', 'students']);
      final val = DistributionItemDto(
        classification: $checkedConvert('classification', (v) => v as String),
        students: $checkedConvert('students', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$DistributionItemDtoToJson(
  DistributionItemDto instance,
) => <String, dynamic>{
  'classification': instance.classification,
  'students': instance.students,
};
