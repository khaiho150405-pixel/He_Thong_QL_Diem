// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PasswordInputCWProxy {
  PasswordInput currentPassword(String currentPassword);

  PasswordInput newPassword(String newPassword);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PasswordInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PasswordInput(...).copyWith(id: 12, name: "My name")
  /// ````
  PasswordInput call({String currentPassword, String newPassword});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPasswordInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPasswordInput.copyWith.fieldName(...)`
class _$PasswordInputCWProxyImpl implements _$PasswordInputCWProxy {
  const _$PasswordInputCWProxyImpl(this._value);

  final PasswordInput _value;

  @override
  PasswordInput currentPassword(String currentPassword) =>
      this(currentPassword: currentPassword);

  @override
  PasswordInput newPassword(String newPassword) =>
      this(newPassword: newPassword);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PasswordInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PasswordInput(...).copyWith(id: 12, name: "My name")
  /// ````
  PasswordInput call({
    Object? currentPassword = const $CopyWithPlaceholder(),
    Object? newPassword = const $CopyWithPlaceholder(),
  }) {
    return PasswordInput(
      currentPassword: currentPassword == const $CopyWithPlaceholder()
          ? _value.currentPassword
          // ignore: cast_nullable_to_non_nullable
          : currentPassword as String,
      newPassword: newPassword == const $CopyWithPlaceholder()
          ? _value.newPassword
          // ignore: cast_nullable_to_non_nullable
          : newPassword as String,
    );
  }
}

extension $PasswordInputCopyWith on PasswordInput {
  /// Returns a callable class that can be used as follows: `instanceOfPasswordInput.copyWith(...)` or like so:`instanceOfPasswordInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PasswordInputCWProxy get copyWith => _$PasswordInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PasswordInput _$PasswordInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PasswordInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['currentPassword', 'newPassword']);
      final val = PasswordInput(
        currentPassword: $checkedConvert('currentPassword', (v) => v as String),
        newPassword: $checkedConvert('newPassword', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PasswordInputToJson(PasswordInput instance) =>
    <String, dynamic>{
      'currentPassword': instance.currentPassword,
      'newPassword': instance.newPassword,
    };
