// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounts_import_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AccountsImportInputCWProxy {
  AccountsImportInput items(List<AccountInput> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AccountsImportInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AccountsImportInput(...).copyWith(id: 12, name: "My name")
  /// ````
  AccountsImportInput call({List<AccountInput> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAccountsImportInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAccountsImportInput.copyWith.fieldName(...)`
class _$AccountsImportInputCWProxyImpl implements _$AccountsImportInputCWProxy {
  const _$AccountsImportInputCWProxyImpl(this._value);

  final AccountsImportInput _value;

  @override
  AccountsImportInput items(List<AccountInput> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AccountsImportInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AccountsImportInput(...).copyWith(id: 12, name: "My name")
  /// ````
  AccountsImportInput call({Object? items = const $CopyWithPlaceholder()}) {
    return AccountsImportInput(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AccountInput>,
    );
  }
}

extension $AccountsImportInputCopyWith on AccountsImportInput {
  /// Returns a callable class that can be used as follows: `instanceOfAccountsImportInput.copyWith(...)` or like so:`instanceOfAccountsImportInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AccountsImportInputCWProxy get copyWith =>
      _$AccountsImportInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountsImportInput _$AccountsImportInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AccountsImportInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = AccountsImportInput(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => AccountInput.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AccountsImportInputToJson(
  AccountsImportInput instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
