// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semester_deadlines_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SemesterDeadlinesDtoCWProxy {
  SemesterDeadlinesDto items(List<SemesterDeadlineDto> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SemesterDeadlinesDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SemesterDeadlinesDto(...).copyWith(id: 12, name: "My name")
  /// ````
  SemesterDeadlinesDto call({List<SemesterDeadlineDto> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSemesterDeadlinesDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSemesterDeadlinesDto.copyWith.fieldName(...)`
class _$SemesterDeadlinesDtoCWProxyImpl
    implements _$SemesterDeadlinesDtoCWProxy {
  const _$SemesterDeadlinesDtoCWProxyImpl(this._value);

  final SemesterDeadlinesDto _value;

  @override
  SemesterDeadlinesDto items(List<SemesterDeadlineDto> items) =>
      this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SemesterDeadlinesDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SemesterDeadlinesDto(...).copyWith(id: 12, name: "My name")
  /// ````
  SemesterDeadlinesDto call({Object? items = const $CopyWithPlaceholder()}) {
    return SemesterDeadlinesDto(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<SemesterDeadlineDto>,
    );
  }
}

extension $SemesterDeadlinesDtoCopyWith on SemesterDeadlinesDto {
  /// Returns a callable class that can be used as follows: `instanceOfSemesterDeadlinesDto.copyWith(...)` or like so:`instanceOfSemesterDeadlinesDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SemesterDeadlinesDtoCWProxy get copyWith =>
      _$SemesterDeadlinesDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SemesterDeadlinesDto _$SemesterDeadlinesDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SemesterDeadlinesDto', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = SemesterDeadlinesDto(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => SemesterDeadlineDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$SemesterDeadlinesDtoToJson(
  SemesterDeadlinesDto instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
