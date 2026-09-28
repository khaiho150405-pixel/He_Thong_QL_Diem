// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounts_import_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AccountsImportResultCWProxy {
  AccountsImportResult imported(num imported);

  AccountsImportResult items(List<AccountDto> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AccountsImportResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AccountsImportResult(...).copyWith(id: 12, name: "My name")
  /// ````
  AccountsImportResult call({num imported, List<AccountDto> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAccountsImportResult.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAccountsImportResult.copyWith.fieldName(...)`
class _$AccountsImportResultCWProxyImpl
    implements _$AccountsImportResultCWProxy {
  const _$AccountsImportResultCWProxyImpl(this._value);

  final AccountsImportResult _value;

  @override
  AccountsImportResult imported(num imported) => this(imported: imported);

  @override
  AccountsImportResult items(List<AccountDto> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AccountsImportResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AccountsImportResult(...).copyWith(id: 12, name: "My name")
  /// ````
  AccountsImportResult call({
    Object? imported = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return AccountsImportResult(
      imported: imported == const $CopyWithPlaceholder()
          ? _value.imported
          // ignore: cast_nullable_to_non_nullable
          : imported as num,
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AccountDto>,
    );
  }
}

extension $AccountsImportResultCopyWith on AccountsImportResult {
  /// Returns a callable class that can be used as follows: `instanceOfAccountsImportResult.copyWith(...)` or like so:`instanceOfAccountsImportResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AccountsImportResultCWProxy get copyWith =>
      _$AccountsImportResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountsImportResult _$AccountsImportResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AccountsImportResult', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['imported', 'items']);
  final val = AccountsImportResult(
    imported: $checkedConvert('imported', (v) => v as num),
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => AccountDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$AccountsImportResultToJson(
  AccountsImportResult instance,
) => <String, dynamic>{
  'imported': instance.imported,
  'items': instance.items.map((e) => e.toJson()).toList(),
};
