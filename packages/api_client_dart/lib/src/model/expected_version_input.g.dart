// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expected_version_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ExpectedVersionInputCWProxy {
  ExpectedVersionInput expectedVersion(num expectedVersion);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExpectedVersionInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExpectedVersionInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ExpectedVersionInput call({num expectedVersion});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfExpectedVersionInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfExpectedVersionInput.copyWith.fieldName(...)`
class _$ExpectedVersionInputCWProxyImpl
    implements _$ExpectedVersionInputCWProxy {
  const _$ExpectedVersionInputCWProxyImpl(this._value);

  final ExpectedVersionInput _value;

  @override
  ExpectedVersionInput expectedVersion(num expectedVersion) =>
      this(expectedVersion: expectedVersion);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExpectedVersionInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExpectedVersionInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ExpectedVersionInput call({
    Object? expectedVersion = const $CopyWithPlaceholder(),
  }) {
    return ExpectedVersionInput(
      expectedVersion: expectedVersion == const $CopyWithPlaceholder()
          ? _value.expectedVersion
          // ignore: cast_nullable_to_non_nullable
          : expectedVersion as num,
    );
  }
}

extension $ExpectedVersionInputCopyWith on ExpectedVersionInput {
  /// Returns a callable class that can be used as follows: `instanceOfExpectedVersionInput.copyWith(...)` or like so:`instanceOfExpectedVersionInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ExpectedVersionInputCWProxy get copyWith =>
      _$ExpectedVersionInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpectedVersionInput _$ExpectedVersionInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ExpectedVersionInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['expectedVersion']);
  final val = ExpectedVersionInput(
    expectedVersion: $checkedConvert('expectedVersion', (v) => v as num),
  );
  return val;
});

Map<String, dynamic> _$ExpectedVersionInputToJson(
  ExpectedVersionInput instance,
) => <String, dynamic>{'expectedVersion': instance.expectedVersion};
