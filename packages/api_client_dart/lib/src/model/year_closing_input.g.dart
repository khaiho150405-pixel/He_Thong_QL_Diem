// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'year_closing_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$YearClosingInputCWProxy {
  YearClosingInput reason(String reason);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearClosingInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearClosingInput(...).copyWith(id: 12, name: "My name")
  /// ````
  YearClosingInput call({String reason});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfYearClosingInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfYearClosingInput.copyWith.fieldName(...)`
class _$YearClosingInputCWProxyImpl implements _$YearClosingInputCWProxy {
  const _$YearClosingInputCWProxyImpl(this._value);

  final YearClosingInput _value;

  @override
  YearClosingInput reason(String reason) => this(reason: reason);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearClosingInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearClosingInput(...).copyWith(id: 12, name: "My name")
  /// ````
  YearClosingInput call({Object? reason = const $CopyWithPlaceholder()}) {
    return YearClosingInput(
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
    );
  }
}

extension $YearClosingInputCopyWith on YearClosingInput {
  /// Returns a callable class that can be used as follows: `instanceOfYearClosingInput.copyWith(...)` or like so:`instanceOfYearClosingInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$YearClosingInputCWProxy get copyWith => _$YearClosingInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YearClosingInput _$YearClosingInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('YearClosingInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reason']);
      final val = YearClosingInput(
        reason: $checkedConvert('reason', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$YearClosingInputToJson(YearClosingInput instance) =>
    <String, dynamic>{'reason': instance.reason};
