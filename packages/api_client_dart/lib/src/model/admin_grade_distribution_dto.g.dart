// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_grade_distribution_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminGradeDistributionDtoCWProxy {
  AdminGradeDistributionDto label(String label);

  AdminGradeDistributionDto code(String code);

  AdminGradeDistributionDto count(num count);

  AdminGradeDistributionDto percentage(num percentage);

  AdminGradeDistributionDto color(String color);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminGradeDistributionDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminGradeDistributionDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminGradeDistributionDto call({
    String label,
    String code,
    num count,
    num percentage,
    String color,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminGradeDistributionDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminGradeDistributionDto.copyWith.fieldName(...)`
class _$AdminGradeDistributionDtoCWProxyImpl
    implements _$AdminGradeDistributionDtoCWProxy {
  const _$AdminGradeDistributionDtoCWProxyImpl(this._value);

  final AdminGradeDistributionDto _value;

  @override
  AdminGradeDistributionDto label(String label) => this(label: label);

  @override
  AdminGradeDistributionDto code(String code) => this(code: code);

  @override
  AdminGradeDistributionDto count(num count) => this(count: count);

  @override
  AdminGradeDistributionDto percentage(num percentage) =>
      this(percentage: percentage);

  @override
  AdminGradeDistributionDto color(String color) => this(color: color);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminGradeDistributionDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminGradeDistributionDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminGradeDistributionDto call({
    Object? label = const $CopyWithPlaceholder(),
    Object? code = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
    Object? percentage = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
  }) {
    return AdminGradeDistributionDto(
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      count: count == const $CopyWithPlaceholder()
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as num,
      percentage: percentage == const $CopyWithPlaceholder()
          ? _value.percentage
          // ignore: cast_nullable_to_non_nullable
          : percentage as num,
      color: color == const $CopyWithPlaceholder()
          ? _value.color
          // ignore: cast_nullable_to_non_nullable
          : color as String,
    );
  }
}

extension $AdminGradeDistributionDtoCopyWith on AdminGradeDistributionDto {
  /// Returns a callable class that can be used as follows: `instanceOfAdminGradeDistributionDto.copyWith(...)` or like so:`instanceOfAdminGradeDistributionDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminGradeDistributionDtoCWProxy get copyWith =>
      _$AdminGradeDistributionDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminGradeDistributionDto _$AdminGradeDistributionDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminGradeDistributionDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['label', 'code', 'count', 'percentage', 'color'],
  );
  final val = AdminGradeDistributionDto(
    label: $checkedConvert('label', (v) => v as String),
    code: $checkedConvert('code', (v) => v as String),
    count: $checkedConvert('count', (v) => v as num),
    percentage: $checkedConvert('percentage', (v) => v as num),
    color: $checkedConvert('color', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$AdminGradeDistributionDtoToJson(
  AdminGradeDistributionDto instance,
) => <String, dynamic>{
  'label': instance.label,
  'code': instance.code,
  'count': instance.count,
  'percentage': instance.percentage,
  'color': instance.color,
};
