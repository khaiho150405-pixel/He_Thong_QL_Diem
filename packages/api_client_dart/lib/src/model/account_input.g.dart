// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AccountInputCWProxy {
  AccountInput username(String username);

  AccountInput password(String password);

  AccountInput role(AccountInputRoleEnum role);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AccountInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AccountInput(...).copyWith(id: 12, name: "My name")
  /// ````
  AccountInput call({
    String username,
    String password,
    AccountInputRoleEnum role,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAccountInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAccountInput.copyWith.fieldName(...)`
class _$AccountInputCWProxyImpl implements _$AccountInputCWProxy {
  const _$AccountInputCWProxyImpl(this._value);

  final AccountInput _value;

  @override
  AccountInput username(String username) => this(username: username);

  @override
  AccountInput password(String password) => this(password: password);

  @override
  AccountInput role(AccountInputRoleEnum role) => this(role: role);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AccountInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AccountInput(...).copyWith(id: 12, name: "My name")
  /// ````
  AccountInput call({
    Object? username = const $CopyWithPlaceholder(),
    Object? password = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
  }) {
    return AccountInput(
      username: username == const $CopyWithPlaceholder()
          ? _value.username
          // ignore: cast_nullable_to_non_nullable
          : username as String,
      password: password == const $CopyWithPlaceholder()
          ? _value.password
          // ignore: cast_nullable_to_non_nullable
          : password as String,
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as AccountInputRoleEnum,
    );
  }
}

extension $AccountInputCopyWith on AccountInput {
  /// Returns a callable class that can be used as follows: `instanceOfAccountInput.copyWith(...)` or like so:`instanceOfAccountInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AccountInputCWProxy get copyWith => _$AccountInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountInput _$AccountInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AccountInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['username', 'password', 'role']);
      final val = AccountInput(
        username: $checkedConvert('username', (v) => v as String),
        password: $checkedConvert('password', (v) => v as String),
        role: $checkedConvert(
          'role',
          (v) => $enumDecode(_$AccountInputRoleEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AccountInputToJson(AccountInput instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'role': _$AccountInputRoleEnumEnumMap[instance.role]!,
    };

const _$AccountInputRoleEnumEnumMap = {
  AccountInputRoleEnum.QUAN_TRI_VIEN: 'QUAN_TRI_VIEN',
  AccountInputRoleEnum.GIAO_VIEN: 'GIAO_VIEN',
  AccountInputRoleEnum.HOC_SINH: 'HOC_SINH',
};
