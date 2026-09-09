// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ErrorDtoCWProxy {
  ErrorDto code(String code);

  ErrorDto message(String message);

  ErrorDto details(Object? details);

  ErrorDto requestId(String requestId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ErrorDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ErrorDto(...).copyWith(id: 12, name: "My name")
  /// ````
  ErrorDto call({
    String code,
    String message,
    Object? details,
    String requestId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfErrorDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfErrorDto.copyWith.fieldName(...)`
class _$ErrorDtoCWProxyImpl implements _$ErrorDtoCWProxy {
  const _$ErrorDtoCWProxyImpl(this._value);

  final ErrorDto _value;

  @override
  ErrorDto code(String code) => this(code: code);

  @override
  ErrorDto message(String message) => this(message: message);

  @override
  ErrorDto details(Object? details) => this(details: details);

  @override
  ErrorDto requestId(String requestId) => this(requestId: requestId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ErrorDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ErrorDto(...).copyWith(id: 12, name: "My name")
  /// ````
  ErrorDto call({
    Object? code = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
    Object? details = const $CopyWithPlaceholder(),
    Object? requestId = const $CopyWithPlaceholder(),
  }) {
    return ErrorDto(
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
      details: details == const $CopyWithPlaceholder()
          ? _value.details
          // ignore: cast_nullable_to_non_nullable
          : details as Object?,
      requestId: requestId == const $CopyWithPlaceholder()
          ? _value.requestId
          // ignore: cast_nullable_to_non_nullable
          : requestId as String,
    );
  }
}

extension $ErrorDtoCopyWith on ErrorDto {
  /// Returns a callable class that can be used as follows: `instanceOfErrorDto.copyWith(...)` or like so:`instanceOfErrorDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ErrorDtoCWProxy get copyWith => _$ErrorDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErrorDto _$ErrorDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ErrorDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['code', 'message', 'details', 'requestId'],
      );
      final val = ErrorDto(
        code: $checkedConvert('code', (v) => v as String),
        message: $checkedConvert('message', (v) => v as String),
        details: $checkedConvert('details', (v) => v),
        requestId: $checkedConvert('requestId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ErrorDtoToJson(ErrorDto instance) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'details': instance.details,
  'requestId': instance.requestId,
};
