// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publish_readiness_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublishReadinessDtoCWProxy {
  PublishReadinessDto ready(bool ready);

  PublishReadinessDto issues(List<PublishIssueDto> issues);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublishReadinessDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublishReadinessDto(...).copyWith(id: 12, name: "My name")
  /// ````
  PublishReadinessDto call({bool ready, List<PublishIssueDto> issues});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublishReadinessDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublishReadinessDto.copyWith.fieldName(...)`
class _$PublishReadinessDtoCWProxyImpl implements _$PublishReadinessDtoCWProxy {
  const _$PublishReadinessDtoCWProxyImpl(this._value);

  final PublishReadinessDto _value;

  @override
  PublishReadinessDto ready(bool ready) => this(ready: ready);

  @override
  PublishReadinessDto issues(List<PublishIssueDto> issues) =>
      this(issues: issues);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublishReadinessDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublishReadinessDto(...).copyWith(id: 12, name: "My name")
  /// ````
  PublishReadinessDto call({
    Object? ready = const $CopyWithPlaceholder(),
    Object? issues = const $CopyWithPlaceholder(),
  }) {
    return PublishReadinessDto(
      ready: ready == const $CopyWithPlaceholder()
          ? _value.ready
          // ignore: cast_nullable_to_non_nullable
          : ready as bool,
      issues: issues == const $CopyWithPlaceholder()
          ? _value.issues
          // ignore: cast_nullable_to_non_nullable
          : issues as List<PublishIssueDto>,
    );
  }
}

extension $PublishReadinessDtoCopyWith on PublishReadinessDto {
  /// Returns a callable class that can be used as follows: `instanceOfPublishReadinessDto.copyWith(...)` or like so:`instanceOfPublishReadinessDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublishReadinessDtoCWProxy get copyWith =>
      _$PublishReadinessDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublishReadinessDto _$PublishReadinessDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PublishReadinessDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['ready', 'issues']);
      final val = PublishReadinessDto(
        ready: $checkedConvert('ready', (v) => v as bool),
        issues: $checkedConvert(
          'issues',
          (v) => (v as List<dynamic>)
              .map((e) => PublishIssueDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PublishReadinessDtoToJson(
  PublishReadinessDto instance,
) => <String, dynamic>{
  'ready': instance.ready,
  'issues': instance.issues.map((e) => e.toJson()).toList(),
};
