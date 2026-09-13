// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calculation_history_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CalculationHistoryDtoCWProxy {
  CalculationHistoryDto id(String id);

  CalculationHistoryDto resultId(String resultId);

  CalculationHistoryDto calculatorId(num calculatorId);

  CalculationHistoryDto oldScore(String? oldScore);

  CalculationHistoryDto oldClassification(String? oldClassification);

  CalculationHistoryDto newScore(String newScore);

  CalculationHistoryDto newClassification(String newClassification);

  CalculationHistoryDto reason(String reason);

  CalculationHistoryDto calculatedAt(DateTime calculatedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CalculationHistoryDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CalculationHistoryDto(...).copyWith(id: 12, name: "My name")
  /// ````
  CalculationHistoryDto call({
    String id,
    String resultId,
    num calculatorId,
    String? oldScore,
    String? oldClassification,
    String newScore,
    String newClassification,
    String reason,
    DateTime calculatedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCalculationHistoryDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCalculationHistoryDto.copyWith.fieldName(...)`
class _$CalculationHistoryDtoCWProxyImpl
    implements _$CalculationHistoryDtoCWProxy {
  const _$CalculationHistoryDtoCWProxyImpl(this._value);

  final CalculationHistoryDto _value;

  @override
  CalculationHistoryDto id(String id) => this(id: id);

  @override
  CalculationHistoryDto resultId(String resultId) => this(resultId: resultId);

  @override
  CalculationHistoryDto calculatorId(num calculatorId) =>
      this(calculatorId: calculatorId);

  @override
  CalculationHistoryDto oldScore(String? oldScore) => this(oldScore: oldScore);

  @override
  CalculationHistoryDto oldClassification(String? oldClassification) =>
      this(oldClassification: oldClassification);

  @override
  CalculationHistoryDto newScore(String newScore) => this(newScore: newScore);

  @override
  CalculationHistoryDto newClassification(String newClassification) =>
      this(newClassification: newClassification);

  @override
  CalculationHistoryDto reason(String reason) => this(reason: reason);

  @override
  CalculationHistoryDto calculatedAt(DateTime calculatedAt) =>
      this(calculatedAt: calculatedAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CalculationHistoryDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CalculationHistoryDto(...).copyWith(id: 12, name: "My name")
  /// ````
  CalculationHistoryDto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? resultId = const $CopyWithPlaceholder(),
    Object? calculatorId = const $CopyWithPlaceholder(),
    Object? oldScore = const $CopyWithPlaceholder(),
    Object? oldClassification = const $CopyWithPlaceholder(),
    Object? newScore = const $CopyWithPlaceholder(),
    Object? newClassification = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? calculatedAt = const $CopyWithPlaceholder(),
  }) {
    return CalculationHistoryDto(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      resultId: resultId == const $CopyWithPlaceholder()
          ? _value.resultId
          // ignore: cast_nullable_to_non_nullable
          : resultId as String,
      calculatorId: calculatorId == const $CopyWithPlaceholder()
          ? _value.calculatorId
          // ignore: cast_nullable_to_non_nullable
          : calculatorId as num,
      oldScore: oldScore == const $CopyWithPlaceholder()
          ? _value.oldScore
          // ignore: cast_nullable_to_non_nullable
          : oldScore as String?,
      oldClassification: oldClassification == const $CopyWithPlaceholder()
          ? _value.oldClassification
          // ignore: cast_nullable_to_non_nullable
          : oldClassification as String?,
      newScore: newScore == const $CopyWithPlaceholder()
          ? _value.newScore
          // ignore: cast_nullable_to_non_nullable
          : newScore as String,
      newClassification: newClassification == const $CopyWithPlaceholder()
          ? _value.newClassification
          // ignore: cast_nullable_to_non_nullable
          : newClassification as String,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      calculatedAt: calculatedAt == const $CopyWithPlaceholder()
          ? _value.calculatedAt
          // ignore: cast_nullable_to_non_nullable
          : calculatedAt as DateTime,
    );
  }
}

extension $CalculationHistoryDtoCopyWith on CalculationHistoryDto {
  /// Returns a callable class that can be used as follows: `instanceOfCalculationHistoryDto.copyWith(...)` or like so:`instanceOfCalculationHistoryDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CalculationHistoryDtoCWProxy get copyWith =>
      _$CalculationHistoryDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalculationHistoryDto _$CalculationHistoryDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CalculationHistoryDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'resultId',
      'calculatorId',
      'oldScore',
      'oldClassification',
      'newScore',
      'newClassification',
      'reason',
      'calculatedAt',
    ],
  );
  final val = CalculationHistoryDto(
    id: $checkedConvert('id', (v) => v as String),
    resultId: $checkedConvert('resultId', (v) => v as String),
    calculatorId: $checkedConvert('calculatorId', (v) => v as num),
    oldScore: $checkedConvert('oldScore', (v) => v as String?),
    oldClassification: $checkedConvert(
      'oldClassification',
      (v) => v as String?,
    ),
    newScore: $checkedConvert('newScore', (v) => v as String),
    newClassification: $checkedConvert('newClassification', (v) => v as String),
    reason: $checkedConvert('reason', (v) => v as String),
    calculatedAt: $checkedConvert(
      'calculatedAt',
      (v) => DateTime.parse(v as String),
    ),
  );
  return val;
});

Map<String, dynamic> _$CalculationHistoryDtoToJson(
  CalculationHistoryDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'resultId': instance.resultId,
  'calculatorId': instance.calculatorId,
  'oldScore': instance.oldScore,
  'oldClassification': instance.oldClassification,
  'newScore': instance.newScore,
  'newClassification': instance.newClassification,
  'reason': instance.reason,
  'calculatedAt': instance.calculatedAt.toIso8601String(),
};
