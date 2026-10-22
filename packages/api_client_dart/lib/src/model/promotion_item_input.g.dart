// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_item_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PromotionItemInputCWProxy {
  PromotionItemInput studentId(num studentId);

  PromotionItemInput action(PromotionItemInputActionEnum action);

  PromotionItemInput targetClassId(num? targetClassId);

  PromotionItemInput reason(String? reason);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PromotionItemInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PromotionItemInput(...).copyWith(id: 12, name: "My name")
  /// ````
  PromotionItemInput call({
    num studentId,
    PromotionItemInputActionEnum action,
    num? targetClassId,
    String? reason,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPromotionItemInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPromotionItemInput.copyWith.fieldName(...)`
class _$PromotionItemInputCWProxyImpl implements _$PromotionItemInputCWProxy {
  const _$PromotionItemInputCWProxyImpl(this._value);

  final PromotionItemInput _value;

  @override
  PromotionItemInput studentId(num studentId) => this(studentId: studentId);

  @override
  PromotionItemInput action(PromotionItemInputActionEnum action) =>
      this(action: action);

  @override
  PromotionItemInput targetClassId(num? targetClassId) =>
      this(targetClassId: targetClassId);

  @override
  PromotionItemInput reason(String? reason) => this(reason: reason);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PromotionItemInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PromotionItemInput(...).copyWith(id: 12, name: "My name")
  /// ````
  PromotionItemInput call({
    Object? studentId = const $CopyWithPlaceholder(),
    Object? action = const $CopyWithPlaceholder(),
    Object? targetClassId = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return PromotionItemInput(
      studentId: studentId == const $CopyWithPlaceholder()
          ? _value.studentId
          // ignore: cast_nullable_to_non_nullable
          : studentId as num,
      action: action == const $CopyWithPlaceholder()
          ? _value.action
          // ignore: cast_nullable_to_non_nullable
          : action as PromotionItemInputActionEnum,
      targetClassId: targetClassId == const $CopyWithPlaceholder()
          ? _value.targetClassId
          // ignore: cast_nullable_to_non_nullable
          : targetClassId as num?,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String?,
    );
  }
}

extension $PromotionItemInputCopyWith on PromotionItemInput {
  /// Returns a callable class that can be used as follows: `instanceOfPromotionItemInput.copyWith(...)` or like so:`instanceOfPromotionItemInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PromotionItemInputCWProxy get copyWith =>
      _$PromotionItemInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromotionItemInput _$PromotionItemInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PromotionItemInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['studentId', 'action']);
      final val = PromotionItemInput(
        studentId: $checkedConvert('studentId', (v) => v as num),
        action: $checkedConvert(
          'action',
          (v) => $enumDecode(_$PromotionItemInputActionEnumEnumMap, v),
        ),
        targetClassId: $checkedConvert('targetClassId', (v) => v as num?),
        reason: $checkedConvert('reason', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$PromotionItemInputToJson(PromotionItemInput instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'action': _$PromotionItemInputActionEnumEnumMap[instance.action]!,
      'targetClassId': ?instance.targetClassId,
      'reason': ?instance.reason,
    };

const _$PromotionItemInputActionEnumEnumMap = {
  PromotionItemInputActionEnum.LEN_LOP: 'LEN_LOP',
  PromotionItemInputActionEnum.LUU_BAN: 'LUU_BAN',
  PromotionItemInputActionEnum.TOT_NGHIEP: 'TOT_NGHIEP',
  PromotionItemInputActionEnum.NGHI_HOC: 'NGHI_HOC',
};
