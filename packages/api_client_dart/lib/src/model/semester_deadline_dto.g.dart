// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semester_deadline_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SemesterDeadlineDtoCWProxy {
  SemesterDeadlineDto type(SemesterDeadlineDtoTypeEnum type);

  SemesterDeadlineDto opensAt(DateTime? opensAt);

  SemesterDeadlineDto closesAt(DateTime? closesAt);

  SemesterDeadlineDto version(num version);

  SemesterDeadlineDto expired(bool expired);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SemesterDeadlineDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SemesterDeadlineDto(...).copyWith(id: 12, name: "My name")
  /// ````
  SemesterDeadlineDto call({
    SemesterDeadlineDtoTypeEnum type,
    DateTime? opensAt,
    DateTime? closesAt,
    num version,
    bool expired,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSemesterDeadlineDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSemesterDeadlineDto.copyWith.fieldName(...)`
class _$SemesterDeadlineDtoCWProxyImpl implements _$SemesterDeadlineDtoCWProxy {
  const _$SemesterDeadlineDtoCWProxyImpl(this._value);

  final SemesterDeadlineDto _value;

  @override
  SemesterDeadlineDto type(SemesterDeadlineDtoTypeEnum type) =>
      this(type: type);

  @override
  SemesterDeadlineDto opensAt(DateTime? opensAt) => this(opensAt: opensAt);

  @override
  SemesterDeadlineDto closesAt(DateTime? closesAt) => this(closesAt: closesAt);

  @override
  SemesterDeadlineDto version(num version) => this(version: version);

  @override
  SemesterDeadlineDto expired(bool expired) => this(expired: expired);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SemesterDeadlineDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SemesterDeadlineDto(...).copyWith(id: 12, name: "My name")
  /// ````
  SemesterDeadlineDto call({
    Object? type = const $CopyWithPlaceholder(),
    Object? opensAt = const $CopyWithPlaceholder(),
    Object? closesAt = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? expired = const $CopyWithPlaceholder(),
  }) {
    return SemesterDeadlineDto(
      type: type == const $CopyWithPlaceholder()
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as SemesterDeadlineDtoTypeEnum,
      opensAt: opensAt == const $CopyWithPlaceholder()
          ? _value.opensAt
          // ignore: cast_nullable_to_non_nullable
          : opensAt as DateTime?,
      closesAt: closesAt == const $CopyWithPlaceholder()
          ? _value.closesAt
          // ignore: cast_nullable_to_non_nullable
          : closesAt as DateTime?,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as num,
      expired: expired == const $CopyWithPlaceholder()
          ? _value.expired
          // ignore: cast_nullable_to_non_nullable
          : expired as bool,
    );
  }
}

extension $SemesterDeadlineDtoCopyWith on SemesterDeadlineDto {
  /// Returns a callable class that can be used as follows: `instanceOfSemesterDeadlineDto.copyWith(...)` or like so:`instanceOfSemesterDeadlineDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SemesterDeadlineDtoCWProxy get copyWith =>
      _$SemesterDeadlineDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SemesterDeadlineDto _$SemesterDeadlineDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SemesterDeadlineDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'type',
          'opensAt',
          'closesAt',
          'version',
          'expired',
        ],
      );
      final val = SemesterDeadlineDto(
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$SemesterDeadlineDtoTypeEnumEnumMap, v),
        ),
        opensAt: $checkedConvert(
          'opensAt',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        closesAt: $checkedConvert(
          'closesAt',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        version: $checkedConvert('version', (v) => v as num),
        expired: $checkedConvert('expired', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$SemesterDeadlineDtoToJson(
  SemesterDeadlineDto instance,
) => <String, dynamic>{
  'type': _$SemesterDeadlineDtoTypeEnumEnumMap[instance.type]!,
  'opensAt': instance.opensAt?.toIso8601String(),
  'closesAt': instance.closesAt?.toIso8601String(),
  'version': instance.version,
  'expired': instance.expired,
};

const _$SemesterDeadlineDtoTypeEnumEnumMap = {
  SemesterDeadlineDtoTypeEnum.TX: 'TX',
  SemesterDeadlineDtoTypeEnum.GK: 'GK',
  SemesterDeadlineDtoTypeEnum.CK: 'CK',
};
