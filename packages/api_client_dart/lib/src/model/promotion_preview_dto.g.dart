// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_preview_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PromotionPreviewDtoCWProxy {
  PromotionPreviewDto sourceClass(PromotionSourceClassDto sourceClass);

  PromotionPreviewDto targetYear(PromotionTargetYearDto targetYear);

  PromotionPreviewDto targetClasses(List<PromotionClassDto> targetClasses);

  PromotionPreviewDto items(List<PromotionPreviewItemDto> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PromotionPreviewDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PromotionPreviewDto(...).copyWith(id: 12, name: "My name")
  /// ````
  PromotionPreviewDto call({
    PromotionSourceClassDto sourceClass,
    PromotionTargetYearDto targetYear,
    List<PromotionClassDto> targetClasses,
    List<PromotionPreviewItemDto> items,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPromotionPreviewDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPromotionPreviewDto.copyWith.fieldName(...)`
class _$PromotionPreviewDtoCWProxyImpl implements _$PromotionPreviewDtoCWProxy {
  const _$PromotionPreviewDtoCWProxyImpl(this._value);

  final PromotionPreviewDto _value;

  @override
  PromotionPreviewDto sourceClass(PromotionSourceClassDto sourceClass) =>
      this(sourceClass: sourceClass);

  @override
  PromotionPreviewDto targetYear(PromotionTargetYearDto targetYear) =>
      this(targetYear: targetYear);

  @override
  PromotionPreviewDto targetClasses(List<PromotionClassDto> targetClasses) =>
      this(targetClasses: targetClasses);

  @override
  PromotionPreviewDto items(List<PromotionPreviewItemDto> items) =>
      this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PromotionPreviewDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PromotionPreviewDto(...).copyWith(id: 12, name: "My name")
  /// ````
  PromotionPreviewDto call({
    Object? sourceClass = const $CopyWithPlaceholder(),
    Object? targetYear = const $CopyWithPlaceholder(),
    Object? targetClasses = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return PromotionPreviewDto(
      sourceClass: sourceClass == const $CopyWithPlaceholder()
          ? _value.sourceClass
          // ignore: cast_nullable_to_non_nullable
          : sourceClass as PromotionSourceClassDto,
      targetYear: targetYear == const $CopyWithPlaceholder()
          ? _value.targetYear
          // ignore: cast_nullable_to_non_nullable
          : targetYear as PromotionTargetYearDto,
      targetClasses: targetClasses == const $CopyWithPlaceholder()
          ? _value.targetClasses
          // ignore: cast_nullable_to_non_nullable
          : targetClasses as List<PromotionClassDto>,
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<PromotionPreviewItemDto>,
    );
  }
}

extension $PromotionPreviewDtoCopyWith on PromotionPreviewDto {
  /// Returns a callable class that can be used as follows: `instanceOfPromotionPreviewDto.copyWith(...)` or like so:`instanceOfPromotionPreviewDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PromotionPreviewDtoCWProxy get copyWith =>
      _$PromotionPreviewDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromotionPreviewDto _$PromotionPreviewDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PromotionPreviewDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'sourceClass',
          'targetYear',
          'targetClasses',
          'items',
        ],
      );
      final val = PromotionPreviewDto(
        sourceClass: $checkedConvert(
          'sourceClass',
          (v) => PromotionSourceClassDto.fromJson(v as Map<String, dynamic>),
        ),
        targetYear: $checkedConvert(
          'targetYear',
          (v) => PromotionTargetYearDto.fromJson(v as Map<String, dynamic>),
        ),
        targetClasses: $checkedConvert(
          'targetClasses',
          (v) => (v as List<dynamic>)
              .map((e) => PromotionClassDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) =>
                    PromotionPreviewItemDto.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PromotionPreviewDtoToJson(
  PromotionPreviewDto instance,
) => <String, dynamic>{
  'sourceClass': instance.sourceClass.toJson(),
  'targetYear': instance.targetYear.toJson(),
  'targetClasses': instance.targetClasses.map((e) => e.toJson()).toList(),
  'items': instance.items.map((e) => e.toJson()).toList(),
};
