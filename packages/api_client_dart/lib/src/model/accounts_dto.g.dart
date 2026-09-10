// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounts_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AccountsDtoCWProxy {
  AccountsDto items(List<AccountDto> items);

  AccountsDto nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AccountsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AccountsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AccountsDto call({List<AccountDto> items, String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAccountsDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAccountsDto.copyWith.fieldName(...)`
class _$AccountsDtoCWProxyImpl implements _$AccountsDtoCWProxy {
  const _$AccountsDtoCWProxyImpl(this._value);

  final AccountsDto _value;

  @override
  AccountsDto items(List<AccountDto> items) => this(items: items);

  @override
  AccountsDto nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AccountsDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AccountsDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AccountsDto call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return AccountsDto(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AccountDto>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $AccountsDtoCopyWith on AccountsDto {
  /// Returns a callable class that can be used as follows: `instanceOfAccountsDto.copyWith(...)` or like so:`instanceOfAccountsDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AccountsDtoCWProxy get copyWith => _$AccountsDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountsDto _$AccountsDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AccountsDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = AccountsDto(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => AccountDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$AccountsDtoToJson(AccountsDto instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
