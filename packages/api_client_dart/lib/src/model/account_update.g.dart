// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_update.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AccountUpdateCWProxy {
  AccountUpdate role(AccountUpdateRoleEnum role);

  AccountUpdate active(bool active);

  AccountUpdate password(String? password);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AccountUpdate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AccountUpdate(...).copyWith(id: 12, name: "My name")
  /// ````
  AccountUpdate call({
    AccountUpdateRoleEnum role,
    bool active,
    String? password,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAccountUpdate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAccountUpdate.copyWith.fieldName(...)`
class _$AccountUpdateCWProxyImpl implements _$AccountUpdateCWProxy {
  const _$AccountUpdateCWProxyImpl(this._value);

  final AccountUpdate _value;

  @override
  AccountUpdate role(AccountUpdateRoleEnum role) => this(role: role);

  @override
  AccountUpdate active(bool active) => this(active: active);

  @override
  AccountUpdate password(String? password) => this(password: password);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AccountUpdate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AccountUpdate(...).copyWith(id: 12, name: "My name")
  /// ````
  AccountUpdate call({
    Object? role = const $CopyWithPlaceholder(),
    Object? active = const $CopyWithPlaceholder(),
    Object? password = const $CopyWithPlaceholder(),
  }) {
    return AccountUpdate(
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as AccountUpdateRoleEnum,
      active: active == const $CopyWithPlaceholder()
          ? _value.active
          // ignore: cast_nullable_to_non_nullable
          : active as bool,
      password: password == const $CopyWithPlaceholder()
          ? _value.password
          // ignore: cast_nullable_to_non_nullable
          : password as String?,
    );
  }
}

extension $AccountUpdateCopyWith on AccountUpdate {
  /// Returns a callable class that can be used as follows: `instanceOfAccountUpdate.copyWith(...)` or like so:`instanceOfAccountUpdate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AccountUpdateCWProxy get copyWith => _$AccountUpdateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountUpdate _$AccountUpdateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AccountUpdate', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['role', 'active']);
      final val = AccountUpdate(
        role: $checkedConvert(
          'role',
          (v) => $enumDecode(_$AccountUpdateRoleEnumEnumMap, v),
        ),
        active: $checkedConvert('active', (v) => v as bool),
        password: $checkedConvert('password', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$AccountUpdateToJson(AccountUpdate instance) =>
    <String, dynamic>{
      'role': _$AccountUpdateRoleEnumEnumMap[instance.role]!,
      'active': instance.active,
      'password': ?instance.password,
    };

const _$AccountUpdateRoleEnumEnumMap = {
  AccountUpdateRoleEnum.QUAN_TRI_VIEN: 'QUAN_TRI_VIEN',
  AccountUpdateRoleEnum.GIAO_VIEN: 'GIAO_VIEN',
  AccountUpdateRoleEnum.HOC_SINH: 'HOC_SINH',
};
