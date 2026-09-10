// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SessionDtoCWProxy {
  SessionDto id(num id);

  SessionDto username(String username);

  SessionDto role(SessionDtoRoleEnum role);

  SessionDto active(bool active);

  SessionDto token(String? token);

  SessionDto csrf(String csrf);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SessionDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SessionDto(...).copyWith(id: 12, name: "My name")
  /// ````
  SessionDto call({
    num id,
    String username,
    SessionDtoRoleEnum role,
    bool active,
    String? token,
    String csrf,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSessionDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSessionDto.copyWith.fieldName(...)`
class _$SessionDtoCWProxyImpl implements _$SessionDtoCWProxy {
  const _$SessionDtoCWProxyImpl(this._value);

  final SessionDto _value;

  @override
  SessionDto id(num id) => this(id: id);

  @override
  SessionDto username(String username) => this(username: username);

  @override
  SessionDto role(SessionDtoRoleEnum role) => this(role: role);

  @override
  SessionDto active(bool active) => this(active: active);

  @override
  SessionDto token(String? token) => this(token: token);

  @override
  SessionDto csrf(String csrf) => this(csrf: csrf);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SessionDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SessionDto(...).copyWith(id: 12, name: "My name")
  /// ````
  SessionDto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? username = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? active = const $CopyWithPlaceholder(),
    Object? token = const $CopyWithPlaceholder(),
    Object? csrf = const $CopyWithPlaceholder(),
  }) {
    return SessionDto(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as num,
      username: username == const $CopyWithPlaceholder()
          ? _value.username
          // ignore: cast_nullable_to_non_nullable
          : username as String,
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as SessionDtoRoleEnum,
      active: active == const $CopyWithPlaceholder()
          ? _value.active
          // ignore: cast_nullable_to_non_nullable
          : active as bool,
      token: token == const $CopyWithPlaceholder()
          ? _value.token
          // ignore: cast_nullable_to_non_nullable
          : token as String?,
      csrf: csrf == const $CopyWithPlaceholder()
          ? _value.csrf
          // ignore: cast_nullable_to_non_nullable
          : csrf as String,
    );
  }
}

extension $SessionDtoCopyWith on SessionDto {
  /// Returns a callable class that can be used as follows: `instanceOfSessionDto.copyWith(...)` or like so:`instanceOfSessionDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SessionDtoCWProxy get copyWith => _$SessionDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionDto _$SessionDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'SessionDto',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['id', 'username', 'role', 'active', 'token', 'csrf'],
    );
    final val = SessionDto(
      id: $checkedConvert('id', (v) => v as num),
      username: $checkedConvert('username', (v) => v as String),
      role: $checkedConvert(
        'role',
        (v) => $enumDecode(_$SessionDtoRoleEnumEnumMap, v),
      ),
      active: $checkedConvert('active', (v) => v as bool),
      token: $checkedConvert('token', (v) => v as String?),
      csrf: $checkedConvert('csrf', (v) => v as String),
    );
    return val;
  },
);

Map<String, dynamic> _$SessionDtoToJson(SessionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'role': _$SessionDtoRoleEnumEnumMap[instance.role]!,
      'active': instance.active,
      'token': instance.token,
      'csrf': instance.csrf,
    };

const _$SessionDtoRoleEnumEnumMap = {
  SessionDtoRoleEnum.QUAN_TRI_VIEN: 'QUAN_TRI_VIEN',
  SessionDtoRoleEnum.GIAO_VIEN: 'GIAO_VIEN',
  SessionDtoRoleEnum.HOC_SINH: 'HOC_SINH',
};
