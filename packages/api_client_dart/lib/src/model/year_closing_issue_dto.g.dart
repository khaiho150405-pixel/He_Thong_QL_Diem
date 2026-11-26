// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'year_closing_issue_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$YearClosingIssueDtoCWProxy {
  YearClosingIssueDto code(String code);

  YearClosingIssueDto severity(String severity);

  YearClosingIssueDto label(String label);

  YearClosingIssueDto count(num count);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearClosingIssueDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearClosingIssueDto(...).copyWith(id: 12, name: "My name")
  /// ````
  YearClosingIssueDto call({
    String code,
    String severity,
    String label,
    num count,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfYearClosingIssueDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfYearClosingIssueDto.copyWith.fieldName(...)`
class _$YearClosingIssueDtoCWProxyImpl implements _$YearClosingIssueDtoCWProxy {
  const _$YearClosingIssueDtoCWProxyImpl(this._value);

  final YearClosingIssueDto _value;

  @override
  YearClosingIssueDto code(String code) => this(code: code);

  @override
  YearClosingIssueDto severity(String severity) => this(severity: severity);

  @override
  YearClosingIssueDto label(String label) => this(label: label);

  @override
  YearClosingIssueDto count(num count) => this(count: count);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearClosingIssueDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearClosingIssueDto(...).copyWith(id: 12, name: "My name")
  /// ````
  YearClosingIssueDto call({
    Object? code = const $CopyWithPlaceholder(),
    Object? severity = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
  }) {
    return YearClosingIssueDto(
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      severity: severity == const $CopyWithPlaceholder()
          ? _value.severity
          // ignore: cast_nullable_to_non_nullable
          : severity as String,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      count: count == const $CopyWithPlaceholder()
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as num,
    );
  }
}

extension $YearClosingIssueDtoCopyWith on YearClosingIssueDto {
  /// Returns a callable class that can be used as follows: `instanceOfYearClosingIssueDto.copyWith(...)` or like so:`instanceOfYearClosingIssueDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$YearClosingIssueDtoCWProxy get copyWith =>
      _$YearClosingIssueDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YearClosingIssueDto _$YearClosingIssueDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('YearClosingIssueDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['code', 'severity', 'label', 'count'],
      );
      final val = YearClosingIssueDto(
        code: $checkedConvert('code', (v) => v as String),
        severity: $checkedConvert('severity', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String),
        count: $checkedConvert('count', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$YearClosingIssueDtoToJson(
  YearClosingIssueDto instance,
) => <String, dynamic>{
  'code': instance.code,
  'severity': instance.severity,
  'label': instance.label,
  'count': instance.count,
};
