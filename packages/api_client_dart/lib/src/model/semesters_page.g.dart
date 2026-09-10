// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semesters_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SemestersPageCWProxy {
  SemestersPage items(List<SemestersDto> items);

  SemestersPage nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SemestersPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SemestersPage(...).copyWith(id: 12, name: "My name")
  /// ````
  SemestersPage call({List<SemestersDto> items, String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSemestersPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSemestersPage.copyWith.fieldName(...)`
class _$SemestersPageCWProxyImpl implements _$SemestersPageCWProxy {
  const _$SemestersPageCWProxyImpl(this._value);

  final SemestersPage _value;

  @override
  SemestersPage items(List<SemestersDto> items) => this(items: items);

  @override
  SemestersPage nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SemestersPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SemestersPage(...).copyWith(id: 12, name: "My name")
  /// ````
  SemestersPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return SemestersPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<SemestersDto>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $SemestersPageCopyWith on SemestersPage {
  /// Returns a callable class that can be used as follows: `instanceOfSemestersPage.copyWith(...)` or like so:`instanceOfSemestersPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SemestersPageCWProxy get copyWith => _$SemestersPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SemestersPage _$SemestersPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SemestersPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = SemestersPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => SemestersDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$SemestersPageToJson(SemestersPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
