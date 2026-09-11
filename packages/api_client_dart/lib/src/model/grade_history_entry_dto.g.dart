// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grade_history_entry_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GradeHistoryEntryDtoCWProxy {
  GradeHistoryEntryDto id(String id);

  GradeHistoryEntryDto cellId(String cellId);

  GradeHistoryEntryDto editor(num editor);

  GradeHistoryEntryDto oldValue(String? oldValue);

  GradeHistoryEntryDto newValue(String? newValue);

  GradeHistoryEntryDto reason(String reason);

  GradeHistoryEntryDto timestamp(String timestamp);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradeHistoryEntryDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradeHistoryEntryDto(...).copyWith(id: 12, name: "My name")
  /// ````
  GradeHistoryEntryDto call({
    String id,
    String cellId,
    num editor,
    String? oldValue,
    String? newValue,
    String reason,
    String timestamp,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGradeHistoryEntryDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGradeHistoryEntryDto.copyWith.fieldName(...)`
class _$GradeHistoryEntryDtoCWProxyImpl
    implements _$GradeHistoryEntryDtoCWProxy {
  const _$GradeHistoryEntryDtoCWProxyImpl(this._value);

  final GradeHistoryEntryDto _value;

  @override
  GradeHistoryEntryDto id(String id) => this(id: id);

  @override
  GradeHistoryEntryDto cellId(String cellId) => this(cellId: cellId);

  @override
  GradeHistoryEntryDto editor(num editor) => this(editor: editor);

  @override
  GradeHistoryEntryDto oldValue(String? oldValue) => this(oldValue: oldValue);

  @override
  GradeHistoryEntryDto newValue(String? newValue) => this(newValue: newValue);

  @override
  GradeHistoryEntryDto reason(String reason) => this(reason: reason);

  @override
  GradeHistoryEntryDto timestamp(String timestamp) =>
      this(timestamp: timestamp);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradeHistoryEntryDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradeHistoryEntryDto(...).copyWith(id: 12, name: "My name")
  /// ````
  GradeHistoryEntryDto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? cellId = const $CopyWithPlaceholder(),
    Object? editor = const $CopyWithPlaceholder(),
    Object? oldValue = const $CopyWithPlaceholder(),
    Object? newValue = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? timestamp = const $CopyWithPlaceholder(),
  }) {
    return GradeHistoryEntryDto(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      cellId: cellId == const $CopyWithPlaceholder()
          ? _value.cellId
          // ignore: cast_nullable_to_non_nullable
          : cellId as String,
      editor: editor == const $CopyWithPlaceholder()
          ? _value.editor
          // ignore: cast_nullable_to_non_nullable
          : editor as num,
      oldValue: oldValue == const $CopyWithPlaceholder()
          ? _value.oldValue
          // ignore: cast_nullable_to_non_nullable
          : oldValue as String?,
      newValue: newValue == const $CopyWithPlaceholder()
          ? _value.newValue
          // ignore: cast_nullable_to_non_nullable
          : newValue as String?,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      timestamp: timestamp == const $CopyWithPlaceholder()
          ? _value.timestamp
          // ignore: cast_nullable_to_non_nullable
          : timestamp as String,
    );
  }
}

extension $GradeHistoryEntryDtoCopyWith on GradeHistoryEntryDto {
  /// Returns a callable class that can be used as follows: `instanceOfGradeHistoryEntryDto.copyWith(...)` or like so:`instanceOfGradeHistoryEntryDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GradeHistoryEntryDtoCWProxy get copyWith =>
      _$GradeHistoryEntryDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GradeHistoryEntryDto _$GradeHistoryEntryDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GradeHistoryEntryDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'cellId',
      'editor',
      'oldValue',
      'newValue',
      'reason',
      'timestamp',
    ],
  );
  final val = GradeHistoryEntryDto(
    id: $checkedConvert('id', (v) => v as String),
    cellId: $checkedConvert('cellId', (v) => v as String),
    editor: $checkedConvert('editor', (v) => v as num),
    oldValue: $checkedConvert('oldValue', (v) => v as String?),
    newValue: $checkedConvert('newValue', (v) => v as String?),
    reason: $checkedConvert('reason', (v) => v as String),
    timestamp: $checkedConvert('timestamp', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$GradeHistoryEntryDtoToJson(
  GradeHistoryEntryDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'cellId': instance.cellId,
  'editor': instance.editor,
  'oldValue': instance.oldValue,
  'newValue': instance.newValue,
  'reason': instance.reason,
  'timestamp': instance.timestamp,
};
