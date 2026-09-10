// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'years_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$YearsPageCWProxy {
  YearsPage items(List<YearsDto> items);

  YearsPage nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearsPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearsPage(...).copyWith(id: 12, name: "My name")
  /// ````
  YearsPage call({List<YearsDto> items, String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfYearsPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfYearsPage.copyWith.fieldName(...)`
class _$YearsPageCWProxyImpl implements _$YearsPageCWProxy {
  const _$YearsPageCWProxyImpl(this._value);

  final YearsPage _value;

  @override
  YearsPage items(List<YearsDto> items) => this(items: items);

  @override
  YearsPage nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `YearsPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// YearsPage(...).copyWith(id: 12, name: "My name")
  /// ````
  YearsPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return YearsPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<YearsDto>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $YearsPageCopyWith on YearsPage {
  /// Returns a callable class that can be used as follows: `instanceOfYearsPage.copyWith(...)` or like so:`instanceOfYearsPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$YearsPageCWProxy get copyWith => _$YearsPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YearsPage _$YearsPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('YearsPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = YearsPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => YearsDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$YearsPageToJson(YearsPage instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': instance.nextCursor,
};
