// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'final_result_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FinalResultDtoCWProxy {
  FinalResultDto id(String id);

  FinalResultDto studentId(num studentId);

  FinalResultDto studentName(String studentName);

  FinalResultDto finalScore(String finalScore);

  FinalResultDto classification(String classification);

  FinalResultDto weightVersion(String weightVersion);

  FinalResultDto policyVersion(String policyVersion);

  FinalResultDto calculatedAt(DateTime calculatedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FinalResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FinalResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  FinalResultDto call({
    String id,
    num studentId,
    String studentName,
    String finalScore,
    String classification,
    String weightVersion,
    String policyVersion,
    DateTime calculatedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFinalResultDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFinalResultDto.copyWith.fieldName(...)`
class _$FinalResultDtoCWProxyImpl implements _$FinalResultDtoCWProxy {
  const _$FinalResultDtoCWProxyImpl(this._value);

  final FinalResultDto _value;

  @override
  FinalResultDto id(String id) => this(id: id);

  @override
  FinalResultDto studentId(num studentId) => this(studentId: studentId);

  @override
  FinalResultDto studentName(String studentName) =>
      this(studentName: studentName);

  @override
  FinalResultDto finalScore(String finalScore) => this(finalScore: finalScore);

  @override
  FinalResultDto classification(String classification) =>
      this(classification: classification);

  @override
  FinalResultDto weightVersion(String weightVersion) =>
      this(weightVersion: weightVersion);

  @override
  FinalResultDto policyVersion(String policyVersion) =>
      this(policyVersion: policyVersion);

  @override
  FinalResultDto calculatedAt(DateTime calculatedAt) =>
      this(calculatedAt: calculatedAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FinalResultDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FinalResultDto(...).copyWith(id: 12, name: "My name")
  /// ````
  FinalResultDto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? studentId = const $CopyWithPlaceholder(),
    Object? studentName = const $CopyWithPlaceholder(),
    Object? finalScore = const $CopyWithPlaceholder(),
    Object? classification = const $CopyWithPlaceholder(),
    Object? weightVersion = const $CopyWithPlaceholder(),
    Object? policyVersion = const $CopyWithPlaceholder(),
    Object? calculatedAt = const $CopyWithPlaceholder(),
  }) {
    return FinalResultDto(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      studentId: studentId == const $CopyWithPlaceholder()
          ? _value.studentId
          // ignore: cast_nullable_to_non_nullable
          : studentId as num,
      studentName: studentName == const $CopyWithPlaceholder()
          ? _value.studentName
          // ignore: cast_nullable_to_non_nullable
          : studentName as String,
      finalScore: finalScore == const $CopyWithPlaceholder()
          ? _value.finalScore
          // ignore: cast_nullable_to_non_nullable
          : finalScore as String,
      classification: classification == const $CopyWithPlaceholder()
          ? _value.classification
          // ignore: cast_nullable_to_non_nullable
          : classification as String,
      weightVersion: weightVersion == const $CopyWithPlaceholder()
          ? _value.weightVersion
          // ignore: cast_nullable_to_non_nullable
          : weightVersion as String,
      policyVersion: policyVersion == const $CopyWithPlaceholder()
          ? _value.policyVersion
          // ignore: cast_nullable_to_non_nullable
          : policyVersion as String,
      calculatedAt: calculatedAt == const $CopyWithPlaceholder()
          ? _value.calculatedAt
          // ignore: cast_nullable_to_non_nullable
          : calculatedAt as DateTime,
    );
  }
}

extension $FinalResultDtoCopyWith on FinalResultDto {
  /// Returns a callable class that can be used as follows: `instanceOfFinalResultDto.copyWith(...)` or like so:`instanceOfFinalResultDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FinalResultDtoCWProxy get copyWith => _$FinalResultDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FinalResultDto _$FinalResultDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FinalResultDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'studentId',
          'studentName',
          'finalScore',
          'classification',
          'weightVersion',
          'policyVersion',
          'calculatedAt',
        ],
      );
      final val = FinalResultDto(
        id: $checkedConvert('id', (v) => v as String),
        studentId: $checkedConvert('studentId', (v) => v as num),
        studentName: $checkedConvert('studentName', (v) => v as String),
        finalScore: $checkedConvert('finalScore', (v) => v as String),
        classification: $checkedConvert('classification', (v) => v as String),
        weightVersion: $checkedConvert('weightVersion', (v) => v as String),
        policyVersion: $checkedConvert('policyVersion', (v) => v as String),
        calculatedAt: $checkedConvert(
          'calculatedAt',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$FinalResultDtoToJson(FinalResultDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studentId': instance.studentId,
      'studentName': instance.studentName,
      'finalScore': instance.finalScore,
      'classification': instance.classification,
      'weightVersion': instance.weightVersion,
      'policyVersion': instance.policyVersion,
      'calculatedAt': instance.calculatedAt.toIso8601String(),
    };
