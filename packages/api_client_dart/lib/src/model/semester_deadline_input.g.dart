// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semester_deadline_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SemesterDeadlineInputCWProxy {
  SemesterDeadlineInput opensAt(DateTime opensAt);

  SemesterDeadlineInput closesAt(DateTime closesAt);

  SemesterDeadlineInput expectedVersion(num expectedVersion);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SemesterDeadlineInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SemesterDeadlineInput(...).copyWith(id: 12, name: "My name")
  /// ````
  SemesterDeadlineInput call({
    DateTime opensAt,
    DateTime closesAt,
    num expectedVersion,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSemesterDeadlineInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSemesterDeadlineInput.copyWith.fieldName(...)`
class _$SemesterDeadlineInputCWProxyImpl
    implements _$SemesterDeadlineInputCWProxy {
  const _$SemesterDeadlineInputCWProxyImpl(this._value);

  final SemesterDeadlineInput _value;

  @override
  SemesterDeadlineInput opensAt(DateTime opensAt) => this(opensAt: opensAt);

  @override
  SemesterDeadlineInput closesAt(DateTime closesAt) => this(closesAt: closesAt);

  @override
  SemesterDeadlineInput expectedVersion(num expectedVersion) =>
      this(expectedVersion: expectedVersion);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SemesterDeadlineInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SemesterDeadlineInput(...).copyWith(id: 12, name: "My name")
  /// ````
  SemesterDeadlineInput call({
    Object? opensAt = const $CopyWithPlaceholder(),
    Object? closesAt = const $CopyWithPlaceholder(),
    Object? expectedVersion = const $CopyWithPlaceholder(),
  }) {
    return SemesterDeadlineInput(
      opensAt: opensAt == const $CopyWithPlaceholder()
          ? _value.opensAt
          // ignore: cast_nullable_to_non_nullable
          : opensAt as DateTime,
      closesAt: closesAt == const $CopyWithPlaceholder()
          ? _value.closesAt
          // ignore: cast_nullable_to_non_nullable
          : closesAt as DateTime,
      expectedVersion: expectedVersion == const $CopyWithPlaceholder()
          ? _value.expectedVersion
          // ignore: cast_nullable_to_non_nullable
          : expectedVersion as num,
    );
  }
}

extension $SemesterDeadlineInputCopyWith on SemesterDeadlineInput {
  /// Returns a callable class that can be used as follows: `instanceOfSemesterDeadlineInput.copyWith(...)` or like so:`instanceOfSemesterDeadlineInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SemesterDeadlineInputCWProxy get copyWith =>
      _$SemesterDeadlineInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SemesterDeadlineInput _$SemesterDeadlineInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SemesterDeadlineInput', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['opensAt', 'closesAt', 'expectedVersion'],
  );
  final val = SemesterDeadlineInput(
    opensAt: $checkedConvert('opensAt', (v) => DateTime.parse(v as String)),
    closesAt: $checkedConvert('closesAt', (v) => DateTime.parse(v as String)),
    expectedVersion: $checkedConvert('expectedVersion', (v) => v as num),
  );
  return val;
});

Map<String, dynamic> _$SemesterDeadlineInputToJson(
  SemesterDeadlineInput instance,
) => <String, dynamic>{
  'opensAt': instance.opensAt.toIso8601String(),
  'closesAt': instance.closesAt.toIso8601String(),
  'expectedVersion': instance.expectedVersion,
};
