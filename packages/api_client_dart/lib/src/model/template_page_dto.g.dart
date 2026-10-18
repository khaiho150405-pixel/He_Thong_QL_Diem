// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_page_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TemplatePageDtoCWProxy {
  TemplatePageDto items(List<TemplateSummaryDto> items);

  TemplatePageDto nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TemplatePageDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TemplatePageDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TemplatePageDto call({List<TemplateSummaryDto> items, String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTemplatePageDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTemplatePageDto.copyWith.fieldName(...)`
class _$TemplatePageDtoCWProxyImpl implements _$TemplatePageDtoCWProxy {
  const _$TemplatePageDtoCWProxyImpl(this._value);

  final TemplatePageDto _value;

  @override
  TemplatePageDto items(List<TemplateSummaryDto> items) => this(items: items);

  @override
  TemplatePageDto nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TemplatePageDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TemplatePageDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TemplatePageDto call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return TemplatePageDto(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<TemplateSummaryDto>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $TemplatePageDtoCopyWith on TemplatePageDto {
  /// Returns a callable class that can be used as follows: `instanceOfTemplatePageDto.copyWith(...)` or like so:`instanceOfTemplatePageDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TemplatePageDtoCWProxy get copyWith => _$TemplatePageDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TemplatePageDto _$TemplatePageDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TemplatePageDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = TemplatePageDto(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => TemplateSummaryDto.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$TemplatePageDtoToJson(TemplatePageDto instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
