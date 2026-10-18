// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'try_result_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TryResultDtoCWProxy {
  TryResultDto templateId(num templateId);

  TryResultDto modelVersion(String modelVersion);

  TryResultDto templateMatchScore(num templateMatchScore);

  TryResultDto pageStartStt(num? pageStartStt);

  TryResultDto rows(List<TryRowDto> rows);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TryResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TryResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TryResultDto call({
    num templateId,
    String modelVersion,
    num templateMatchScore,
    num? pageStartStt,
    List<TryRowDto> rows,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTryResultDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTryResultDto.copyWith.fieldName(...)`
class _$TryResultDtoCWProxyImpl implements _$TryResultDtoCWProxy {
  const _$TryResultDtoCWProxyImpl(this._value);

  final TryResultDto _value;

  @override
  TryResultDto templateId(num templateId) => this(templateId: templateId);

  @override
  TryResultDto modelVersion(String modelVersion) =>
      this(modelVersion: modelVersion);

  @override
  TryResultDto templateMatchScore(num templateMatchScore) =>
      this(templateMatchScore: templateMatchScore);

  @override
  TryResultDto pageStartStt(num? pageStartStt) =>
      this(pageStartStt: pageStartStt);

  @override
  TryResultDto rows(List<TryRowDto> rows) => this(rows: rows);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TryResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TryResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TryResultDto call({
    Object? templateId = const $CopyWithPlaceholder(),
    Object? modelVersion = const $CopyWithPlaceholder(),
    Object? templateMatchScore = const $CopyWithPlaceholder(),
    Object? pageStartStt = const $CopyWithPlaceholder(),
    Object? rows = const $CopyWithPlaceholder(),
  }) {
    return TryResultDto(
      templateId: templateId == const $CopyWithPlaceholder()
          ? _value.templateId
          // ignore: cast_nullable_to_non_nullable
          : templateId as num,
      modelVersion: modelVersion == const $CopyWithPlaceholder()
          ? _value.modelVersion
          // ignore: cast_nullable_to_non_nullable
          : modelVersion as String,
      templateMatchScore: templateMatchScore == const $CopyWithPlaceholder()
          ? _value.templateMatchScore
          // ignore: cast_nullable_to_non_nullable
          : templateMatchScore as num,
      pageStartStt: pageStartStt == const $CopyWithPlaceholder()
          ? _value.pageStartStt
          // ignore: cast_nullable_to_non_nullable
          : pageStartStt as num?,
      rows: rows == const $CopyWithPlaceholder()
          ? _value.rows
          // ignore: cast_nullable_to_non_nullable
          : rows as List<TryRowDto>,
    );
  }
}

extension $TryResultDtoCopyWith on TryResultDto {
  /// Returns a callable class that can be used as follows: `instanceOfTryResultDto.copyWith(...)` or like so:`instanceOfTryResultDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TryResultDtoCWProxy get copyWith => _$TryResultDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TryResultDto _$TryResultDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TryResultDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'templateId',
          'modelVersion',
          'templateMatchScore',
          'pageStartStt',
          'rows',
        ],
      );
      final val = TryResultDto(
        templateId: $checkedConvert('templateId', (v) => v as num),
        modelVersion: $checkedConvert('modelVersion', (v) => v as String),
        templateMatchScore: $checkedConvert(
          'templateMatchScore',
          (v) => v as num,
        ),
        pageStartStt: $checkedConvert('pageStartStt', (v) => v as num?),
        rows: $checkedConvert(
          'rows',
          (v) => (v as List<dynamic>)
              .map((e) => TryRowDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TryResultDtoToJson(TryResultDto instance) =>
    <String, dynamic>{
      'templateId': instance.templateId,
      'modelVersion': instance.modelVersion,
      'templateMatchScore': instance.templateMatchScore,
      'pageStartStt': instance.pageStartStt,
      'rows': instance.rows.map((e) => e.toJson()).toList(),
    };
