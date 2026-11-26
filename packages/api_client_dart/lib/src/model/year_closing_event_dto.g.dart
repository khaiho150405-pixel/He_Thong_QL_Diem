// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'year_closing_event_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$YearClosingEventDtoCWProxy {
  YearClosingEventDto action(String action);

  YearClosingEventDto reason(String reason);

  YearClosingEventDto actor(String actor);

  YearClosingEventDto at(String at);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearClosingEventDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearClosingEventDto(...).copyWith(id: 12, name: "My name")
  /// ````
  YearClosingEventDto call({
    String action,
    String reason,
    String actor,
    String at,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfYearClosingEventDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfYearClosingEventDto.copyWith.fieldName(...)`
class _$YearClosingEventDtoCWProxyImpl implements _$YearClosingEventDtoCWProxy {
  const _$YearClosingEventDtoCWProxyImpl(this._value);

  final YearClosingEventDto _value;

  @override
  YearClosingEventDto action(String action) => this(action: action);

  @override
  YearClosingEventDto reason(String reason) => this(reason: reason);

  @override
  YearClosingEventDto actor(String actor) => this(actor: actor);

  @override
  YearClosingEventDto at(String at) => this(at: at);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearClosingEventDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearClosingEventDto(...).copyWith(id: 12, name: "My name")
  /// ````
  YearClosingEventDto call({
    Object? action = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? actor = const $CopyWithPlaceholder(),
    Object? at = const $CopyWithPlaceholder(),
  }) {
    return YearClosingEventDto(
      action: action == const $CopyWithPlaceholder()
          ? _value.action
          // ignore: cast_nullable_to_non_nullable
          : action as String,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      actor: actor == const $CopyWithPlaceholder()
          ? _value.actor
          // ignore: cast_nullable_to_non_nullable
          : actor as String,
      at: at == const $CopyWithPlaceholder()
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as String,
    );
  }
}

extension $YearClosingEventDtoCopyWith on YearClosingEventDto {
  /// Returns a callable class that can be used as follows: `instanceOfYearClosingEventDto.copyWith(...)` or like so:`instanceOfYearClosingEventDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$YearClosingEventDtoCWProxy get copyWith =>
      _$YearClosingEventDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YearClosingEventDto _$YearClosingEventDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('YearClosingEventDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['action', 'reason', 'actor', 'at']);
      final val = YearClosingEventDto(
        action: $checkedConvert('action', (v) => v as String),
        reason: $checkedConvert('reason', (v) => v as String),
        actor: $checkedConvert('actor', (v) => v as String),
        at: $checkedConvert('at', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$YearClosingEventDtoToJson(
  YearClosingEventDto instance,
) => <String, dynamic>{
  'action': instance.action,
  'reason': instance.reason,
  'actor': instance.actor,
  'at': instance.at,
};
