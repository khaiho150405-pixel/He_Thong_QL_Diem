// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'year_comparison_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$YearComparisonDtoCWProxy {
  YearComparisonDto items(List<YearComparisonItemDto> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearComparisonDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearComparisonDto(...).copyWith(id: 12, name: "My name")
  /// ````
  YearComparisonDto call({List<YearComparisonItemDto> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfYearComparisonDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfYearComparisonDto.copyWith.fieldName(...)`
class _$YearComparisonDtoCWProxyImpl implements _$YearComparisonDtoCWProxy {
  const _$YearComparisonDtoCWProxyImpl(this._value);

  final YearComparisonDto _value;

  @override
  YearComparisonDto items(List<YearComparisonItemDto> items) =>
      this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearComparisonDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearComparisonDto(...).copyWith(id: 12, name: "My name")
  /// ````
  YearComparisonDto call({Object? items = const $CopyWithPlaceholder()}) {
    return YearComparisonDto(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<YearComparisonItemDto>,
    );
  }
}

extension $YearComparisonDtoCopyWith on YearComparisonDto {
  /// Returns a callable class that can be used as follows: `instanceOfYearComparisonDto.copyWith(...)` or like so:`instanceOfYearComparisonDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$YearComparisonDtoCWProxy get copyWith =>
      _$YearComparisonDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YearComparisonDto _$YearComparisonDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('YearComparisonDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = YearComparisonDto(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) =>
                    YearComparisonItemDto.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$YearComparisonDtoToJson(YearComparisonDto instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
