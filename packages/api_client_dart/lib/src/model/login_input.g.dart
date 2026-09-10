// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LoginInputCWProxy {
  LoginInput username(String username);

  LoginInput password(String password);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LoginInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LoginInput(...).copyWith(id: 12, name: "My name")
  /// ````
  LoginInput call({String username, String password});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLoginInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLoginInput.copyWith.fieldName(...)`
class _$LoginInputCWProxyImpl implements _$LoginInputCWProxy {
  const _$LoginInputCWProxyImpl(this._value);

  final LoginInput _value;

  @override
  LoginInput username(String username) => this(username: username);

  @override
  LoginInput password(String password) => this(password: password);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LoginInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LoginInput(...).copyWith(id: 12, name: "My name")
  /// ````
  LoginInput call({
    Object? username = const $CopyWithPlaceholder(),
    Object? password = const $CopyWithPlaceholder(),
  }) {
    return LoginInput(
      username: username == const $CopyWithPlaceholder()
          ? _value.username
          // ignore: cast_nullable_to_non_nullable
          : username as String,
      password: password == const $CopyWithPlaceholder()
          ? _value.password
          // ignore: cast_nullable_to_non_nullable
          : password as String,
    );
  }
}

extension $LoginInputCopyWith on LoginInput {
  /// Returns a callable class that can be used as follows: `instanceOfLoginInput.copyWith(...)` or like so:`instanceOfLoginInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LoginInputCWProxy get copyWith => _$LoginInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginInput _$LoginInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LoginInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['username', 'password']);
      final val = LoginInput(
        username: $checkedConvert('username', (v) => v as String),
        password: $checkedConvert('password', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$LoginInputToJson(LoginInput instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
    };
