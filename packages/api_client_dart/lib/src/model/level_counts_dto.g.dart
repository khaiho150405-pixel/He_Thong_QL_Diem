// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_counts_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LevelCountsDtoCWProxy {
  LevelCountsDto TOT(num TOT);

  LevelCountsDto KHA(num KHA);

  LevelCountsDto DAT(num DAT);

  LevelCountsDto CHUA_DAT(num CHUA_DAT);

  LevelCountsDto CHUA_DU_MON(num CHUA_DU_MON);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LevelCountsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LevelCountsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  LevelCountsDto call({
    num TOT,
    num KHA,
    num DAT,
    num CHUA_DAT,
    num CHUA_DU_MON,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLevelCountsDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLevelCountsDto.copyWith.fieldName(...)`
class _$LevelCountsDtoCWProxyImpl implements _$LevelCountsDtoCWProxy {
  const _$LevelCountsDtoCWProxyImpl(this._value);

  final LevelCountsDto _value;

  @override
  LevelCountsDto TOT(num TOT) => this(TOT: TOT);

  @override
  LevelCountsDto KHA(num KHA) => this(KHA: KHA);

  @override
  LevelCountsDto DAT(num DAT) => this(DAT: DAT);

  @override
  LevelCountsDto CHUA_DAT(num CHUA_DAT) => this(CHUA_DAT: CHUA_DAT);

  @override
  LevelCountsDto CHUA_DU_MON(num CHUA_DU_MON) => this(CHUA_DU_MON: CHUA_DU_MON);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LevelCountsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LevelCountsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  LevelCountsDto call({
    Object? TOT = const $CopyWithPlaceholder(),
    Object? KHA = const $CopyWithPlaceholder(),
    Object? DAT = const $CopyWithPlaceholder(),
    Object? CHUA_DAT = const $CopyWithPlaceholder(),
    Object? CHUA_DU_MON = const $CopyWithPlaceholder(),
  }) {
    return LevelCountsDto(
      TOT: TOT == const $CopyWithPlaceholder()
          ? _value.TOT
          // ignore: cast_nullable_to_non_nullable
          : TOT as num,
      KHA: KHA == const $CopyWithPlaceholder()
          ? _value.KHA
          // ignore: cast_nullable_to_non_nullable
          : KHA as num,
      DAT: DAT == const $CopyWithPlaceholder()
          ? _value.DAT
          // ignore: cast_nullable_to_non_nullable
          : DAT as num,
      CHUA_DAT: CHUA_DAT == const $CopyWithPlaceholder()
          ? _value.CHUA_DAT
          // ignore: cast_nullable_to_non_nullable
          : CHUA_DAT as num,
      CHUA_DU_MON: CHUA_DU_MON == const $CopyWithPlaceholder()
          ? _value.CHUA_DU_MON
          // ignore: cast_nullable_to_non_nullable
          : CHUA_DU_MON as num,
    );
  }
}

extension $LevelCountsDtoCopyWith on LevelCountsDto {
  /// Returns a callable class that can be used as follows: `instanceOfLevelCountsDto.copyWith(...)` or like so:`instanceOfLevelCountsDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LevelCountsDtoCWProxy get copyWith => _$LevelCountsDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LevelCountsDto _$LevelCountsDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LevelCountsDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['TOT', 'KHA', 'DAT', 'CHUA_DAT', 'CHUA_DU_MON'],
      );
      final val = LevelCountsDto(
        TOT: $checkedConvert('TOT', (v) => v as num),
        KHA: $checkedConvert('KHA', (v) => v as num),
        DAT: $checkedConvert('DAT', (v) => v as num),
        CHUA_DAT: $checkedConvert('CHUA_DAT', (v) => v as num),
        CHUA_DU_MON: $checkedConvert('CHUA_DU_MON', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$LevelCountsDtoToJson(LevelCountsDto instance) =>
    <String, dynamic>{
      'TOT': instance.TOT,
      'KHA': instance.KHA,
      'DAT': instance.DAT,
      'CHUA_DAT': instance.CHUA_DAT,
      'CHUA_DU_MON': instance.CHUA_DU_MON,
    };
