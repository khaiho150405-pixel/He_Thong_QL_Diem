// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'components_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComponentsPageCWProxy {
  ComponentsPage items(List<ComponentsDto> items);

  ComponentsPage nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComponentsPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComponentsPage(...).copyWith(id: 12, name: "My name")
  /// ````
  ComponentsPage call({List<ComponentsDto> items, String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfComponentsPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfComponentsPage.copyWith.fieldName(...)`
class _$ComponentsPageCWProxyImpl implements _$ComponentsPageCWProxy {
  const _$ComponentsPageCWProxyImpl(this._value);

  final ComponentsPage _value;

  @override
  ComponentsPage items(List<ComponentsDto> items) => this(items: items);

  @override
  ComponentsPage nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComponentsPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComponentsPage(...).copyWith(id: 12, name: "My name")
  /// ````
  ComponentsPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return ComponentsPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<ComponentsDto>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $ComponentsPageCopyWith on ComponentsPage {
  /// Returns a callable class that can be used as follows: `instanceOfComponentsPage.copyWith(...)` or like so:`instanceOfComponentsPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComponentsPageCWProxy get copyWith => _$ComponentsPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComponentsPage _$ComponentsPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ComponentsPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = ComponentsPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ComponentsDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ComponentsPageToJson(ComponentsPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
