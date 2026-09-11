// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grade_cell_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GradeCellDtoCWProxy {
  GradeCellDto id(String id);

  GradeCellDto studentId(num studentId);

  GradeCellDto studentName(String studentName);

  GradeCellDto active(bool active);

  GradeCellDto componentId(num componentId);

  GradeCellDto componentName(String componentName);

  GradeCellDto coefficient(String coefficient);

  GradeCellDto required_(bool required_);

  GradeCellDto displayOrder(num displayOrder);

  GradeCellDto value(String? value);

  GradeCellDto status(GradeCellDtoStatusEnum status);

  GradeCellDto source_(GradeCellDtoSource_Enum source_);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradeCellDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradeCellDto(...).copyWith(id: 12, name: "My name")
  /// ````
  GradeCellDto call({
    String id,
    num studentId,
    String studentName,
    bool active,
    num componentId,
    String componentName,
    String coefficient,
    bool required_,
    num displayOrder,
    String? value,
    GradeCellDtoStatusEnum status,
    GradeCellDtoSource_Enum source_,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGradeCellDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGradeCellDto.copyWith.fieldName(...)`
class _$GradeCellDtoCWProxyImpl implements _$GradeCellDtoCWProxy {
  const _$GradeCellDtoCWProxyImpl(this._value);

  final GradeCellDto _value;

  @override
  GradeCellDto id(String id) => this(id: id);

  @override
  GradeCellDto studentId(num studentId) => this(studentId: studentId);

  @override
  GradeCellDto studentName(String studentName) =>
      this(studentName: studentName);

  @override
  GradeCellDto active(bool active) => this(active: active);

  @override
  GradeCellDto componentId(num componentId) => this(componentId: componentId);

  @override
  GradeCellDto componentName(String componentName) =>
      this(componentName: componentName);

  @override
  GradeCellDto coefficient(String coefficient) =>
      this(coefficient: coefficient);

  @override
  GradeCellDto required_(bool required_) => this(required_: required_);

  @override
  GradeCellDto displayOrder(num displayOrder) =>
      this(displayOrder: displayOrder);

  @override
  GradeCellDto value(String? value) => this(value: value);

  @override
  GradeCellDto status(GradeCellDtoStatusEnum status) => this(status: status);

  @override
  GradeCellDto source_(GradeCellDtoSource_Enum source_) =>
      this(source_: source_);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GradeCellDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GradeCellDto(...).copyWith(id: 12, name: "My name")
  /// ````
  GradeCellDto call({
    Object? id = const $CopyWithPlaceholder(),
    Object? studentId = const $CopyWithPlaceholder(),
    Object? studentName = const $CopyWithPlaceholder(),
    Object? active = const $CopyWithPlaceholder(),
    Object? componentId = const $CopyWithPlaceholder(),
    Object? componentName = const $CopyWithPlaceholder(),
    Object? coefficient = const $CopyWithPlaceholder(),
    Object? required_ = const $CopyWithPlaceholder(),
    Object? displayOrder = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
  }) {
    return GradeCellDto(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      studentId: studentId == const $CopyWithPlaceholder()
          ? _value.studentId
          // ignore: cast_nullable_to_non_nullable
          : studentId as num,
      studentName: studentName == const $CopyWithPlaceholder()
          ? _value.studentName
          // ignore: cast_nullable_to_non_nullable
          : studentName as String,
      active: active == const $CopyWithPlaceholder()
          ? _value.active
          // ignore: cast_nullable_to_non_nullable
          : active as bool,
      componentId: componentId == const $CopyWithPlaceholder()
          ? _value.componentId
          // ignore: cast_nullable_to_non_nullable
          : componentId as num,
      componentName: componentName == const $CopyWithPlaceholder()
          ? _value.componentName
          // ignore: cast_nullable_to_non_nullable
          : componentName as String,
      coefficient: coefficient == const $CopyWithPlaceholder()
          ? _value.coefficient
          // ignore: cast_nullable_to_non_nullable
          : coefficient as String,
      required_: required_ == const $CopyWithPlaceholder()
          ? _value.required_
          // ignore: cast_nullable_to_non_nullable
          : required_ as bool,
      displayOrder: displayOrder == const $CopyWithPlaceholder()
          ? _value.displayOrder
          // ignore: cast_nullable_to_non_nullable
          : displayOrder as num,
      value: value == const $CopyWithPlaceholder()
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as GradeCellDtoStatusEnum,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as GradeCellDtoSource_Enum,
    );
  }
}

extension $GradeCellDtoCopyWith on GradeCellDto {
  /// Returns a callable class that can be used as follows: `instanceOfGradeCellDto.copyWith(...)` or like so:`instanceOfGradeCellDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GradeCellDtoCWProxy get copyWith => _$GradeCellDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GradeCellDto _$GradeCellDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'GradeCellDto',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'studentId',
            'studentName',
            'active',
            'componentId',
            'componentName',
            'coefficient',
            'required',
            'displayOrder',
            'value',
            'status',
            'source',
          ],
        );
        final val = GradeCellDto(
          id: $checkedConvert('id', (v) => v as String),
          studentId: $checkedConvert('studentId', (v) => v as num),
          studentName: $checkedConvert('studentName', (v) => v as String),
          active: $checkedConvert('active', (v) => v as bool),
          componentId: $checkedConvert('componentId', (v) => v as num),
          componentName: $checkedConvert('componentName', (v) => v as String),
          coefficient: $checkedConvert('coefficient', (v) => v as String),
          required_: $checkedConvert('required', (v) => v as bool),
          displayOrder: $checkedConvert('displayOrder', (v) => v as num),
          value: $checkedConvert('value', (v) => v as String?),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$GradeCellDtoStatusEnumEnumMap, v),
          ),
          source_: $checkedConvert(
            'source',
            (v) => $enumDecode(_$GradeCellDtoSource_EnumEnumMap, v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {'required_': 'required', 'source_': 'source'},
    );

Map<String, dynamic> _$GradeCellDtoToJson(GradeCellDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studentId': instance.studentId,
      'studentName': instance.studentName,
      'active': instance.active,
      'componentId': instance.componentId,
      'componentName': instance.componentName,
      'coefficient': instance.coefficient,
      'required': instance.required_,
      'displayOrder': instance.displayOrder,
      'value': instance.value,
      'status': _$GradeCellDtoStatusEnumEnumMap[instance.status]!,
      'source': _$GradeCellDtoSource_EnumEnumMap[instance.source_]!,
    };

const _$GradeCellDtoStatusEnumEnumMap = {
  GradeCellDtoStatusEnum.CHUA_CO: 'CHUA_CO',
  GradeCellDtoStatusEnum.CHO_DOI_CHIEU: 'CHO_DOI_CHIEU',
  GradeCellDtoStatusEnum.DA_DUYET: 'DA_DUYET',
};

const _$GradeCellDtoSource_EnumEnumMap = {
  GradeCellDtoSource_Enum.NHAP_TAY: 'NHAP_TAY',
  GradeCellDtoSource_Enum.NHAN_DIEN: 'NHAN_DIEN',
};
