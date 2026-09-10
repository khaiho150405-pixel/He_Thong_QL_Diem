// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AccountDtoCWProxy {
  AccountDto id(num id);

  AccountDto username(String username);

  AccountDto role(AccountDtoRoleEnum role);

  AccountDto active(bool active);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AccountDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AccountDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AccountDto call({
    num id,
    String username,
    AccountDtoRoleEnum role,
    bool active,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAccountDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAccountDto.copyWith.fieldName(...)`
class _$AccountDtoCWProxyImpl implements _$AccountDtoCWProxy {
  const _$AccountDtoCWProxyImpl(this._value);

  final AccountDto _value;

  @override
  AccountDto id(num id) => this(id: id);

  @override
  AccountDto username(String username) => this(username: username);

  @override
  AccountDto role(AccountDtoRoleEnum role) => this(role: role);

  @override
  AccountDto active(bool active) => this(active: active);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AccountDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AccountDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AccountDto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? username = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? active = const $CopyWithPlaceholder(),
  }) {
    return AccountDto(
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
          : role as AccountDtoRoleEnum,
      active: active == const $CopyWithPlaceholder()
          ? _value.active
          // ignore: cast_nullable_to_non_nullable
          : active as bool,
    );
  }
}

extension $AccountDtoCopyWith on AccountDto {
  /// Returns a callable class that can be used as follows: `instanceOfAccountDto.copyWith(...)` or like so:`instanceOfAccountDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AccountDtoCWProxy get copyWith => _$AccountDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountDto _$AccountDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AccountDto',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['id', 'username', 'role', 'active']);
    final val = AccountDto(
      id: $checkedConvert('id', (v) => v as num),
      username: $checkedConvert('username', (v) => v as String),
      role: $checkedConvert(
        'role',
        (v) => $enumDecode(_$AccountDtoRoleEnumEnumMap, v),
      ),
      active: $checkedConvert('active', (v) => v as bool),
    );
    return val;
  },
);

Map<String, dynamic> _$AccountDtoToJson(AccountDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'role': _$AccountDtoRoleEnumEnumMap[instance.role]!,
      'active': instance.active,
    };

const _$AccountDtoRoleEnumEnumMap = {
  AccountDtoRoleEnum.QUAN_TRI_VIEN: 'QUAN_TRI_VIEN',
  AccountDtoRoleEnum.GIAO_VIEN: 'GIAO_VIEN',
  AccountDtoRoleEnum.HOC_SINH: 'HOC_SINH',
};
