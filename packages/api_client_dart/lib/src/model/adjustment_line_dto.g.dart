// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adjustment_line_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdjustmentLineDtoCWProxy {
  AdjustmentLineDto cellId(String cellId);

  AdjustmentLineDto studentId(num studentId);

  AdjustmentLineDto studentName(String studentName);

  AdjustmentLineDto componentId(num componentId);

  AdjustmentLineDto componentName(String componentName);

  AdjustmentLineDto oldValue(String? oldValue);

  AdjustmentLineDto oldStatus(AdjustmentLineDtoOldStatusEnum oldStatus);

  AdjustmentLineDto newValue(String? newValue);

  AdjustmentLineDto newExempt(bool newExempt);

  AdjustmentLineDto note(String? note);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdjustmentLineDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdjustmentLineDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdjustmentLineDto call({
    String cellId,
    num studentId,
    String studentName,
    num componentId,
    String componentName,
    String? oldValue,
    AdjustmentLineDtoOldStatusEnum oldStatus,
    String? newValue,
    bool newExempt,
    String? note,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdjustmentLineDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdjustmentLineDto.copyWith.fieldName(...)`
class _$AdjustmentLineDtoCWProxyImpl implements _$AdjustmentLineDtoCWProxy {
  const _$AdjustmentLineDtoCWProxyImpl(this._value);

  final AdjustmentLineDto _value;

  @override
  AdjustmentLineDto cellId(String cellId) => this(cellId: cellId);

  @override
  AdjustmentLineDto studentId(num studentId) => this(studentId: studentId);

  @override
  AdjustmentLineDto studentName(String studentName) =>
      this(studentName: studentName);

  @override
  AdjustmentLineDto componentId(num componentId) =>
      this(componentId: componentId);

  @override
  AdjustmentLineDto componentName(String componentName) =>
      this(componentName: componentName);

  @override
  AdjustmentLineDto oldValue(String? oldValue) => this(oldValue: oldValue);

  @override
  AdjustmentLineDto oldStatus(AdjustmentLineDtoOldStatusEnum oldStatus) =>
      this(oldStatus: oldStatus);

  @override
  AdjustmentLineDto newValue(String? newValue) => this(newValue: newValue);

  @override
  AdjustmentLineDto newExempt(bool newExempt) => this(newExempt: newExempt);

  @override
  AdjustmentLineDto note(String? note) => this(note: note);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdjustmentLineDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdjustmentLineDto(...).copyWith(id: 12, name: "My name")
  /// ````
  AdjustmentLineDto call({
    Object? cellId = const $CopyWithPlaceholder(),
    Object? studentId = const $CopyWithPlaceholder(),
    Object? studentName = const $CopyWithPlaceholder(),
    Object? componentId = const $CopyWithPlaceholder(),
    Object? componentName = const $CopyWithPlaceholder(),
    Object? oldValue = const $CopyWithPlaceholder(),
    Object? oldStatus = const $CopyWithPlaceholder(),
    Object? newValue = const $CopyWithPlaceholder(),
    Object? newExempt = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return AdjustmentLineDto(
      cellId: cellId == const $CopyWithPlaceholder()
          ? _value.cellId
          // ignore: cast_nullable_to_non_nullable
          : cellId as String,
      studentId: studentId == const $CopyWithPlaceholder()
          ? _value.studentId
          // ignore: cast_nullable_to_non_nullable
          : studentId as num,
      studentName: studentName == const $CopyWithPlaceholder()
          ? _value.studentName
          // ignore: cast_nullable_to_non_nullable
          : studentName as String,
      componentId: componentId == const $CopyWithPlaceholder()
          ? _value.componentId
          // ignore: cast_nullable_to_non_nullable
          : componentId as num,
      componentName: componentName == const $CopyWithPlaceholder()
          ? _value.componentName
          // ignore: cast_nullable_to_non_nullable
          : componentName as String,
      oldValue: oldValue == const $CopyWithPlaceholder()
          ? _value.oldValue
          // ignore: cast_nullable_to_non_nullable
          : oldValue as String?,
      oldStatus: oldStatus == const $CopyWithPlaceholder()
          ? _value.oldStatus
          // ignore: cast_nullable_to_non_nullable
          : oldStatus as AdjustmentLineDtoOldStatusEnum,
      newValue: newValue == const $CopyWithPlaceholder()
          ? _value.newValue
          // ignore: cast_nullable_to_non_nullable
          : newValue as String?,
      newExempt: newExempt == const $CopyWithPlaceholder()
          ? _value.newExempt
          // ignore: cast_nullable_to_non_nullable
          : newExempt as bool,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $AdjustmentLineDtoCopyWith on AdjustmentLineDto {
  /// Returns a callable class that can be used as follows: `instanceOfAdjustmentLineDto.copyWith(...)` or like so:`instanceOfAdjustmentLineDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdjustmentLineDtoCWProxy get copyWith =>
      _$AdjustmentLineDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdjustmentLineDto _$AdjustmentLineDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdjustmentLineDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'cellId',
          'studentId',
          'studentName',
          'componentId',
          'componentName',
          'oldValue',
          'oldStatus',
          'newValue',
          'newExempt',
          'note',
        ],
      );
      final val = AdjustmentLineDto(
        cellId: $checkedConvert('cellId', (v) => v as String),
        studentId: $checkedConvert('studentId', (v) => v as num),
        studentName: $checkedConvert('studentName', (v) => v as String),
        componentId: $checkedConvert('componentId', (v) => v as num),
        componentName: $checkedConvert('componentName', (v) => v as String),
        oldValue: $checkedConvert('oldValue', (v) => v as String?),
        oldStatus: $checkedConvert(
          'oldStatus',
          (v) => $enumDecode(_$AdjustmentLineDtoOldStatusEnumEnumMap, v),
        ),
        newValue: $checkedConvert('newValue', (v) => v as String?),
        newExempt: $checkedConvert('newExempt', (v) => v as bool),
        note: $checkedConvert('note', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$AdjustmentLineDtoToJson(AdjustmentLineDto instance) =>
    <String, dynamic>{
      'cellId': instance.cellId,
      'studentId': instance.studentId,
      'studentName': instance.studentName,
      'componentId': instance.componentId,
      'componentName': instance.componentName,
      'oldValue': instance.oldValue,
      'oldStatus': _$AdjustmentLineDtoOldStatusEnumEnumMap[instance.oldStatus]!,
      'newValue': instance.newValue,
      'newExempt': instance.newExempt,
      'note': instance.note,
    };

const _$AdjustmentLineDtoOldStatusEnumEnumMap = {
  AdjustmentLineDtoOldStatusEnum.CHUA_CO: 'CHUA_CO',
  AdjustmentLineDtoOldStatusEnum.CHO_DOI_CHIEU: 'CHO_DOI_CHIEU',
  AdjustmentLineDtoOldStatusEnum.DA_DUYET: 'DA_DUYET',
  AdjustmentLineDtoOldStatusEnum.MIEN: 'MIEN',
};
