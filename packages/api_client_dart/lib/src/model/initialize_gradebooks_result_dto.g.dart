// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'initialize_gradebooks_result_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InitializeGradebooksResultDtoCWProxy {
  InitializeGradebooksResultDto created(List<InitializedGradebookDto> created);

  InitializeGradebooksResultDto skipped(List<SkippedGradebookDto> skipped);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `InitializeGradebooksResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// InitializeGradebooksResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  InitializeGradebooksResultDto call({
    List<InitializedGradebookDto> created,
    List<SkippedGradebookDto> skipped,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfInitializeGradebooksResultDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfInitializeGradebooksResultDto.copyWith.fieldName(...)`
class _$InitializeGradebooksResultDtoCWProxyImpl
    implements _$InitializeGradebooksResultDtoCWProxy {
  const _$InitializeGradebooksResultDtoCWProxyImpl(this._value);

  final InitializeGradebooksResultDto _value;

  @override
  InitializeGradebooksResultDto created(
    List<InitializedGradebookDto> created,
  ) => this(created: created);

  @override
  InitializeGradebooksResultDto skipped(List<SkippedGradebookDto> skipped) =>
      this(skipped: skipped);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `InitializeGradebooksResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// InitializeGradebooksResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  InitializeGradebooksResultDto call({
    Object? created = const $CopyWithPlaceholder(),
    Object? skipped = const $CopyWithPlaceholder(),
  }) {
    return InitializeGradebooksResultDto(
      created: created == const $CopyWithPlaceholder()
          ? _value.created
          // ignore: cast_nullable_to_non_nullable
          : created as List<InitializedGradebookDto>,
      skipped: skipped == const $CopyWithPlaceholder()
          ? _value.skipped
          // ignore: cast_nullable_to_non_nullable
          : skipped as List<SkippedGradebookDto>,
    );
  }
}

extension $InitializeGradebooksResultDtoCopyWith
    on InitializeGradebooksResultDto {
  /// Returns a callable class that can be used as follows: `instanceOfInitializeGradebooksResultDto.copyWith(...)` or like so:`instanceOfInitializeGradebooksResultDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InitializeGradebooksResultDtoCWProxy get copyWith =>
      _$InitializeGradebooksResultDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InitializeGradebooksResultDto _$InitializeGradebooksResultDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('InitializeGradebooksResultDto', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['created', 'skipped']);
  final val = InitializeGradebooksResultDto(
    created: $checkedConvert(
      'created',
      (v) => (v as List<dynamic>)
          .map(
            (e) => InitializedGradebookDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    skipped: $checkedConvert(
      'skipped',
      (v) => (v as List<dynamic>)
          .map((e) => SkippedGradebookDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$InitializeGradebooksResultDtoToJson(
  InitializeGradebooksResultDto instance,
) => <String, dynamic>{
  'created': instance.created.map((e) => e.toJson()).toList(),
  'skipped': instance.skipped.map((e) => e.toJson()).toList(),
};
