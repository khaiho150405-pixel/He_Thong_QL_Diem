// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'try_row_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TryRowDtoCWProxy {
  TryRowDto rowIndex(num rowIndex);

  TryRowDto struck(bool struck);

  TryRowDto sttRead(num? sttRead);

  TryRowDto nameRead(String? nameRead);

  TryRowDto grades(List<TryGradeDto> grades);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TryRowDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TryRowDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TryRowDto call({
    num rowIndex,
    bool struck,
    num? sttRead,
    String? nameRead,
    List<TryGradeDto> grades,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTryRowDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTryRowDto.copyWith.fieldName(...)`
class _$TryRowDtoCWProxyImpl implements _$TryRowDtoCWProxy {
  const _$TryRowDtoCWProxyImpl(this._value);

  final TryRowDto _value;

  @override
  TryRowDto rowIndex(num rowIndex) => this(rowIndex: rowIndex);

  @override
  TryRowDto struck(bool struck) => this(struck: struck);

  @override
  TryRowDto sttRead(num? sttRead) => this(sttRead: sttRead);

  @override
  TryRowDto nameRead(String? nameRead) => this(nameRead: nameRead);

  @override
  TryRowDto grades(List<TryGradeDto> grades) => this(grades: grades);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TryRowDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TryRowDto(...).copyWith(id: 12, name: "My name")
  /// ````
  TryRowDto call({
    Object? rowIndex = const $CopyWithPlaceholder(),
    Object? struck = const $CopyWithPlaceholder(),
    Object? sttRead = const $CopyWithPlaceholder(),
    Object? nameRead = const $CopyWithPlaceholder(),
    Object? grades = const $CopyWithPlaceholder(),
  }) {
    return TryRowDto(
      rowIndex: rowIndex == const $CopyWithPlaceholder()
          ? _value.rowIndex
          // ignore: cast_nullable_to_non_nullable
          : rowIndex as num,
      struck: struck == const $CopyWithPlaceholder()
          ? _value.struck
          // ignore: cast_nullable_to_non_nullable
          : struck as bool,
      sttRead: sttRead == const $CopyWithPlaceholder()
          ? _value.sttRead
          // ignore: cast_nullable_to_non_nullable
          : sttRead as num?,
      nameRead: nameRead == const $CopyWithPlaceholder()
          ? _value.nameRead
          // ignore: cast_nullable_to_non_nullable
          : nameRead as String?,
      grades: grades == const $CopyWithPlaceholder()
          ? _value.grades
          // ignore: cast_nullable_to_non_nullable
          : grades as List<TryGradeDto>,
    );
  }
}

extension $TryRowDtoCopyWith on TryRowDto {
  /// Returns a callable class that can be used as follows: `instanceOfTryRowDto.copyWith(...)` or like so:`instanceOfTryRowDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TryRowDtoCWProxy get copyWith => _$TryRowDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TryRowDto _$TryRowDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TryRowDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'rowIndex',
          'struck',
          'sttRead',
          'nameRead',
          'grades',
        ],
      );
      final val = TryRowDto(
        rowIndex: $checkedConvert('rowIndex', (v) => v as num),
        struck: $checkedConvert('struck', (v) => v as bool),
        sttRead: $checkedConvert('sttRead', (v) => v as num?),
        nameRead: $checkedConvert('nameRead', (v) => v as String?),
        grades: $checkedConvert(
          'grades',
          (v) => (v as List<dynamic>)
              .map((e) => TryGradeDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TryRowDtoToJson(TryRowDto instance) => <String, dynamic>{
  'rowIndex': instance.rowIndex,
  'struck': instance.struck,
  'sttRead': instance.sttRead,
  'nameRead': instance.nameRead,
  'grades': instance.grades.map((e) => e.toJson()).toList(),
};
