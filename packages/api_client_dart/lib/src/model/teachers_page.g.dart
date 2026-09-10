// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teachers_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TeachersPageCWProxy {
  TeachersPage items(List<TeachersDto> items);

  TeachersPage nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TeachersPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TeachersPage(...).copyWith(id: 12, name: "My name")
  /// ````
  TeachersPage call({List<TeachersDto> items, String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTeachersPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTeachersPage.copyWith.fieldName(...)`
class _$TeachersPageCWProxyImpl implements _$TeachersPageCWProxy {
  const _$TeachersPageCWProxyImpl(this._value);

  final TeachersPage _value;

  @override
  TeachersPage items(List<TeachersDto> items) => this(items: items);

  @override
  TeachersPage nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TeachersPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TeachersPage(...).copyWith(id: 12, name: "My name")
  /// ````
  TeachersPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return TeachersPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<TeachersDto>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $TeachersPageCopyWith on TeachersPage {
  /// Returns a callable class that can be used as follows: `instanceOfTeachersPage.copyWith(...)` or like so:`instanceOfTeachersPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TeachersPageCWProxy get copyWith => _$TeachersPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeachersPage _$TeachersPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TeachersPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = TeachersPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => TeachersDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$TeachersPageToJson(TeachersPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
