// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'students_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StudentsPageCWProxy {
  StudentsPage items(List<StudentsDto> items);

  StudentsPage nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentsPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentsPage(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentsPage call({List<StudentsDto> items, String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStudentsPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStudentsPage.copyWith.fieldName(...)`
class _$StudentsPageCWProxyImpl implements _$StudentsPageCWProxy {
  const _$StudentsPageCWProxyImpl(this._value);

  final StudentsPage _value;

  @override
  StudentsPage items(List<StudentsDto> items) => this(items: items);

  @override
  StudentsPage nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StudentsPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StudentsPage(...).copyWith(id: 12, name: "My name")
  /// ````
  StudentsPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return StudentsPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<StudentsDto>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $StudentsPageCopyWith on StudentsPage {
  /// Returns a callable class that can be used as follows: `instanceOfStudentsPage.copyWith(...)` or like so:`instanceOfStudentsPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StudentsPageCWProxy get copyWith => _$StudentsPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentsPage _$StudentsPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StudentsPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = StudentsPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => StudentsDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$StudentsPageToJson(StudentsPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
