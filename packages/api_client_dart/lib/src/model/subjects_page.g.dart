// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subjects_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SubjectsPageCWProxy {
  SubjectsPage items(List<SubjectsDto> items);

  SubjectsPage nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SubjectsPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SubjectsPage(...).copyWith(id: 12, name: "My name")
  /// ````
  SubjectsPage call({List<SubjectsDto> items, String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSubjectsPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSubjectsPage.copyWith.fieldName(...)`
class _$SubjectsPageCWProxyImpl implements _$SubjectsPageCWProxy {
  const _$SubjectsPageCWProxyImpl(this._value);

  final SubjectsPage _value;

  @override
  SubjectsPage items(List<SubjectsDto> items) => this(items: items);

  @override
  SubjectsPage nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SubjectsPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SubjectsPage(...).copyWith(id: 12, name: "My name")
  /// ````
  SubjectsPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return SubjectsPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<SubjectsDto>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $SubjectsPageCopyWith on SubjectsPage {
  /// Returns a callable class that can be used as follows: `instanceOfSubjectsPage.copyWith(...)` or like so:`instanceOfSubjectsPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SubjectsPageCWProxy get copyWith => _$SubjectsPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectsPage _$SubjectsPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SubjectsPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = SubjectsPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => SubjectsDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$SubjectsPageToJson(SubjectsPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
