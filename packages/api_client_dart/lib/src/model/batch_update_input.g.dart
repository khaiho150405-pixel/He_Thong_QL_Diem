// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_update_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BatchUpdateInputCWProxy {
  BatchUpdateInput expectedVersion(num expectedVersion);

  BatchUpdateInput changes(List<GradeChangeInput> changes);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BatchUpdateInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BatchUpdateInput(...).copyWith(id: 12, name: "My name")
  /// ````
  BatchUpdateInput call({num expectedVersion, List<GradeChangeInput> changes});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfBatchUpdateInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfBatchUpdateInput.copyWith.fieldName(...)`
class _$BatchUpdateInputCWProxyImpl implements _$BatchUpdateInputCWProxy {
  const _$BatchUpdateInputCWProxyImpl(this._value);

  final BatchUpdateInput _value;

  @override
  BatchUpdateInput expectedVersion(num expectedVersion) =>
      this(expectedVersion: expectedVersion);

  @override
  BatchUpdateInput changes(List<GradeChangeInput> changes) =>
      this(changes: changes);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BatchUpdateInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BatchUpdateInput(...).copyWith(id: 12, name: "My name")
  /// ````
  BatchUpdateInput call({
    Object? expectedVersion = const $CopyWithPlaceholder(),
    Object? changes = const $CopyWithPlaceholder(),
  }) {
    return BatchUpdateInput(
      expectedVersion: expectedVersion == const $CopyWithPlaceholder()
          ? _value.expectedVersion
          // ignore: cast_nullable_to_non_nullable
          : expectedVersion as num,
      changes: changes == const $CopyWithPlaceholder()
          ? _value.changes
          // ignore: cast_nullable_to_non_nullable
          : changes as List<GradeChangeInput>,
    );
  }
}

extension $BatchUpdateInputCopyWith on BatchUpdateInput {
  /// Returns a callable class that can be used as follows: `instanceOfBatchUpdateInput.copyWith(...)` or like so:`instanceOfBatchUpdateInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BatchUpdateInputCWProxy get copyWith => _$BatchUpdateInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BatchUpdateInput _$BatchUpdateInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BatchUpdateInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['expectedVersion', 'changes']);
      final val = BatchUpdateInput(
        expectedVersion: $checkedConvert('expectedVersion', (v) => v as num),
        changes: $checkedConvert(
          'changes',
          (v) => (v as List<dynamic>)
              .map((e) => GradeChangeInput.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$BatchUpdateInputToJson(BatchUpdateInput instance) =>
    <String, dynamic>{
      'expectedVersion': instance.expectedVersion,
      'changes': instance.changes.map((e) => e.toJson()).toList(),
    };
