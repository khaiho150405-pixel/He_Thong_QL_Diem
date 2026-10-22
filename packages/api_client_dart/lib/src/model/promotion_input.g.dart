// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PromotionInputCWProxy {
  PromotionInput targetYearId(num targetYearId);

  PromotionInput items(List<PromotionItemInput> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PromotionInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PromotionInput(...).copyWith(id: 12, name: "My name")
  /// ````
  PromotionInput call({num targetYearId, List<PromotionItemInput> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPromotionInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPromotionInput.copyWith.fieldName(...)`
class _$PromotionInputCWProxyImpl implements _$PromotionInputCWProxy {
  const _$PromotionInputCWProxyImpl(this._value);

  final PromotionInput _value;

  @override
  PromotionInput targetYearId(num targetYearId) =>
      this(targetYearId: targetYearId);

  @override
  PromotionInput items(List<PromotionItemInput> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PromotionInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PromotionInput(...).copyWith(id: 12, name: "My name")
  /// ````
  PromotionInput call({
    Object? targetYearId = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return PromotionInput(
      targetYearId: targetYearId == const $CopyWithPlaceholder()
          ? _value.targetYearId
          // ignore: cast_nullable_to_non_nullable
          : targetYearId as num,
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<PromotionItemInput>,
    );
  }
}

extension $PromotionInputCopyWith on PromotionInput {
  /// Returns a callable class that can be used as follows: `instanceOfPromotionInput.copyWith(...)` or like so:`instanceOfPromotionInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PromotionInputCWProxy get copyWith => _$PromotionInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromotionInput _$PromotionInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PromotionInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['targetYearId', 'items']);
      final val = PromotionInput(
        targetYearId: $checkedConvert('targetYearId', (v) => v as num),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => PromotionItemInput.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PromotionInputToJson(PromotionInput instance) =>
    <String, dynamic>{
      'targetYearId': instance.targetYearId,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };
