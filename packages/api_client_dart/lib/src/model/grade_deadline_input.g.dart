// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grade_deadline_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GradeDeadlineInputCWProxy {
  GradeDeadlineInput opensAt(DateTime opensAt);

  GradeDeadlineInput closesAt(DateTime closesAt);

  GradeDeadlineInput expectedVersion(num expectedVersion);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradeDeadlineInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradeDeadlineInput(...).copyWith(id: 12, name: "My name")
  /// ````
  GradeDeadlineInput call({
    DateTime opensAt,
    DateTime closesAt,
    num expectedVersion,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGradeDeadlineInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGradeDeadlineInput.copyWith.fieldName(...)`
class _$GradeDeadlineInputCWProxyImpl implements _$GradeDeadlineInputCWProxy {
  const _$GradeDeadlineInputCWProxyImpl(this._value);

  final GradeDeadlineInput _value;

  @override
  GradeDeadlineInput opensAt(DateTime opensAt) => this(opensAt: opensAt);

  @override
  GradeDeadlineInput closesAt(DateTime closesAt) => this(closesAt: closesAt);

  @override
  GradeDeadlineInput expectedVersion(num expectedVersion) =>
      this(expectedVersion: expectedVersion);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradeDeadlineInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradeDeadlineInput(...).copyWith(id: 12, name: "My name")
  /// ````
  GradeDeadlineInput call({
    Object? opensAt = const $CopyWithPlaceholder(),
    Object? closesAt = const $CopyWithPlaceholder(),
    Object? expectedVersion = const $CopyWithPlaceholder(),
  }) {
    return GradeDeadlineInput(
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

extension $GradeDeadlineInputCopyWith on GradeDeadlineInput {
  /// Returns a callable class that can be used as follows: `instanceOfGradeDeadlineInput.copyWith(...)` or like so:`instanceOfGradeDeadlineInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GradeDeadlineInputCWProxy get copyWith =>
      _$GradeDeadlineInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GradeDeadlineInput _$GradeDeadlineInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GradeDeadlineInput', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['opensAt', 'closesAt', 'expectedVersion'],
      );
      final val = GradeDeadlineInput(
        opensAt: $checkedConvert('opensAt', (v) => DateTime.parse(v as String)),
        closesAt: $checkedConvert(
          'closesAt',
          (v) => DateTime.parse(v as String),
        ),
        expectedVersion: $checkedConvert('expectedVersion', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$GradeDeadlineInputToJson(GradeDeadlineInput instance) =>
    <String, dynamic>{
      'opensAt': instance.opensAt.toIso8601String(),
      'closesAt': instance.closesAt.toIso8601String(),
      'expectedVersion': instance.expectedVersion,
    };
