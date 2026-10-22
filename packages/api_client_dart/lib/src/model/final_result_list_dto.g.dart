// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'final_result_list_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FinalResultListDtoCWProxy {
  FinalResultListDto items(List<FinalResultDto> items);

  FinalResultListDto nextCursor(String? nextCursor);

  FinalResultListDto exemptedStudents(num exemptedStudents);

  FinalResultListDto exempted(List<ExemptedStudentDto> exempted);

  FinalResultListDto skippedStudents(num skippedStudents);

  FinalResultListDto skipped(List<SkippedStudentDto> skipped);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FinalResultListDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FinalResultListDto(...).copyWith(id: 12, name: "My name")
  /// ````
  FinalResultListDto call({
    List<FinalResultDto> items,
    String? nextCursor,
    num exemptedStudents,
    List<ExemptedStudentDto> exempted,
    num skippedStudents,
    List<SkippedStudentDto> skipped,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFinalResultListDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFinalResultListDto.copyWith.fieldName(...)`
class _$FinalResultListDtoCWProxyImpl implements _$FinalResultListDtoCWProxy {
  const _$FinalResultListDtoCWProxyImpl(this._value);

  final FinalResultListDto _value;

  @override
  FinalResultListDto items(List<FinalResultDto> items) => this(items: items);

  @override
  FinalResultListDto nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  FinalResultListDto exemptedStudents(num exemptedStudents) =>
      this(exemptedStudents: exemptedStudents);

  @override
  FinalResultListDto exempted(List<ExemptedStudentDto> exempted) =>
      this(exempted: exempted);

  @override
  FinalResultListDto skippedStudents(num skippedStudents) =>
      this(skippedStudents: skippedStudents);

  @override
  FinalResultListDto skipped(List<SkippedStudentDto> skipped) =>
      this(skipped: skipped);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FinalResultListDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FinalResultListDto(...).copyWith(id: 12, name: "My name")
  /// ````
  FinalResultListDto call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
    Object? exemptedStudents = const $CopyWithPlaceholder(),
    Object? exempted = const $CopyWithPlaceholder(),
    Object? skippedStudents = const $CopyWithPlaceholder(),
    Object? skipped = const $CopyWithPlaceholder(),
  }) {
    return FinalResultListDto(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<FinalResultDto>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
      exemptedStudents: exemptedStudents == const $CopyWithPlaceholder()
          ? _value.exemptedStudents
          // ignore: cast_nullable_to_non_nullable
          : exemptedStudents as num,
      exempted: exempted == const $CopyWithPlaceholder()
          ? _value.exempted
          // ignore: cast_nullable_to_non_nullable
          : exempted as List<ExemptedStudentDto>,
      skippedStudents: skippedStudents == const $CopyWithPlaceholder()
          ? _value.skippedStudents
          // ignore: cast_nullable_to_non_nullable
          : skippedStudents as num,
      skipped: skipped == const $CopyWithPlaceholder()
          ? _value.skipped
          // ignore: cast_nullable_to_non_nullable
          : skipped as List<SkippedStudentDto>,
    );
  }
}

extension $FinalResultListDtoCopyWith on FinalResultListDto {
  /// Returns a callable class that can be used as follows: `instanceOfFinalResultListDto.copyWith(...)` or like so:`instanceOfFinalResultListDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FinalResultListDtoCWProxy get copyWith =>
      _$FinalResultListDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FinalResultListDto _$FinalResultListDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FinalResultListDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'items',
          'nextCursor',
          'exemptedStudents',
          'exempted',
          'skippedStudents',
          'skipped',
        ],
      );
      final val = FinalResultListDto(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => FinalResultDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
        exemptedStudents: $checkedConvert('exemptedStudents', (v) => v as num),
        exempted: $checkedConvert(
          'exempted',
          (v) => (v as List<dynamic>)
              .map(
                (e) => ExemptedStudentDto.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        skippedStudents: $checkedConvert('skippedStudents', (v) => v as num),
        skipped: $checkedConvert(
          'skipped',
          (v) => (v as List<dynamic>)
              .map((e) => SkippedStudentDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$FinalResultListDtoToJson(FinalResultListDto instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
      'exemptedStudents': instance.exemptedStudents,
      'exempted': instance.exempted.map((e) => e.toJson()).toList(),
      'skippedStudents': instance.skippedStudents,
      'skipped': instance.skipped.map((e) => e.toJson()).toList(),
    };
