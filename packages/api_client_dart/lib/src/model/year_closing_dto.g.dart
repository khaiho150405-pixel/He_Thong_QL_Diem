// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'year_closing_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$YearClosingDtoCWProxy {
  YearClosingDto yearId(num yearId);

  YearClosingDto closedAt(String? closedAt);

  YearClosingDto ready(bool ready);

  YearClosingDto issues(List<YearClosingIssueDto> issues);

  YearClosingDto history(List<YearClosingEventDto> history);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearClosingDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearClosingDto(...).copyWith(id: 12, name: "My name")
  /// ````
  YearClosingDto call({
    num yearId,
    String? closedAt,
    bool ready,
    List<YearClosingIssueDto> issues,
    List<YearClosingEventDto> history,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfYearClosingDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfYearClosingDto.copyWith.fieldName(...)`
class _$YearClosingDtoCWProxyImpl implements _$YearClosingDtoCWProxy {
  const _$YearClosingDtoCWProxyImpl(this._value);

  final YearClosingDto _value;

  @override
  YearClosingDto yearId(num yearId) => this(yearId: yearId);

  @override
  YearClosingDto closedAt(String? closedAt) => this(closedAt: closedAt);

  @override
  YearClosingDto ready(bool ready) => this(ready: ready);

  @override
  YearClosingDto issues(List<YearClosingIssueDto> issues) =>
      this(issues: issues);

  @override
  YearClosingDto history(List<YearClosingEventDto> history) =>
      this(history: history);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearClosingDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearClosingDto(...).copyWith(id: 12, name: "My name")
  /// ````
  YearClosingDto call({
    Object? yearId = const $CopyWithPlaceholder(),
    Object? closedAt = const $CopyWithPlaceholder(),
    Object? ready = const $CopyWithPlaceholder(),
    Object? issues = const $CopyWithPlaceholder(),
    Object? history = const $CopyWithPlaceholder(),
  }) {
    return YearClosingDto(
      yearId: yearId == const $CopyWithPlaceholder()
          ? _value.yearId
          // ignore: cast_nullable_to_non_nullable
          : yearId as num,
      closedAt: closedAt == const $CopyWithPlaceholder()
          ? _value.closedAt
          // ignore: cast_nullable_to_non_nullable
          : closedAt as String?,
      ready: ready == const $CopyWithPlaceholder()
          ? _value.ready
          // ignore: cast_nullable_to_non_nullable
          : ready as bool,
      issues: issues == const $CopyWithPlaceholder()
          ? _value.issues
          // ignore: cast_nullable_to_non_nullable
          : issues as List<YearClosingIssueDto>,
      history: history == const $CopyWithPlaceholder()
          ? _value.history
          // ignore: cast_nullable_to_non_nullable
          : history as List<YearClosingEventDto>,
    );
  }
}

extension $YearClosingDtoCopyWith on YearClosingDto {
  /// Returns a callable class that can be used as follows: `instanceOfYearClosingDto.copyWith(...)` or like so:`instanceOfYearClosingDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$YearClosingDtoCWProxy get copyWith => _$YearClosingDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YearClosingDto _$YearClosingDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('YearClosingDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['yearId', 'closedAt', 'ready', 'issues', 'history'],
  );
  final val = YearClosingDto(
    yearId: $checkedConvert('yearId', (v) => v as num),
    closedAt: $checkedConvert('closedAt', (v) => v as String?),
    ready: $checkedConvert('ready', (v) => v as bool),
    issues: $checkedConvert(
      'issues',
      (v) => (v as List<dynamic>)
          .map((e) => YearClosingIssueDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    history: $checkedConvert(
      'history',
      (v) => (v as List<dynamic>)
          .map((e) => YearClosingEventDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$YearClosingDtoToJson(YearClosingDto instance) =>
    <String, dynamic>{
      'yearId': instance.yearId,
      'closedAt': instance.closedAt,
      'ready': instance.ready,
      'issues': instance.issues.map((e) => e.toJson()).toList(),
      'history': instance.history.map((e) => e.toJson()).toList(),
    };
