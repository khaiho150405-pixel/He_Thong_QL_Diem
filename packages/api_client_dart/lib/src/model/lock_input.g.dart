// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lock_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LockInputCWProxy {
  LockInput expectedVersion(num expectedVersion);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LockInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LockInput(...).copyWith(id: 12, name: "My name")
  /// ````
  LockInput call({num expectedVersion});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLockInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLockInput.copyWith.fieldName(...)`
class _$LockInputCWProxyImpl implements _$LockInputCWProxy {
  const _$LockInputCWProxyImpl(this._value);

  final LockInput _value;

  @override
  LockInput expectedVersion(num expectedVersion) =>
      this(expectedVersion: expectedVersion);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LockInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LockInput(...).copyWith(id: 12, name: "My name")
  /// ````
  LockInput call({Object? expectedVersion = const $CopyWithPlaceholder()}) {
    return LockInput(
      expectedVersion: expectedVersion == const $CopyWithPlaceholder()
          ? _value.expectedVersion
          // ignore: cast_nullable_to_non_nullable
          : expectedVersion as num,
    );
  }
}

extension $LockInputCopyWith on LockInput {
  /// Returns a callable class that can be used as follows: `instanceOfLockInput.copyWith(...)` or like so:`instanceOfLockInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LockInputCWProxy get copyWith => _$LockInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LockInput _$LockInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LockInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['expectedVersion']);
      final val = LockInput(
        expectedVersion: $checkedConvert('expectedVersion', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$LockInputToJson(LockInput instance) => <String, dynamic>{
  'expectedVersion': instance.expectedVersion,
};
