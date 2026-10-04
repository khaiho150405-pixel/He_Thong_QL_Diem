// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semester_weights_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SemesterWeightsPageCWProxy {
  SemesterWeightsPage items(List<SemesterWeightsDto> items);

  SemesterWeightsPage nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SemesterWeightsPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SemesterWeightsPage(...).copyWith(id: 12, name: "My name")
  /// ````
  SemesterWeightsPage call({
    List<SemesterWeightsDto> items,
    String? nextCursor,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSemesterWeightsPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSemesterWeightsPage.copyWith.fieldName(...)`
class _$SemesterWeightsPageCWProxyImpl implements _$SemesterWeightsPageCWProxy {
  const _$SemesterWeightsPageCWProxyImpl(this._value);

  final SemesterWeightsPage _value;

  @override
  SemesterWeightsPage items(List<SemesterWeightsDto> items) =>
      this(items: items);

  @override
  SemesterWeightsPage nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SemesterWeightsPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SemesterWeightsPage(...).copyWith(id: 12, name: "My name")
  /// ````
  SemesterWeightsPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return SemesterWeightsPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<SemesterWeightsDto>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $SemesterWeightsPageCopyWith on SemesterWeightsPage {
  /// Returns a callable class that can be used as follows: `instanceOfSemesterWeightsPage.copyWith(...)` or like so:`instanceOfSemesterWeightsPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SemesterWeightsPageCWProxy get copyWith =>
      _$SemesterWeightsPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SemesterWeightsPage _$SemesterWeightsPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SemesterWeightsPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = SemesterWeightsPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => SemesterWeightsDto.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$SemesterWeightsPageToJson(
  SemesterWeightsPage instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': instance.nextCursor,
};
