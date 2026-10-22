// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enrollment_list_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EnrollmentListDtoCWProxy {
  EnrollmentListDto items(List<EnrollmentDto> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EnrollmentListDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EnrollmentListDto(...).copyWith(id: 12, name: "My name")
  /// ````
  EnrollmentListDto call({List<EnrollmentDto> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfEnrollmentListDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfEnrollmentListDto.copyWith.fieldName(...)`
class _$EnrollmentListDtoCWProxyImpl implements _$EnrollmentListDtoCWProxy {
  const _$EnrollmentListDtoCWProxyImpl(this._value);

  final EnrollmentListDto _value;

  @override
  EnrollmentListDto items(List<EnrollmentDto> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EnrollmentListDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EnrollmentListDto(...).copyWith(id: 12, name: "My name")
  /// ````
  EnrollmentListDto call({Object? items = const $CopyWithPlaceholder()}) {
    return EnrollmentListDto(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<EnrollmentDto>,
    );
  }
}

extension $EnrollmentListDtoCopyWith on EnrollmentListDto {
  /// Returns a callable class that can be used as follows: `instanceOfEnrollmentListDto.copyWith(...)` or like so:`instanceOfEnrollmentListDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EnrollmentListDtoCWProxy get copyWith =>
      _$EnrollmentListDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnrollmentListDto _$EnrollmentListDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EnrollmentListDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = EnrollmentListDto(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => EnrollmentDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$EnrollmentListDtoToJson(EnrollmentListDto instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
