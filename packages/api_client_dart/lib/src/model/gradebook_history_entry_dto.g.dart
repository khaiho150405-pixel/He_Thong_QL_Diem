// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gradebook_history_entry_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GradebookHistoryEntryDtoCWProxy {
  GradebookHistoryEntryDto id(String id);

  GradebookHistoryEntryDto cellId(String cellId);

  GradebookHistoryEntryDto editor(num editor);

  GradebookHistoryEntryDto oldValue(String? oldValue);

  GradebookHistoryEntryDto newValue(String? newValue);

  GradebookHistoryEntryDto reason(String reason);

  GradebookHistoryEntryDto timestamp(String timestamp);

  GradebookHistoryEntryDto studentName(String studentName);

  GradebookHistoryEntryDto componentName(String componentName);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradebookHistoryEntryDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradebookHistoryEntryDto(...).copyWith(id: 12, name: "My name")
  /// ````
  GradebookHistoryEntryDto call({
    String id,
    String cellId,
    num editor,
    String? oldValue,
    String? newValue,
    String reason,
    String timestamp,
    String studentName,
    String componentName,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGradebookHistoryEntryDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGradebookHistoryEntryDto.copyWith.fieldName(...)`
class _$GradebookHistoryEntryDtoCWProxyImpl
    implements _$GradebookHistoryEntryDtoCWProxy {
  const _$GradebookHistoryEntryDtoCWProxyImpl(this._value);

  final GradebookHistoryEntryDto _value;

  @override
  GradebookHistoryEntryDto id(String id) => this(id: id);

  @override
  GradebookHistoryEntryDto cellId(String cellId) => this(cellId: cellId);

  @override
  GradebookHistoryEntryDto editor(num editor) => this(editor: editor);

  @override
  GradebookHistoryEntryDto oldValue(String? oldValue) =>
      this(oldValue: oldValue);

  @override
  GradebookHistoryEntryDto newValue(String? newValue) =>
      this(newValue: newValue);

  @override
  GradebookHistoryEntryDto reason(String reason) => this(reason: reason);

  @override
  GradebookHistoryEntryDto timestamp(String timestamp) =>
      this(timestamp: timestamp);

  @override
  GradebookHistoryEntryDto studentName(String studentName) =>
      this(studentName: studentName);

  @override
  GradebookHistoryEntryDto componentName(String componentName) =>
      this(componentName: componentName);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradebookHistoryEntryDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradebookHistoryEntryDto(...).copyWith(id: 12, name: "My name")
  /// ````
  GradebookHistoryEntryDto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? cellId = const $CopyWithPlaceholder(),
    Object? editor = const $CopyWithPlaceholder(),
    Object? oldValue = const $CopyWithPlaceholder(),
    Object? newValue = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? timestamp = const $CopyWithPlaceholder(),
    Object? studentName = const $CopyWithPlaceholder(),
    Object? componentName = const $CopyWithPlaceholder(),
  }) {
    return GradebookHistoryEntryDto(
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
      studentName: studentName == const $CopyWithPlaceholder()
          ? _value.studentName
          // ignore: cast_nullable_to_non_nullable
          : studentName as String,
      componentName: componentName == const $CopyWithPlaceholder()
          ? _value.componentName
          // ignore: cast_nullable_to_non_nullable
          : componentName as String,
    );
  }
}

extension $GradebookHistoryEntryDtoCopyWith on GradebookHistoryEntryDto {
  /// Returns a callable class that can be used as follows: `instanceOfGradebookHistoryEntryDto.copyWith(...)` or like so:`instanceOfGradebookHistoryEntryDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GradebookHistoryEntryDtoCWProxy get copyWith =>
      _$GradebookHistoryEntryDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GradebookHistoryEntryDto _$GradebookHistoryEntryDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GradebookHistoryEntryDto', json, ($checkedConvert) {
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
      'studentName',
      'componentName',
    ],
  );
  final val = GradebookHistoryEntryDto(
    id: $checkedConvert('id', (v) => v as String),
    cellId: $checkedConvert('cellId', (v) => v as String),
    editor: $checkedConvert('editor', (v) => v as num),
    oldValue: $checkedConvert('oldValue', (v) => v as String?),
    newValue: $checkedConvert('newValue', (v) => v as String?),
    reason: $checkedConvert('reason', (v) => v as String),
    timestamp: $checkedConvert('timestamp', (v) => v as String),
    studentName: $checkedConvert('studentName', (v) => v as String),
    componentName: $checkedConvert('componentName', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$GradebookHistoryEntryDtoToJson(
  GradebookHistoryEntryDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'cellId': instance.cellId,
  'editor': instance.editor,
  'oldValue': instance.oldValue,
  'newValue': instance.newValue,
  'reason': instance.reason,
  'timestamp': instance.timestamp,
  'studentName': instance.studentName,
  'componentName': instance.componentName,
};
