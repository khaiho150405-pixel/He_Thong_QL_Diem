// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignments_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AssignmentsPageCWProxy {
  AssignmentsPage items(List<AssignmentsDto> items);

  AssignmentsPage nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AssignmentsPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AssignmentsPage(...).copyWith(id: 12, name: "My name")
  /// ````
  AssignmentsPage call({List<AssignmentsDto> items, String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAssignmentsPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAssignmentsPage.copyWith.fieldName(...)`
class _$AssignmentsPageCWProxyImpl implements _$AssignmentsPageCWProxy {
  const _$AssignmentsPageCWProxyImpl(this._value);

  final AssignmentsPage _value;

  @override
  AssignmentsPage items(List<AssignmentsDto> items) => this(items: items);

  @override
  AssignmentsPage nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AssignmentsPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AssignmentsPage(...).copyWith(id: 12, name: "My name")
  /// ````
  AssignmentsPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return AssignmentsPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AssignmentsDto>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $AssignmentsPageCopyWith on AssignmentsPage {
  /// Returns a callable class that can be used as follows: `instanceOfAssignmentsPage.copyWith(...)` or like so:`instanceOfAssignmentsPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AssignmentsPageCWProxy get copyWith => _$AssignmentsPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssignmentsPage _$AssignmentsPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AssignmentsPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = AssignmentsPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => AssignmentsDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$AssignmentsPageToJson(AssignmentsPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
