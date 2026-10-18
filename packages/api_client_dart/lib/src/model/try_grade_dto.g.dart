// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'try_grade_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TryGradeDtoCWProxy {
  TryGradeDto key(String key);

  TryGradeDto numericValue(String? numericValue);

  TryGradeDto numericConfidence(String? numericConfidence);

  TryGradeDto writtenValue(String? writtenValue);

  TryGradeDto writtenConfidence(String? writtenConfidence);

  TryGradeDto comparison(TryGradeDtoComparisonEnum comparison);

  TryGradeDto reviewLevel(TryGradeDtoReviewLevelEnum reviewLevel);

  TryGradeDto suggestedSource(TryGradeDtoSuggestedSourceEnum? suggestedSource);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TryGradeDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TryGradeDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TryGradeDto call({
    String key,
    String? numericValue,
    String? numericConfidence,
    String? writtenValue,
    String? writtenConfidence,
    TryGradeDtoComparisonEnum comparison,
    TryGradeDtoReviewLevelEnum reviewLevel,
    TryGradeDtoSuggestedSourceEnum? suggestedSource,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTryGradeDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTryGradeDto.copyWith.fieldName(...)`
class _$TryGradeDtoCWProxyImpl implements _$TryGradeDtoCWProxy {
  const _$TryGradeDtoCWProxyImpl(this._value);

  final TryGradeDto _value;

  @override
  TryGradeDto key(String key) => this(key: key);

  @override
  TryGradeDto numericValue(String? numericValue) =>
      this(numericValue: numericValue);

  @override
  TryGradeDto numericConfidence(String? numericConfidence) =>
      this(numericConfidence: numericConfidence);

  @override
  TryGradeDto writtenValue(String? writtenValue) =>
      this(writtenValue: writtenValue);

  @override
  TryGradeDto writtenConfidence(String? writtenConfidence) =>
      this(writtenConfidence: writtenConfidence);

  @override
  TryGradeDto comparison(TryGradeDtoComparisonEnum comparison) =>
      this(comparison: comparison);

  @override
  TryGradeDto reviewLevel(TryGradeDtoReviewLevelEnum reviewLevel) =>
      this(reviewLevel: reviewLevel);

  @override
  TryGradeDto suggestedSource(
    TryGradeDtoSuggestedSourceEnum? suggestedSource,
  ) => this(suggestedSource: suggestedSource);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TryGradeDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TryGradeDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TryGradeDto call({
    Object? key = const $CopyWithPlaceholder(),
    Object? numericValue = const $CopyWithPlaceholder(),
    Object? numericConfidence = const $CopyWithPlaceholder(),
    Object? writtenValue = const $CopyWithPlaceholder(),
    Object? writtenConfidence = const $CopyWithPlaceholder(),
    Object? comparison = const $CopyWithPlaceholder(),
    Object? reviewLevel = const $CopyWithPlaceholder(),
    Object? suggestedSource = const $CopyWithPlaceholder(),
  }) {
    return TryGradeDto(
      key: key == const $CopyWithPlaceholder()
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String,
      numericValue: numericValue == const $CopyWithPlaceholder()
          ? _value.numericValue
          // ignore: cast_nullable_to_non_nullable
          : numericValue as String?,
      numericConfidence: numericConfidence == const $CopyWithPlaceholder()
          ? _value.numericConfidence
          // ignore: cast_nullable_to_non_nullable
          : numericConfidence as String?,
      writtenValue: writtenValue == const $CopyWithPlaceholder()
          ? _value.writtenValue
          // ignore: cast_nullable_to_non_nullable
          : writtenValue as String?,
      writtenConfidence: writtenConfidence == const $CopyWithPlaceholder()
          ? _value.writtenConfidence
          // ignore: cast_nullable_to_non_nullable
          : writtenConfidence as String?,
      comparison: comparison == const $CopyWithPlaceholder()
          ? _value.comparison
          // ignore: cast_nullable_to_non_nullable
          : comparison as TryGradeDtoComparisonEnum,
      reviewLevel: reviewLevel == const $CopyWithPlaceholder()
          ? _value.reviewLevel
          // ignore: cast_nullable_to_non_nullable
          : reviewLevel as TryGradeDtoReviewLevelEnum,
      suggestedSource: suggestedSource == const $CopyWithPlaceholder()
          ? _value.suggestedSource
          // ignore: cast_nullable_to_non_nullable
          : suggestedSource as TryGradeDtoSuggestedSourceEnum?,
    );
  }
}

extension $TryGradeDtoCopyWith on TryGradeDto {
  /// Returns a callable class that can be used as follows: `instanceOfTryGradeDto.copyWith(...)` or like so:`instanceOfTryGradeDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TryGradeDtoCWProxy get copyWith => _$TryGradeDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TryGradeDto _$TryGradeDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TryGradeDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'key',
          'numericValue',
          'numericConfidence',
          'writtenValue',
          'writtenConfidence',
          'comparison',
          'reviewLevel',
          'suggestedSource',
        ],
      );
      final val = TryGradeDto(
        key: $checkedConvert('key', (v) => v as String),
        numericValue: $checkedConvert('numericValue', (v) => v as String?),
        numericConfidence: $checkedConvert(
          'numericConfidence',
          (v) => v as String?,
        ),
        writtenValue: $checkedConvert('writtenValue', (v) => v as String?),
        writtenConfidence: $checkedConvert(
          'writtenConfidence',
          (v) => v as String?,
        ),
        comparison: $checkedConvert(
          'comparison',
          (v) => $enumDecode(_$TryGradeDtoComparisonEnumEnumMap, v),
        ),
        reviewLevel: $checkedConvert(
          'reviewLevel',
          (v) => $enumDecode(_$TryGradeDtoReviewLevelEnumEnumMap, v),
        ),
        suggestedSource: $checkedConvert(
          'suggestedSource',
          (v) =>
              $enumDecodeNullable(_$TryGradeDtoSuggestedSourceEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TryGradeDtoToJson(TryGradeDto instance) =>
    <String, dynamic>{
      'key': instance.key,
      'numericValue': instance.numericValue,
      'numericConfidence': instance.numericConfidence,
      'writtenValue': instance.writtenValue,
      'writtenConfidence': instance.writtenConfidence,
      'comparison': _$TryGradeDtoComparisonEnumEnumMap[instance.comparison]!,
      'reviewLevel': _$TryGradeDtoReviewLevelEnumEnumMap[instance.reviewLevel]!,
      'suggestedSource':
          _$TryGradeDtoSuggestedSourceEnumEnumMap[instance.suggestedSource],
    };

const _$TryGradeDtoComparisonEnumEnumMap = {
  TryGradeDtoComparisonEnum.KHOP: 'KHOP',
  TryGradeDtoComparisonEnum.LECH: 'LECH',
  TryGradeDtoComparisonEnum.MOT_KENH: 'MOT_KENH',
  TryGradeDtoComparisonEnum.KHONG_DOC_DUOC: 'KHONG_DOC_DUOC',
};

const _$TryGradeDtoReviewLevelEnumEnumMap = {
  TryGradeDtoReviewLevelEnum.XANH: 'XANH',
  TryGradeDtoReviewLevelEnum.VANG: 'VANG',
  TryGradeDtoReviewLevelEnum.DO: 'DO',
};

const _$TryGradeDtoSuggestedSourceEnumEnumMap = {
  TryGradeDtoSuggestedSourceEnum.SO: 'SO',
  TryGradeDtoSuggestedSourceEnum.CHU: 'CHU',
};
