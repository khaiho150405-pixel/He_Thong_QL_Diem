// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'late_student_result_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LateStudentResultDtoCWProxy {
  LateStudentResultDto bookId(num bookId);

  LateStudentResultDto version(num version);

  LateStudentResultDto createdCells(num createdCells);

  LateStudentResultDto exemptedCells(num exemptedCells);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LateStudentResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LateStudentResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  LateStudentResultDto call({
    num bookId,
    num version,
    num createdCells,
    num exemptedCells,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLateStudentResultDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLateStudentResultDto.copyWith.fieldName(...)`
class _$LateStudentResultDtoCWProxyImpl
    implements _$LateStudentResultDtoCWProxy {
  const _$LateStudentResultDtoCWProxyImpl(this._value);

  final LateStudentResultDto _value;

  @override
  LateStudentResultDto bookId(num bookId) => this(bookId: bookId);

  @override
  LateStudentResultDto version(num version) => this(version: version);

  @override
  LateStudentResultDto createdCells(num createdCells) =>
      this(createdCells: createdCells);

  @override
  LateStudentResultDto exemptedCells(num exemptedCells) =>
      this(exemptedCells: exemptedCells);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LateStudentResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LateStudentResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  LateStudentResultDto call({
    Object? bookId = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? createdCells = const $CopyWithPlaceholder(),
    Object? exemptedCells = const $CopyWithPlaceholder(),
  }) {
    return LateStudentResultDto(
      bookId: bookId == const $CopyWithPlaceholder()
          ? _value.bookId
          // ignore: cast_nullable_to_non_nullable
          : bookId as num,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as num,
      createdCells: createdCells == const $CopyWithPlaceholder()
          ? _value.createdCells
          // ignore: cast_nullable_to_non_nullable
          : createdCells as num,
      exemptedCells: exemptedCells == const $CopyWithPlaceholder()
          ? _value.exemptedCells
          // ignore: cast_nullable_to_non_nullable
          : exemptedCells as num,
    );
  }
}

extension $LateStudentResultDtoCopyWith on LateStudentResultDto {
  /// Returns a callable class that can be used as follows: `instanceOfLateStudentResultDto.copyWith(...)` or like so:`instanceOfLateStudentResultDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LateStudentResultDtoCWProxy get copyWith =>
      _$LateStudentResultDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LateStudentResultDto _$LateStudentResultDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('LateStudentResultDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['bookId', 'version', 'createdCells', 'exemptedCells'],
  );
  final val = LateStudentResultDto(
    bookId: $checkedConvert('bookId', (v) => v as num),
    version: $checkedConvert('version', (v) => v as num),
    createdCells: $checkedConvert('createdCells', (v) => v as num),
    exemptedCells: $checkedConvert('exemptedCells', (v) => v as num),
  );
  return val;
});

Map<String, dynamic> _$LateStudentResultDtoToJson(
  LateStudentResultDto instance,
) => <String, dynamic>{
  'bookId': instance.bookId,
  'version': instance.version,
  'createdCells': instance.createdCells,
  'exemptedCells': instance.exemptedCells,
};
