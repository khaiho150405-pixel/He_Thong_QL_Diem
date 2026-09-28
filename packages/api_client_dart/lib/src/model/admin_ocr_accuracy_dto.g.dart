// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_ocr_accuracy_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminOcrAccuracyDtoCWProxy {
  AdminOcrAccuracyDto totalCells(num totalCells);

  AdminOcrAccuracyDto greenCount(num greenCount);

  AdminOcrAccuracyDto yellowCount(num yellowCount);

  AdminOcrAccuracyDto redCount(num redCount);

  AdminOcrAccuracyDto accuracyRate(num accuracyRate);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminOcrAccuracyDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminOcrAccuracyDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminOcrAccuracyDto call({
    num totalCells,
    num greenCount,
    num yellowCount,
    num redCount,
    num accuracyRate,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminOcrAccuracyDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminOcrAccuracyDto.copyWith.fieldName(...)`
class _$AdminOcrAccuracyDtoCWProxyImpl implements _$AdminOcrAccuracyDtoCWProxy {
  const _$AdminOcrAccuracyDtoCWProxyImpl(this._value);

  final AdminOcrAccuracyDto _value;

  @override
  AdminOcrAccuracyDto totalCells(num totalCells) =>
      this(totalCells: totalCells);

  @override
  AdminOcrAccuracyDto greenCount(num greenCount) =>
      this(greenCount: greenCount);

  @override
  AdminOcrAccuracyDto yellowCount(num yellowCount) =>
      this(yellowCount: yellowCount);

  @override
  AdminOcrAccuracyDto redCount(num redCount) => this(redCount: redCount);

  @override
  AdminOcrAccuracyDto accuracyRate(num accuracyRate) =>
      this(accuracyRate: accuracyRate);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminOcrAccuracyDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminOcrAccuracyDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminOcrAccuracyDto call({
    Object? totalCells = const $CopyWithPlaceholder(),
    Object? greenCount = const $CopyWithPlaceholder(),
    Object? yellowCount = const $CopyWithPlaceholder(),
    Object? redCount = const $CopyWithPlaceholder(),
    Object? accuracyRate = const $CopyWithPlaceholder(),
  }) {
    return AdminOcrAccuracyDto(
      totalCells: totalCells == const $CopyWithPlaceholder()
          ? _value.totalCells
          // ignore: cast_nullable_to_non_nullable
          : totalCells as num,
      greenCount: greenCount == const $CopyWithPlaceholder()
          ? _value.greenCount
          // ignore: cast_nullable_to_non_nullable
          : greenCount as num,
      yellowCount: yellowCount == const $CopyWithPlaceholder()
          ? _value.yellowCount
          // ignore: cast_nullable_to_non_nullable
          : yellowCount as num,
      redCount: redCount == const $CopyWithPlaceholder()
          ? _value.redCount
          // ignore: cast_nullable_to_non_nullable
          : redCount as num,
      accuracyRate: accuracyRate == const $CopyWithPlaceholder()
          ? _value.accuracyRate
          // ignore: cast_nullable_to_non_nullable
          : accuracyRate as num,
    );
  }
}

extension $AdminOcrAccuracyDtoCopyWith on AdminOcrAccuracyDto {
  /// Returns a callable class that can be used as follows: `instanceOfAdminOcrAccuracyDto.copyWith(...)` or like so:`instanceOfAdminOcrAccuracyDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminOcrAccuracyDtoCWProxy get copyWith =>
      _$AdminOcrAccuracyDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminOcrAccuracyDto _$AdminOcrAccuracyDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminOcrAccuracyDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'totalCells',
          'greenCount',
          'yellowCount',
          'redCount',
          'accuracyRate',
        ],
      );
      final val = AdminOcrAccuracyDto(
        totalCells: $checkedConvert('totalCells', (v) => v as num),
        greenCount: $checkedConvert('greenCount', (v) => v as num),
        yellowCount: $checkedConvert('yellowCount', (v) => v as num),
        redCount: $checkedConvert('redCount', (v) => v as num),
        accuracyRate: $checkedConvert('accuracyRate', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$AdminOcrAccuracyDtoToJson(
  AdminOcrAccuracyDto instance,
) => <String, dynamic>{
  'totalCells': instance.totalCells,
  'greenCount': instance.greenCount,
  'yellowCount': instance.yellowCount,
  'redCount': instance.redCount,
  'accuracyRate': instance.accuracyRate,
};
