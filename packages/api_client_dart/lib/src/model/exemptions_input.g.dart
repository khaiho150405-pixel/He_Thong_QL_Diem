// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exemptions_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ExemptionsInputCWProxy {
  ExemptionsInput expectedVersion(num expectedVersion);

  ExemptionsInput changes(List<ExemptionChangeInput> changes);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExemptionsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExemptionsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ExemptionsInput call({
    num expectedVersion,
    List<ExemptionChangeInput> changes,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfExemptionsInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfExemptionsInput.copyWith.fieldName(...)`
class _$ExemptionsInputCWProxyImpl implements _$ExemptionsInputCWProxy {
  const _$ExemptionsInputCWProxyImpl(this._value);

  final ExemptionsInput _value;

  @override
  ExemptionsInput expectedVersion(num expectedVersion) =>
      this(expectedVersion: expectedVersion);

  @override
  ExemptionsInput changes(List<ExemptionChangeInput> changes) =>
      this(changes: changes);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExemptionsInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExemptionsInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ExemptionsInput call({
    Object? expectedVersion = const $CopyWithPlaceholder(),
    Object? changes = const $CopyWithPlaceholder(),
  }) {
    return ExemptionsInput(
      expectedVersion: expectedVersion == const $CopyWithPlaceholder()
          ? _value.expectedVersion
          // ignore: cast_nullable_to_non_nullable
          : expectedVersion as num,
      changes: changes == const $CopyWithPlaceholder()
          ? _value.changes
          // ignore: cast_nullable_to_non_nullable
          : changes as List<ExemptionChangeInput>,
    );
  }
}

extension $ExemptionsInputCopyWith on ExemptionsInput {
  /// Returns a callable class that can be used as follows: `instanceOfExemptionsInput.copyWith(...)` or like so:`instanceOfExemptionsInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ExemptionsInputCWProxy get copyWith => _$ExemptionsInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExemptionsInput _$ExemptionsInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ExemptionsInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['expectedVersion', 'changes']);
      final val = ExemptionsInput(
        expectedVersion: $checkedConvert('expectedVersion', (v) => v as num),
        changes: $checkedConvert(
          'changes',
          (v) => (v as List<dynamic>)
              .map(
                (e) => ExemptionChangeInput.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ExemptionsInputToJson(ExemptionsInput instance) =>
    <String, dynamic>{
      'expectedVersion': instance.expectedVersion,
      'changes': instance.changes.map((e) => e.toJson()).toList(),
    };
