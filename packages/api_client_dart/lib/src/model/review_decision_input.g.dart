// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_decision_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReviewDecisionInputCWProxy {
  ReviewDecisionInput rowId(String rowId);

  ReviewDecisionInput value(String? value);

  ReviewDecisionInput reason(String reason);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReviewDecisionInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReviewDecisionInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ReviewDecisionInput call({String rowId, String? value, String reason});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfReviewDecisionInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfReviewDecisionInput.copyWith.fieldName(...)`
class _$ReviewDecisionInputCWProxyImpl implements _$ReviewDecisionInputCWProxy {
  const _$ReviewDecisionInputCWProxyImpl(this._value);

  final ReviewDecisionInput _value;

  @override
  ReviewDecisionInput rowId(String rowId) => this(rowId: rowId);

  @override
  ReviewDecisionInput value(String? value) => this(value: value);

  @override
  ReviewDecisionInput reason(String reason) => this(reason: reason);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReviewDecisionInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReviewDecisionInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ReviewDecisionInput call({
    Object? rowId = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return ReviewDecisionInput(
      rowId: rowId == const $CopyWithPlaceholder()
          ? _value.rowId
          // ignore: cast_nullable_to_non_nullable
          : rowId as String,
      value: value == const $CopyWithPlaceholder()
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String?,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
    );
  }
}

extension $ReviewDecisionInputCopyWith on ReviewDecisionInput {
  /// Returns a callable class that can be used as follows: `instanceOfReviewDecisionInput.copyWith(...)` or like so:`instanceOfReviewDecisionInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReviewDecisionInputCWProxy get copyWith =>
      _$ReviewDecisionInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewDecisionInput _$ReviewDecisionInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReviewDecisionInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['rowId', 'value', 'reason']);
      final val = ReviewDecisionInput(
        rowId: $checkedConvert('rowId', (v) => v as String),
        value: $checkedConvert('value', (v) => v as String?),
        reason: $checkedConvert('reason', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ReviewDecisionInputToJson(
  ReviewDecisionInput instance,
) => <String, dynamic>{
  'rowId': instance.rowId,
  'value': instance.value,
  'reason': instance.reason,
};
