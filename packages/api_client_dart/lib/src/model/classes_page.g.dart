// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classes_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ClassesPageCWProxy {
  ClassesPage items(List<ClassesDto> items);

  ClassesPage nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClassesPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClassesPage(...).copyWith(id: 12, name: "My name")
  /// ````
  ClassesPage call({List<ClassesDto> items, String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfClassesPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfClassesPage.copyWith.fieldName(...)`
class _$ClassesPageCWProxyImpl implements _$ClassesPageCWProxy {
  const _$ClassesPageCWProxyImpl(this._value);

  final ClassesPage _value;

  @override
  ClassesPage items(List<ClassesDto> items) => this(items: items);

  @override
  ClassesPage nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClassesPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClassesPage(...).copyWith(id: 12, name: "My name")
  /// ````
  ClassesPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return ClassesPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<ClassesDto>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $ClassesPageCopyWith on ClassesPage {
  /// Returns a callable class that can be used as follows: `instanceOfClassesPage.copyWith(...)` or like so:`instanceOfClassesPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ClassesPageCWProxy get copyWith => _$ClassesPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassesPage _$ClassesPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ClassesPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = ClassesPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ClassesDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ClassesPageToJson(ClassesPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
